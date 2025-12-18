# Danh sách kiểm tra di chuyển dịch vụ & Khắc phục sự cố

## 📋 Danh sách kiểm tra công việc di chuyển

### Kiểm tra trước
- [ ] Xác định dịch vụ mục tiêu di chuyển
- [ ] Kiểm tra ngăn xếp công nghệ hiện tại (phiên bản Spring Boot, phiên bản Java)
- [ ] Xác định các chức năng được sử dụng của service-framework
- [ ] Hoàn thành build trước các thư viện lib-*
- [ ] Backup database và cấu hình hiện tại (nếu có thay đổi)
- [ ] Xác định loại service: OAuth2 Server / API Service / gRPC Service
- [ ] Đánh giá tác động migration đến downstream services

### Giai đoạn 1: Chuẩn bị môi trường
- [ ] Tạo nhánh feature/renew_framework
- [ ] Phân tích phụ thuộc (`mvn dependency:tree`)
- [ ] Phân tích các vị trí sử dụng framework (`grep -r "jp.drjoy.service.framework"`)

### Giai đoạn 2: Cập nhật pom.xml
- [ ] Phiên bản Spring Boot → 3.3.1
- [ ] Phiên bản Java → 21
- [ ] Xóa phụ thuộc service-framework
- [ ] Thêm lib-common-utils
- [ ] Thêm lib-common-models
- [ ] Thêm thư viện lib-* theo chức năng:
  - [ ] lib-spring-boot-starter-web (khi sử dụng chức năng Web)
  - [ ] lib-spring-boot-starter-security (khi sử dụng chức năng xác thực)
  - [ ] lib-spring-boot-starter-mongodb (khi sử dụng MongoDB)
  - [ ] lib-spring-boot-starter-grpc (khi sử dụng gRPC)
  - [ ] lib-spring-boot-starter-masterdata (khi sử dụng dữ liệu chính)
- [ ] Cập nhật phiên bản plugin Maven
- [ ] Lombok Cập nhật lên 1.18.30+
- [ ] Protobuf Kiểm tra version 0.1.XXX-SNAPSHOT có tương thích

### Giai đoạn 3: Sửa đổi mã nguồn
- [ ] Thực hiện thay thế hàng loạt gói javax → jakarta
- [ ] Thực hiện thay thế hàng loạt import của service-framework
- [ ] Tương thích với Spring Security 6:
  - [ ] WebSecurityConfigurerAdapter → SecurityFilterChain
  - [ ] authorizeRequests → authorizeHttpRequests
- [ ] Cập nhật cấu hình MongoDB:
  - [ ] AbstractMongoConfiguration → Định nghĩa Bean MongoClient
- [ ] Sửa lỗi biên dịch riêng lẻ
  - [ ] PathPatternParser mặc định: Kiểm tra các pattern matching
  - [ ] Jackson ObjectMapper: Kiểm tra custom serializers/deserializers
  - [ ] gRPC: Kiểm tra interceptor signatures có thay đổi không

### Giai đoạn 4: Cập nhật tệp cấu hình
- [ ] Tương thích application.yml với Spring Boot 3
- [ ] Thêm cấu hình gRPC (khi sử dụng gRPC)
- [ ] Cấu hình xác thực (theo loại dịch vụ):
  - [ ] **Dịch vụ API HTTP**: Cấu hình JWT Resource Server
  - [ ] **Dịch vụ gRPC**: Chỉ cấu hình cơ bản (không cần cấu hình OAuth2)
- [ ] Kiểm tra cấu hình theo môi trường
- [ ] Properties Deprecation Check
  - [ ] Chạy application với `--debug` để xem deprecated properties
  - [ ] Fix các properties đã đổi tên hoặc bị xóa
  - [ ] Kiểm tra `spring-configuration-metadata.json` nếu có custom properties

### Giai đoạn 5: Kiểm tra và xác minh
- [ ] `mvn clean compile` thành công
- [ ] `mvn clean test` thành công
- [ ] `mvn spring-boot:run` khởi động thành công
- [ ] Kiểm tra hoạt động theo chức năng:
  - [ ] **Dịch vụ API HTTP**: Kiểm tra phản hồi Web API và xác thực JWT
  - [ ] **Dịch vụ gRPC**: Kiểm tra giao tiếp gRPC và bộ chặn xác thực
  - [ ] **Khi sử dụng MongoDB**: Kiểm tra kết nối và hoạt động của repository

### Giai đoạn 6: Kiểm tra tích hợp
- [ ] Kiểm tra liên kết với các dịch vụ khác
- [ ] Kiểm tra liên kết xác thực (theo loại dịch vụ):
  - [ ] **Dịch vụ API HTTP**: Liên kết JWT với service-security hoặc service-oauth2-server
  - [ ] **Dịch vụ gRPC**: Liên kết bộ chặn xác thực gRPC
- [ ] Thực hiện kiểm tra hiệu năng

### Giai đoạn 7: Docker & Deployment
- [ ] Dockerfile Updates
- [ ] CI/CD Pipeline Updates
- [ ] Deployment Strategy
- [ ] Pre-deployment Checks
  - [ ] Backup database
  - [ ] Run migration scripts (nếu có)
  - [ ] Verify data integrity
- [ ] Rollback Plan

---

## 🔥 Hướng dẫn khắc phục sự cố

### Lỗi biên dịch

#### 1. Không tìm thấy gói `javax.*`
```
Ví dụ lỗi: cannot find symbol javax.persistence.Entity
```
**Nguyên nhân**: Thiếu sót khi thay thế javax → jakarta
**Giải pháp**:
```bash
# Xác định các vị trí còn lại
find src/ -name "*.java" -exec grep -l "javax\." {} \;

# Sửa thủ công hoặc thực hiện thay thế bổ sung
sed -i 's/javax\.annotation\./jakarta.annotation./g' [tệp mục tiêu]
```

#### 2. Không tìm thấy lớp service-framework
```
Ví dụ lỗi: cannot find symbol jp.drjoy.service.framework.*
```
**Nguyên nhân**: Thiếu sót khi thay thế câu lệnh import hoặc sử dụng chức năng chưa được chuyển sang thư viện mới
**Giải pháp**:
```bash
# Xác định các vị trí còn lại
grep -r "jp.drjoy.service.framework" src/

# Thay thế bằng lớp của thư viện lib-* tương ứng
# Ví dụ: jp.drjoy.service.framework.utils.Strings → jp.drjoy.lib.utils.Strings
```

#### 3. Lỗi liên quan đến Spring Security
```
Ví dụ lỗi: cannot find symbol WebSecurityConfigurerAdapter
```
**Nguyên nhân**: Sử dụng lớp đã bị xóa trong Spring Security 6
**Giải pháp**:
```java
// Trước khi cập nhật
public class SecurityConfig extends WebSecurityConfigurerAdapter {
  @Override
  protected void configure(HttpSecurity http) throws Exception {
    // Cấu hình
  }
}

// Sau khi cập nhật
@Configuration
public class SecurityConfig {
  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    // Kết thúc cấu hình bằng return http.build();
    return http.build();
  }
}
```

#### 4. Lỗi cấu hình MongoDB
```
Ví dụ lỗi: cannot find symbol AbstractMongoConfiguration
```
**Nguyên nhân**: Sử dụng lớp không được dùng nữa
**Giải pháp**:
```java
// Trước khi cập nhật
@Configuration
public class MongoConfig extends AbstractMongoConfiguration {
  // Cấu hình phức tạp
}

// Sau khi cập nhật
@Configuration
public class MongoConfig {
  @Bean
  public MongoClient mongoClient() {
    return MongoClients.create("mongodb://localhost:27017");
  }
}
```

### Lỗi phụ thuộc

#### 5. Không tìm thấy thư viện lib-*
```
Ví dụ lỗi: Could not find artifact jp.drjoy:lib-common-utils
```
**Nguyên nhân**: Thư viện lib-* chưa được build hoặc phiên bản không khớp
**Giải pháp**:
```bash
# Build tất cả các thư viện lib-* theo thứ tự phụ thuộc
cd work/lib-common-utils && mvn clean install
cd ../lib-common-models && mvn clean install
cd ../lib-spring-boot-starter-mongodb && mvn clean install
cd ../lib-spring-boot-starter-security && mvn clean install
cd ../lib-spring-boot-starter-grpc && mvn clean install
cd ../lib-spring-boot-starter-web && mvn clean install
cd ../lib-spring-boot-starter-masterdata && mvn clean install
```

#### 6. Lỗi xung đột phiên bản
```
Ví dụ lỗi: Dependency convergence error
```
**Nguyên nhân**: Xung đột giữa Spring Boot 3 và các phụ thuộc cũ
**Giải pháp**:
```xml
<!-- Chỉ định phiên bản rõ ràng trong pom.xml -->
<properties>
  <spring-boot.version>3.2.0</spring-boot.version>
</properties>

<!-- Hoặc quản lý bằng dependencyManagement -->
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-dependencies</artifactId>
      <version>3.2.0</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>
```

### Lỗi khi chạy

#### 7. Khởi động ứng dụng thất bại
```
Ví dụ lỗi: Failed to configure a DataSource
```
**Nguyên nhân**: Tệp cấu hình không tương thích với Spring Boot 3
**Giải pháp**:
```yaml
# Kiểm tra và sửa application.yml
spring:
  application:
    name: [SERVICE_NAME]
  data:
    mongodb:
      uri: mongodb://localhost:27017/[DATABASE_NAME]
```

#### 8. Khởi động máy chủ gRPC thất bại
```
Ví dụ lỗi: Port already in use: 9091
```
**Nguyên nhân**: Xung đột cổng hoặc cấu hình gRPC không hợp lệ
**Giải pháp**:
```bash
# Kiểm tra việc sử dụng cổng
netstat -tulpn | grep 9091

# Thay đổi sang cổng khác
# application.yml
grpc:
  server:
    port: 9092  # Cổng có sẵn
```

#### 9. Lỗi xác thực (theo loại dịch vụ)

**Trường hợp dịch vụ API HTTP:**
```
Ví dụ lỗi: 401 Unauthorized / JWT validation error
```
**Nguyên nhân**: Cấu hình JWT Resource Server không hợp lệ hoặc máy chủ xác thực chưa khởi động
**Giải pháp**:
```yaml
# Kiểm tra cấu hình JWT trong application.yml
service:
  oauth2:
    secret-public: secret/oauth2.pub  # Kiểm tra đường dẫn tệp khóa công khai
    resource-id: demo
```

**Trường hợp dịch vụ gRPC:**
```
Ví dụ lỗi: PERMISSION_DENIED (Trạng thái gRPC)
```
**Nguyên nhân**: Xác thực của bộ chặn xác thực gRPC thất bại
**Giải pháp**:
```bash
# Kiểm tra xem máy khách gRPC có gửi mã thông báo xác thực phù hợp không
# Kiểm tra cấu hình GrpcAuthServerInterceptor
```

#### 10. Lỗi kết nối MongoDB
```
Ví dụ lỗi: Connection refused to MongoDB
```
**Nguyên nhân**: MongoDB chưa khởi động hoặc cấu hình URI không hợp lệ
**Giải pháp**:
```bash
# Kiểm tra khởi động MongoDB
sudo systemctl status mongod

# Kiểm tra chuỗi kết nối
# application.yml
spring:
  data:
    mongodb:
      uri: mongodb://localhost:27017/[tên DB chính xác]
```

### Lỗi kiểm thử

#### 11. Kiểm thử đơn vị thất bại
```
Ví dụ lỗi: NoSuchMethodError in test
```
**Nguyên nhân**: Mã kiểm thử không tương thích với Spring Boot 3
**Giải pháp**:
```java
// Trước khi cập nhật
@SpringBootTest
@TestPropertySource(locations = "classpath:application-test.yml")

// Sau khi cập nhật
@SpringBootTest
@TestPropertySource(properties = {
  "spring.test.database.replace=none"
})
```

#### 12. Lỗi kiểm thử MockMvc
```
Ví dụ lỗi: IllegalArgumentException in MockMvc
```
**Nguyên nhân**: Thay đổi phương thức kiểm thử của Spring Security 6
**Giải pháp**:
```java
// Trước khi cập nhật
@Test
@WithMockUser
public void testEndpoint() throws Exception {
  mockMvc.perform(get("/api/test"))
    .andExpect(status().isOk());
}

// Sau khi cập nhật (vô hiệu hóa Security bằng @MockBean nếu cần)
@Test
@WithMockUser
@MockBean(SecurityFilterChain.class)
public void testEndpoint() throws Exception {
  // Triển khai kiểm thử
}
```

---

#### 13. Lỗi OAuth2 Authentication Provider
```
Ví dụ lỗi: No AuthenticationProvider found for ResourceOwnerPasswordAuthenticationToken
```
**Nguyên nhân**: Custom authentication provider chưa được đăng ký đúng với Spring Authorization Server
**Giải pháp**:
```java
// Trong AuthorizationServerConfig
http.getConfigurer(OAuth2AuthorizationServerConfigurer.class)
    .tokenEndpoint(tokenEndpoint ->
        tokenEndpoint
            .accessTokenRequestConverters(converters ->
                converters.add(new ResourceOwnerPasswordAuthenticationConverter()))
            .authenticationProvider(new ResourceOwnerPasswordAuthenticationProvider(
                authenticationManager, authorizationService, tokenGenerator,
                clientRepository, authenticationTokenFactory))
    );
```

#### 14. JWT Claims không xuất hiện trong token
```
Ví dụ lỗi: Expected claim 'user_id' not found in JWT
```
**Nguyên nhân**: OAuth2TokenCustomizer chưa được áp dụng hoặc logic customize có vấn đề
**Giải pháp**:
```java
// Đảm bảo JwtTokenCustomizer được đánh dấu @Component
@Component
public class JwtTokenCustomizer implements OAuth2TokenCustomizer<JwtEncodingContext> {
    @Override
    public void customize(JwtEncodingContext context) {
        if (context.getTokenType().getValue().equals("access_token")) {
            // Add custom claims
            context.getClaims().claim("user_id", userId);
        }
    }
}

// Và tokenGenerator được config với customizer
@Bean
public OAuth2TokenGenerator<?> tokenGenerator(
        JWKSource<SecurityContext> jwkSource,
        @Autowired(required = false) OAuth2TokenCustomizer<JwtEncodingContext> jwtCustomizer) {
    JwtGenerator jwtGenerator = new JwtGenerator(new NimbusJwtEncoder(jwkSource));
    if (jwtCustomizer != null) {
        jwtGenerator.setJwtCustomizer(jwtCustomizer);
    }
    return jwtGenerator;
}
```

#### 15. gRPC Interceptor không hoạt động
```
Ví dụ lỗi: Authentication required but no token found in metadata
```
**Nguyên nhân**: Interceptor chưa được đăng ký hoặc order không đúng
**Giải pháp**:
```java
// Server interceptor
@GrpcService
public class MyGrpcService extends MyServiceGrpc.MyServiceImplBase {
    // Service implementation
}

// Đảm bảo GrpcAuthServerInterceptor từ lib-spring-boot-starter-security được auto-configured
// Hoặc đăng ký thủ công:
@Configuration
public class GrpcConfig {
    @Bean
    public GlobalServerInterceptorConfigurer authInterceptor(GrpcAuthServerInterceptor interceptor) {
        return registry -> registry.addServerInterceptors(interceptor);
    }
}
```

#### 16. Lỗi "aud claim is not a JSON array"
```
Ví dụ lỗi: Legacy services expect aud as array but getting string
```
**Nguyên nhân**: Spring Authorization Server mặc định tạo aud là string, legacy services cần array
**Giải pháp**:
```java
// Sử dụng LegacyCompatibleJwtEncoder
@Bean
public OAuth2TokenGenerator<?> tokenGenerator(JWKSource<SecurityContext> jwkSource) {
    // Custom encoder converts aud to array for backward compatibility
    JwtEncoder jwtEncoder = new LegacyCompatibleJwtEncoder(jwkSource);
    JwtGenerator jwtGenerator = new JwtGenerator(jwtEncoder);
    return jwtGenerator;
}

// LegacyCompatibleJwtEncoder implementation in service-security
```

#### 17. Lỗi client authentication với {noop} prefix
```
Ví dụ lỗi: Client authentication failed - password mismatch
```
**Nguyên nhân**: PasswordEncoder không xử lý {noop} prefix đúng
**Giải pháp**:
```java
// Sử dụng DelegatingPasswordEncoder với {noop} support
@Bean
public PasswordEncoder passwordEncoder() {
    return PasswordEncoderFactories.createDelegatingPasswordEncoder();
}

// Và configure ClientSecretAuthenticationProvider
private Consumer<List<AuthenticationProvider>> configureClientAuthenticationProviders() {
    return authenticationProviders -> {
        for (AuthenticationProvider provider : authenticationProviders) {
            if (provider instanceof ClientSecretAuthenticationProvider) {
                ((ClientSecretAuthenticationProvider) provider)
                    .setPasswordEncoder(passwordEncoder);
            }
        }
    };
}
```

#### 18. Lỗi MongoDB Index creation
```
Ví dụ lỗi: Index already exists with different options
```
**Nguyên nhân**: Index definition thay đổi nhưng index cũ vẫn tồn tại
**Giải pháp**:
```bash
# Connect to MongoDB và drop index cũ
mongo
use your_database
db.your_collection.dropIndex("index_name")

# Hoặc trong code, drop và recreate
@Configuration
public class MongoIndexConfig implements InitializingBean {
    @Autowired
    private MongoTemplate mongoTemplate;
    
    @Override
    public void afterPropertiesSet() {
        // Drop old index if exists
        try {
            mongoTemplate.indexOps(User.class).dropIndex("old_index");
        } catch (Exception e) {
            // Ignore if not exists
        }
        
        // Create new index
        mongoTemplate.indexOps(User.class).ensureIndex(
            new Index().on("field", Sort.Direction.ASC).unique()
        );
    }
}
```

#### 19. Lỗi PathPattern không khớp
```
Ví dụ lỗi: Endpoint /api/users/{id} không match với PathPatternParser
```
**Nguyên nhân**: Spring Boot 3 dùng PathPatternParser thay vì AntPathMatcher
**Giải pháp**:
```java
// OLD pattern (AntPathMatcher)
"/api/users/**"  // Match /api/users/1/profile

// NEW pattern (PathPatternParser) - tương tự nhưng strict hơn
"/api/users/**"  // Vẫn work nhưng có thể cần adjust
"/api/users/{id}"  // Exact match
"/api/users/{id}/**"  // Match sub-paths

// Nếu vẫn muốn dùng AntPathMatcher (không khuyến nghị):
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {
    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        configurer.setPatternParser(null); // Disable PathPatternParser
        configurer.setPathMatcher(new AntPathMatcher());
    }
}
```

#### 20. Lỗi Java 17/21 module system
```
Ví dụ lỗi: IllegalAccessError: class X cannot access class Y (module java.base)
```
**Nguyên nhân**: Java 9+ module system restrictions
**Giải pháp**:
```bash
# Thêm JVM flags để open modules (development only)
--add-opens java.base/java.lang=ALL-UNNAMED
--add-opens java.base/java.util=ALL-UNNAMED

# Trong pom.xml surefire plugin
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <configuration>
        <argLine>
            --add-opens java.base/java.lang=ALL-UNNAMED
            --add-opens java.base/java.util=ALL-UNNAMED
        </argLine>
    </configuration>
</plugin>

# Long-term: Fix code để không rely on reflection vào internal classes
```

#### 21. Lỗi Protobuf version incompatibility
```
Ví dụ lỗi: com.google.protobuf.GeneratedMessageV3 not found
```
**Nguyên nhân**: gRPC và Protobuf versions không compatible với Java 17/21
**Giải pháp**:
```xml
<!-- Trong pom.xml, đảm bảo versions tương thích -->
<properties>
    <grpc.version>1.64.0</grpc.version>
    <protobuf.version>3.25.3</protobuf.version>
</properties>

<dependency>
    <groupId>io.grpc</groupId>
    <artifactId>grpc-netty</artifactId>
    <version>${grpc.version}</version>
</dependency>
<dependency>
    <groupId>com.google.protobuf</groupId>
    <artifactId>protobuf-java</artifactId>
    <version>${protobuf.version}</version>
</dependency>
```

#### 22. Masterdata không load được
```
Ví dụ lỗi: RoleMasterService returns empty roles
```
**Nguyên nhân**: Masterdata collection chưa được populate hoặc cache chưa refresh
**Giải pháp**:
```java
// Kiểm tra MongoDB có data không
db.master_data.find({ type: "ROLE" })

// Force refresh cache
@Autowired
private MasterDataCacheService masterDataCacheService;

public void refreshMasterData() {
    masterDataCacheService.refreshCache();
}

// Hoặc thêm data initialization service
@Service
public class DataInitializationService implements ApplicationRunner {
    @Override
    public void run(ApplicationArguments args) {
        if (masterDataRepository.count() == 0) {
            // Load default master data
            seedDefaultMasterData();
        }
    }
}
```

## 🚨 Xử lý khẩn cấp

### Quy trình khôi phục

Nếu xảy ra sự cố nghiêm trọng trong quá trình di chuyển:

```bash
# 1. Quay lại nhánh ban đầu từ nhánh làm việc
git checkout develop

# 2. Xóa nhánh làm việc (nếu cần)
git branch -D feature/renew_framework

# 3. Hoặc quay lại một commit cụ thể
git reset --hard [hàm băm commit trước đó]

# 4. Đẩy bắt buộc (thực hiện cẩn thận)
git push origin develop --force
```

### Phục hồi theo giai đoạn

Nếu chỉ một số chức năng có vấn đề:

```bash
# 1. Chỉ khôi phục các tệp có vấn đề
git checkout HEAD~1 -- [đường dẫn tệp có vấn đề]

# 2. Khôi phục các commit theo giai đoạn
git revert [hàm băm commit có vấn đề]

# 3. Tạm thời vô hiệu hóa các cấu hình riêng lẻ
# Chú thích các cấu hình có vấn đề trong application.yml
```

---

---

## ⚠️ Lưu ý quan trọng

### Hiểu kiến trúc xác thực

**Dịch vụ API HTTP (service-web-front, service-admin, v.v.):**
- Cần xác thực và ủy quyền bằng JWT Token
- Lấy JWT từ service-oauth2-server hoặc service-security và xác minh trong mỗi yêu cầu
- Cần thiết phải có cấu hình JWT Resource Server

**Dịch vụ gRPC (service-registration, v.v.):**
- Sử dụng cơ chế xác thực gRPC riêng
- Xử lý xác thực bằng GrpcAuthServerInterceptor
- **Không cần cấu hình máy khách OAuth2**

### Các điểm kiểm tra khi di chuyển
1. Xác định kiến trúc của dịch vụ trước tiên
2. Kiểm tra sự tồn tại của các điểm cuối API HTTP
3. Chọn và cấu hình phương thức xác thực phù hợp

## 📞 Thông tin hỗ trợ

### Nơi tư vấn
- **Vấn đề kỹ thuật**: Trưởng nhóm phát triển
- **Vấn đề thư viện lib-***: Người phụ trách framework
- **Kiến trúc xác thực**: Nhóm nền tảng xác thực

### Tài liệu tham khảo
- `projects/renew-backend-framework/detailed_plan.md` - Kế hoạch di chuyển chi tiết
- Thành tích di chuyển `service-registration` - Ví dụ thực tế về dịch vụ gRPC
- Hướng dẫn di chuyển Spring Boot 3 - Tài liệu chính thức
- Hướng dẫn di chuyển Spring Security 6 - Liên quan đến xác thực

### Nơi kiểm tra nhật ký
- Nhật ký ứng dụng: `logs/application.log`
- Nhật ký gRPC: `logs/grpc.log`
- Nhật ký Spring Boot: Đầu ra của bảng điều khiển
- Nhật ký xác thực JWT: Nhật ký gỡ lỗi Spring Security
