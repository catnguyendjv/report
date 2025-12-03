# Danh sách kiểm tra di chuyển dịch vụ & Khắc phục sự cố

## 📋 Danh sách kiểm tra công việc di chuyển

### Xác nhận trước
- [ ] Xác định các dịch vụ cần di chuyển
- [ ] Xác nhận ngăn xếp công nghệ hiện tại (phiên bản Spring Boot, phiên bản Java)
- [ ] Xác định các chức năng được sử dụng của service-framework
- [ ] Hoàn thành việc xây dựng trước các thư viện lib-*

### Giai đoạn 1: Chuẩn bị môi trường
- [ ] Tạo nhánh feature/renew_framework
- [ ] Phân tích phụ thuộc (`mvn dependency:tree`)
- [ ] Phân tích các vị trí sử dụng framework (`grep -r "jp.drjoy.service.framework"`)

### Giai đoạn 2: Cập nhật pom.xml
- [ ] Phiên bản Spring Boot → 3.2.0
- [ ] Phiên bản Java → 17
- [ ] Xóa phụ thuộc service-framework
- [ ] Thêm lib-common-utils
- [ ] Thêm lib-common-models
- [ ] Thêm các thư viện lib-* theo chức năng:
  - [ ] lib-spring-boot-starter-web (khi sử dụng chức năng Web)
  - [ ] lib-spring-boot-starter-security (khi sử dụng chức năng xác thực)
  - [ ] lib-spring-boot-starter-mongodb (khi sử dụng MongoDB)
  - [ ] lib-spring-boot-starter-grpc (khi sử dụng gRPC)
  - [ ] lib-spring-boot-starter-masterdata (khi sử dụng dữ liệu chính)
- [ ] Cập nhật phiên bản plugin Maven

### Giai đoạn 3: Sửa đổi mã
- [ ] Chạy thay thế hàng loạt gói javax → jakarta
- [ ] Chạy thay thế hàng loạt import service-framework
- [ ] Hỗ trợ Spring Security 6:
  - [ ] WebSecurityConfigurerAdapter → SecurityFilterChain
  - [ ] authorizeRequests → authorizeHttpRequests
- [ ] Cập nhật cấu hình MongoDB:
  - [ ] AbstractMongoConfiguration → Định nghĩa Bean MongoClient
- [ ] Sửa đổi riêng lẻ các lỗi biên dịch

### Giai đoạn 4: Cập nhật tệp cấu hình
- [ ] Hỗ trợ Spring Boot 3 cho application.yml
- [ ] Thêm cấu hình gRPC (khi sử dụng gRPC)
- [ ] Cấu hình xác thực (tùy theo loại dịch vụ):
  - [ ] **Dịch vụ API HTTP**: Cấu hình Máy chủ tài nguyên JWT
  - [ ] **Dịch vụ gRPC**: Chỉ cấu hình cơ bản (không cần cấu hình OAuth2)
- [ ] Xác nhận cấu hình theo môi trường

### Giai đoạn 5: Kiểm thử và xác minh
- [ ] `mvn clean compile` thành công
- [ ] `mvn clean test` thành công
- [ ] `mvn spring-boot:run` khởi động thành công
- [ ] Xác nhận hoạt động theo chức năng:
  - [ ] **Dịch vụ API HTTP**: Xác nhận phản hồi API Web và xác thực JWT
  - [ ] **Dịch vụ gRPC**: Xác nhận giao tiếp gRPC và bộ chặn xác thực
  - [ ] **Khi sử dụng MongoDB**: Xác nhận kết nối và hoạt động của kho lưu trữ

### Giai đoạn 6: Xác nhận tích hợp
- [ ] Xác nhận tích hợp với các dịch vụ khác
- [ ] Xác nhận tích hợp xác thực (tùy theo loại dịch vụ):
  - [ ] **Dịch vụ API HTTP**: Tích hợp JWT với service-security hoặc service-oauth2-server
  - [ ] **Dịch vụ gRPC**: Tích hợp bộ chặn xác thực gRPC
- [ ] Thực hiện kiểm thử hiệu năng

---

## 🔥 Hướng dẫn khắc phục sự cố

### Lỗi biên dịch

#### 1. Không tìm thấy gói `javax.*`
```
Ví dụ lỗi: cannot find symbol javax.persistence.Entity
```
**Nguyên nhân**: Bỏ sót thay thế javax → jakarta
**Giải pháp**:
```bash
# Xác định các vị trí còn lại
find src/ -name "*.java" -exec grep -l "javax\." {} \;

# Sửa đổi thủ công hoặc chạy thay thế bổ sung
sed -i 's/javax\.annotation\./jakarta.annotation./g' [tệp mục tiêu]
```

#### 2. Không tìm thấy lớp service-framework
```
Ví dụ lỗi: cannot find symbol jp.drjoy.service.framework.*
```
**Nguyên nhân**: Bỏ sót thay thế câu lệnh import hoặc sử dụng chức năng chưa được chuyển sang thư viện mới
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
**Nguyên nhân**: Thư viện lib-* chưa được xây dựng hoặc phiên bản không khớp
**Giải pháp**:
```bash
# Xây dựng trước tất cả các thư viện lib-*
./scripts/build-libs.sh

# Hoặc xây dựng riêng lẻ
cd work/lib-common-utils && mvn clean install
cd work/lib-common-models && mvn clean install
# Các lib-* khác cũng tương tự
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

### Lỗi thời gian chạy

#### 7. Khởi động ứng dụng không thành công
```
Ví dụ lỗi: Failed to configure a DataSource
```
**Nguyên nhân**: Tệp cấu hình không tương thích với Spring Boot 3
**Giải pháp**:
```yaml
# Xác nhận và sửa đổi application.yml
spring:
  application:
    name: [SERVICE_NAME]
  data:
    mongodb:
      uri: mongodb://localhost:27017/[DATABASE_NAME]
```

#### 8. Khởi động máy chủ gRPC không thành công
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

#### 9. Lỗi xác thực (tùy theo loại dịch vụ)

**Trường hợp dịch vụ API HTTP:**
```
Ví dụ lỗi: 401 Unauthorized / JWT validation error
```
**Nguyên nhân**: Cấu hình Máy chủ tài nguyên JWT không hợp lệ hoặc máy chủ xác thực chưa được khởi động
**Giải pháp**:
```yaml
# Xác nhận cấu hình JWT trong application.yml
service:
  oauth2:
    secret-public: secret/oauth2.pub  # Xác nhận đường dẫn tệp khóa công khai
    resource-id: demo
```

**Trường hợp dịch vụ gRPC:**
```
Ví dụ lỗi: PERMISSION_DENIED (Trạng thái gRPC)
```
**Nguyên nhân**: Xác thực của bộ chặn xác thực gRPC không thành công
**Giải pháp**:
```bash
# Xác nhận rằng máy khách gRPC đang gửi mã thông báo xác thực phù hợp
# Xác nhận cấu hình của GrpcAuthServerInterceptor
```

#### 10. Lỗi kết nối MongoDB
```
Ví dụ lỗi: Connection refused to MongoDB
```
**Nguyên nhân**: MongoDB chưa được khởi động hoặc cấu hình URI không hợp lệ
**Giải pháp**:
```bash
# Xác nhận khởi động MongoDB
sudo systemctl status mongod

# Xác nhận chuỗi kết nối
# application.yml
spring:
  data:
    mongodb:
      uri: mongodb://localhost:27017/[tên DB chính xác]
```

### Lỗi kiểm thử

#### 11. Kiểm thử đơn vị không thành công
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

// Sau khi cập nhật (vô hiệu hóa Security bằng @MockBean, v.v. nếu cần)
@Test
@WithMockUser
@MockBean(SecurityFilterChain.class)
public void testEndpoint() throws Exception {
  // Triển khai kiểm thử
}
```

---

## 🚨 Xử lý khẩn cấp

### Quy trình khôi phục

Nếu xảy ra sự cố nghiêm trọng trong quá trình di chuyển:

```bash
# 1. Quay lại nhánh ban đầu từ nhánh làm việc
git checkout develop

# 2. Xóa nhánh làm việc (nếu cần)
git branch -D feature/renew_framework

# 3. Hoặc quay lại một cam kết cụ thể
git reset --hard [hàm băm cam kết trước đó]

# 4. Đẩy bắt buộc (thực hiện cẩn thận)
git push origin develop --force
```

### Phục hồi theo giai đoạn

Nếu chỉ một số chức năng có vấn đề:

```bash
# 1. Chỉ khôi phục các tệp có vấn đề
git checkout HEAD~1 -- [đường dẫn tệp có vấn đề]

# 2. Quay lại các cam kết theo từng giai đoạn
git revert [hàm băm cam kết có vấn đề]

# 3. Tạm thời vô hiệu hóa các cấu hình riêng lẻ
# Chú thích các cấu hình có vấn đề trong application.yml
```

---

---

## ⚠️ Lưu ý quan trọng

### Hiểu kiến trúc xác thực

**Dịch vụ API HTTP (service-web-front, service-admin, v.v.):**
- Cần xác thực và ủy quyền bằng Mã thông báo JWT
- Lấy JWT từ service-oauth2-server hoặc service-security và xác minh trong mỗi yêu cầu
- Cần có cấu hình Máy chủ tài nguyên JWT

**Dịch vụ gRPC (service-registration, v.v.):**
- Sử dụng cơ chế xác thực gRPC riêng
- Xử lý xác thực bằng GrpcAuthServerInterceptor
- **Không cần cấu hình máy khách OAuth2**

### Các điểm kiểm tra khi di chuyển
1. Xác định kiến trúc của dịch vụ trước tiên
2. Xác nhận sự tồn tại của các điểm cuối API HTTP
3. Chọn và cấu hình phương thức xác thực phù hợp

## 📞 Thông tin hỗ trợ

### Nơi tư vấn
- **Vấn đề kỹ thuật**: Trưởng nhóm phát triển
- **Vấn đề thư viện lib-***: Người phụ trách khung
- **Kiến trúc xác thực**: Nhóm nền tảng xác thực

### Tài liệu tham khảo
- `projects/renew-backend-framework/detailed_plan.md` - Kế hoạch di chuyển chi tiết
- Thành tích di chuyển `service-registration` - Ví dụ thực tế về dịch vụ gRPC
- Hướng dẫn di chuyển Spring Boot 3 - Tài liệu chính thức
- Hướng dẫn di chuyển Spring Security 6 - Liên quan đến xác thực

### Vị trí kiểm tra nhật ký
- Nhật ký ứng dụng: `logs/application.log`
- Nhật ký gRPC: `logs/grpc.log`
- Nhật ký Spring Boot: Đầu ra của bảng điều khiển
- Nhật ký xác thực JWT: Nhật ký gỡ lỗi Spring Security