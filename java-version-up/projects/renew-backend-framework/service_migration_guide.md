# Hướng dẫn di chuyển dịch vụ hiện có
## Sổ tay hướng dẫn thực hành di chuyển thư viện service-framework → lib-*

Hướng dẫn này là một sổ tay hướng dẫn chung để di chuyển hiệu quả các microservice có cấu hình tương tự, dựa trên thành tích di chuyển của `service-registration` (hoàn thành 95%).

## 🏗️ Tổng quan về kiến trúc di chuyển

### Trước khi di chuyển (Hiện tại)
```
Microservice → service-framework (Spring Boot 2.x, Java 8/11) → Các chức năng khác nhau
```

### Sau khi di chuyển (Mục tiêu)
```
Microservice → lib-spring-boot-starter-* (Spring Boot 3.x, Java 17) → Các chức năng khác nhau
```

### Cấu hình thư viện mới
- **Nền tảng**: `lib-common-utils`, `lib-common-models`
- **Spring Boot Starter**: `lib-spring-boot-starter-{grpc,security,mongodb,web,masterdata}`

---

## 📋 Xác định đối tượng di chuyển

### Đặc điểm của các dịch vụ cần di chuyển
- [ ] Có phụ thuộc vào `service-framework`
- [ ] Sử dụng Spring Boot 2.x
- [ ] Sử dụng Java 8 hoặc 11
- [ ] Sử dụng giao tiếp gRPC
- [ ] Sử dụng cơ sở dữ liệu MongoDB
- [ ] Sử dụng chức năng xác thực OAuth2

### Xác định mức độ ưu tiên di chuyển
- **🔴 Cao**: Các dịch vụ quan trọng đang được phát triển tích cực, đang hoạt động trong môi trường sản xuất
- **🟡 Trung bình**: Các dịch vụ được bảo trì định kỳ
- **🟢 Thấp**: Các dịch vụ cũ hoặc ít được sử dụng

---

## 📂 Giai đoạn 1: Chuẩn bị trước (Thời gian ước tính: 30 phút)

### 1.1. Tạo nhánh và phân tích hiện trạng

```bash
# Di chuyển đến thư mục của dịch vụ mục tiêu
cd [TARGET_SERVICE_DIRECTORY]

# Tạo và chuyển sang nhánh feature/renew_framework
git checkout -b feature/renew_framework

# Kiểm tra các phụ thuộc hiện tại
mvn dependency:tree > dependency_analysis.txt

# Phân tích các vị trí sử dụng service-framework
grep -r "jp.drjoy.service.framework" src/ > framework_usage.txt
```

### 1.2. Kiểm tra khả năng di chuyển

**Các mục kiểm tra bắt buộc:**
- [ ] Kiểm tra phiên bản Spring Boot hiện tại
- [ ] Kiểm tra phiên bản Java
- [ ] Xác định các chức năng chính đang được sử dụng
  - gRPC (Server/Client)
  - MongoDB Repository
  - Cấu hình Spring Security
  - Web Controllers
  - Quản lý dữ liệu chính

---

## 📦 Giai đoạn 2: Cập nhật pom.xml (Thời gian ước tính: 45 phút)

### 2.1. Cập nhật phiên bản cơ bản

```xml
<!-- Cập nhật POM cha của Spring Boot -->
<parent>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-parent</artifactId>
  <version>3.2.0</version>
</parent>

<!-- Cập nhật phiên bản Java -->
<properties>
  <java.version>17</java.version>
  <maven.compiler.source>17</maven.compiler.source>
  <maven.compiler.target>17</maven.compiler.target>
</properties>
```

### 2.2. Thay thế các phụ thuộc

**Xóa service-framework:**
```xml
<!-- Đối tượng xóa -->
<dependency>
  <groupId>jp.drjoy.service</groupId>
  <artifactId>service-framework</artifactId>
  <version>*</version>
</dependency>
```

**Thêm các thư viện lib-* (chọn tùy theo chức năng sử dụng):**
```xml
<!-- Thư viện nền tảng (bắt buộc) -->
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-common-utils</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-common-models</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>

<!-- Khi sử dụng chức năng Web -->
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-web</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>

<!-- Khi sử dụng chức năng xác thực -->
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-security</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>

<!-- Khi sử dụng MongoDB -->
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-mongodb</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>

<!-- Khi sử dụng gRPC -->
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-grpc</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>

<!-- Khi sử dụng quản lý dữ liệu chính -->
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-masterdata</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>
```

### 2.3. Cập nhật plugin Maven

```xml
<properties>
  <maven-compiler-plugin.version>3.11.0</maven-compiler-plugin.version>
  <maven-surefire-plugin.version>3.0.0-M9</maven-surefire-plugin.version>
</properties>

<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-compiler-plugin</artifactId>
      <version>${maven-compiler-plugin.version}</version>
      <configuration>
        <release>17</release>
      </configuration>
    </plugin>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-surefire-plugin</artifactId>
      <version>${maven-surefire-plugin.version}</version>
    </plugin>
  </plugins>
</build>
```

---

## 🔧 Giai đoạn 3: Sửa đổi mã nguồn (Thời gian ước tính: 2-3 giờ)

### 3.1. Thay thế hàng loạt tên gói

```bash
# Thay thế hàng loạt gói javax → jakarta
find src/ -name "*.java" -exec sed -i 's/javax\.persistence\./jakarta.persistence./g' {} \;
find src/ -name "*.java" -exec sed -i 's/javax\.validation\./jakarta.validation./g' {} \;
find src/ -name "*.java" -exec sed -i 's/javax\.servlet\./jakarta.servlet./g' {} \;
find src/ -name "*.java" -exec sed -i 's/javax\.transaction\./jakarta.transaction./g' {} \;

# Thay thế hàng loạt import của service-framework
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.grpc\./jp.drjoy.lib.grpc./g' {} \;
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.security\./jp.drjoy.lib.security./g' {} \;
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.utils\./jp.drjoy.lib.utils./g' {} \;
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.model\./jp.drjoy.lib.models./g' {} \;
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.publisher\./jp.drjoy.lib.grpc./g' {} \;
```

### 3.2. Tương thích với Spring Security 6

**Xử lý việc loại bỏ WebSecurityConfigurerAdapter:**

```java
// Trước khi cập nhật
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
  @Override
  protected void configure(HttpSecurity http) throws Exception {
    http.authorizeRequests()
        .antMatchers("/api/public/**").permitAll()
        .anyRequest().authenticated();
  }
}

// Sau khi cập nhật
@Configuration
@EnableWebSecurity
public class SecurityConfig {
  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http.authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/public/**").permitAll()
            .anyRequest().authenticated())
        .build();
  }
}
```

### 3.3. Cập nhật lớp cấu hình MongoDB

```java
// Trước khi cập nhật
@Configuration
@EnableMongoRepositories
public class MongoConfig extends AbstractMongoConfiguration {
  @Override
  protected String getDatabaseName() {
    return "database_name";
  }
  
  @Override
  public MongoClient mongoClient() {
    return MongoClients.create("mongodb://localhost:27017");
  }
}

// Sau khi cập nhật
@Configuration
@EnableMongoRepositories
public class MongoConfig {
  @Bean
  public MongoClient mongoClient() {
    return MongoClients.create("mongodb://localhost:27017");
  }
}
```

### 3.4. Các vị trí cần sửa đổi thủ công còn lại

Sửa đổi riêng lẻ các mẫu sau được xác định bởi lỗi biên dịch:

1. **Sử dụng các lớp/phương thức đã bị xóa**
2. **Thay đổi việc sử dụng enum sang dịch vụ dữ liệu chính**
3. **Tương thích lớp cấu hình gRPC với thư viện mới**

---

## ⚙️ Giai đoạn 4: Cập nhật tệp cấu hình (Thời gian ước tính: 30 phút)

### 4.1. Tương thích application.yml với Spring Boot 3

**Cập nhật cấu hình cơ bản:**
```yaml
spring:
  application:
    name: [SERVICE_NAME]
  
# Cấu hình gRPC (khi sử dụng gRPC)
grpc:
  server:
    port: [GRPC_PORT]
  client:
    channels:
      [TARGET_SERVICE]:
        address: static://localhost:[TARGET_PORT]
        negotiationType: plaintext

# Cấu hình MongoDB (khi sử dụng MongoDB)
spring:
  data:
    mongodb:
      uri: mongodb://localhost:27017/[DATABASE_NAME]
```

### 4.2. Cấu hình xác thực (theo loại dịch vụ)

#### 4.2.1. Trường hợp dịch vụ API HTTP (cấu hình JWT Resource Server)

Đối với các dịch vụ công khai các điểm cuối HTTP (service-web-front, service-admin, v.v.):

```yaml
# Cấu hình để xác minh JWT
service:
  oauth2:
    secret-public: ${OAUTH_SECRET_PUBLIC:secret/oauth2.pub}  # Đường dẫn khóa công khai JWT
    resource-id: ${OAUTH_RESOURCE_ID:demo}

# Cấu hình Spring Security 6 Resource Server
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          public-key-location: ${service.oauth2.secret-public}
```

#### 4.2.2. Trường hợp dịch vụ gRPC (không cần cấu hình OAuth2)

Đối với các dịch vụ chỉ dành cho gRPC (service-registration, v.v.):

```yaml
# Xác thực gRPC được xử lý bởi GrpcAuthServerInterceptor
# Không cần cấu hình máy khách OAuth2
# Chỉ cần cấu hình Spring Security cơ bản
```

**Quan trọng**: Các dịch vụ gRPC sử dụng cơ chế xác thực gRPC riêng, do đó không cần thêm cấu hình máy khách OAuth2.

---

## 🧪 Giai đoạn 5: Kiểm tra và xác minh (Thời gian ước tính: 1-2 giờ)

### 5.1. Kiểm tra hoạt động theo từng giai đoạn

```bash
# 1. Kiểm tra việc giải quyết các phụ thuộc
mvn clean compile

# 2. Chạy các bài kiểm tra đơn vị
mvn clean test

# 3. Kiểm tra khởi động ứng dụng
mvn spring-boot:run
```

### 5.2. Các mục kiểm tra theo chức năng

**Chức năng gRPC (nếu có):**
- [ ] Kiểm tra khởi động máy chủ gRPC
- [ ] Kiểm tra kết nối máy khách gRPC
- [ ] Kiểm tra hoạt động của bộ chặn

**Chức năng MongoDB (nếu có):**
- [ ] Kiểm tra kết nối cơ sở dữ liệu
- [ ] Kiểm tra hoạt động của Repository
- [ ] Kiểm tra hoạt động của giao dịch

**Chức năng Web (trường hợp dịch vụ API HTTP):**
- [ ] Kiểm tra phản hồi của bộ điều khiển
- [ ] Kiểm tra hoạt động xác thực và ủy quyền JWT
- [ ] Kiểm tra hoạt động của bộ lọc và bộ chặn

**Chức năng xác thực (theo loại dịch vụ):**
- [ ] **Dịch vụ API HTTP**: Kiểm tra hoạt động của JWT Resource Server
- [ ] **Dịch vụ gRPC**: Kiểm tra hoạt động của bộ chặn xác thực gRPC

---

## ✅ Danh sách kiểm tra chung

### Giai đoạn 1: Chuẩn bị trước
- [ ] Tạo nhánh feature/renew_framework
- [ ] Hoàn thành phân tích ngăn xếp công nghệ hiện tại
- [ ] Hoàn thành việc xác định các chức năng được sử dụng
- [ ] Xác định các phụ thuộc mục tiêu di chuyển

### Giai đoạn 2: Cập nhật pom.xml
- [ ] Cập nhật Spring Boot 3.2.0
- [ ] Cập nhật Java 17
- [ ] Xóa phụ thuộc service-framework
- [ ] Thêm các thư viện lib-* cần thiết
- [ ] Cập nhật plugin Maven

### Giai đoạn 3: Sửa đổi mã nguồn
- [ ] Hoàn thành thay thế hàng loạt javax → jakarta
- [ ] Hoàn thành thay thế hàng loạt import của service-framework
- [ ] Hoàn thành tương thích với Spring Security 6
- [ ] Hoàn thành cập nhật cấu hình MongoDB
- [ ] Hoàn thành giải quyết lỗi biên dịch

### Giai đoạn 4: Cập nhật cấu hình
- [ ] Tương thích application.yml với Spring Boot 3
- [ ] Cấu hình xác thực phù hợp với loại dịch vụ:
  - [ ] **Dịch vụ API HTTP**: Cấu hình JWT Resource Server
  - [ ] **Dịch vụ gRPC**: Chỉ cấu hình Spring Security cơ bản
- [ ] Hoàn thành thêm cấu hình theo chức năng sử dụng
- [ ] Hoàn thành kiểm tra cấu hình theo môi trường

### Giai đoạn 5: Kiểm tra và xác minh
- [ ] `mvn clean compile` thành công
- [ ] `mvn clean test` thành công
- [ ] `mvn spring-boot:run` khởi động thành công
- [ ] Hoàn thành kiểm tra hoạt động cơ bản của từng chức năng

---

## 🔥 Khắc phục sự cố thường gặp

### Các vấn đề thường gặp và giải pháp

#### 1. Lỗi biên dịch: Không tìm thấy gói
```bash
# Nguyên nhân: Thiếu sót khi thay thế javax → jakarta
# Giải pháp: Kiểm tra các vị trí còn lại và sửa thủ công
find src/ -name "*.java" -exec grep -l "javax\." {} \;
```

#### 2. Lỗi cấu hình Spring Security
```
Lỗi: Không tìm thấy các phương thức liên quan đến WebSecurityConfigurerAdapter
Giải pháp: Thay đổi sang mẫu định nghĩa Bean SecurityFilterChain
```

#### 3. Lỗi kết nối MongoDB
```
Lỗi: Lỗi gọi phương thức liên quan đến AbstractMongoConfiguration
Giải pháp: Thay đổi sang mẫu đơn giản hóa chỉ định nghĩa Bean MongoClient
```

#### 4. Lỗi phụ thuộc thư viện lib-*
```bash
# Nguyên nhân: Thư viện lib-* chưa được build
# Giải pháp: Build trước tất cả các thư viện lib-* theo thứ tự phụ thuộc
cd work/lib-common-utils && mvn clean install
cd ../lib-common-models && mvn clean install
cd ../lib-spring-boot-starter-mongodb && mvn clean install
cd ../lib-spring-boot-starter-security && mvn clean install
cd ../lib-spring-boot-starter-grpc && mvn clean install
cd ../lib-spring-boot-starter-web && mvn clean install
cd ../lib-spring-boot-starter-masterdata && mvn clean install
```

#### 5. Lỗi liên quan đến gRPC
```yaml
# Nguyên nhân: Cấu hình gRPC không nhất quán
# Giải pháp: Kiểm tra cấu hình grpc trong application.yml
grpc:
  server:
    port: [số cổng không được sử dụng]
```
#### 6. Một số khai báo hoặc hàm không còn sử dụng được nữa
  ```java
  1. new Sort ==> Sort.by
  2. List<Pair<Query, Update>> ==> List<Pair<Query, UpdateDefinition>>
  3. StreamUtils.createStreamFromIterator(mongoTemplate.stream(query, class)) ==> StreamUtils.createStreamFromIterator(mongoTemplate.stream(query, class).iterator())
  4. query.with(new PageRequest()) ==> query.with(PageRequest.of())
  5. new MongoClient(new MongoClientURI(props.getUri())) ==> MongoClients.create(props.getUri())
  6. .map(ATCalculateOverTimeBatchResult.Builder::build) ==> .map(builder -> builder.build())
  7. import javax.validation.constraints.NotBlank ==> import jakarta.validation.constraints.NotBlank
  8. application.yml : spring.profiles ==> spring.config.activate.on-profile
  9. mongoCollection.find(BSON.class) ==> mongoCollection.find(Document.class)
  10. Mockito.verifyZeroInteractions ==> Mockito.verifyNoInteractions
  11. Mockito.anyListOf(String.class) ==> Mockito.anyList()
  ```

#### 7. PowerMock gây lỗi trong JUnit khi nâng cấp lên Java 21 do không tương thích với phiên bản Java này.
  ```java
  1. Loại bỏ powermock ở file pom, thay thế bằng mockito version 5.2
  2. Sửa lại các class Unit test đang sử dụng powermock.
  ```
---

## 📊 Hướng dẫn ước tính nỗ lực di chuyển

### Phân loại theo quy mô dịch vụ
- **Quy mô nhỏ** (10-30 lớp): 2-3 ngày
- **Quy mô trung bình** (30-100 lớp): 3-5 ngày
- **Quy mô lớn** (100+ lớp): 5-7 ngày

### Nỗ lực bổ sung theo chức năng sử dụng
- **Sử dụng gRPC**: +0.5 ngày
- **API HTTP + Xác thực JWT**: +1 ngày
- **Nhiều Repository MongoDB**: +0.5 ngày
- **Bộ lọc và bộ chặn tùy chỉnh**: +1 ngày

### Cân nhắc bổ sung theo loại dịch vụ
- **Dịch vụ API HTTP**: Cần cấu hình JWT Resource Server
- **Dịch vụ gRPC**: Không cần cấu hình OAuth2, chỉ cần cấu hình Spring Security cơ bản

---

## 🎯 Điểm mấu chốt để thành công

1. **Tuân thủ mẫu service-registration**: Dựa trên quy trình đã được chứng minh
2. **Hiểu loại dịch vụ**: Nắm bắt sự khác biệt về phương thức xác thực giữa dịch vụ API HTTP và dịch vụ gRPC
3. **Tiếp cận theo từng giai đoạn**: Tiến hành chắc chắn theo từng giai đoạn
4. **Tận dụng tự động hóa**: Tích cực sử dụng các tập lệnh thay thế hàng loạt
5. **Chuẩn bị trước các thư viện lib-***: Build trước các phụ thuộc
6. **Xác minh liên tục**: Xác nhận từng giai đoạn theo thứ tự biên dịch → kiểm tra → khởi động
7. **Kiểm tra theo chức năng**: Thực hiện kiểm tra hoạt động phù hợp với các chức năng đang được sử dụng

## ⚠️ Lưu ý quan trọng

**Phân biệt cấu hình xác thực:**
- **Dịch vụ API HTTP**: Cần cấu hình JWT Resource Server
- **Dịch vụ gRPC**: Không cần cấu hình OAuth2, sử dụng bộ chặn xác thực gRPC

Bằng cách làm theo hướng dẫn này, bạn có thể di chuyển hiệu quả tương tự như service-registration. Vui lòng chọn và thực hiện phương thức xác thực phù hợp tùy theo đặc điểm và kiến trúc của từng dịch vụ.
