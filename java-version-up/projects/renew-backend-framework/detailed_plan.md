# Kế hoạch chuyển đổi hiện đại hóa OAuth2 Server - Danh sách công việc chi tiết

Tài liệu này chi tiết hóa nội dung công việc của từng giai đoạn được nêu trong [Kế hoạch chuyển đổi hiện đại hóa OAuth2 Server](README.md) ở cấp độ công việc cụ thể hơn.

## Nhánh làm việc

- **Dịch vụ hiện có**: `configuration`, `service-admin`, `service-registration`, `service-web-front`, `web-drjoy`
  - Làm việc trên nhánh `feature/renew_framework`.
- **Kho lưu trữ nguồn di chuyển**: `service-oauth2-server`, `service-framework`
  - Luôn tham chiếu trạng thái mới nhất của nhánh `develop`.
- **Kho lưu trữ mới được tạo**: `lib-*`, `service-security`
  - Làm việc trên nhánh `master`.
- **Định nghĩa bộ đệm giao thức**: `protobuf`
  - Quản lý định nghĩa giao thức được sử dụng cho giao tiếp gRPC giữa các dịch vụ.
  - Làm việc trên nhánh `feature/renew_framework`.

## Giai đoạn 1: Thiết kế lại và phân tách `service-framework`

### 1.1. Tạo dự án thư viện mới

-   [x] Tạo dự án `lib-spring-boot-starter-grpc`.
    -   [x] Cấu hình `pom.xml` và thêm các thư viện liên quan đến gRPC cần thiết.
    -   [x] Tạo mẫu cho lớp AutoConfiguration cơ bản.
-   [x] Tạo dự án `lib-spring-boot-starter-security`.
    -   [x] Cấu hình `pom.xml` và thêm các thư viện liên quan đến Spring Security 6.
    -   [x] Tạo mẫu cho lớp AutoConfiguration cơ bản.
-   [x] Tạo dự án `lib-spring-boot-starter-mongodb`.
    -   [x] Cấu hình `pom.xml` và thêm các thư viện liên quan đến Spring Data MongoDB.
    -   [x] Tạo mẫu cho lớp AutoConfiguration cơ bản.
-   [x] Tạo dự án `lib-spring-boot-starter-web`.
    -   [x] Cấu hình `pom.xml` và thêm các thư viện liên quan đến Spring Web.
    -   [x] Tạo mẫu cho lớp AutoConfiguration cơ bản.
-   [x] Tạo dự án `lib-common-models`.
    -   [x] Cấu hình `pom.xml` (không bao gồm các phụ thuộc Spring).
-   [x] Tạo dự án `lib-common-utils`.
    -   [x] Cấu hình `pom.xml`.

### 1.2. Chuyển giao chức năng từ `service-framework` và kiểm thử

-   [x] **`lib-common-models`**
    -   [x] Xác định các DTO và POJO được sử dụng chung trong `service-framework` và các dịch vụ khác, sau đó tập hợp chúng vào thư viện mới.
    -   [x] Xác nhận rằng các phụ thuộc chỉ là Java/Lombok đơn thuần.
-   [x] **`lib-common-utils`**
    -   [x] Chuyển các lớp tiện ích chung (thao tác chuỗi, thao tác ngày tháng, v.v.) từ `service-framework`.
    -   [x] Tạo kiểm thử đơn vị cho `CaseConvertUtils`.
    -   [x] Tạo kiểm thử đơn vị cho `Dates`.
    -   [x] Tạo kiểm thử đơn vị cho `KanaUtils`.
-   [x] **`lib-spring-boot-starter-grpc`**
    -   [x] Xác định và chuyển mã liên quan đến gRPC (cấu hình máy chủ/máy khách, interceptor, v.v.) từ `service-framework` sang thư viện mới.
    -   [x] Sửa đổi mã để phù hợp với đặc tả của Spring Boot 3 (ví dụ: `javax` -> `jakarta`).
    -   [x] Tạo kiểm thử đơn vị cho `ErrorHandlingInterceptor`.
    -   [x] Tạo kiểm thử đơn vị cho `GrpcAuthClientInterceptor`.
    -   [x] Tạo kiểm thử đơn vị cho `GrpcAuthServerInterceptor`.
-   [x] **`lib-spring-boot-starter-security`**
    -   [x] Tham khảo mã liên quan đến bảo mật của `service-framework` để triển khai lớp cấu hình mới dựa trên Spring Security 6.
    -   [x] Triển khai lại logic xác thực hiện có, chẳng hạn như xác minh JWT và giải quyết thông tin người dùng.
    -   [x] Tạo kiểm thử đơn vị cho `BCryptService`.
    -   [x] Tạo kiểm thử đơn vị cho `ShaPasswordService`.
    -   [x] Tạo kiểm thử đơn vị cho `UserAuthenticationConverter`.
-   [x] **`lib-spring-boot-starter-mongodb`**
    -   [x] Chuyển cấu hình chung của MongoDB, repository tùy chỉnh và các lớp document cơ sở từ `service-framework`.
    -   [x] Sửa đổi mã để phù hợp với đặc tả của Spring Boot 3.
    -   [x] Tách trách nhiệm: Tách các chức năng liên quan đến dữ liệu chủ sang `lib-spring-boot-starter-masterdata`.
    -   [x] Sửa đổi để chỉ cung cấp các chức năng MongoDB chung (chức năng kiểm toán, v.v.).
    -   [ ] Tạo kiểm thử đơn vị cho `RoleMasterService` (→ chuyển sang thư viện masterdata).
-   [x] **`lib-spring-boot-starter-masterdata`** ✨ *Mới tạo*
    -   [x] Tách các chức năng liên quan đến dữ liệu chủ từ `lib-spring-boot-starter-mongodb`.
    -   [x] Quản lý `RoleRepository`, `StaffAuthorityRepository`, `MasterDataRepository`.
    -   [x] Cung cấp `RoleMasterService`, `StaffAuthorityMasterService`, `MasterDataCacheService`.
    -   [x] Tập hợp chức năng thay thế các enum được mã hóa cứng bằng dữ liệu chủ dựa trên DB.
    -   [ ] Cấu hình phụ thuộc riêng lẻ và xác nhận hoạt động trong từng dịch vụ.
-   [x] **`lib-spring-boot-starter-web`**
    -   [x] Chuyển các bộ lọc Web chung, trình xử lý ngoại lệ, serializer, v.v. từ `service-framework`.
    -   [x] Sửa đổi mã để phù hợp với đặc tả của Spring Boot 3.
    -   [x] Tạo kiểm thử đơn vị cho `RequestHandlerInterceptor`.

### 1.3. Loại bỏ các enum được mã hóa cứng

-   [x] **Enum liên quan đến logic nghiệp vụ**
    -   [x] Thiết kế lược đồ collection MongoDB để quản lý dữ liệu chủ (`roles`, `authorities`, `products`, v.v.).
    -   [x] Trong `lib-spring-boot-starter-mongodb` hoặc `lib-spring-boot-starter-web`, triển khai một dịch vụ (ví dụ: `MasterDataCacheService`) để đọc dữ liệu chủ từ DB khi khởi động và lưu vào bộ đệm.
    -   [x] Định nghĩa một giao diện để sử dụng dữ liệu đã lưu trong bộ đệm thông qua DI.
    -   [ ] Thực hiện điều tra phạm vi ảnh hưởng để xác định các vị trí tham chiếu đến enum hiện có và sửa đổi chúng để sử dụng dịch vụ mới.
-   [x] **Enum liên quan đến cấu hình hệ thống**
    -   [x] Trong kho lưu trữ `configuration`, thêm/cập nhật các tệp `.yml` để quản lý các cấu hình như `ServiceType` và `HealthyProbe`.
    -   [ ] Thực hiện điều tra phạm vi ảnh hưởng để sửa đổi mã hiện có nhằm lấy các giá trị cấu hình bằng `@Value` hoặc `@ConfigurationProperties`.

### 1.4. Khởi tạo và nhập dữ liệu chủ

-   [x] **Thiết kế lược đồ dữ liệu chủ**
    -   [x] Hoàn thành định nghĩa cấu trúc cho các collection `roles`, `authorities`, `master_data`
    -   [x] Đã triển khai Document/Repository trong `lib-spring-boot-starter-masterdata`
-   [ ] **Chuẩn bị dữ liệu ban đầu và phát triển công cụ nhập dữ liệu**
    -   [ ] Tạo các tệp JSON dữ liệu ban đầu (`roles.json`, `authorities.json`, `master-data.json`)
    -   [ ] `DataInitializationService` - Triển khai logic đọc JSON và nhập vào DB
    -   [ ] `MasterDataInitializer` - Triển khai khởi tạo khi khởi động bằng `CommandLineRunner`
    -   [ ] Quản lý dữ liệu theo hồ sơ (hỗ trợ môi trường dev/test/prod)
-   [ ] **Tài liệu hóa quy trình nhập dữ liệu**
    -   [ ] Cung cấp ví dụ về lệnh nhập trực tiếp vào MongoDB
    -   [ ] Tạo hướng dẫn chuẩn bị dữ liệu kiểm thử trong môi trường phát triển
    -   [ ] Tạo hướng dẫn cập nhật và vận hành dữ liệu trong môi trường sản xuất
    -   [ ] Xây dựng quy trình sao lưu và phục hồi dữ liệu
-   [ ] **Chức năng hỗ trợ vận hành (tùy chọn)**
    -   [ ] Triển khai API REST để thao tác CRUD dữ liệu chủ
    -   [ ] Triển khai API làm mới bộ đệm
    -   [ ] Triển khai chức năng kiểm tra tính toàn vẹn của dữ liệu

#### Phương pháp nhập dữ liệu

**1. Nhập dữ liệu ban đầu trong môi trường phát triển**
```bash
# Nhập trực tiếp vào MongoDB (khuyến nghị)
mongosh your_database
db.roles.insertMany([
  {"name": "ADMIN", "description": "Quản trị viên"},
  {"name": "USER", "description": "Người dùng thông thường"},
  {"name": "DOCTOR", "description": "Bác sĩ"}
])
```

**2. Tự động khởi tạo khi khởi động ứng dụng**
- Tự động nhập dữ liệu ban đầu bằng `CommandLineRunner`
- Hỗ trợ hồ sơ theo môi trường (`application-{profile}.yml`)
- Chức năng kiểm tra trùng lặp dữ liệu hiện có

**3. Quản lý dữ liệu trong môi trường sản xuất**
- Cập nhật qua màn hình quản lý (khuyến nghị)
- Thao tác trực tiếp với MongoDB (chỉ trong trường hợp khẩn cấp)
- Bắt buộc ghi lại lịch sử thay đổi và sao lưu

## Xây dựng và sử dụng các dự án lib-*

### Kiến trúc thư viện

Khung công tác mới bao gồm sáu thư viện sau:

#### Thư viện nền tảng
- **`lib-common-utils`** - Các lớp tiện ích chung (thao tác chuỗi, thao tác ngày tháng, v.v.)
- **`lib-common-models`** - Các lớp DTO và POJO chung

#### Thư viện Spring Boot Starter
- **`lib-spring-boot-starter-grpc`** - Chức năng máy khách/máy chủ gRPC
- **`lib-spring-boot-starter-security`** - Cấu hình và bộ lọc Spring Security 6
- **`lib-spring-boot-starter-mongodb`** - Nền tảng kết nối MongoDB và Repository
- **`lib-spring-boot-starter-web`** - Chức năng liên quan đến Web và nền tảng bộ điều khiển

#### Thư viện đặc biệt
- **`lib-spring-boot-starter-masterdata`** - Chức năng quản lý dữ liệu chủ (tách từ service-registration)

### Phương pháp xây dựng

#### Xây dựng trong môi trường phát triển cục bộ


**Xây dựng từng thư viện riêng lẻ:**
```bash
# Thực thi trong mỗi thư mục lib-*
cd work/lib-common-utils
mvn clean install

cd work/lib-common-models
mvn clean install

# Xây dựng theo thứ tự phụ thuộc (quan trọng)
cd work/lib-spring-boot-starter-mongodb
mvn clean install

cd work/lib-spring-boot-starter-security
mvn clean install

cd work/lib-spring-boot-starter-grpc
mvn clean install

cd work/lib-spring-boot-starter-web
mvn clean install
```

#### Xây dựng trong môi trường CI/CD (khuyến nghị)

Cấu hình `.drone.yml` riêng cho mỗi kho lưu trữ lib-* để tự động xây dựng và triển khai:

**Ví dụ về xây dựng trong môi trường CI/CD:**
Triển khai xây dựng và triển khai tự động bằng cách cấu hình CI/CD riêng cho mỗi kho lưu trữ lib-*.

### Phương pháp sử dụng

#### Sử dụng trong dự án Maven

**Thêm phụ thuộc vào pom.xml:**
```xml
<dependencies>
  <!-- Thư viện nền tảng -->
  <dependency>
    <groupId>jp.drjoy</groupId>
    <artifactId>lib-common-utils</artifactId>
    <version>0.0.1-SNAPSHOT</version>
  </dependency>
  
  <dependency>
    <groupId>jp.drjoy</groupId>
    <artifactId>lib-common-models</artifactId>
    <version>0.0.1-SNAPSHOT</version>
  </dependency>

  <!-- Spring Boot Starter -->
  <dependency>
    <groupId>jp.drjoy</groupId>
    <artifactId>lib-spring-boot-starter-grpc</artifactId>
    <version>0.0.1-SNAPSHOT</version>
  </dependency>

  <dependency>
    <groupId>jp.drjoy</groupId>
    <artifactId>lib-spring-boot-starter-security</artifactId>
    <version>0.0.1-SNAPSHOT</version>
  </dependency>

  <dependency>
    <groupId>jp.drjoy</groupId>
    <artifactId>lib-spring-boot-starter-mongodb</artifactId>
    <version>0.0.1-SNAPSHOT</version>
  </dependency>

  <dependency>
    <groupId>jp.drjoy</groupId>
    <artifactId>lib-spring-boot-starter-web</artifactId>
    <version>0.0.1-SNAPSHOT</version>
  </dependency>
</dependencies>
```

#### Sử dụng trong mã ứng dụng

**Ví dụ sử dụng cơ bản:**
```java
// Tự động cấu hình bằng AutoConfiguration
@SpringBootApplication
public class MyApplication {
    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}

// Sử dụng các lớp tiện ích
import jp.drjoy.utils.Strings;
import jp.drjoy.utils.Dates;

@Service
public class MyService {
    public void example() {
        String result = Strings.nvl(null, "default");
        Date formatted = Dates.formatUTC(new Date());
    }
}
```

### Quản lý phiên bản

#### Phiên bản theo nhánh
- **develop**: `0.1.DEVELOP-SNAPSHOT`
- **master**: `0.1.MASTER-SNAPSHOT`
- **feature/xxx**: `0.1.FEATURE/XXX-SNAPSHOT`

#### Giải quyết phụ thuộc
1. Tự động lấy từ **kho lưu trữ Maven riêng**
2. Xác thực bằng bí mật **mvn-settings**
3. Tích hợp vào JAR cuối cùng bằng **Spring Boot repackaging**

### Đảm bảo chất lượng

#### Kiểm thử tự động
- Thực thi kiểm thử đơn vị (`mvn test`)
- Phân tích tĩnh SonarQube
- Kiểm tra lỗ hổng phụ thuộc

#### Tích hợp liên tục
- Tự động xây dựng khi có thay đổi mã
- Kiểm tra chất lượng khi có yêu cầu kéo
- Tự động triển khai vào nhánh chính

## Giai đoạn 2: Phát triển `service-security`

### 2.1. Thiết lập dự án

-   [x] Tạo một dự án Maven mới có tên `service-security` dựa trên Spring Boot 3 / JDK 17.
-   [x] Trong `pom.xml`, thêm nhóm thư viện `lib-spring-boot-starter-*` được tạo ở giai đoạn 1 và `spring-boot-starter-oauth2-authorization-server` làm phụ thuộc.
-   [x] Thực hiện cấu hình cơ bản cho `application.yml` (cổng máy chủ, thông tin kết nối DB, v.v.).
-   [x] Khởi tạo kho lưu trữ cục bộ và đẩy lên kho lưu trữ từ xa.

### 2.2. Triển khai logic xác thực và ủy quyền

-   [x] Tạo `AuthorizationServerConfig` và cấu hình các điểm cuối cơ bản (`/oauth2/authorize`, `/oauth2/token`, v.v.).
-   [x] Triển khai `UserDetailsService` để lấy thông tin người dùng từ DB.
-   [x] Triển khai `RegisteredClientRepository` để đọc thông tin máy khách từ DB hoặc tệp cấu hình.
-   [x] Tạo `SecurityConfig` và cấu hình các thiết lập bảo mật.
-   [x] Triển khai các trình xử lý xác thực tùy chỉnh (`CustomAuthenticationSuccessHandler`, `CustomAuthenticationFailureHandler`).
-   [x] Triển khai dịch vụ giới hạn số lần đăng nhập (`LoginAttemptService`).
-   [x] Triển khai máy khách xác thực gRPC (`GrpcRegistrationAuthClient`).
-   [x] **Triển khai các nhà cung cấp xác thực tùy chỉnh**: Triển khai lại logic xác thực tùy chỉnh sau đây có trong `service-oauth2-server` dưới dạng `AuthenticationProvider` của Spring Authorization Server.
    -   [x] `DrjoyPasswordAuthenticationProvider` (Xác thực ID/PW cho người dùng Dr.JOY)
    -   [x] `PrjoyPasswordAuthenticationProvider` (Xác thực ID/PW cho người dùng PR.JOY)
    -   [x] `AdminPasswordAuthenticationProvider` (Xác thực ID/PW cho quản trị viên)
    -   [x] `QuickPersonalAuthenticationProvider` (Đăng nhập nhanh cho mục đích sử dụng cá nhân)
    -   [x] `NologinMeetingAuthenticationProvider` (Xác thực không cần đăng nhập cho hội nghị web)
    -   [x] `NologinAnswerSurveyAuthenticationProvider` (Xác thực không cần đăng nhập để trả lời khảo sát)
    -   [x] `NologinPersonalInvitationAuthenticationProvider` (Xác thực không cần đăng nhập cho lời mời cá nhân)
    -   [x] `JoyPassAuthenticationProvider` (Xác thực cho người dùng JoyPass)
    -   [x] `SchoolPasswordAuthenticationProvider` (Xác thực ID/PW cho chức năng trường học)
    -   [x] `SsoAuthenticationProvider` (Xác thực SSO)
-   [x] **Thay đổi phương thức ký JWT**: Thay đổi từ phương thức tạo khóa động hiện tại sang phương thức sử dụng kho khóa (`.jks`) tương tự như `service-oauth2-server`.
    -   [x] Đặt tệp kho khóa (oauth2.jks)
    -   [x] Thêm cấu hình vào application.yml
    -   [x] Cải thiện AuthorizationServerConfig (xử lý lỗi, ghi nhật ký)
    -   [x] Triển khai dự phòng ClassPathResource
-   [x] **Triển khai trình tùy chỉnh mã thông báo**: Tham khảo `JwtTokenEnhancer` của `service-oauth2-server` để triển khai `OAuth2TokenCustomizer` và thêm các xác nhận quyền sở hữu tùy chỉnh (ví dụ: thông tin đơn vị, quyền hạn của người dùng) vào JWT.
    -   [x] Triển khai đầy đủ phương thức isSaveLogin
    -   [x] Thêm logic trích xuất xác nhận quyền sở hữu từ thông tin xác thực người dùng
    -   [x] Tích hợp với dịch vụ dữ liệu chủ
    -   [x] Hỗ trợ tất cả các trường được định nghĩa trong UserAuthenticationConverter hiện có
    -   [x] Tạo nền tảng cho kiểm thử đơn vị
-   [x] Sử dụng cơ chế quản lý dữ liệu chủ đã được triển khai ở giai đoạn 1 để bao gồm thông tin về vai trò và quyền hạn trong mã thông báo.
-   [x] **Triển khai bộ lọc tùy chỉnh**: Triển khai lại các interceptor sau đây của `service-oauth2-server` dưới dạng `Filter` của Spring Security và tích hợp chúng vào `SecurityFilterChain`.
    -   [x] `MaintenanceRequestInterceptor` → `MaintenanceRequestFilter` (Kiểm tra chế độ bảo trì)
    -   [x] `RecaptchaCheckerInterceptor` → `RecaptchaCheckerFilter` (Xác minh reCAPTCHA)
    -   [x] `TwoFactorAuthenticationInterceptor` → `TwoFactorAuthenticationFilter` (Xác minh xác thực hai yếu tố)
    -   [x] **Hoàn thành triển khai**: Các bộ lọc này đã được chuyển sang `lib-spring-boot-starter-security` và được kích hoạt tự động trong `service-security` thông qua AutoConfiguration.
    -   [x] **Tạo kiểm thử đơn vị**: Đã tạo các trường hợp kiểm thử toàn diện cho mỗi bộ lọc và đã xác nhận hoạt động.

### 2.2.1. Di chuyển các điểm cuối API tùy chỉnh

-   [x] **Di chuyển API thông tin chứng chỉ**: Triển khai chức năng tương đương với `/v1/certificate/check` của `service-oauth2-server` trong `service-security` hoặc xem xét và thực hiện việc chuyển giao cho một dịch vụ khác có trách nhiệm phù hợp hơn.
    -   [x] **Triển khai CertificateInfoResponse**: Mô hình phản hồi JSON định dạng `{"approved": boolean}`
    -   [x] **Mở rộng GrpcRegistrationAuthClient**: Thêm phương thức getUserLoginInfoResponse và mô hình POJO UserLoginInfo
    -   [x] **Triển khai CertificateService**: Logic xác minh chứng chỉ (trạng thái phê duyệt văn phòng, quyền FP21, xác minh chứng chỉ máy khách)
    -   [x] **Triển khai CertificateController**: Điểm cuối GET /v1/certificate/check (xác thực đầu vào, xử lý lỗi)
    -   [x] **Tích hợp TwoFactorAuthenticationFilter**: Hỗ trợ trích xuất chứng chỉ từ cả ThreadLocal và tiêu đề
    -   [x] **Kiểm thử đơn vị và tích hợp**: Đã tạo và xác nhận biên dịch các kiểm thử cho lớp web và lớp dịch vụ
-   [x] **Di chuyển API mã thông báo Firebase**: Triển khai lại chức năng tương đương với `/fb/access/token` của `service-oauth2-server` trong `service-security`.
    -   [x] **Tích hợp Firebase Admin SDK**: Thêm phụ thuộc Firebase Admin SDK và triển khai lớp cấu hình FirebaseConfig
    -   [x] **Triển khai FirebaseAuthService**: Lấy thông tin người dùng từ SecurityContextHolder, tạo xác nhận quyền sở hữu tùy chỉnh, tích hợp RxJava3
    -   [x] **Triển khai FirebaseAuthController**: Điểm cuối GET/POST /fb/access/token (xử lý không đồng bộ DeferredResult)
    -   [x] **Tích hợp ngữ cảnh xác thực**: Tạo mã thông báo tùy chỉnh Firebase từ thông tin xác thực JWT, hỗ trợ PaymentFunctionType
    -   [x] **Kiểm thử đơn vị và tích hợp**: Hoàn thành kiểm thử đơn vị Mockito và kiểm thử tích hợp cho FirebaseAuthService
-   [ ] `NologinChatAuthenticationProvider` (Xác thực không cần đăng nhập cho trò chuyện, **cần điều tra**: có định nghĩa máy khách trong `data.sql` nhưng không tìm thấy triển khai Provider, vì vậy cần xác nhận tình hình sử dụng và di chuyển nếu cần)
-   [x] **Di chuyển các dịch vụ gRPC**: Đối với các dịch vụ gRPC sau đây do `service-oauth2-server` cung cấp, hãy xác định xem có cần di chuyển sang `service-security` hay không và triển khai những dịch vụ cần thiết.
    -   [x] **Triển khai GrpcActuatorServer**: Kích hoạt phụ thuộc protobuf, tích hợp Spring Cloud Context Refresher, chức năng làm mới cấu hình, khởi động lại và tắt máy
    -   [x] **Triển khai GrpcHealthServer**: Triển khai Giao thức kiểm tra sức khỏe gRPC tiêu chuẩn, tích hợp chỉ báo sức khỏe Spring Boot Actuator
    -   [x] **Tích hợp cấu hình Spring**: Lớp cấu hình GrpcConfig, cấu hình bean ContextRefresher, HealthIndicator, thêm cấu hình gRPC vào application.yml
    -   [x] **Tăng cường bảo mật**: Xem xét xác thực và ủy quyền trong môi trường sản xuất, cải thiện xử lý lỗi, ghi nhật ký phù hợp
    -   [x] **Kiểm thử toàn diện**: Hoàn thành kiểm thử đơn vị cho GrpcActuatorServer, GrpcHealthServer, GrpcConfig và kiểm thử tích hợp gRPC

### 2.2.2. Di chuyển các cấu hình khác

-   [x] **Di chuyển cấu hình CORS**: Tham khảo `CorsPreflightConfiguration` và `CorsPreflightSecureConfiguration` của `service-oauth2-server` để triển khai cấu hình CORS phù hợp với môi trường trong `service-security`.
    -   [x] **Triển khai CorsAutoConfiguration**: Cấu hình tự động chuyển đổi giữa môi trường phát triển (cho phép) và môi trường sản xuất (hạn chế)
    -   [x] **Cấu hình CorsProperties**: Quản lý cấu hình linh hoạt bằng application.yml
    -   [x] **Tích hợp AuthorizationServerConfig**: Tích hợp với cấu hình CORS của Spring Security 6
    -   [x] **Kiểm thử đơn vị**: Hoàn thành kiểm thử hoạt động của cấu hình CORS theo môi trường
-   [x] **Di chuyển logic tùy chỉnh thời hạn mã thông báo**: Tái tạo logic thay đổi động thời hạn mã thông báo tùy thuộc vào tham số yêu cầu (xác định ứng dụng di động, duy trì đăng nhập) có trong `CustomTokenServices` của `service-oauth2-server` trong `service-security`.
    -   [x] **Triển khai OAuth2TokenSettingsProvider**: Hoàn thành việc chuyển logic thời gian mã thông báo phức tạp
    -   [x] **Kiểm soát ưu tiên**: di động > phiên văn phòng > save_login + sản phẩm > mặc định
    -   [x] **Thời gian theo sản phẩm**: DRJOY/PRJOY/SCHOOL (90 ngày), ADMIN (30 ngày)
    -   [x] **Mở rộng CustomTokenSettings**: Hỗ trợ ngữ cảnh OAuth2Authentication
    -   [x] **Kiểm thử đơn vị toàn diện**: Hoàn thành việc tạo kiểm thử cho tất cả các trường hợp và sử dụng mock

### 2.3. Chuẩn bị cơ sở dữ liệu

-   [ ] Thiết kế lược đồ cho các collection MongoDB mà `service-security` sẽ sử dụng (người dùng, thông tin máy khách, v.v.).
-   [ ] **Cụ thể hóa kế hoạch di chuyển dữ liệu và tạo tập lệnh**:
    -   [ ] **Thông tin máy khách**: Chuyển đổi và di chuyển thông tin tương đương với `oauth_client_details` cũ sang định dạng `RegisteredClient` mà Spring Authorization Server yêu cầu.
    -   [ ] **Thông tin người dùng**: Di chuyển thông tin người dùng hiện có để phù hợp với lược đồ DB của dịch vụ mới. Xem xét xem có cần băm lại mật khẩu hay không.
    -   [ ] **Mã thông báo làm mới**: Quyết định chiến lược vô hiệu hóa các mã thông báo làm mới hiện có hoặc di chuyển chúng theo cách có thể sử dụng được trong hệ thống mới.

## Giai đoạn 3: Di chuyển máy khách theo từng giai đoạn

### 3.1. Thực hiện kiểm thử

-   [ ] **Kiểm thử đơn vị:** Triển khai kiểm thử đơn vị bằng JUnit/Mockito, v.v. cho mỗi thành phần của `service-security`.
-   [ ] **Kiểm thử tích hợp:** Sử dụng khung kiểm thử của Spring để triển khai kiểm thử tích hợp với các yêu cầu/phản hồi HTTP thực tế. Bao gồm các loại cấp phép chính (Mã ủy quyền, Thông tin xác thực máy khách, v.v.).
-   [ ] **Kiểm thử E2E:**
    -   Chuẩn bị một ứng dụng máy khách để kiểm thử.
    -   Triển khai `service-security` lên môi trường dàn dựng, v.v.
    -   Xác nhận rằng toàn bộ luồng xác thực từ máy khách hoạt động bình thường.

### 3.2. Xây dựng và thực hiện chiến lược di chuyển

**Lưu ý:** Vì việc di chuyển tất cả các dịch vụ cùng một lúc là khó khăn, trước tiên hãy tiến hành công việc di chuyển với `service-web-front` và `service-registration` làm trường hợp mẫu. Sau khi di chuyển thành công các dịch vụ này, hãy mở rộng sang các dịch vụ khác.

-   [ ] Tạo danh sách các dịch vụ máy khách sẽ được di chuyển (`service-admin`, `web-drjoy`, v.v.).
-   [ ] Lập kế hoạch bắt đầu di chuyển từ các dịch vụ nội bộ ít bị ảnh hưởng hơn.
-   [ ] Thay đổi cài đặt của cổng API hoặc proxy ngược để chuyển một phần lưu lượng truy cập đến `service-security` (phát hành canary).
-   [ ] Cập nhật các tệp cấu hình (`.yml`) của mỗi ứng dụng máy khách và thay đổi URL điểm cuối của máy chủ OAuth2 thành URL mới.
-   [ ] Tăng dần tỷ lệ lưu lượng truy cập.

### 3.4. Di chuyển service-registration (trường hợp mẫu) 🎉 **Di chuyển gần như hoàn tất**

**📊 Tình hình tiến độ hiện tại**: Hoàn thành khoảng 95% (phần lớn việc di chuyển đã hoàn tất tính đến tháng 12 năm 2024)

#### 3.4.1. Chuẩn bị trước ✅ **Đã hoàn thành**

-   [x] Tạo nhánh `feature/renew_framework`
-   [x] Phân tích các thư viện phụ thuộc hiện tại và các vị trí sử dụng `service-framework`
-   [x] Điều tra phạm vi ảnh hưởng (bộ điều khiển, dịch vụ, lớp cấu hình)
-   [x] Xác nhận hoạt động của các chức năng hiện có và sắp xếp các trường hợp kiểm thử

#### 3.4.2. Cập nhật pom.xml ✅ **Đã hoàn thành**

-   [x] Cập nhật từ JDK 11 → **17** *(đã triển khai xong)*
-   [x] Cập nhật từ Spring Boot 2.x → **3.2.0** *(đã triển khai xong)*
-   [x] Thay thế `service-framework` → `lib-spring-boot-starter-*` *(đã triển khai xong)*
-   [x] Cập nhật plugin Maven compiler/surefire *(đã triển khai xong)*
-   [x] Thêm các phụ thuộc thư viện mới *(đã triển khai xong)*
-   [x] **Thay đổi POM mẹ**: Đang sử dụng `spring-boot-starter-parent` 3.2.0 *(đã triển khai xong)*
-   [x] **Cập nhật các thư viện cũ**: *(đã triển khai xong)*
    -   [x] Jackson → Sử dụng phiên bản tiêu chuẩn của Spring Boot 3
    -   [x] Sử dụng commons-lang3
    -   [x] Sử dụng lombok 1.18.30
    -   [x] Sử dụng phiên bản tiêu chuẩn của reactor-core Spring Boot 3
-   [x] Xác nhận tính nhất quán của **phụ thuộc protobuf** *(đã triển khai xong)*
-   [x] **Thống nhất phiên bản phụ thuộc**: Hoàn thành cấu hình Maven *(đã triển khai xong)*

#### 3.4.3. Sửa đổi mã 🔄 **Hoàn thành 95% (còn lại 2 tệp)**

-   [x] Thay thế hàng loạt gói `javax` → `jakarta` *(đã triển khai xong)*
-   [x] Hỗ trợ Spring Security 6 (bộ lọc xác thực, lớp cấu hình) *(đã triển khai xong)*
-   [x] Cập nhật lớp cấu hình MongoDB *(đã triển khai xong)*
-   [x] Hỗ trợ thư viện mới cho cấu hình máy khách gRPC *(đã triển khai xong)*
-   [x] Sửa các API không dùng nữa *(đã triển khai xong)*
-   [x] Thay đổi enum để sử dụng dịch vụ dữ liệu chủ *(đã triển khai xong)*
-   [x] **Thay thế import service-framework**: *(hoàn thành 95%)*
    -   [x] `jp.drjoy.service.framework.grpc.*` → `jp.drjoy.lib.grpc.*`
    -   [x] `jp.drjoy.service.framework.security.*` → `jp.drjoy.lib.security.*`
    -   [x] `jp.drjoy.service.framework.utils.*` → `jp.drjoy.lib.utils.*`
    -   [x] `jp.drjoy.service.framework.model.*` → `jp.drjoy.lib.models.*`
    -   [x] `jp.drjoy.service.framework.publisher.*` → `jp.drjoy.lib.grpc.*`
    -   [ ] **Công việc còn lại**: Xóa các tham chiếu đã được chú thích trong 2 tệp
        - `LoginService.java:30` - Xóa tham chiếu lớp `Settings`
        - `ExternalRegistrationGrpcServerConfiguration.java` - Xóa cấu hình interceptor
-   [x] **Hỗ trợ API đã bị loại bỏ của Spring Security 6**: *(đã triển khai xong)*
    -   [x] `WebSecurityConfigurerAdapter` → Bean `SecurityFilterChain`
    -   [x] Viết lại cấu hình xác thực
-   [x] **Di chuyển lớp kiểm thử**: *(đã xác nhận các kiểm thử hiện có)*

#### 3.4.4. Cập nhật tệp cấu hình 🔄 **Chỉ còn lại cấu hình OAuth2**

-   [x] Hỗ trợ Spring Boot 3 cho `application.yml` *(đã triển khai xong)*
-   [ ] **Cấu hình máy khách OAuth2** (điểm cuối `service-security`) *※ Cần thêm công việc*
-   [x] Điều chỉnh cấu hình nhật ký và cấu hình bộ truyền động *(đã triển khai xong)*
-   [x] Cập nhật cấu hình kết nối gRPC *(đã triển khai xong)*
-   [x] **Hỗ trợ thư viện mới cho cấu hình gRPC**: *(đã triển khai xong)*
    -   [x] Đã xác nhận tính tương thích của cấu hình `grpc.server.*`
    -   [x] Đã hoàn thành cấu hình `grpc.client.channels.*`

#### 3.4.5. Kiểm thử và xác minh 🔄 **Giai đoạn thực hiện**

-   [x] Xác nhận sự tồn tại của các kiểm thử đơn vị (85 tệp)
-   [ ] Thực hiện các kiểm thử đơn vị và xác nhận kết quả
-   [ ] Thực hiện và sửa các kiểm thử tích hợp
-   [ ] Kiểm thử tích hợp với `service-security`
-   [ ] Xác nhận hoạt động trong môi trường cục bộ
-   [ ] Thực hiện kiểm thử hiệu năng
-   [x] **Xác nhận tình hình di chuyển các phần phụ thuộc vào service-framework**: *(đã hoàn thành điều tra)*
    -   [x] Kiểm tra kết quả thay thế hàng loạt câu lệnh import (chỉ còn lại 2 vị trí)
    -   [x] Hoàn thành việc xác định các lớp chưa được hỗ trợ
-   [x] **Xác nhận nền tảng giao tiếp gRPC**: *(đã hoàn thành cấu hình)*
    -   [ ] Kiểm thử khởi động máy chủ
    -   [ ] Kiểm thử kết nối máy khách
    -   [ ] Kiểm thử hoạt động của interceptor

#### 3.4.6. Điều tra trước ✅ **Đã hoàn thành**

-   [x] **Xác nhận tình hình cung cấp chức năng trong các thư viện lib-***: *(đã hoàn thành điều tra)*
    -   [x] Hoàn thành việc xác nhận tình hình cung cấp tất cả các chức năng được sử dụng trong `service-registration` trong các thư viện mới
    -   [x] Chỉ xác định được các vấn đề nhỏ còn lại
-   [x] **Xây dựng chiến lược di chuyển theo giai đoạn**: *(đã xác định chiến lược)*
    -   [x] Hoàn thành việc cụ thể hóa các công việc còn lại
    -   [x] Không cần chiến lược khôi phục (vì việc di chuyển gần như đã hoàn tất)

#### 3.4.7. Công việc hoàn thành cuối cùng 🎯 **Dự kiến thực hiện**

-   [ ] **Xóa hoàn toàn các tham chiếu service-framework còn lại**:
    -   [ ] Xóa dòng chú thích trong `LoginService.java`
    -   [ ] Xóa dòng chú thích trong `ExternalRegistrationGrpcServerConfiguration.java`
-   [ ] **Thêm cấu hình máy khách OAuth2**:
    -   [ ] Thêm cấu hình kết nối service-security vào `application.yml`
    -   [ ] Thêm cấu hình theo môi trường
-   [ ] **Xác nhận hoạt động cuối cùng**:
    -   [ ] Kiểm thử khởi động ứng dụng
    -   [ ] Xác nhận hoạt động của dịch vụ gRPC
    -   [ ] Xác nhận hoạt động của chức năng xác thực (sau khi tích hợp với service-security)

### 3.5. Giám sát

-   [ ] Chuẩn bị một bảng điều khiển để giám sát các chỉ số của `service-security` (số lượng yêu cầu, độ trễ, tỷ lệ lỗi) (ví dụ: Prometheus, Grafana).
-   [ ] Giám sát các nhật ký lỗi và cảnh báo theo thời gian thực bằng một hệ thống tổng hợp nhật ký (ví dụ: ELK Stack, Splunk).
-   [ ] Định nghĩa trước quy trình khôi phục trong trường hợp xảy ra sự cố do di chuyển.

## Giai đoạn 4: Loại bỏ hệ thống cũ

### 4.1. Xác nhận hoàn thành di chuyển

-   [ ] Xác nhận rằng tất cả các ứng dụng máy khách đều đang trỏ đến `service-security` bằng cách kiểm tra các tệp cấu hình và quy tắc định tuyến của cổng API.
-   [ ] Xác nhận rằng lưu lượng truy cập đến `service-oauth2-server` cũ đã bằng không bằng cách kiểm tra nhật ký truy cập và các chỉ số.
-   [ ] Tiếp tục giám sát trong một khoảng thời gian nhất định (ví dụ: 1 tuần) và xác nhận rằng không có sự cố nào xảy ra.

### 4.2. Công việc loại bỏ

-   [ ] Dừng và xóa các triển khai của `service-oauth2-server` cũ.
-   [ ] Xác nhận rằng không còn dịch vụ nào đang sử dụng `service-framework` cũ và lưu trữ hoặc xóa kho lưu trữ.
-   [ ] Xóa các tham chiếu đến hệ thống cũ khỏi các quy trình CI/CD và tài liệu liên quan.