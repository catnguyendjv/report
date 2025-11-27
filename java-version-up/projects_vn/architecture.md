# OAuth2サーバー近代化 設計書 | Bản thiết kế Hiện đại hóa server OAuth2

## 1. 概要 | 1. Tổng quan

このドキュメントは、[OAuth2サーバー近代化 移行計画書](README.md)に基づき、新しい認証・認可基盤の技術的な設計を定義する。
主な目的は、現行の`service-framework`をマイクロサービス指向の複数のライブラリに分割し、Spring Boot 3 / JDK 17ベースの新しいOAuth2サーバー `service-security` を構築することである。
=====================================================
Tài liệu này, dựa trên 「Kế hoạch chuyển đổi hiện đại hóa server OAuth2」, định nghĩa thiết kế kỹ thuật của nền tảng xác thực và cấp quyền mới.
Mục tiêu chính là tách "service-framework" hiện tại thành nhiều thư viện hướng microservice, và xây dựng server OAuth2 `service-security` mới dựa trên Spring Boot 3 / JDK 17.

## 2. 全体アーキテクチャ | 2. Kiến trúc toàn thể

新しいアーキテクチャは、責務が明確に分離されたSpring Boot Starterライブラリ群と、それらを利用する新しいOAuth2サーバー `service-security` で構成される。
=================================================
Kiến trúc mới bao gồm một tập hợp các thư viện Spring Boot Starter với trách nhiệm được phân tách rõ ràng, và server OAuth2 `service-security` mới sẽ sử dụng những thư viện này.

### 2.1. コンポーネント分割 | 2.1. Phân tách component

モノリシックな `service-framework` は、以下のライブラリに分割される。

-   `lib-common-models`: サービス間で共有されるプレーンなデータモデル (DTO, POJO)。
-   `lib-common-utils`: 汎用的なユーティリティクラス群。
-   `lib-spring-boot-starter-grpc`: gRPCのサーバー/クライアントの自動設定、共通インターセプターを提供。
-   `lib-spring-boot-starter-security`: Spring Security 6ベースの認証・認可フィルター、JWT関連の機能を提供。
-   `lib-spring-boot-starter-mongodb`: MongoDBの共通設定、カスタムリポジトリ、ベースドキュメントクラスを提供。
-   `lib-spring-boot-starter-masterdata`: マスターデータ管理機能（ロール、権限等のDBベース設定管理）を提供。
-   `lib-spring-boot-starter-web`: 共通のWebフィルター、例外ハンドラー、シリアライザーを提供。
=======================================================
`service-framework` dạng monolithic sẽ được tách thành các thư viện sau:

- `lib-common-models`: Các Plain Data Model (DTO, POJO) được chia sẻ giữa các service.
- `lib-common-utils`: Tập hợp utility class dùng chung.
- `lib-spring-boot-starter-grpc`: Cung cấp cấu hình tự động cho server/client gRPC và các interceptor chung.
- `lib-spring-boot-starter-security`: Cung cấp filter xác thực và cấp quyền dựa trên Spring Security 6, cùng các chức năng liên quan đến JWT.
- `lib-spring-boot-starter-mongodb`: Cung cấp cấu hình chung cho MongoDB, custom repository, và base document class.
- `lib-spring-boot-starter-masterdata`: Cung cấp chức năng quản lý data master (role, quyền cài đặt/quản lý DB ..vv).
- `lib-spring-boot-starter-web`: Cung cấp các web filter chung, handler cho exception, và serializer.


### 2.2. 設定管理の近代化 | 2.2. Hiện đại hóa quản lý cài đặt

ハードコードされた`enum`を排除し、外部から動的に設定を管理する仕組みを導入する。

-   **ビジネスロジック関連の設定 (役割、権限など):**
    -   MongoDBをマスターデータとして利用する。
    -   各サービスは起動時にDBから設定を読み込み、キャッシュする。この機能は専用の `lib-spring-boot-starter-masterdata` に実装される。
-   **システム設定 (サービスタイプなど):**
    -   Spring Cloud Config Server を利用し、`.yml`ファイルで一元管理する。
===========================================================
Loại bỏ hard-code `enum`  và áp dụng cơ chế quản lý cấu hình dynamic từ bên ngoài.

- **Cấu hình liên quan đến business logic (role, permission, v.v.):**
    - Sử dụng MongoDB làm Master Data.
    - Các service, khi khởi động sẽ đọc cấu hình từ DB và cache lại. Chức năng này được triển khai trong `lib-spring-boot-starter-masterdata`.
- **Cấu hình hệ thống (service type, ...vv):**
    -Sử dụng Spring Cloud Config Server và quản lý tập trung bằng file `.yml`.

## 3. `service-security` 設計 | 3. Thiết kế `service-security`

`service-security` は、Spring Authorization Serverをベースとした新しいOAuth2サーバーである。
============================================
`service-security` là OAuth2 Server mới, dựa trên Spring Authorization Server.

### 3.1. 主要な依存関係 | 3.1. Mối quan hệ phụ thuộc chủ yếu

-   Spring Boot 3 / JDK 17
-   `spring-boot-starter-oauth2-authorization-server`
-   上記で定義した `lib-spring-boot-starter-*` 群
======================================================
- Spring Boot 3 / JDK 17
- `spring-boot-starter-oauth2-authorization-server`
- Tập hợp `lib-spring-boot-starter-*` đã định nghĩa ở trên

### 3.2. 認証メカニズム | 3.2. Cơ chế xác thực

既存の多様な認証方式をサポートするため、複数のカスタム認証プロバイダーを実装する。これらはSpring Authorization Serverの`AuthenticationProvider`として実装される。

-   `DrjoyPasswordAuthenticationProvider`: Dr.JOYユーザー向けID/PW認証
-   `PrjoyPasswordAuthenticationProvider`: PR.JOYユーザー向けID/PW認証
-   `AdminPasswordAuthenticationProvider`: 管理者向けID/PW認証
-   `QuickPersonalAuthenticationProvider`: 個人利用向けクイックログイン
-   `NologinMeetingAuthenticationProvider`: Web会議向け非ログイン認証
-   `NologinAnswerSurveyAuthenticationProvider`: アンケート回答向け非ログイン認証
-   `NologinPersonalInvitationAuthenticationProvider`: 個人招待向け非ログイン認証
-   `JoyPassAuthenticationProvider`: JoyPassユーザー向け認証
-   `SchoolPasswordAuthenticationProvider`: スクール機能向けID/PW認証
-   `SsoAuthenticationProvider`: SSO認証
=============================================
Để hỗ trợ các phương thức xác thực đa dạng hiện tại, sẽ triển khai nhiều custom authentication provider. Chúng được triển khai như `AuthenticationProvider` của Spring Authorization Server.

- `DrjoyPasswordAuthenticationProvider`: Xác thực ID/PW  cho người dùng Dr.JOY
- `PrjoyPasswordAuthenticationProvider`: Xác thực ID/PW  cho người dùng PR.JOY
- `AdminPasswordAuthenticationProvider`: Xác thực ID/PW  cho admin
- `QuickPersonalAuthenticationProvider`: Quick login cho cá nhân
- `NologinMeetingAuthenticationProvider`: Xác thực không login cho Web meeting
- `NologinAnswerSurveyAuthenticationProvider`: Xác thực không login cho trả lời survey
- `NologinPersonalInvitationAuthenticationProvider`: Xác thực không login cho việc mời cá nhân
- `JoyPassAuthenticationProvider`: Xác thực cho người dùng JoyPass
- `SchoolPasswordAuthenticationProvider`: Xác thực ID/PW  cho chức năng School
- `SsoAuthenticationProvider`: Xác thực SSO

### 3.3. トークン生成 | 3.3. Tạo token

-   **JWT署名:** `service-oauth2-server`と同様に、キーストア (`.jks`) を利用した署名方式を採用する。
-   **カスタムクレーム:** `OAuth2TokenCustomizer`を実装し、JWTペイロードにユーザーの所属情報や権限などのカスタムクレームを追加する。これらの権限情報は、マスターデータ管理の仕組みを通じてDBから取得される。
=====================================================
-   **JWT signature:** Giống như `service-oauth2-server`, sử dụng phương thức signature dựa trên keystore (`.jks`).

-   **Custom claim:** Triển khai `OAuth2TokenCustomizer` để thêm các custom claim vào JWT payload, ví dụ như thông tin affiliation của user và quyền hạn. Các thông tin quyền hạn này được lấy từ DB thông qua cơ chế quản lý Master Data.

### 3.4. セキュリティフィルター | 3.4. Security filter

既存のインターセプターは、Spring Securityの`Filter`として再実装され、`SecurityFilterChain`に組み込まれる。

-   `MaintenanceRequestFilter`: メンテナンスモードをチェックする。
-   `RecaptchaCheckerFilter`: reCAPTCHAを検証する。
-   `TwoFactorAuthenticationFilter`: 二要素認証を検証する。

これらのフィルターは、`lib-spring-boot-starter-web` または `lib-spring-boot-starter-security` に実装され、`service-security`で有効化される。
====================================================
Các interceptor hiện tại được triển khai lại như Filter của Spring Security và được tích hợp vào SecurityFilterChain.

- `MaintenanceRequestFilter`: Kiểm tra chế độ maintenance.
- `RecaptchaCheckerFilter`: Kiểm tra reCAPTCHA.
- `TwoFactorAuthenticationFilter`: Kiểm tra xác thực 2 yếu tố

Các filter này được triển khai trong `lib-spring-boot-starter-web` hoặc `lib-spring-boot-starter-security` và được bật trong `service-security`.
### 3.5. カスタムAPIエンドポイント | 3.5. Custom API endpoint

`service-oauth2-server`に存在した以下のカスタムAPIは、`service-security`に移行または再実装される。

-   `/v1/certificate/check`: 証明書情報API
-   `/fb/access/token`: FirebaseトークンAPI
-   gRPCサービス群
===================================================
Các custom API sau tồn tại trong `service-oauth2-server` sẽ được chuyển sang hoặc triển khai lại trong `service-security`:

-   `/v1/certificate/check`: Certificate information API
-   `/fb/access/token:` Firebase token API
-   Nhóm gRPC Service

## 4. データ設計 | 4. Thiết kế data

### 4.1. データベーススキーマ | 4.1. Database schema

`service-security`はMongoDBを使用する。主要なコレクションは以下の通り。

-   **users**: ユーザー情報
-   **clients**: OAuth2クライアント情報 (`RegisteredClient`)
-   **authorizations**: 認可情報
-   **master_data**: 役割、権限などのマスターデータ
===================================================
`service-security` sử dụng MongoDB. Các collection chính như sau:

-   **users**: Thông tin người dùng
-   **clients**: Thông tin OAuth2 client (`RegisteredClient`)
-   **authorizations**: Thông tin cấp quyền
-   **master_data**: Master Data như role, permission, v.v.

### 4.2. データ移行 | 4.2. Migrate data

-   **クライアント情報:** 旧`oauth_client_details`のデータを、Spring Authorization Serverの`RegisteredClient`フォーマットに変換する移行スクリプトを作成する。
-   **ユーザー情報:** 既存のユーザー情報を新しいスキーマに合わせて移行する。パスワードは必要に応じて再ハッシュ化する。
-   **リフレッシュトークン:** 既存のリフレッシュトークンは原則として無効化する。移行戦略については別途検討する。
====================================================
-   **Client information**: Tạo script migrate dữ liệu từ  `oauth_client_details` cũ sang định dạng `RegisteredClient` của Spring Authorization Server.
-   **User information**: migrate thông tin người dùng hiện tại sao cho tương thích với schema mới. Password sẽ được re-hash nếu cần.
-   **Refresh token**: Refresh token hiện tại về nguyên tắc sẽ bị vô hiệu hóa. Chiến lược migrate sẽ được xem xét riêng.

## 5. テスト・移行戦略 | Chiến lược migrate/Test

### 5.1. テスト計画 | Kế hoạch test

-   **単体テスト:** 各コンポーネント、特に認証プロバイダーやサービスロジックに対してJUnit/Mockitoを用いたテストを実装する。
-   **結合テスト:** 主要なグラントタイプ（Authorization Code, Client Credentials等）を網羅するHTTPレベルのテストを実装する。
-   **E2Eテスト:** テスト用クライアントを用意し、ステージング環境で認証フロー全体の動作を確認する。
==================================================
-   **Unit Test:** Triển khai kiểm thử bằng JUnit/Mockito cho từng component, đặc biệt là các Authentication Provider và business logic (dịch vụ xử lý nghiệp vụ).
-   **Integration Test:** Thực hiện các bài kiểm thử ở cấp độ HTTP, bao phủ các grant type chính (như Authorization Code, Client Credentials, ...vv).
-   **E2E Test:** Chuẩn bị client dùng cho test, và xác nhận hoạt động của toàn bộ luồng xác thực (authentication flow) trong môi trường staging.

### 5.2. 段階的移行 | 5.2. Migrate theo từng giai đoạn

`service-web-front`と`service-registration`を先行して移行させ、その知見を他のサービスへの展開に活かす。APIゲートウェイを利用したカナリアリリースにより、段階的にトラフィックを新システムへ移行する。
======================================================
`service-web-front` và `service-registration` sẽ được di chuyển trước, tận dụng những kiến thức của công việc này đó để triển khai sang các Service khác. Thông qua Canary release sử dụng API Gateway, sẽ chuyển dần Traffic sang System mới.

## 6. モニタリング | Monitoring

PrometheusとGrafanaを用いて、新サービスのリクエスト数、レイテンシ、エラーレートを監視するダッシュボードを構築する。また、集約ログシステムでエラーをリアルタイムに監視する。
=================================================
Sử dụng Prometheus và Grafana để xây dựng dashboard giám sát số lượng request, độ trễ (latency) và tỷ lệ lỗi (error rate) của dịch vụ mới.
Ngoài ra, Error sẽ được theo dõi realtime bằng Centralized Logging System