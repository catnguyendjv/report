# Tài liệu thiết kế hiện đại hóa OAuth2 Server

## 1. Tổng quan

Tài liệu này định nghĩa thiết kế kỹ thuật cho nền tảng xác thực và ủy quyền mới, dựa trên [Kế hoạch chuyển đổi hiện đại hóa OAuth2 Server](README.md).
Mục tiêu chính là phân tách `service-framework` hiện tại thành nhiều thư viện hướng microservice và xây dựng một OAuth2 Server mới là `service-security` dựa trên Spring Boot 3 / JDK 17.

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

### 2.2. Hiện đại hóa quản lý cấu hình

Loại bỏ các `enum` được hardcode và giới thiệu một cơ chế để quản lý cấu hình động từ bên ngoài.

-   **Cấu hình liên quan đến logic nghiệp vụ (vai trò, quyền hạn, v.v.):**
    -   Sử dụng MongoDB làm dữ liệu chủ.
    -   Mỗi dịch vụ sẽ đọc cấu hình từ DB khi khởi động và lưu vào bộ đệm. Chức năng này sẽ được triển khai trong thư viện chuyên dụng `lib-spring-boot-starter-masterdata`.
-   **Cấu hình hệ thống (loại dịch vụ, v.v.):**
    -   Sử dụng Spring Cloud Config Server để quản lý tập trung bằng các tệp `.yml`.

## 3. Thiết kế `service-security`

`service-security` là một OAuth2 Server mới dựa trên Spring Authorization Server.

### 3.1. Các dependency chính

-   Spring Boot 3 / JDK 17
-   `spring-boot-starter-oauth2-authorization-server`
-   Nhóm các thư viện `lib-spring-boot-starter-*` đã được định nghĩa ở trên.

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

### 3.3. Tạo token

-   **Chữ ký JWT:** Tương tự như `service-oauth2-server`, sẽ áp dụng phương thức ký sử dụng keystore (`.jks`).
-   **Custom Claims:** Triển khai `OAuth2TokenCustomizer` để thêm các claim tùy chỉnh như thông tin đơn vị và quyền hạn của người dùng vào payload của JWT. Thông tin quyền hạn này sẽ được lấy từ DB thông qua cơ chế quản lý dữ liệu chủ.

### 3.4. Bộ lọc bảo mật (Security Filter)

Các interceptor hiện có sẽ được triển khai lại dưới dạng `Filter` của Spring Security và được tích hợp vào `SecurityFilterChain`.

-   `MaintenanceRequestFilter`: Kiểm tra chế độ bảo trì.
-   `RecaptchaCheckerFilter`: Xác minh reCAPTCHA.
-   `TwoFactorAuthenticationFilter`: Xác minh xác thực hai yếu tố.

Các bộ lọc này sẽ được triển khai trong `lib-spring-boot-starter-web` hoặc `lib-spring-boot-starter-security` và được kích hoạt trong `service-security`.

### 3.5. Endpoint API tùy chỉnh

Các API tùy chỉnh sau đây đã tồn tại trong `service-oauth2-server` sẽ được chuyển đổi hoặc triển khai lại trong `service-security`.

-   `/v1/certificate/check`: API thông tin chứng chỉ
-   `/fb/access/token`: API token Firebase
-   Nhóm dịch vụ gRPC

## 4. Thiết kế dữ liệu

### 4.1. Lược đồ cơ sở dữ liệu

`service-security` sẽ sử dụng MongoDB. Các collection chính như sau:

-   **users**: Thông tin người dùng
-   **clients**: Thông tin client OAuth2 (`RegisteredClient`)
-   **authorizations**: Thông tin ủy quyền
-   **master_data**: Dữ liệu chủ như vai trò, quyền hạn

### 4.2. Di chuyển dữ liệu

-   **Thông tin client:** Tạo một script di chuyển để chuyển đổi dữ liệu từ `oauth_client_details` cũ sang định dạng `RegisteredClient` của Spring Authorization Server.
-   **Thông tin người dùng:** Di chuyển thông tin người dùng hiện có để phù hợp với lược đồ mới. Mật khẩu sẽ được băm lại nếu cần.
-   **Refresh token:** Về nguyên tắc, các refresh token hiện có sẽ bị vô hiệu hóa. Chiến lược di chuyển sẽ được xem xét riêng.

## 5. Chiến lược kiểm thử và chuyển đổi

### 5.1. Kế hoạch kiểm thử

-   **Kiểm thử đơn vị (Unit test):** Triển khai các bài kiểm thử sử dụng JUnit/Mockito cho từng thành phần, đặc biệt là các nhà cung cấp xác thực và logic dịch vụ.
-   **Kiểm thử tích hợp (Integration test):** Triển khai các bài kiểm thử ở cấp độ HTTP bao gồm các loại grant chính (Authorization Code, Client Credentials, v.v.).
-   **Kiểm thử đầu cuối (E2E test):** Chuẩn bị một client thử nghiệm và xác nhận hoạt động của toàn bộ luồng xác thực trên môi trường staging.

### 5.2. Chuyển đổi theo giai đoạn

`service-web-front` và `service-registration` sẽ được chuyển đổi trước, và kiến thức thu được sẽ được áp dụng để triển khai cho các dịch vụ khác. Sử dụng canary release với API gateway để chuyển dần lưu lượng truy cập sang hệ thống mới.

## 6. Giám sát

Sử dụng Prometheus và Grafana để xây dựng một dashboard giám sát số lượng yêu cầu, độ trễ và tỷ lệ lỗi của dịch vụ mới. Đồng thời, giám sát lỗi theo thời gian thực bằng hệ thống ghi log tập trung.
