# Tài liệu thiết kế hiện đại hóa OAuth2 Server

## 1. Tổng quan

Tài liệu này định nghĩa thiết kế kỹ thuật cho nền tảng xác thực và ủy quyền mới, dựa trên [Kế hoạch chuyển đổi hiện đại hóa OAuth2 Server](README.md).
Mục tiêu chính là phân tách `service-framework` hiện tại thành nhiều thư viện hướng microservice và xây dựng một OAuth2 Server mới là `service-security` dựa trên Spring Boot 3.3.1 / JDK 21.


### 1.1. Bối cảnh và động lực

**Vấn đề hiện tại:**
- `service-framework` là một thư viện nguyên khối (monolithic library) chứa tất cả các chức năng chung
- Khó bảo trì và mở rộng do sự phụ thuộc chặt chẽ giữa các thành phần
- Sử dụng Spring Boot 2.x và JDK 11, cần nâng cấp để tận dụng các tính năng mới
- Các enum được hardcode gây khó khăn trong việc quản lý cấu hình động
- `service-oauth2-server` cũ dựa trên Spring Security OAuth2 (deprecated) cần chuyển sang Spring Authorization Server

**Giải pháp:**
- Phân tách `service-framework` thành các thư viện Spring Boot Starter độc lập, mỗi thư viện có trách nhiệm rõ ràng
- Xây dựng `service-security` mới dựa trên Spring Authorization Server (Spring Boot 3)
- Quản lý cấu hình động thông qua MongoDB (masterdata) và Spring Cloud Config
- Hỗ trợ đầy đủ các phương thức xác thực hiện có với khả năng mở rộng

### 1.2. Lợi ích kiến trúc

1. **Tính mô-đun hóa:** Mỗi thư viện có thể được phát triển, kiểm thử và triển khai độc lập
2. **Khả năng tái sử dụng:** Các dịch vụ khác có thể chỉ sử dụng các thư viện cần thiết
3. **Dễ bảo trì:** Thay đổi trong một thư viện không ảnh hưởng đến các thư viện khác
4. **Hiệu suất:** Giảm kích thước JAR và thời gian khởi động bằng cách chỉ tải các thành phần cần thiết
5. **Tương thích ngược:** Hỗ trợ đầy đủ các chức năng hiện có trong quá trình chuyển đổi

## 2. Kiến trúc tổng thể

Kiến trúc mới bao gồm một nhóm các thư viện Spring Boot Starter được phân tách rõ ràng về trách nhiệm và một OAuth2 Server mới là `service-security` sử dụng chúng.

### 2.1. Phân tách thành phần

`service-framework` nguyên khối sẽ được chia thành các thư viện sau:

-   `lib-common-models`: Các mô hình dữ liệu đơn giản (DTO, POJO) được chia sẻ giữa các dịch vụ.
-   `lib-common-utils`: Nhóm các lớp tiện ích chung.
-   `lib-spring-boot-starter-grpc`: Cung cấp cấu hình tự động cho gRPC server/client và các interceptor chung.
-   `lib-spring-boot-starter-security`: Cung cấp các bộ lọc xác thực và ủy quyền dựa trên Spring Security 6, và các chức năng liên quan đến JWT.
-   `lib-spring-boot-starter-mongodb`: Cung cấp cấu hình chung cho MongoDB, repository tùy chỉnh và các lớp document cơ sở.
-   `lib-spring-boot-starter-masterdata`: Cung cấp chức năng quản lý dữ liệu chủ (quản lý cấu hình dựa trên DB cho vai trò, quyền hạn, v.v.).
-   `lib-spring-boot-starter-web`: Cung cấp các bộ lọc Web chung, trình xử lý ngoại lệ và serializer.

#### 2.1.1. `lib-common-models`

**Mục đích:** Các mô hình dữ liệu đơn giản (DTO, POJO) được chia sẻ giữa các dịch vụ.

**Đặc điểm:**
- Không phụ thuộc vào Spring Framework (chỉ Java thuần + Lombok)
- Có thể được sử dụng trong các dự án không phải Spring Boot
- Bao gồm các lớp như:
  - Response DTOs (API response models)
  - Request DTOs (API request models)
  - Value objects (immutable data structures)
  - Enums đơn giản (không phụ thuộc vào logic nghiệp vụ)

**Ví dụ sử dụng:**
```java
// Trong lib-common-models
public class ApiResponse<T> {
    private boolean success;
    private T data;
    private String message;
    // getters/setters
}
```

**Phụ thuộc:**
- Java 21
- Lombok (để giảm boilerplate code)

---

#### 2.1.2. `lib-common-utils`

**Mục đích:** Nhóm các lớp tiện ích chung không phụ thuộc vào framework.

**Các tiện ích chính:**
- `CaseConvertUtils`: Chuyển đổi kiểu chữ (camelCase, snake_case, etc.)
- `Dates`: Xử lý ngày tháng (format, parse, timezone conversion)
- `KanaUtils`: Xử lý ký tự Kana (Hiragana/Katakana conversion)
- `Strings`: Xử lý chuỗi (null-safe operations, validation)

**Ví dụ sử dụng:**
```java
import jp.drjoy.lib.utils.Strings;
import jp.drjoy.lib.utils.Dates;

String result = Strings.nvl(null, "default"); // "default"
Date utcDate = Dates.formatUTC(new Date());
```

**Phụ thuộc:**
- Java 21
- Lombok

---

#### 2.1.3. `lib-spring-boot-starter-grpc`

**Mục đích:** Cung cấp cấu hình tự động cho gRPC server/client và các interceptor chung.

**Tính năng:**
- **AutoConfiguration:** Tự động cấu hình gRPC server và client dựa trên `application.yml`
- **Server Interceptors:**
  - `GrpcAuthServerInterceptor`: Xác thực JWT từ metadata gRPC
  - `ErrorHandlingInterceptor`: Xử lý lỗi thống nhất và chuyển đổi sang StatusRuntimeException
- **Client Interceptors:**
  - `GrpcAuthClientInterceptor`: Tự động thêm JWT token vào metadata khi gọi gRPC
- **Health Check:** Tích hợp với Spring Boot Actuator

**Cấu hình mẫu:**
```yaml
grpc:
  server:
    port: 9090
  client:
    channels:
      registration:
        address: static://localhost:9091
        negotiation-type: plaintext
```

**Phụ thuộc:**
- Spring Boot 3.x
- gRPC Java libraries
- Spring Cloud Context (cho refresh configuration)

---

#### 2.1.4. `lib-spring-boot-starter-security`

**Mục đích:** Cung cấp các bộ lọc xác thực và ủy quyền dựa trên Spring Security 6, và các chức năng liên quan đến JWT.

**Tính năng chính:**

1. **JWT Authentication:**
   - `JwtAuthenticationFilter`: Xác thực JWT token từ Authorization header
   - `UserAuthenticationConverter`: Chuyển đổi JWT claims thành UserDetails
   - Hỗ trợ cả JWT access token và refresh token

2. **Password Hashing:**
   - `BCryptService`: Băm mật khẩu bằng BCrypt
   - `ShaPasswordService`: Băm mật khẩu bằng SHA (legacy support)

3. **Security Filters:**
   - `MaintenanceRequestFilter`: Kiểm tra chế độ bảo trì hệ thống
   - `RecaptchaCheckerFilter`: Xác minh reCAPTCHA v3
   - `TwoFactorAuthenticationFilter`: Xác minh xác thực hai yếu tố (2FA)

4. **AutoConfiguration:**
   - Tự động cấu hình `SecurityFilterChain` với các filter trên
   - Tích hợp với Spring Authorization Server

**Ví dụ cấu hình:**
```yaml
security:
  jwt:
    public-key-location: classpath:public-key.pem
    issuer: https://auth.drjoy.jp
  maintenance:
    enabled: false
  recaptcha:
    enabled: true
    min-score: 0.5
```

**Phụ thuộc:**
- Spring Boot 3.x
- Spring Security 6.x
- JJWT (Java JWT library)

---

#### 2.1.5. `lib-spring-boot-starter-mongodb`

**Mục đích:** Cung cấp cấu hình chung cho MongoDB, repository tùy chỉnh và các lớp document cơ sở.

**Tính năng:**

1. **Base Document Classes:**
   - `BaseDocument`: Lớp cơ sở cho tất cả MongoDB documents
   - Hỗ trợ audit fields (createdAt, updatedAt, createdBy, updatedBy)
   - Soft delete support

2. **Custom Repository:**
   - `BaseRepository<T>`: Repository interface với các phương thức chung
   - Hỗ trợ tìm kiếm, phân trang, sắp xếp

3. **MongoDB Configuration:**
   - Tự động cấu hình `MongoTemplate` và `MongoClient`
   - Hỗ trợ transaction (MongoDB 4.0+)
   - Connection pooling configuration

**Ví dụ sử dụng:**
```java
@Document(collection = "users")
public class UserDocument extends BaseDocument {
    private String email;
    private String passwordHash;
    // ...
}

public interface UserRepository extends BaseRepository<UserDocument> {
    Optional<UserDocument> findByEmail(String email);
}
```

**Phụ thuộc:**
- Spring Boot 3.x
- Spring Data MongoDB
- MongoDB Java Driver

---

#### 2.1.6. `lib-spring-boot-starter-masterdata`

**Mục đích:** Cung cấp chức năng quản lý dữ liệu chủ (quản lý cấu hình dựa trên DB cho vai trò, quyền hạn, v.v.).

**Tính năng:**

1. **Master Data Management:**
   - `RoleMasterService`: Quản lý vai trò (roles)
   - `StaffAuthorityMasterService`: Quản lý quyền hạn nhân viên
   - `MasterDataCacheService`: Cache dữ liệu chủ trong memory

2. **Data Models:**
   - `RoleDocument`: Vai trò người dùng
   - `StaffAuthorityDocument`: Quyền hạn nhân viên
   - `MasterDataDocument`: Dữ liệu chủ tổng quát

3. **Cache Strategy:**
   - Load dữ liệu từ MongoDB khi khởi động ứng dụng
   - Cache trong memory với TTL (Time To Live)
   - API refresh cache (không cần restart)

**Ví dụ sử dụng:**
```java
@Service
public class MyService {
    @Autowired
    private RoleMasterService roleMasterService;
    
    public boolean hasRole(String userId, String roleName) {
        return roleMasterService.hasRole(userId, roleName);
    }
}
```

**Cấu hình:**
```yaml
masterdata:
  cache:
    enabled: true
    ttl: 3600 # seconds
  collections:
    roles: roles
    authorities: staff_authorities
```

**Phụ thuộc:**
- Spring Boot 3.x
- `lib-spring-boot-starter-mongodb`
- Spring Cache

---

#### 2.1.7. `lib-spring-boot-starter-web`

**Mục đích:** Cung cấp các bộ lọc Web chung, trình xử lý ngoại lệ và serializer.

**Tính năng:**

1. **Exception Handling:**
   - `GlobalExceptionHandler`: Xử lý ngoại lệ toàn cục
   - Chuyển đổi exception thành response JSON chuẩn
   - Hỗ trợ validation errors, business exceptions

2. **Request/Response Interceptors:**
   - `RequestHandlerInterceptor`: Logging request/response
   - Request ID generation và propagation
   - Performance monitoring

3. **Serialization:**
   - Custom Jackson serializers/deserializers
   - Date/Time formatting
   - Null-safe serialization

4. **CORS Configuration:**
   - Tự động cấu hình CORS dựa trên profile (dev/prod)
   - Hỗ trợ multiple origins

**Ví dụ exception handling:**
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<?>> handleBusinessException(BusinessException e) {
        return ResponseEntity.status(e.getStatusCode())
            .body(ApiResponse.error(e.getMessage()));
    }
}
```

**Phụ thuộc:**
- Spring Boot 3.x
- Spring Web
- Jackson
 
### 2.2. Hiện đại hóa quản lý cấu hình

Loại bỏ các `enum` được hardcode và giới thiệu một cơ chế để quản lý cấu hình động từ bên ngoài.

-   **Cấu hình liên quan đến logic nghiệp vụ (vai trò, quyền hạn, v.v.):**
    -   Sử dụng MongoDB làm dữ liệu chủ.
    -   Mỗi dịch vụ sẽ đọc cấu hình từ DB khi khởi động và lưu vào bộ đệm. Chức năng này sẽ được triển khai trong thư viện chuyên dụng `lib-spring-boot-starter-masterdata`.
-   **Cấu hình hệ thống (loại dịch vụ, v.v.):**
    -   Sử dụng Spring Cloud Config Server để quản lý tập trung bằng các tệp `.yml`.

#### 2.2.1. Cấu hình liên quan đến logic nghiệp vụ

**Vấn đề:** Các enum như `Role`, `StaffAuthority` được hardcode trong code, khó thay đổi mà không cần deploy lại.

**Giải pháp:** Sử dụng MongoDB làm dữ liệu chủ (masterdata).

**Cơ chế hoạt động:**

1. **Lưu trữ trong MongoDB:**
   ```javascript
   // Collection: roles
   {
     "_id": ObjectId("..."),
     "name": "ADMIN",
     "description": "Quản trị viên hệ thống",
     "permissions": ["user.read", "user.write"],
     "createdAt": ISODate("2024-01-01T00:00:00Z"),
     "updatedAt": ISODate("2024-01-01T00:00:00Z")
   }
   ```

2. **Cache trong memory:**
   - Đọc tất cả dữ liệu chủ khi khởi động ứng dụng
   - Lưu vào `ConcurrentHashMap` hoặc `Caffeine Cache`
   - TTL (Time To Live) có thể cấu hình

3. **Refresh cache:**
   - API endpoint để refresh cache: `POST /admin/masterdata/refresh`
   - Hoặc tự động refresh theo schedule (ví dụ: mỗi 1 giờ)

**Ví dụ implementation:**
```java
@Service
public class MasterDataCacheService {
    private final Map<String, RoleDocument> roleCache = new ConcurrentHashMap<>();
    
    @PostConstruct
    public void loadCache() {
        List<RoleDocument> roles = roleRepository.findAll();
        roles.forEach(role -> roleCache.put(role.getName(), role));
    }
    
    public Optional<RoleDocument> getRole(String name) {
        return Optional.ofNullable(roleCache.get(name));
    }
    
    @CacheEvict(value = "masterdata", allEntries = true)
    public void refreshCache() {
        loadCache();
    }
}
```

**Lợi ích:**
- Thay đổi cấu hình mà không cần deploy lại code
- Dễ dàng quản lý và audit thay đổi
- Hỗ trợ multiple environments (dev, staging, prod)

**Quy trình đồng bộ hóa:**
- Xem chi tiết trong [service-framework-masterdata-sync-guide.md](service-framework-masterdata-sync-guide.md)

---

#### 2.2.2. Cấu hình hệ thống

**Vấn đề:** Cấu hình như `ServiceType`, `HealthyProbe` được hardcode trong code.

**Giải pháp:** Sử dụng Spring Cloud Config Server để quản lý tập trung bằng các tệp `.yml`.

**Cấu trúc cấu hình:**

```
configuration-repo/
├── application.yml (cấu hình chung)
├── application-dev.yml
├── application-staging.yml
└── application-prod.yml
```

**Ví dụ cấu hình:**
```yaml
# application.yml
drjoy:
  services:
    registration:
      type: INTERNAL
      health-probe: /actuator/health
    web-front:
      type: EXTERNAL
      health-probe: /health
```

**Sử dụng trong code:**
```java
@ConfigurationProperties(prefix = "drjoy.services")
public class ServiceConfig {
    private Map<String, ServiceInfo> services;
    // getters/setters
}

@Service
public class MyService {
    @Value("${drjoy.services.registration.type}")
    private String registrationServiceType;
}
```

**Lợi ích:**
- Quản lý cấu hình tập trung
- Hỗ trợ multiple environments
- Có thể refresh cấu hình mà không cần restart (Spring Cloud Context Refresh)
- Version control cho cấu hình

---

#### 2.2.3. So sánh hai phương pháp

| Tiêu chí | Masterdata (MongoDB) | Spring Cloud Config |
|----------|---------------------|---------------------|
| **Loại cấu hình** | Logic nghiệp vụ (roles, permissions) | Cấu hình hệ thống (service types, URLs) |
| **Tần suất thay đổi** | Thường xuyên | Ít thay đổi |
| **Người quản lý** | Business users (qua admin UI) | DevOps/Developers |
| **Cần restart?** | Không (có cache refresh) | Không (có context refresh) |
| **Version control** | Qua MongoDB audit | Qua Git |
| **Performance** | Cache trong memory | Đọc từ Config Server |

## 3. Thiết kế `service-security`

`service-security` là một OAuth2 Server mới dựa trên Spring Authorization Server.

### 3.1. Các dependency chính

-   Spring Boot 3.x / JDK 21
-   `spring-boot-starter-oauth2-authorization-server`
-   Nhóm các thư viện `lib-spring-boot-starter-*` đã được định nghĩa ở trên.

**Core Dependencies:**
- Spring Boot 3.3.1 / JDK 21
- `spring-boot-starter-oauth2-authorization-server`: Spring Authorization Server (thay thế Spring Security OAuth2 deprecated)
- `spring-boot-starter-web`: REST API endpoints
- `spring-boot-starter-data-mongodb`: Lưu trữ users, clients, authorizations

**Library Dependencies:**
- `lib-spring-boot-starter-security`: JWT authentication, security filters
- `lib-spring-boot-starter-mongodb`: MongoDB configuration và base repositories
- `lib-spring-boot-starter-masterdata`: Master data management (roles, permissions)
- `lib-spring-boot-starter-web`: Exception handling, request interceptors
- `lib-spring-boot-starter-grpc`: gRPC client/server cho tích hợp với các services khác
- `lib-common-models`: Shared DTOs
- `lib-common-utils`: Utility classes

**Additional Dependencies:**
- `firebase-admin`: Firebase token generation
- `jjwt`: JWT token parsing và validation
- `grpc-*`: gRPC libraries

**Ví dụ pom.xml:**
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-authorization-server</artifactId>
    </dependency>
    <dependency>
        <groupId>jp.drjoy</groupId>
        <artifactId>lib-spring-boot-starter-security</artifactId>
        <version>0.1.0-SNAPSHOT</version>
    </dependency>
    <!-- ... các thư viện khác ... -->
</dependencies>
```

### 3.2. Cơ chế xác thực

Để hỗ trợ các phương thức xác thực đa dạng hiện có, sẽ triển khai nhiều nhà cung cấp xác thực tùy chỉnh. Chúng sẽ được triển khai dưới dạng `AuthenticationProvider` của Spring Authorization Server.

-   `DrjoyPasswordAuthenticationProvider`: Xác thực ID/PW cho người dùng Dr.JOY
-   `PrjoyPasswordAuthenticationProvider`: Xác thực ID/PW cho người dùng PR.JOY
-   `AdminPasswordAuthenticationProvider`: Xác thực ID/PW cho quản trị viên
-   `QuickPersonalAuthenticationProvider`: Đăng nhập nhanh cho mục đích sử dụng cá nhân
-   `NologinMeetingAuthenticationProvider`: Xác thực không cần đăng nhập cho hội nghị web
-   `NologinAnswerSurveyAuthenticationProvider`: Xác thực không cần đăng nhập để trả lời khảo sát
-   `NologinPersonalInvitationAuthenticationProvider`: Xác thực không cần đăng nhập cho lời mời cá nhân
-   `JoyPassAuthenticationProvider`: Xác thực cho người dùng JoyPass
-   `SchoolPasswordAuthenticationProvider`: Xác thực ID/PW cho chức năng trường học
-   `SsoAuthenticationProvider`: Xác thực SSO
**Kiến trúc Authentication Provider:**

```
OAuth2AuthorizationEndpoint
    ↓
AuthenticationManager
    ↓
┌─────────────────────────────────────┐
│  AuthenticationProvider Chain       │
├─────────────────────────────────────┤
│ 1. DrjoyPasswordAuthenticationProvider │
│ 2. PrjoyPasswordAuthenticationProvider │
│ 3. AdminPasswordAuthenticationProvider  │
│ 4. QuickPersonalAuthenticationProvider  │
│ 5. NologinMeetingAuthenticationProvider │
│ 6. NologinAnswerSurveyAuthenticationProvider │
│ 7. NologinPersonalInvitationAuthenticationProvider │
│ 8. JoyPassAuthenticationProvider     │
│ 9. SchoolPasswordAuthenticationProvider │
│ 10. SsoAuthenticationProvider       │
└─────────────────────────────────────┘
    ↓
UserDetailsService (load user info)
    ↓
Authentication Success
```

#### 3.2.1. Password-based Authentication Providers

**1. `DrjoyPasswordAuthenticationProvider`**
- **Mục đích:** Xác thực ID/PW cho người dùng Dr.JOY (bệnh nhân)
- **Grant Type:** `password` hoặc `authorization_code`
- **Client ID:** `drjoy-web`, `drjoy-mobile`
- **Flow:**
  1. Nhận username/password từ request
  2. Gọi `GrpcRegistrationAuthClient` để xác thực với service-registration
  3. Verify password hash (BCrypt hoặc SHA)
  4. Load user details từ MongoDB
  5. Tạo `OAuth2Authentication` với user info và authorities

**2. `PrjoyPasswordAuthenticationProvider`**
- **Mục đích:** Xác thực ID/PW cho người dùng PR.JOY (nhân viên y tế)
- **Tương tự DrjoyPasswordAuthenticationProvider** nhưng:
  - Client ID: `prjoy-web`, `prjoy-mobile`
  - Load thêm thông tin staff authority từ masterdata
  - Hỗ trợ 2FA (Two-Factor Authentication)

**3. `AdminPasswordAuthenticationProvider`**
- **Mục đích:** Xác thực ID/PW cho quản trị viên hệ thống
- **Đặc biệt:**
  - Client ID: `admin-web`
  - Yêu cầu role `ADMIN` hoặc `SUPER_ADMIN`
  - Logging chi tiết cho security audit
  - Rate limiting nghiêm ngặt hơn

**4. `SchoolPasswordAuthenticationProvider`**
- **Mục đích:** Xác thực ID/PW cho chức năng trường học
- **Client ID:** `school-web`
- **Flow:** Tương tự DrjoyPasswordAuthenticationProvider nhưng với business logic riêng cho trường học

#### 3.2.2. Token-based Authentication Providers

**5. `QuickPersonalAuthenticationProvider`**
- **Mục đích:** Đăng nhập nhanh cho mục đích sử dụng cá nhân
- **Flow:**
  1. Nhận quick login token từ request
  2. Verify token với `QuickLoginService` (gọi service-registration qua gRPC)
  3. Token có TTL ngắn (ví dụ: 5 phút)
  4. Một lần sử dụng (single-use token)

**6. `JoyPassAuthenticationProvider`**
- **Mục đích:** Xác thực cho người dùng JoyPass (third-party integration)
- **Flow:**
  1. Nhận JoyPass token từ request
  2. Verify token với JoyPass API (external service)
  3. Map JoyPass user ID sang Dr.JOY user ID
  4. Tạo OAuth2 token với mapped user info

#### 3.2.3. No-login Authentication Providers

**7. `NologinMeetingAuthenticationProvider`**
- **Mục đích:** Xác thực không cần đăng nhập cho hội nghị web
- **Flow:**
  1. Nhận meeting nonce token từ request
  2. Gọi `GrpcMeetingAuthenticationClient` để verify nonce
  3. Load user theo office ID (không phải user ID)
  4. Tạo temporary token với quyền hạn giới hạn
  5. Token chỉ có quyền truy cập meeting resources

**8. `NologinAnswerSurveyAuthenticationProvider`**
- **Mục đích:** Xác thực không cần đăng nhập để trả lời khảo sát
- **Flow:**
  1. Nhận survey nonce token từ request
  2. Gọi `GrpcGroupAuthenticationClient` để verify group membership
  3. Verify user có quyền trả lời survey
  4. Tạo temporary token với quyền hạn giới hạn

**9. `NologinPersonalInvitationAuthenticationProvider`**
- **Mục đích:** Xác thực không cần đăng nhập cho lời mời cá nhân
- **Flow:**
  1. Nhận invitation token từ request
  2. Gọi `GrpcRegistrationAuthClient` để verify invitation
  3. Load user info từ invitation
  4. Tạo temporary token với quyền hạn giới hạn

#### 3.2.4. SSO Authentication Provider

**10. `SsoAuthenticationProvider`**
- **Mục đích:** Xác thực SSO (Single Sign-On)
- **Flow:**
  1. Nhận SSO token từ external identity provider
  2. Verify token signature và expiration
  3. Extract user info từ SSO token claims
  4. Map SSO user sang Dr.JOY user (có thể tạo user mới nếu chưa tồn tại)
  5. Tạo OAuth2 token

#### 3.2.5. Implementation Pattern

**Ví dụ cấu trúc AuthenticationProvider:**
```java
@Component
public class DrjoyPasswordAuthenticationProvider implements AuthenticationProvider {
    
    @Autowired
    private GrpcRegistrationAuthClient registrationClient;
    
    @Autowired
    private UserDetailsService userDetailsService;
    
    @Override
    public Authentication authenticate(Authentication authentication) {
        UsernamePasswordAuthenticationToken token = 
            (UsernamePasswordAuthenticationToken) authentication;
        
        String username = token.getName();
        String password = (String) token.getCredentials();
        
        // 1. Verify credentials với service-registration
        UserLoginInfo userInfo = registrationClient.verifyPassword(username, password);
        
        // 2. Load user details
        UserDetails userDetails = userDetailsService.loadUserByUsername(username);
        
        // 3. Create authenticated token
        return new UsernamePasswordAuthenticationToken(
            userDetails, 
            null, 
            userDetails.getAuthorities()
        );
    }
    
    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class
            .isAssignableFrom(authentication);
    }
}
```

**Cấu hình trong AuthorizationServerConfig:**
```java
@Configuration
public class AuthorizationServerConfig {
    
    @Bean
    public AuthenticationManager authenticationManager(
            List<AuthenticationProvider> providers) {
        return new ProviderManager(providers);
    }
}
```
### 3.3. Tạo token

-   **Chữ ký JWT:** Tương tự như `service-oauth2-server`, sẽ áp dụng phương thức ký sử dụng keystore (`.jks`).
-   **Custom Claims:** Triển khai `OAuth2TokenCustomizer` để thêm các claim tùy chỉnh như thông tin đơn vị và quyền hạn của người dùng vào payload của JWT. Thông tin quyền hạn này sẽ được lấy từ DB thông qua cơ chế quản lý dữ liệu chủ.
#### 3.3.1. Chữ ký JWT

**Phương pháp:** Sử dụng Java KeyStore (`.jks`) để ký JWT token, tương tự như `service-oauth2-server`.

**Cấu hình:**
```yaml
oauth2:
  jwt:
    keystore:
      location: classpath:oauth2.jks
      password: ${JKS_PASSWORD}
      alias: oauth2-key
      key-password: ${JKS_KEY_PASSWORD}
```

**Implementation:**
```java
@Configuration
public class JwtKeyStoreConfig {
    
    @Bean
    public JWKSource<SecurityContext> jwkSource() throws Exception {
        KeyStore keyStore = KeyStore.getInstance("JKS");
        InputStream inputStream = new ClassPathResource("oauth2.jks")
            .getInputStream();
        keyStore.load(inputStream, keystorePassword.toCharArray());
        
        RSAKey rsaKey = RSAKey.load(
            keyStore, 
            alias, 
            keyPassword.toCharArray()
        );
        
        JWKSet jwkSet = new JWKSet(rsaKey);
        return new ImmutableJWKSet<>(jwkSet);
    }
}
```

**Lợi ích:**
- Bảo mật cao: private key được bảo vệ trong keystore
- Dễ quản lý: có thể rotate key bằng cách thay thế file `.jks`
- Tương thích: giống với hệ thống cũ

---

#### 3.3.2. Custom Claims

**Mục đích:** Thêm thông tin nghiệp vụ vào JWT payload để các service khác không cần query DB.

**Triển khai `OAuth2TokenCustomizer`:**

```java
@Component
public class CustomJwtTokenCustomizer implements OAuth2TokenCustomizer<JwtEncodingContext> {
    
    @Autowired
    private RoleMasterService roleMasterService;
    
    @Autowired
    private StaffAuthorityMasterService authorityService;
    
    @Override
    public void customize(JwtEncodingContext context) {
        OAuth2Authentication authentication = context.getPrincipal();
        
        // Extract user info
        String userId = authentication.getName();
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        
        // Get roles và permissions từ masterdata
        List<String> roles = roleMasterService.getUserRoles(userId);
        List<String> permissions = authorityService.getUserPermissions(userId);
        
        // Add custom claims
        JwtClaimsSet.Builder claims = context.getClaims();
        claims.claim("userId", userId);
        claims.claim("email", userDetails.getEmail());
        claims.claim("roles", roles);
        claims.claim("permissions", permissions);
        claims.claim("division", userDetails.getDivision());
        claims.claim("officeId", userDetails.getOfficeId());
        
        // Product-specific claims
        if (isDrjoyUser(userDetails)) {
            claims.claim("patientId", userDetails.getPatientId());
        } else if (isPrjoyUser(userDetails)) {
            claims.claim("staffId", userDetails.getStaffId());
        }
    }
}
```

**JWT Payload Structure:**
```json
{
  "sub": "user123",
  "iss": "https://auth.drjoy.jp",
  "aud": "drjoy-web",
  "exp": 1704067200,
  "iat": 1704063600,
  "jti": "token-id-123",
  "userId": "user123",
  "email": "user@example.com",
  "roles": ["USER", "PATIENT"],
  "permissions": ["appointment.read", "appointment.write"],
  "division": "TOKYO",
  "officeId": "office-001",
  "patientId": "patient-123"
}
```

**Lợi ích:**
- Giảm số lượng query DB từ các service khác
- Thông tin user được embed sẵn trong token
- Dễ dàng verify và authorize requests

---

#### 3.3.3. Token Lifetime Management

**Dynamic Token Lifetime:** Thời gian sống của token phụ thuộc vào:
- Loại client (mobile vs web)
- Product type (DRJOY, PRJOY, ADMIN, SCHOOL)
- Save login flag (remember me)

**Implementation:**
```java
@Component
public class OAuth2TokenSettingsProvider {
    
    public TokenSettings getTokenSettings(OAuth2Authentication auth) {
        String clientId = auth.getOAuth2Request().getClientId();
        boolean isMobile = isMobileClient(clientId);
        boolean saveLogin = auth.getOAuth2Request()
            .getRequestParameters().get("save_login") != null;
        
        Duration accessTokenLifetime;
        Duration refreshTokenLifetime;
        
        if (isMobile) {
            accessTokenLifetime = Duration.ofDays(30);
            refreshTokenLifetime = Duration.ofDays(90);
        } else if (saveLogin) {
            accessTokenLifetime = Duration.ofDays(7);
            refreshTokenLifetime = Duration.ofDays(90);
        } else {
            accessTokenLifetime = Duration.ofHours(1);
            refreshTokenLifetime = Duration.ofDays(7);
        }
        
        return TokenSettings.builder()
            .accessTokenTimeToLive(accessTokenLifetime)
            .refreshTokenTimeToLive(refreshTokenLifetime)
            .build();
    }
}
```

**Token Lifetime Rules:**
| Client Type | Save Login | Access Token | Refresh Token |
|-------------|------------|--------------|---------------|
| Mobile | N/A | 30 days | 90 days |
| Web | Yes | 7 days | 90 days |
| Web | No | 1 hour | 7 days |
| Admin | N/A | 1 hour | 24 hours |
### 3.4. Bộ lọc bảo mật (Security Filter)

Các interceptor hiện có sẽ được triển khai lại dưới dạng `Filter` của Spring Security và được tích hợp vào `SecurityFilterChain`.

-   `MaintenanceRequestFilter`: Kiểm tra chế độ bảo trì.
-   `RecaptchaCheckerFilter`: Xác minh reCAPTCHA.
-   `TwoFactorAuthenticationFilter`: Xác minh xác thực hai yếu tố.

Các bộ lọc này sẽ được triển khai trong `lib-spring-boot-starter-web` hoặc `lib-spring-boot-starter-security` và được kích hoạt trong `service-security`.

**Filter Chain Order:**
```
1. MaintenanceRequestFilter
2. RecaptchaCheckerFilter
3. TwoFactorAuthenticationFilter
4. JwtAuthenticationFilter
5. OAuth2AuthorizationFilter (Spring Authorization Server)
```

#### 3.4.1. `MaintenanceRequestFilter`

**Mục đích:** Kiểm tra chế độ bảo trì hệ thống và chặn requests nếu đang trong maintenance mode.

**Implementation:**
```java
@Component
public class MaintenanceRequestFilter extends OncePerRequestFilter {
    
    @Value("${maintenance.enabled:false}")
    private boolean maintenanceEnabled;
    
    @Value("${maintenance.message:システムメンテナンス中です}")
    private String maintenanceMessage;
    
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        
        if (maintenanceEnabled && !isMaintenanceBypass(request)) {
            response.setStatus(HttpStatus.SERVICE_UNAVAILABLE.value());
            response.setContentType("application/json");
            
            ApiResponse<?> error = ApiResponse.error(maintenanceMessage);
            response.getWriter().write(objectMapper.writeValueAsString(error));
            return;
        }
        
        filterChain.doFilter(request, response);
    }
    
    private boolean isMaintenanceBypass(HttpServletRequest request) {
        // Cho phép health check endpoints
        return request.getRequestURI().startsWith("/actuator/health");
    }
}
```

**Cấu hình:**
```yaml
maintenance:
  enabled: false
  message: "システムメンテナンス中です。しばらくお待ちください。"
  bypass-paths:
    - "/actuator/**"
    - "/health"
```

---

#### 3.4.2. `RecaptchaCheckerFilter`

**Mục đích:** Xác minh reCAPTCHA v3 để chống bot và spam.

**Flow:**
1. Extract reCAPTCHA token từ request header hoặc parameter
2. Gọi Google reCAPTCHA API để verify token
3. Kiểm tra score (>= 0.5 là pass)
4. Nếu fail, trả về 403 Forbidden

**Implementation:**
```java
@Component
public class RecaptchaCheckerFilter extends OncePerRequestFilter {
    
    @Autowired
    private GoogleClient googleClient;
    
    @Value("${recaptcha.enabled:true}")
    private boolean recaptchaEnabled;
    
    @Value("${recaptcha.min-score:0.5}")
    private double minScore;
    
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        
        if (!recaptchaEnabled || isRecaptchaExcluded(request)) {
            filterChain.doFilter(request, response);
            return;
        }
        
        String recaptchaToken = extractRecaptchaToken(request);
        if (recaptchaToken == null) {
            sendError(response, "reCAPTCHA token is required");
            return;
        }
        
        RecaptchaVerifyResponse verifyResponse = 
            googleClient.verifyRecaptcha(recaptchaToken);
        
        if (!verifyResponse.isSuccess() || 
            verifyResponse.getScore() < minScore) {
            sendError(response, "reCAPTCHA verification failed");
            return;
        }
        
        filterChain.doFilter(request, response);
    }
}
```

**Cấu hình:**
```yaml
recaptcha:
  enabled: true
  secret: ${RECAPTCHA_SECRET}
  verify-url: https://www.google.com/recaptcha/api/siteverify
  min-score: 0.5
  excluded-paths:
    - "/actuator/**"
    - "/health"
```

---

#### 3.4.3. `TwoFactorAuthenticationFilter`

**Mục đích:** Xác minh xác thực hai yếu tố (2FA) cho các tài khoản yêu cầu.

**Flow:**
1. Kiểm tra user có enabled 2FA không
2. Nếu có, yêu cầu OTP (One-Time Password) từ request
3. Verify OTP với `OTPService`
4. Nếu fail, trả về 428 Precondition Required (OTP required)

**Implementation:**
```java
@Component
public class TwoFactorAuthenticationFilter extends OncePerRequestFilter {
    
    @Autowired
    private OTPService otpService;
    
    @Autowired
    private UserService userService;
    
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        
        Authentication auth = SecurityContextHolder.getContext()
            .getAuthentication();
        
        if (auth == null || !auth.isAuthenticated()) {
            filterChain.doFilter(request, response);
            return;
        }
        
        UserDetails userDetails = (UserDetails) auth.getPrincipal();
        
        // Check if user requires 2FA
        if (userService.is2FARequired(userDetails.getUsername())) {
            String otp = extractOTP(request);
            
            if (otp == null || !otpService.verifyOTP(
                    userDetails.getUsername(), otp)) {
                throw new OTPRequiredException("2FA verification required");
            }
        }
        
        filterChain.doFilter(request, response);
    }
}
```

**Exception Handling:**
```java
@ExceptionHandler(OTPRequiredException.class)
public ResponseEntity<?> handleOTPRequired(OTPRequiredException e) {
    return ResponseEntity.status(428) // Precondition Required
        .body(ApiResponse.error("2FA verification required"));
}
```

---

#### 3.4.4. Filter Configuration

**Cấu hình trong SecurityFilterChain:**
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            MaintenanceRequestFilter maintenanceFilter,
            RecaptchaCheckerFilter recaptchaFilter,
            TwoFactorAuthenticationFilter twoFactorFilter) throws Exception {
        
        http
            .addFilterBefore(maintenanceFilter, 
                UsernamePasswordAuthenticationFilter.class)
            .addFilterAfter(recaptchaFilter, 
                MaintenanceRequestFilter.class)
            .addFilterAfter(twoFactorFilter, 
                RecaptchaCheckerFilter.class)
            // ... other security configurations
        
        return http.build();
    }
}
```

### 3.5. Endpoint API tùy chỉnh

Các API tùy chỉnh sau đây đã tồn tại trong `service-oauth2-server` sẽ được chuyển đổi hoặc triển khai lại trong `service-security`.

-   `/v1/certificate/check`: API thông tin chứng chỉ
-   `/fb/access/token`: API token Firebase
-   Nhóm dịch vụ gRPC
#### 3.5.1. `/v1/certificate/check`

**Mục đích:** API thông tin chứng chỉ - kiểm tra trạng thái phê duyệt chứng chỉ của user.

**Request:**
```http
GET /v1/certificate/check
Authorization: Bearer <jwt-token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "approved": true,
    "certificateType": "FP21",
    "approvalDate": "2024-01-15T00:00:00Z"
  }
}
```

**Implementation:**
```java
@RestController
@RequestMapping("/v1/certificate")
public class CertificateController {
    
    @Autowired
    private CertificateService certificateService;
    
    @GetMapping("/check")
    public ResponseEntity<CertificateInfoResponse> checkCertificate(
            @AuthenticationPrincipal UserDetails userDetails) {
        
        CertificateInfo info = certificateService.getCertificateInfo(
            userDetails.getUserId()
        );
        
        return ResponseEntity.ok(
            CertificateInfoResponse.builder()
                .approved(info.isApproved())
                .certificateType(info.getType())
                .approvalDate(info.getApprovalDate())
                .build()
        );
    }
}
```

**Business Logic:**
- Kiểm tra trạng thái phê duyệt văn phòng (office approval status)
- Kiểm tra quyền FP21 (Functional Program 21)
- Verify chứng chỉ client (nếu có)

---

#### 3.5.2. `/fb/access/token`

**Mục đích:** API token Firebase - tạo custom Firebase token với claims từ JWT hiện tại.

**Request:**
```http
GET /fb/access/token
Authorization: Bearer <jwt-token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "firebaseToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 3600
  }
}
```

**Implementation:**
```java
@RestController
@RequestMapping("/fb")
public class FirebaseAuthController {
    
    @Autowired
    private FirebaseAuthService firebaseAuthService;
    
    @GetMapping("/access/token")
    public DeferredResult<ResponseEntity<FirebaseTokenResponse>> getFirebaseToken(
            @AuthenticationPrincipal UserDetails userDetails) {
        
        DeferredResult<ResponseEntity<FirebaseTokenResponse>> result = 
            new DeferredResult<>();
        
        firebaseAuthService.createCustomToken(userDetails)
            .subscribe(
                token -> result.setResult(ResponseEntity.ok(token)),
                error -> result.setErrorResult(error)
            );
        
        return result;
    }
}
```

**Custom Claims trong Firebase Token:**
```json
{
  "uid": "user123",
  "email": "user@example.com",
  "roles": ["USER", "PATIENT"],
  "permissions": ["appointment.read"],
  "groupIds": ["group-001", "group-002"],
  "chatRoomIds": ["room-001"],
  "paymentFunctionType": "PREMIUM"
}
```

**Tích hợp với gRPC:**
- Gọi `GrpcGroupClient` để lấy group IDs
- Gọi `GrpcChatClient` để lấy chat room IDs
- Gọi `GrpcPaymentClient` để lấy payment function type

---

#### 3.5.3. Nhóm dịch vụ gRPC

**Mục đích:** Cung cấp các dịch vụ gRPC cho các service khác gọi.

**1. `GrpcActuatorServer`**
- **Service:** Actuator operations (refresh config, restart, shutdown)
- **Protocol:** gRPC
- **Endpoints:**
  - `RefreshConfig`: Refresh Spring Cloud Config
  - `Restart`: Restart application
  - `Shutdown`: Graceful shutdown

**2. `GrpcHealthServer`**
- **Service:** Health check
- **Protocol:** gRPC Health Checking Protocol
- **Tích hợp:** Spring Boot Actuator HealthIndicator

**Implementation:**
```java
@GrpcService
public class GrpcHealthServer extends HealthGrpc.HealthImplBase {
    
    @Autowired
    private HealthIndicator healthIndicator;
    
    @Override
    public void check(
            HealthCheckRequest request,
            StreamObserver<HealthCheckResponse> responseObserver) {
        
        Health health = healthIndicator.health();
        HealthCheckResponse.ServingStatus status = 
            health.getStatus() == Status.UP 
                ? ServingStatus.SERVING 
                : ServingStatus.NOT_SERVING;
        
        responseObserver.onNext(
            HealthCheckResponse.newBuilder()
                .setStatus(status)
                .build()
        );
        responseObserver.onCompleted();
    }
}
```

**Cấu hình:**
```yaml
grpc:
  server:
    port: 9090
    services:
      - name: health
        enabled: true
      - name: actuator
        enabled: true
```

---

#### 3.5.4. OAuth2 Standard Endpoints

**Spring Authorization Server cung cấp sẵn:**

- `POST /oauth2/token`: Issue access token và refresh token
- `GET /oauth2/authorize`: Authorization endpoint
- `POST /oauth2/introspect`: Token introspection
- `GET /.well-known/oauth-authorization-server`: Discovery endpoint
- `GET /.well-known/jwks.json`: JWK Set endpoint

**Custom Endpoints:**
- `POST /oauth2/revoke`: Revoke token (custom implementation)
- `GET /oauth2/userinfo`: User info endpoint (OpenID Connect)

## 4. Thiết kế dữ liệu

### 4.1. Lược đồ cơ sở dữ liệu

`service-security` sẽ sử dụng MongoDB. Các collection chính như sau:

-   **users**: Thông tin người dùng
-   **clients**: Thông tin client OAuth2 (`RegisteredClient`)
-   **authorizations**: Thông tin ủy quyền
-   **master_data**: Dữ liệu chủ như vai trò, quyền hạn

#### 4.1.1. Collection `users`

**Mục đích:** Lưu trữ thông tin người dùng.

**Schema:**
```javascript
{
  "_id": ObjectId("..."),
  "userId": "user123",
  "email": "user@example.com",
  "passwordHash": "$2a$10$...", // BCrypt hash
  "passwordHashAlgorithm": "BCRYPT", // BCRYPT or SHA
  "enabled": true,
  "accountNonLocked": true,
  "accountNonExpired": true,
  "credentialsNonExpired": true,
  "division": "TOKYO",
  "officeId": "office-001",
  "patientId": "patient-123", // for Dr.JOY users
  "staffId": "staff-456", // for PR.JOY users
  "twoFactorEnabled": false,
  "twoFactorSecret": "...", // encrypted
  "lastLoginAt": ISODate("2024-01-15T10:00:00Z"),
  "createdAt": ISODate("2024-01-01T00:00:00Z"),
  "updatedAt": ISODate("2024-01-15T10:00:00Z")
}
```

**Indexes:**
```javascript
db.users.createIndex({ "userId": 1 }, { unique: true });
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "officeId": 1 });
db.users.createIndex({ "patientId": 1 });
db.users.createIndex({ "staffId": 1 });
```

---

#### 4.1.2. Collection `clients`

**Mục đích:** Lưu trữ thông tin OAuth2 clients (`RegisteredClient`).

**Schema:**
```javascript
{
  "_id": ObjectId("..."),
  "clientId": "drjoy-web",
  "clientSecret": "$2a$10$...", // hashed
  "clientName": "Dr.JOY Web Application",
  "clientAuthenticationMethods": ["client_secret_basic", "client_secret_post"],
  "authorizationGrantTypes": ["authorization_code", "refresh_token"],
  "redirectUris": ["https://web.drjoy.jp/callback"],
  "scopes": ["openid", "profile", "email"],
  "clientSettings": {
    "requireProofKey": false,
    "requireAuthorizationConsent": true
  },
  "tokenSettings": {
    "accessTokenFormat": "SELF_CONTAINED",
    "accessTokenTimeToLive": 3600,
    "refreshTokenTimeToLive": 604800
  },
  "enabled": true,
  "createdAt": ISODate("2024-01-01T00:00:00Z"),
  "updatedAt": ISODate("2024-01-01T00:00:00Z")
}
```

**Indexes:**
```javascript
db.clients.createIndex({ "clientId": 1 }, { unique: true });
```

---

#### 4.1.3. Collection `authorizations`

**Mục đích:** Lưu trữ thông tin ủy quyền OAuth2 (authorization codes, consent).

**Schema:**
```javascript
{
  "_id": ObjectId("..."),
  "registeredClientId": "drjoy-web",
  "principalName": "user123",
  "authorizationGrantType": "authorization_code",
  "authorizedScopes": ["openid", "profile", "email"],
  "attributes": {
    "state": "...",
    "code_challenge": "...",
    "code_challenge_method": "S256"
  },
  "state": "PENDING", // PENDING, APPROVED, DENIED
  "authorizationCodeValue": "...", // encrypted
  "authorizationCodeIssuedAt": ISODate("2024-01-15T10:00:00Z"),
  "authorizationCodeExpiresAt": ISODate("2024-01-15T10:10:00Z"),
  "createdAt": ISODate("2024-01-15T10:00:00Z")
}
```

**Indexes:**
```javascript
db.authorizations.createIndex({ "registeredClientId": 1, "principalName": 1 });
db.authorizations.createIndex({ "authorizationCodeValue": 1 });
db.authorizations.createIndex({ "createdAt": 1 }, { expireAfterSeconds: 3600 }); // TTL
```

---

#### 4.1.4. Collection `master_data`

**Mục đích:** Dữ liệu chủ như vai trò, quyền hạn (được quản lý bởi `lib-spring-boot-starter-masterdata`).

**Sub-collections:**
- `roles`: Vai trò người dùng
- `staff_authorities`: Quyền hạn nhân viên
- `master_data`: Dữ liệu chủ tổng quát

**Schema `roles`:**
```javascript
{
  "_id": ObjectId("..."),
  "name": "ADMIN",
  "description": "Quản trị viên hệ thống",
  "permissions": ["user.read", "user.write", "system.admin"],
  "enabled": true,
  "createdAt": ISODate("2024-01-01T00:00:00Z"),
  "updatedAt": ISODate("2024-01-01T00:00:00Z")
}
```

**Schema `staff_authorities`:**
```javascript
{
  "_id": ObjectId("..."),
  "name": "APPOINTMENT_MANAGEMENT",
  "description": "Quản lý lịch hẹn",
  "category": "APPOINTMENT",
  "enabled": true,
  "createdAt": ISODate("2024-01-01T00:00:00Z"),
  "updatedAt": ISODate("2024-01-01T00:00:00Z")
}
```

---

### 4.2. Di chuyển dữ liệu

-   **Thông tin client:** Tạo một script di chuyển để chuyển đổi dữ liệu từ `oauth_client_details` cũ sang định dạng `RegisteredClient` của Spring Authorization Server.
-   **Thông tin người dùng:** Di chuyển thông tin người dùng hiện có để phù hợp với lược đồ mới. Mật khẩu sẽ được băm lại nếu cần.
-   **Refresh token:** Về nguyên tắc, các refresh token hiện có sẽ bị vô hiệu hóa. Chiến lược di chuyển sẽ được xem xét riêng.
#### 4.2.1. Thông tin client

**Nguồn:** MySQL table `oauth_client_details` (hệ thống cũ)

**Đích:** MongoDB collection `clients`

**Script di chuyển:**
```java
@Component
public class ClientMigrationService {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Autowired
    private RegisteredClientRepository clientRepository;
    
    public void migrateClients() {
        List<Map<String, Object>> oldClients = jdbcTemplate.queryForList(
            "SELECT * FROM oauth_client_details"
        );
        
        for (Map<String, Object> oldClient : oldClients) {
            RegisteredClient newClient = RegisteredClient.withId(UUID.randomUUID().toString())
                .clientId((String) oldClient.get("client_id"))
                .clientSecret(passwordEncoder.encode(
                    (String) oldClient.get("client_secret")))
                .clientAuthenticationMethod(
                    ClientAuthenticationMethod.CLIENT_SECRET_BASIC)
                .authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
                .authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN)
                .redirectUri((String) oldClient.get("web_server_redirect_uri"))
                .scope(OidcScopes.OPENID)
                .scope(OidcScopes.PROFILE)
                .scope(OidcScopes.EMAIL)
                .clientSettings(ClientSettings.builder()
                    .requireProofKey(false)
                    .requireAuthorizationConsent(true)
                    .build())
                .tokenSettings(TokenSettings.builder()
                    .accessTokenTimeToLive(Duration.ofHours(1))
                    .refreshTokenTimeToLive(Duration.ofDays(7))
                    .build())
                .build();
            
            clientRepository.save(newClient);
        }
    }
}
```

---

#### 4.2.2. Thông tin người dùng

**Nguồn:** MySQL table `users` (hệ thống cũ)

**Đích:** MongoDB collection `users`

**Chiến lược:**
1. Export dữ liệu từ MySQL sang JSON
2. Transform schema để phù hợp với MongoDB
3. Hash lại mật khẩu nếu cần (nếu algorithm cũ không còn được hỗ trợ)
4. Import vào MongoDB

**Script di chuyển:**
```java
@Component
public class UserMigrationService {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private BCryptService bcryptService;
    
    public void migrateUsers() {
        List<Map<String, Object>> oldUsers = jdbcTemplate.queryForList(
            "SELECT * FROM users"
        );
        
        for (Map<String, Object> oldUser : oldUsers) {
            String oldPasswordHash = (String) oldUser.get("password");
            String algorithm = detectPasswordAlgorithm(oldPasswordHash);
            
            // Re-hash nếu cần
            String newPasswordHash = oldPasswordHash;
            if ("SHA".equals(algorithm)) {
                // Giữ nguyên SHA hash (legacy support)
                newPasswordHash = oldPasswordHash;
            } else if ("PLAIN".equals(algorithm)) {
                // Hash lại bằng BCrypt
                newPasswordHash = bcryptService.encode(oldPasswordHash);
            }
            
            UserDocument newUser = UserDocument.builder()
                .userId((String) oldUser.get("user_id"))
                .email((String) oldUser.get("email"))
                .passwordHash(newPasswordHash)
                .passwordHashAlgorithm(algorithm.equals("PLAIN") ? "BCRYPT" : algorithm)
                .enabled((Boolean) oldUser.get("enabled"))
                .division((String) oldUser.get("division"))
                .officeId((String) oldUser.get("office_id"))
                .createdAt(parseDate(oldUser.get("created_at")))
                .build();
            
            userRepository.save(newUser);
        }
    }
}
```

---

#### 4.2.3. Refresh token

**Chiến lược:** Về nguyên tắc, các refresh token hiện có sẽ bị vô hiệu hóa.

**Lý do:**
- Refresh token cũ không tương thích với Spring Authorization Server
- Bảo mật: Đảm bảo tất cả token được tạo lại với format mới
- Đơn giản hóa: Không cần migrate token state

**Quy trình:**
1. Thông báo trước cho users về việc cần đăng nhập lại
2. Vô hiệu hóa tất cả refresh token cũ trong DB
3. Users sẽ nhận refresh token mới sau khi đăng nhập lại

**Alternative (nếu cần giữ token):**
- Tạo mapping table giữa old token và new token
- Implement custom `OAuth2RefreshTokenService` để verify old token format
- Migrate từng bước với dual support

## 5. Chiến lược kiểm thử và chuyển đổi

### 5.1. Kế hoạch kiểm thử

-   **Kiểm thử đơn vị (Unit test):** Triển khai các bài kiểm thử sử dụng JUnit/Mockito cho từng thành phần, đặc biệt là các nhà cung cấp xác thực và logic dịch vụ.
-   **Kiểm thử tích hợp (Integration test):** Triển khai các bài kiểm thử ở cấp độ HTTP bao gồm các loại grant chính (Authorization Code, Client Credentials, v.v.).
-   **Kiểm thử đầu cuối (E2E test):** Chuẩn bị một client thử nghiệm và xác nhận hoạt động của toàn bộ luồng xác thực trên môi trường staging.
#### 5.1.1. Kiểm thử đơn vị (Unit Test)

**Mục đích:** Kiểm thử từng thành phần độc lập với mock dependencies.

**Công cụ:**
- JUnit 5
- Mockito
- AssertJ (fluent assertions)

**Phạm vi kiểm thử:**

1. **Authentication Providers:**
```java
@ExtendWith(MockitoExtension.class)
class DrjoyPasswordAuthenticationProviderTest {
    
    @Mock
    private GrpcRegistrationAuthClient registrationClient;
    
    @Mock
    private UserDetailsService userDetailsService;
    
    @InjectMocks
    private DrjoyPasswordAuthenticationProvider provider;
    
    @Test
    void shouldAuthenticateValidCredentials() {
        // Given
        when(registrationClient.verifyPassword("user", "pass"))
            .thenReturn(createUserLoginInfo());
        when(userDetailsService.loadUserByUsername("user"))
            .thenReturn(createUserDetails());
        
        // When
        Authentication result = provider.authenticate(
            new UsernamePasswordAuthenticationToken("user", "pass")
        );
        
        // Then
        assertThat(result.isAuthenticated()).isTrue();
        assertThat(result.getPrincipal()).isNotNull();
    }
}
```

2. **Services:**
- `CertificateServiceTest`
- `FirebaseAuthServiceTest`
- `OTPServiceTest`
- `MasterDataCacheServiceTest`

3. **Filters:**
- `MaintenanceRequestFilterTest`
- `RecaptchaCheckerFilterTest`
- `TwoFactorAuthenticationFilterTest`

4. **Controllers:**
- `CertificateControllerTest`
- `FirebaseAuthControllerTest`

**Coverage Target:** >= 80% code coverage

---

#### 5.1.2. Kiểm thử tích hợp (Integration Test)

**Mục đích:** Kiểm thử tương tác giữa các thành phần với database và external services thật.

**Công cụ:**
- Spring Boot Test
- TestContainers (MongoDB)
- MockWebServer (cho external HTTP calls)
- WireMock (cho gRPC mocks)

**Phạm vi kiểm thử:**

1. **OAuth2 Grant Types:**
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
class OAuth2IntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    void shouldIssueAccessTokenWithAuthorizationCodeGrant() throws Exception {
        // 1. Get authorization code
        String authCode = getAuthorizationCode("user", "pass");
        
        // 2. Exchange for access token
        mockMvc.perform(post("/oauth2/token")
                .param("grant_type", "authorization_code")
                .param("code", authCode)
                .param("redirect_uri", "https://client.example.com/callback")
                .header("Authorization", "Basic " + base64(clientId + ":" + clientSecret)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.access_token").exists())
            .andExpect(jsonPath("$.refresh_token").exists());
    }
    
    @Test
    void shouldIssueAccessTokenWithClientCredentialsGrant() throws Exception {
        mockMvc.perform(post("/oauth2/token")
                .param("grant_type", "client_credentials")
                .param("scope", "read write")
                .header("Authorization", "Basic " + base64(clientId + ":" + clientSecret)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.access_token").exists());
    }
    
    @Test
    void shouldRefreshAccessToken() throws Exception {
        String refreshToken = getRefreshToken();
        
        mockMvc.perform(post("/oauth2/token")
                .param("grant_type", "refresh_token")
                .param("refresh_token", refreshToken)
                .header("Authorization", "Basic " + base64(clientId + ":" + clientSecret)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.access_token").exists());
    }
}
```

2. **Custom Endpoints:**
- `/v1/certificate/check` integration test
- `/fb/access/token` integration test

3. **gRPC Services:**
- `GrpcHealthServerTest`
- `GrpcActuatorServerTest`

**Test Environment:**
- MongoDB: TestContainers
- External services: WireMock
- gRPC: InProcessServer

---

#### 5.1.3. Kiểm thử đầu cuối (E2E Test)

**Mục đích:** Kiểm thử toàn bộ luồng xác thực từ client đến server.

**Công cụ:**
- Selenium/Playwright (cho web clients)
- Postman/Newman (cho API testing)
- Cypress (cho frontend testing)

**Test Scenarios:**

1. **Web Client Flow:**
   - User đăng nhập qua web browser
   - Redirect đến authorization endpoint
   - User approve consent
   - Redirect về client với authorization code
   - Client exchange code lấy access token
   - Client sử dụng access token để gọi API

2. **Mobile Client Flow:**
   - Mobile app gọi `/oauth2/token` với username/password
   - Nhận access token và refresh token
   - Sử dụng token để gọi API
   - Refresh token khi access token hết hạn

3. **Service-to-Service Flow:**
   - Service A gọi `/oauth2/token` với client_credentials
   - Nhận access token
   - Gọi API của Service B với access token

**Test Environment:**
- Staging environment
- Test users và test clients
- Monitoring và logging

---
### 5.2. Chuyển đổi theo giai đoạn

`service-web-front` và `service-registration` sẽ được chuyển đổi trước, và kiến thức thu được sẽ được áp dụng để triển khai cho các dịch vụ khác. Sử dụng canary release với API gateway để chuyển dần lưu lượng truy cập sang hệ thống mới.
#### 5.2.1. Chiến lược chuyển đổi

**Nguyên tắc:**
1. **Chuyển đổi từng service một:** Bắt đầu với services ít quan trọng
2. **Canary release:** Chuyển dần lưu lượng (10% → 50% → 100%)
3. **Rollback plan:** Có thể rollback nhanh nếu có vấn đề
4. **Monitoring:** Giám sát chặt chẽ trong quá trình chuyển đổi

**Thứ tự chuyển đổi:**

1. **Phase 1: Pilot Services** (2-4 tuần)
   - `service-registration` ✅ (đã hoàn thành ~95%)
   - `service-web-front`
   - Mục tiêu: Validate architecture và process

2. **Phase 2: Internal Services** (4-6 tuần)
   - `service-admin`
   - `configuration`
   - Mục tiêu: Mở rộng sang internal services

3. **Phase 3: External Services** (6-8 tuần)
   - `web-drjoy`
   - Các services khác
   - Mục tiêu: Hoàn thành chuyển đổi

---

#### 5.2.2. Canary Release Strategy

**Cấu hình API Gateway (Kong/Nginx):**

```yaml
# Canary configuration
upstreams:
  oauth2:
    primary:
      - host: oauth2-old.drjoy.jp
        weight: 90
    canary:
      - host: service-security-new.drjoy.jp
        weight: 10
```

**Quy trình:**

1. **Week 1: 10% traffic**
   - Monitor error rate, latency, success rate
   - Compare với old system
   - Fix issues nếu có

2. **Week 2: 50% traffic**
   - Tiếp tục monitoring
   - Validate performance

3. **Week 3: 100% traffic**
   - Chuyển toàn bộ traffic
   - Monitor 1 tuần
   - Decommission old system nếu stable

**Rollback Criteria:**
- Error rate > 1%
- Latency tăng > 50%
- Critical bugs không thể fix nhanh

---

#### 5.2.3. Checklist cho mỗi service

**Trước khi chuyển đổi:**
- [ ] Update dependencies (lib-spring-boot-starter-*)
- [ ] Update OAuth2 client configuration
- [ ] Test trong môi trường dev
- [ ] Code review
- [ ] Documentation update

**Trong quá trình chuyển đổi:**
- [ ] Deploy canary version
- [ ] Monitor metrics
- [ ] Test với real users (beta)
- [ ] Collect feedback

**Sau khi chuyển đổi:**
- [ ] Verify 100% traffic
- [ ] Monitor 1 tuần
- [ ] Update documentation
- [ ] Decommission old endpoints
## 6. Giám sát

Sử dụng Prometheus và Grafana để xây dựng một dashboard giám sát số lượng yêu cầu, độ trễ và tỷ lệ lỗi của dịch vụ mới. Đồng thời, giám sát lỗi theo thời gian thực bằng hệ thống ghi log tập trung.

### 6.1. Metrics Collection (Prometheus)

**Mục đích:** Thu thập metrics từ `service-security` và các services khác.

**Metrics cần thu thập:**

1. **HTTP Metrics:**
   - Request count (by endpoint, method, status code)
   - Request duration (p50, p95, p99)
   - Error rate

2. **OAuth2 Metrics:**
   - Token issuance count (by grant type)
   - Token refresh count
   - Authentication success/failure count
   - Authentication provider usage

3. **Business Metrics:**
   - Active users
   - Login attempts (success/failure)
   - 2FA verification count
   - Certificate check count

4. **System Metrics:**
   - JVM memory usage
   - Thread pool usage
   - Database connection pool
   - gRPC call metrics

**Implementation:**
```java
@Component
public class OAuth2Metrics {
    
    private final Counter tokenIssuedCounter;
    private final Counter tokenRefreshCounter;
    private final Counter authSuccessCounter;
    private final Counter authFailureCounter;
    private final Timer tokenIssuanceDuration;
    
    public OAuth2Metrics(MeterRegistry registry) {
        this.tokenIssuedCounter = Counter.builder("oauth2.tokens.issued")
            .description("Number of tokens issued")
            .tag("grant_type", "authorization_code")
            .register(registry);
        
        this.tokenRefreshCounter = Counter.builder("oauth2.tokens.refreshed")
            .description("Number of tokens refreshed")
            .register(registry);
        
        this.authSuccessCounter = Counter.builder("oauth2.auth.success")
            .description("Number of successful authentications")
            .tag("provider", "drjoy_password")
            .register(registry);
        
        this.authFailureCounter = Counter.builder("oauth2.auth.failure")
            .description("Number of failed authentications")
            .tag("provider", "drjoy_password")
            .register(registry);
        
        this.tokenIssuanceDuration = Timer.builder("oauth2.tokens.issuance.duration")
            .description("Token issuance duration")
            .register(registry);
    }
    
    public void recordTokenIssued(String grantType) {
        tokenIssuedCounter.increment(
            Tags.of("grant_type", grantType)
        );
    }
    
    public void recordAuthSuccess(String provider) {
        authSuccessCounter.increment(
            Tags.of("provider", provider)
        );
    }
}
```

**Prometheus Configuration:**
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'service-security'
    scrape_interval: 15s
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['service-security:8080']
```

---

### 6.2. Dashboard (Grafana)

**Mục đích:** Visualization metrics để dễ dàng monitor và troubleshoot.

**Dashboards:**

1. **OAuth2 Overview Dashboard:**
   - Token issuance rate (by grant type)
   - Authentication success/failure rate
   - Top authentication providers
   - Token refresh rate

2. **Performance Dashboard:**
   - Request latency (p50, p95, p99)
   - Request rate (by endpoint)
   - Error rate (by endpoint, status code)
   - Database query performance

3. **System Health Dashboard:**
   - JVM memory usage
   - CPU usage
   - Thread pool status
   - Database connection pool

4. **Business Metrics Dashboard:**
   - Active users (last 24h, 7d, 30d)
   - Login attempts (success/failure)
   - 2FA usage
   - Certificate checks

**Grafana Dashboard Example:**
```json
{
  "dashboard": {
    "title": "OAuth2 Server Metrics",
    "panels": [
      {
        "title": "Token Issuance Rate",
        "targets": [
          {
            "expr": "rate(oauth2_tokens_issued_total[5m])",
            "legendFormat": "{{grant_type}}"
          }
        ]
      },
      {
        "title": "Authentication Success Rate",
        "targets": [
          {
            "expr": "rate(oauth2_auth_success_total[5m]) / rate(oauth2_auth_total[5m])",
            "legendFormat": "Success Rate"
          }
        ]
      }
    ]
  }
}
```

---

### 6.3. Logging (Centralized Logging)

**Mục đích:** Tập trung logs từ tất cả services để dễ dàng search và analyze.

**Stack:**
- **ELK Stack:** Elasticsearch + Logstash + Kibana
- Hoặc **Loki + Grafana:** Lightweight alternative

**Log Levels:**
- **ERROR:** Lỗi nghiêm trọng cần xử lý ngay
- **WARN:** Cảnh báo nhưng không ảnh hưởng nghiêm trọng
- **INFO:** Thông tin quan trọng (authentication events, token issuance)
- **DEBUG:** Chi tiết để debug (chỉ trong dev/staging)

**Structured Logging:**
```java
@Slf4j
@Component
public class AuthenticationLogger {
    
    public void logAuthenticationSuccess(
            String userId, 
            String provider, 
            String clientId) {
        log.info("Authentication successful", 
            kv("userId", userId),
            kv("provider", provider),
            kv("clientId", clientId),
            kv("event", "authentication_success")
        );
    }
    
    public void logAuthenticationFailure(
            String username, 
            String provider, 
            String reason) {
        log.warn("Authentication failed", 
            kv("username", username),
            kv("provider", provider),
            kv("reason", reason),
            kv("event", "authentication_failure")
        );
    }
    
    public void logTokenIssued(
            String userId, 
            String grantType, 
            String clientId) {
        log.info("Token issued", 
            kv("userId", userId),
            kv("grantType", grantType),
            kv("clientId", clientId),
            kv("event", "token_issued")
        );
    }
}
```

**Log Format (JSON):**
```json
{
  "timestamp": "2024-01-15T10:00:00Z",
  "level": "INFO",
  "logger": "jp.drjoy.security.AuthenticationLogger",
  "message": "Authentication successful",
  "userId": "user123",
  "provider": "drjoy_password",
  "clientId": "drjoy-web",
  "event": "authentication_success",
  "requestId": "req-123"
}
```

**Log Aggregation:**
```yaml
# logstash.conf
input {
  beats {
    port => 5044
  }
}

filter {
  if [fields][service] == "service-security" {
    json {
      source => "message"
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "service-security-%{+YYYY.MM.dd}"
  }
}
```

---

### 6.4. Alerting

**Mục đích:** Cảnh báo ngay khi có vấn đề xảy ra.

**Alert Rules:**

1. **High Error Rate:**
   ```yaml
   - alert: HighErrorRate
     expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.01
     for: 5m
     annotations:
       summary: "High error rate detected"
   ```

2. **High Latency:**
   ```yaml
   - alert: HighLatency
     expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
     for: 5m
     annotations:
       summary: "High latency detected"
   ```

3. **Authentication Failure Spike:**
   ```yaml
   - alert: AuthFailureSpike
     expr: rate(oauth2_auth_failure_total[5m]) > 10
     for: 5m
     annotations:
       summary: "Authentication failure spike detected"
   ```

4. **Token Issuance Failure:**
   ```yaml
   - alert: TokenIssuanceFailure
     expr: rate(oauth2_tokens_issuance_failure_total[5m]) > 0.1
     for: 5m
     annotations:
       summary: "Token issuance failure detected"
   ```

**Notification Channels:**
- Email
- Slack
- PagerDuty (cho critical alerts)

---

### 6.5. Health Checks

**Mục đích:** Kiểm tra health của service để load balancer biết khi nào cần route traffic.

**Endpoints:**
- `/actuator/health`: Basic health check
- `/actuator/health/liveness`: Liveness probe (Kubernetes)
- `/actuator/health/readiness`: Readiness probe (Kubernetes)

**Custom Health Indicators:**
```java
@Component
public class OAuth2HealthIndicator implements HealthIndicator {
    
    @Autowired
    private RegisteredClientRepository clientRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Override
    public Health health() {
        try {
            // Check database connectivity
            clientRepository.count();
            userRepository.count();
            
            // Check keystore
            if (!isKeystoreAvailable()) {
                return Health.down()
                    .withDetail("keystore", "Not available")
                    .build();
            }
            
            return Health.up()
                .withDetail("database", "Connected")
                .withDetail("keystore", "Available")
                .build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("error", e.getMessage())
                .build();
        }
    }
}
```

**Kubernetes Configuration:**
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```