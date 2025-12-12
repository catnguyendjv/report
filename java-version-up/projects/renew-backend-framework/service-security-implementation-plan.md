# Kế hoạch triển khai các tính năng chưa được triển khai của service-security

## Tổng quan

Tài liệu này liệt kê các tính năng chưa được triển khai trong quá trình chuyển đổi từ `service-oauth2-server` sang `service-security` và xác định kế hoạch triển khai.

**Ngày tạo**: Tháng 12 năm 2024
**Repository mục tiêu**: `work/service-security`
**Nguồn di chuyển**: `work/service-oauth2-server`

---

## Tóm tắt trạng thái triển khai

| Danh mục | Đã triển khai | Chưa triển khai/Triển khai một phần | Tỷ lệ hoàn thành |
|---|---|---|---|
| Máy khách gRPC | 1 | 5 | 17% |
| Nhà cung cấp xác thực | 7 | 4 | 64% |
| Lớp dịch vụ | 5 | 7 | 42% |
| Bảo mật/Mã thông báo | 4 | 3 | 57% |
| Bộ điều khiển | 3 | 1 | 75% |

---

## Giai đoạn 1: Ưu tiên cao (cần thiết cho luồng xác thực)

### 1.1 GoogleClient (xác minh reCAPTCHA)

**Ưu tiên**: 🔴 Cao nhất
**Ước tính nỗ lực**: 4 giờ
**Phụ thuộc**: RecaptchaCheckerFilter

```
Nội dung công việc:
- [ ] Tạo GoogleClient.java
  - Gọi API Google reCAPTCHA
  - Logic thử lại (backoff theo cấp số nhân)
  - Cài đặt thời gian chờ
- [ ] Tạo RecaptchaVerifyRequest.java
- [ ] Tạo RecaptchaVerifyResponse.java
- [ ] Tích hợp với RecaptchaCheckerFilter
- [ ] Tạo bài kiểm tra đơn vị
- [ ] Thêm cài đặt vào application.yml
  - recaptcha.secret
  - recaptcha.verify-url
  - recaptcha.min-score
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/service/GoogleClient.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/request/RecaptchaVerifyRequest.java`

---

### 1.2 RefreshTokenService

**Ưu tiên**: 🔴 Cao nhất
**Ước tính nỗ lực**: 3 giờ
**Phụ thuộc**: GrpcRegistrationAuthClient

```
Nội dung công việc:
- [ ] Tạo RefreshTokenService.java
  - Triển khai UserDetailsService
  - Làm mới thông tin bằng ID người dùng
  - Liên kết với GrpcRegistrationAuthClient
- [ ] Tích hợp vào AuthorizationServerConfig
- [ ] Tạo bài kiểm tra đơn vị
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/service/RefreshTokenService.java`

---

### 1.3 ExceptionTranslator

**Ưu tiên**: 🔴 Cao nhất
**Ước tính nỗ lực**: 4 giờ
**Phụ thuộc**: OTPRequiredException

```
Nội dung công việc:
- [ ] Tạo ExceptionTranslator.java
  - Triển khai WebResponseExceptionTranslator
  - Chuyển đổi OTPRequiredException → HTTP 428
  - Chuyển đổi StatusRuntimeException (gRPC) → HTTP
  - Tạo phản hồi phù hợp cho OAuth2Exception
- [ ] Tích hợp vào AuthorizationServerConfig
- [ ] Tạo bài kiểm tra đơn vị
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/security/ExceptionTranslator.java`

---

### 1.4 QuickLoginService

**Ưu tiên**: 🔴 Cao
**Ước tính nỗ lực**: 3 giờ
**Phụ thuộc**: GrpcRegistrationAuthClient

```
Nội dung công việc:
- [ ] Tạo QuickLoginService.java
  - Triển khai UserDetailsService
  - Xác minh mã thông báo đăng nhập nhanh
  - Liên kết với dịch vụ Đăng ký
- [ ] Triển khai đầy đủ QuickPersonalAuthenticationProvider
- [ ] Tạo bài kiểm tra đơn vị
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/service/QuickLoginService.java`

---

### 1.5 GrpcMeetingAuthenticationClient + NologinMeetingService

**Ưu tiên**: 🔴 Cao
**Ước tính nỗ lực**: 5 giờ
**Phụ thuộc**: định nghĩa protobuf

```
Nội dung công việc:
- [ ] Tạo GrpcMeetingAuthenticationClient.java
  - Kết nối gRPC với dịch vụ Cuộc họp
  - Lấy thông tin nonce cuộc họp
- [ ] Tạo NologinMeetingService.java
  - Triển khai UserDetailsService
  - Xác minh nonce cuộc họp
  - Lấy người dùng theo ID văn phòng
- [ ] Triển khai đầy đủ NologinMeetingAuthenticationProvider
  - Triển khai phần TODO
  - Đối sánh mã thông báo văn bản thuần túy
  - Logic từ chối người dùng cá nhân
- [ ] Thêm cài đặt kênh gRPC vào application.yml
- [ ] Tạo bài kiểm tra đơn vị
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/grpc/GrpcMeetingAuthenticationClient.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/service/NologinMeetingService.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/provider/NologinMeetingAuthenticationProvider.java`

---

### 1.6 GrpcGroupAuthenticationClient + NologinAnswerSurveyService

**Ưu tiên**: 🔴 Cao
**Ước tính nỗ lực**: 5 giờ
**Phụ thuộc**: định nghĩa protobuf

```
Nội dung công việc:
- [ ] Tạo GrpcGroupAuthenticationClient.java
  - Kết nối gRPC với dịch vụ Nhóm
  - Lấy thông tin nonce khảo sát
- [ ] Tạo NologinAnswerSurveyService.java
  - Triển khai UserDetailsService
  - Xác minh tư cách thành viên nhóm
  - Lấy thông tin đăng nhập của người dùng
- [ ] Triển khai đầy đủ NologinAnswerSurveyAuthenticationProvider
  - Triển khai phần TODO
  - Đối sánh mã thông báo văn bản thuần túy
  - Kiểm tra tư cách thành viên nhóm
- [ ] Thêm cài đặt kênh gRPC vào application.yml
- [ ] Tạo bài kiểm tra đơn vị
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/grpc/GrpcGroupAuthenticationClient.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/service/NologinAnswerSurveyService.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/provider/NologinAnswerSurveyAuthenticationProvider.java`

---

### 1.7 NologinPersonalInvitationService

**Ưu tiên**: 🔴 Cao
**Ước tính nỗ lực**: 3 giờ
**Phụ thuộc**: GrpcRegistrationAuthClient

```
Nội dung công việc:
- [ ] Tạo NologinPersonalInvitationService.java
  - Triển khai UserDetailsService
  - Lấy thông tin đăng nhập lời mời cá nhân
  - Liên kết với dịch vụ Đăng ký
- [ ] Triển khai đầy đủ NologinPersonalInvitationAuthenticationProvider
  - Triển khai phần TODO
  - Xác minh mã thông báo nonce
- [ ] Tạo bài kiểm tra đơn vị
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/service/NologinPersonalInvitationService.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/provider/NologinPersonalInvitationAuthenticationProvider.java`

---

## Giai đoạn 2: Ưu tiên trung bình (tính đầy đủ của chức năng)

### 2.1 Nhóm máy khách gRPC để tích hợp Firebase

**Ưu tiên**: 🟡 Trung bình
**Ước tính nỗ lực**: 8 giờ
**Phụ thuộc**: định nghĩa protobuf

```
Nội dung công việc:
- [ ] Tạo GrpcGroupClient.java
  - Lấy danh sách ID nhóm mà người dùng thuộc về
- [ ] Tạo GrpcChatClient.java
  - Lấy danh sách ID phòng trò chuyện mà người dùng thuộc về
- [ ] Tạo GrpcPaymentClient.java
  - Lấy loại chức năng thanh toán của người dùng
- [ ] Mở rộng FirebaseAuthService
  - Thêm xác nhận quyền sở hữu groupIds
  - Thêm xác nhận quyền sở hữu chatRoomIds
  - Thêm xác nhận quyền sở hữu paymentFunctionType
- [ ] Thêm cài đặt kênh gRPC vào application.yml
- [ ] Tạo bài kiểm tra đơn vị
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/grpc/GrpcGroupClient.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/grpc/GrpcChatClient.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/grpc/GrpcPaymentClient.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/service/FirebaseAuthService.java`

---

### 2.2 ResourcePerClientTokenGranter

**Ưu tiên**: 🟡 Trung bình
**Ước tính nỗ lực**: 6 giờ
**Phụ thuộc**: cài đặt máy khách

```
Nội dung công việc:
- [ ] Tạo ResourcePerClientTokenGranter.java
  - Tạo động mã thông báo xác thực dựa trên cài đặt máy khách
  - Hỗ trợ nhiều loại xác thực
- [ ] Mở rộng thực thể Máy khách
  - Thêm trường tokenClass
  - Thêm trường division
- [ ] Tích hợp vào AuthorizationServerConfig
- [ ] Tạo bài kiểm tra đơn vị
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/security/ResourcePerClientTokenGranter.java`
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/domain/model/Client.java`

---

### 2.3 CustomPreAuthUserDetailsService

**Ưu tiên**: 🟡 Trung bình
**Ước tính nỗ lực**: 2 giờ
**Phụ thuộc**: GrpcRegistrationAuthClient

```
Nội dung công việc:
- [ ] Tạo CustomPreAuthUserDetailsService.java
  - Triển khai AuthenticationUserDetailsService
  - Làm mới chi tiết người dùng trong luồng mã thông báo được xác thực trước
- [ ] Tích hợp vào SecurityConfig
- [ ] Tạo bài kiểm tra đơn vị
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/service/CustomPreAuthUserDetailsService.java`

---

## Giai đoạn 3: Ưu tiên thấp (xem xét sự khác biệt về thiết kế)

### 3.1 Nhóm lớp AuthenticationToken theo sản phẩm

**Ưu tiên**: 🟢 Thấp
**Ước tính nỗ lực**: 8 giờ
**Ghi chú**: Cần xem xét sự khác biệt về thiết kế

```
Các điểm cần xem xét:
- [ ] Xác minh xem việc sử dụng chung UsernamePasswordAuthenticationToken hiện tại có vấn đề gì không
- [ ] Chỉ triển khai các lớp mã thông báo theo sản phẩm nếu cần
  - DrjoyPasswordAuthenticationToken
  - PrjoyPasswordAuthenticationToken
  - AdminPasswordAuthenticationToken
  - JoyPassAuthenticationToken
  - QuickPersonalAuthenticationToken
  - SchoolPasswordAuthenticationToken
```

**Tệp tham chiếu**:
- `service-oauth2-server/src/main/java/jp/drjoy/service/auth2/provider/*AuthenticationToken.java`

---

### 3.2 NologinChatAuthenticationProvider

**Ưu tiên**: 🟢 Thấp
**Ước tính nỗ lực**: 4 giờ
**Ghi chú**: Cần xác nhận tình hình sử dụng

```
Nội dung công việc:
- [ ] Xác nhận định nghĩa máy khách trong data.sql
- [ ] Điều tra tình hình sử dụng thực tế
- [ ] Chỉ triển khai nếu cần
  - NologinChatAuthenticationToken
  - NologinChatAuthenticationProvider
  - Các dịch vụ liên quan
```

---

### 3.3 HealthCheckController

**Ưu tiên**: 🟢 Thấp
**Ước tính nỗ lực**: 1 giờ
**Ghi chú**: Có thể thay thế bằng Spring Boot Actuator

```
Các điểm cần xem xét:
- [ ] Xác nhận xem có cần điểm cuối /health không
- [ ] Xác minh xem có thể thay thế bằng /actuator/health của Actuator không
- [ ] Chỉ triển khai HealthCheckController nếu cần
```

---

## Đề xuất lịch trình triển khai

### Tuần 1: Hoàn thành nền tảng xác thực
| Ngày | Nhiệm vụ | Nỗ lực |
|---|---|---|
| Ngày 1 | Tích hợp GoogleClient + reCAPTCHA | 4 giờ |
| Ngày 2 | RefreshTokenService | 3 giờ |
| Ngày 3 | ExceptionTranslator | 4 giờ |
| Ngày 4 | Triển khai đầy đủ QuickLoginService + Provider | 3 giờ |
| Ngày 5 | Kiểm tra và gỡ lỗi | 4 giờ |

### Tuần 2: Hoàn thành xác thực Nologin
| Ngày | Nhiệm vụ | Nỗ lực |
|---|---|---|
| Ngày 1-2 | GrpcMeetingAuthenticationClient + NologinMeetingService | 5 giờ |
| Ngày 2-3 | GrpcGroupAuthenticationClient + NologinAnswerSurveyService | 5 giờ |
| Ngày 4 | NologinPersonalInvitationService | 3 giờ |
| Ngày 5 | Kiểm tra và gỡ lỗi | 4 giờ |

### Tuần 3: Tích hợp Firebase và các nội dung khác
| Ngày | Nhiệm vụ | Nỗ lực |
|---|---|---|
| Ngày 1-2 | Nhóm máy khách gRPC để tích hợp Firebase | 8 giờ |
| Ngày 3 | ResourcePerClientTokenGranter | 6 giờ |
| Ngày 4 | CustomPreAuthUserDetailsService | 2 giờ |
| Ngày 5 | Kiểm tra tích hợp và xác nhận cuối cùng | 4 giờ |

---

## Sơ đồ phụ thuộc

```
                    ┌─────────────────────────────────┐
                    │   AuthorizationServerConfig     │
                    └─────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ ExceptionTrans│         │ TokenGranter    │         │ Filters         │
│ lator         │         │                 │         │                 │
└───────────────┘         └─────────────────┘         └─────────────────┘
        │                           │                           │
        │                           │                     ┌─────┴─────┐
        │                           │                     │           │
        ▼                           ▼                     ▼           ▼
┌───────────────┐         ┌─────────────────┐   ┌──────────┐ ┌──────────┐
│OTPRequired    │         │ Auth Providers  │   │Recaptcha │ │Maintenanc│
│Exception      │         │                 │   │Filter    │ │eFilter   │
└───────────────┘         └─────────────────┘   └──────────┘ └──────────┘
                                    │                 │
                    ┌───────────────┼─────────┐       │
                    │               │         │       ▼
                    ▼               ▼         ▼  ┌──────────┐
            ┌───────────┐   ┌───────────┐ ┌───┐ │GoogleClie│
            │UserDetails│   │Nologin    │ │SSO│ │nt        │
            │Services   │   │Services   │ │   │ └──────────┘
            └───────────┘   └───────────┘ └───┘
                    │               │
                    ▼               ▼
            ┌─────────────────────────────────┐
            │      gRPC Clients               │
            │  ┌─────────┐ ┌─────────┐        │
            │  │Registra │ │Meeting  │        │
            │  │tion     │ │Auth     │        │
            │  └─────────┘ └─────────┘        │
            │  ┌─────────┐ ┌─────────┐        │
            │  │Group    │ │Chat     │        │
            │  │Auth     │ │         │        │
            │  └─────────┘ └─────────┘        │
            │  ┌─────────┐ ┌─────────┐        │
            │  │Group    │ │Payment  │        │
            │  └─────────┘ └─────────┘        │
            └─────────────────────────────────┘
```

---

## Kế hoạch kiểm tra

### Kiểm tra đơn vị
Sử dụng JUnit 5 + Mockito cho mỗi thành phần:
- Máy khách gRPC: Sử dụng máy chủ giả
- Dịch vụ: Giả lập các phụ thuộc
- Nhà cung cấp: Kiểm tra toàn bộ luồng xác thực
- Bộ lọc: Sử dụng MockMvc

### Kiểm tra tích hợp
- Spring Boot Test + TestContainers (MongoDB)
- Kiểm tra tích hợp gRPC (InProcessServer)
- Kiểm tra E2E toàn bộ luồng OAuth2

### Kiểm tra hồi quy
Tham khảo các trường hợp kiểm tra hiện có của service-oauth2-server để đảm bảo độ bao phủ tương đương.

---

## Rủi ro và biện pháp đối phó

| Rủi ro | Tác động | Biện pháp đối phó |
|---|---|---|
| Không nhất quán trong định nghĩa protobuf | Không thể triển khai máy khách gRPC | Xác nhận cập nhật mới nhất của kho lưu trữ protobuf |
| Vấn đề tương thích luồng xác thực | Xác thực máy khách hiện tại không thành công | Di chuyển theo giai đoạn, phát hành canary |
| Suy giảm hiệu suất | Độ trễ phản hồi | Thực hiện kiểm tra tải, xem xét bộ nhớ đệm |
| Lỗ hổng bảo mật | Bỏ qua xác thực | Yêu cầu đánh giá bảo mật |

---

## Điều kiện hoàn thành

- [ ] Tất cả các nhiệm vụ ưu tiên cao đã hoàn thành
- [ ] Tất cả các bài kiểm tra đơn vị đều vượt qua
- [ ] Kiểm tra tích hợp vượt qua
- [ ] Luồng xác thực hoạt động tương đương với service-oauth2-server
- [ ] Phát hành canary thành công trong môi trường sản xuất
- [ ] Không có vấn đề gì trong thời gian giám sát 1 tuần

---

*Cập nhật lần cuối: Tháng 12 năm 2024*
