# OAuth2サーバー近代化 移行計画 - 詳細タスクリスト | Bản kế hoạch migrate và hiện đại hóa server OAuth2 - Danh sách task chi tiết

このドキュメントは、[OAuth2サーバー近代化 移行計画書](README.md)で概説された各フェーズの作業内容を、より具体的なタスクレベルに詳細化したものです。
Tài liệu này cụ thể hóa nội dung công việc của từng giai đoạn đã được mô tả trong Kế hoạch migrate và hiện đại hóa server OAuth2 (README.md) ở cấp độ task chi tiết hơn.

## 作業ブランチ | Nhánh làm việc

- **既存サービス**: `configuration`, `service-admin`, `service-registration`, `service-web-front`, `web-drjoy`
  - `feature/renew_framework` ブランチで作業します。
- **移行元リポジトリ**: `service-oauth2-server`, `service-framework`
  - `develop` ブランチの最新状態を常に参照します。
- **新規作成リポジトリ**: `lib-*`, `service-security`
  - `master` ブランチで作業します。
- **プロトコルバッファ定義**: `protobuf`
  - 各サービス間のgRPC通信で使用するプロトコル定義を管理します。
  - `feature/renew_framework` ブランチで作業します。
=====================================================================================================================
- Dịch vụ hiện tại: `configuration`, `service-admin`, `service-registration`, `service-web-front`, `web-drjoy`
    - Làm việc trên nhánh `feature/renew_framework`.
- Repo gốc của migration: `service-oauth2-server`, `service-framework`
    - Luôn tham chiếu trạng thái mới nhất của nhánh `develop`.
- Repo mới được tạo: `lib-*`, `service-security`
    - Làm việc trên nhánh `master`.
- Định nghĩa Protocol Buffers: `protobuf`
    - Quản lý các định nghĩa protocal dùng gRPC giữa các service.
    - Làm việc trên nhánh `feature/renew_framework`.

## フェーズ1: `service-framework` の再設計と分割 | Thiết kế lại và chia tách `service-framework`

### 1.1. 新規ライブラリプロジェクトの作成 | Tạo project thư viện mới

-   [x] `lib-spring-boot-starter-grpc` プロジェクトを作成する。
    -   [x] `pom.xml` を設定し、必要なgRPC関連ライブラリを追加する。
    -   [x] 基本的なAutoConfigurationクラスの雛形を作成する。
-   [x] `lib-spring-boot-starter-security` プロジェクトを作成する。
    -   [x] `pom.xml` を設定し、Spring Security 6関連ライブラリを追加する。
    -   [x] 基本的なAutoConfigurationクラスの雛形を作成する。
-   [x] `lib-spring-boot-starter-mongodb` プロジェクトを作成する。
    -   [x] `pom.xml` を設定し、Spring Data MongoDB関連ライブラリを追加する。
    -   [x] 基本的なAutoConfigurationクラスの雛形を作成する。
-   [x] `lib-spring-boot-starter-web` プロジェクトを作成する。
    -   [x] `pom.xml` を設定し、Spring Web関連ライブラリを追加する。
    -   [x] 基本的なAutoConfigurationクラスの雛形を作成する。
-   [x] `lib-common-models` プロジェクトを作成する。
    -   [x] `pom.xml` を設定する（Spring依存関係は含めない）。
-   [x] `lib-common-utils` プロジェクトを作成する。
    -   [x] `pom.xml` を設定する。
====================================================================================================================
-   [x] Tạo dự án `lib-spring-boot-starter-grpc`
    -   [x] Cấu hình `pom.xml`, thêm thư viện liên quan gRPC cần thiết.
    -   [x] Tạo template cho class AutoConfiguration cơ bản.
-   [x] Tạo dự án `lib-spring-boot-starter-security`
    -   [x] Cấu hình `pom.xml`, thêm các thư viện Spring Security 6.
    -   [x] Tạo template cho class AutoConfiguration cơ bản.
-   [x] Tạo dự án `lib-spring-boot-starter-mongodb`
    -   [x] Cấu hình `pom.xml`, thêm các thư viện Spring Data MongoDB.
    -   [x] Tạo template cho class AutoConfiguration cơ bản.
-   [x] Tạo dự án `lib-spring-boot-starter-web`
    -   [x] Cấu hình `pom.xml`, thêm các thư viện Spring Web.
    -   [x] Tạo template cho class AutoConfiguration cơ bản.
-   [x] Tạo dự án `lib-common-models`
    -   [x] Cấu hình `pom.xml` (không bao gồm phụ thuộc Spring).
-   [x] Tạo dự án `lib-common-utils`
    -   [x] Cấu hình `pom.xml`.


### 1.2. `service-framework` からの機能移管とテスト | Migrate chức năng từ  `service-framework` và test 

-   [x] **`lib-common-models`**
    -   [x] `service-framework` 及び各サービスで共通利用されているDTOやPOJOを特定し、新ライブラリに集約する。
    -   [x] 依存関係がプレーンなJava/Lombokのみであることを確認する。
-   [x] **`lib-common-utils`**
    -   [x] `service-framework` から汎用的なユーティリティクラス（文字列操作、日付操作など）を移植する。
    -   [x] `CaseConvertUtils` の単体テストを作成する。
    -   [x] `Dates` の単体テストを作成する。
    -   [x] `KanaUtils` の単体テストを作成する。
-   [x] **`lib-spring-boot-starter-grpc`**
    -   [x] `service-framework` からgRPC関連のコード（サーバー/クライアント設定、インターセプター等）を特定し、新ライブラリに移植する。
    -   [x] Spring Boot 3の仕様に合わせてコードを修正する（例: `javax` -> `jakarta`）。
    -   [x] `ErrorHandlingInterceptor` の単体テストを作成する。
    -   [x] `GrpcAuthClientInterceptor` の単体テストを作成する。
    -   [x] `GrpcAuthServerInterceptor` の単体テストを作成する。
-   [x] **`lib-spring-boot-starter-security`**
    -   [x] `service-framework` のセキュリティ関連コードを参考に、Spring Security 6ベースの新しい設定クラスを実装する。
    -   [x] JWTの検証、ユーザー情報の解決など、既存の認証ロジックを再実装する。
    -   [x] `BCryptService` の単体テストを作成する。
    -   [x] `ShaPasswordService` の単体テストを作成する。
    -   [x] `UserAuthenticationConverter` の単体テストを作成する。
-   [x] **`lib-spring-boot-starter-mongodb`**
    -   [x] `service-framework` からMongoDBの共通設定、カスタムリポジトリ、ベースドキュメントクラスを移植する。
    -   [x] Spring Boot 3の仕様に合わせてコードを修正する。
    -   [x] 責務の分離: マスターデータ関連機能を `lib-spring-boot-starter-masterdata` に分離。
    -   [x] 汎用MongoDB機能（監査機能など）のみを提供するように修正。
    -   [ ] `RoleMasterService` の単体テストを作成する（→ masterdataライブラリに移行）。
-   [x] **`lib-spring-boot-starter-masterdata`** ✨ *新規作成*
    -   [x] `lib-spring-boot-starter-mongodb` からマスターデータ関連機能を分離。
    -   [x] `RoleRepository`, `StaffAuthorityRepository`, `MasterDataRepository` を管理。
    -   [x] `RoleMasterService`, `StaffAuthorityMasterService`, `MasterDataCacheService` を提供。
    -   [x] ハードコードされたenumをDBベースのマスターデータで置き換える機能を集約。
    -   [ ] 各サービスでの個別依存関係設定と動作確認。
-   [x] **`lib-spring-boot-starter-web`**
    -   [x] `service-framework` から共通のWebフィルター、例外ハンドラー、シリアライザー等を移植する。
    -   [x] Spring Boot 3の仕様に合わせてコードを修正する。
    -   [x] `RequestHandlerInterceptor` の単体テストを作成する。
==============================================================================================================================================
-   [x] `lib-common-models`
     -   [x] Xác định các DTO và POJO được sử dụng chung trong `service-framework` và các service , sau đó tổng hợp chúng vào thư viện mới.
     -   [x] Xác nhận mối quan hệ phụ thuộc chỉ là Java/Lombok thuần túy (plain Java/Lombok).
-   [x] `lib-common-utils`
    -   [x] Chuyển giao các utility classes chung (thao tác String, thao tác date, v.v.) từ `service-framework`.
    -   [x] Tạo unit test cho `CaseConvertUtils`.
    -   [x] Tạo unit test cho `Dates`.
    -   [x] Tạo unit test cho `KanaUtils`.
-   [x] `lib-spring-boot-starter-grpc`
    -   [x] Xác định các mã code liên quan đến gRPC (cấu hình server/máy chủ, client/máy khách, interceptor v.v.) từ `service-framework` và chuyển giao chúng sang thư viện mới.
    -   [x] Sửa đổi mã code để tuân thủ spec của Spring Boot 3 (ví dụ: javax -> jakarta).
    -   [x] Tạo unit test cho `ErrorHandlingInterceptor`.
    -   [x] Tạo unit test cho `GrpcAuthClientInterceptor`.
    -   [x] Tạo unit test cho `GrpcAuthServerInterceptor`.
-   [x] `lib-spring-boot-starter-security`
    -   [x] Triển khai các class cấu hình mới dựa trên Spring Security 6, tham khảo code liên quan đến bảo mật của `service-framework`.
    -   [x] Tái triển khai logic xác thực hiện có như xác thực JWT và giải quyết thông tin người dùng ..vv
    -   [x] Tạo unit test cho `BCryptService`.
    -   [x] Tạo unit test cho `ShaPasswordService`.
    -   [x] Tạo unit test cho `UserAuthenticationConverter`.
-   [x] `lib-spring-boot-starter-mongodb`
    -   [x] Chuyển giao cấu hình chung, custom repository, và class tài liệu cơ sở cho MongoDB từ `service-framework`.
    -   [x] Sửa đổi mã code để tuân thủ spec của Spring Boot 3.
    -   [x] Phân tách trách nhiệm: Tách chức năng liên quan đến master data sang `lib-spring-boot-starter-masterdata`.
    -   [x] Sửa đổi để chỉ cung cấp các chức năng MongoDB tổng quát (chức năng kiểm toán/audit, v.v.).
    -   [ ] Tạo unit test cho `RoleMasterService` (→ chuyển giao sang thư viện masterdata).
-   [x] `lib-spring-boot-starter-masterdata` ✨ TẠO MỚI
    -   [x] Tách chức năng liên quan đến master data từ `lib-spring-boot-starter-mongodb`.
    -   [x] Quản lý `RoleRepository`, `StaffAuthorityRepository`, và `MasterDataRepository`.
    -   [x] Cung cấp `RoleMasterService`, `StaffAuthorityMasterService`, và `MasterDataCacheService.`
    -   [x] Gộp chức năng thay thế từ enum được hardcode sang master data dựa trên DB.
    -   [ ] Xác nhận cấu hình mối quan hệ phụ thuộc riêng lẻ và kiểm tra hoạt động tại mỗi service.
-   [x] `lib-spring-boot-starter-web`
    -   [x] Chuyển giao Web filter chung, exception handler, serializer, v.v. từ `service-framework`.
    -   [x] Sửa đổi mã code để tuân thủ spec của Spring Boot 3.
    -   [x] Tạo unit test cho `RequestHandlerInterceptor`.


### 1.3. ハードコードされたenumの排除 | Loại bỏ enum bị hardcode

-   [x] **ビジネスロジック関連のenum** | Enum liên quan đến Logic nghiệp vụ
    -   [x] マスターデータ管理用のMongoDBコレクションスキーマを設計する (`roles`, `authorities`, `products`など)。
    -   [x] `lib-spring-boot-starter-mongodb` または `lib-spring-boot-starter-web` に、起動時にDBからマスターデータを読み込み、キャッシュするサービス（例: `MasterDataCacheService`）を実装する。
    -   [x] キャッシュしたデータをDI経由で利用するためのインターフェースを定義する。
    -   [ ] 既存のenumを参照している箇所を特定し、新サービスを利用するように修正するための影響範囲調査を行う。
==============================================================================================================================================================================================
-   [x] Thiết kế schema collection MongoDB cho quản lý master data (`roles`, `authorities`, `products`, v.v.).
    -   [x] Triển khai một service (ví dụ: `MasterDataCacheService`) trong `lib-spring-boot-starter-mongodb` hoặc `lib-spring-boot-starter-web` để đọc dữ liệu chính từ DB và cache khi khởi động.
    -   [x] Định nghĩa interface để sử dụng data đã cache thông qua DI.
    -   [ ] Điều tra phạm vi ảnh hưởng để xác định các vị trí tham chiếu đến enum hiện có và sửa đổi chúng để sử dụng service mới.


-   [x] **システム設定関連のenum** | Enum liên quan đến Cấu hình hệ thống
    -   [x] `configuration`リポジトリに、`ServiceType` や `HealthyProbe` などの設定を管理するための `.yml` ファイルを追加・更新する。
    -   [ ] 各サービスで `@Value` や `@ConfigurationProperties` を使って設定値を取得するように、既存コードを修正するための影響範囲調査を行う。
==============================================================================================================================================================================================
    -   [x] Thêm/cập nhật file .yml trong repo của` configuration` để quản lý cấu hình như `ServiceType` và `HealthyProbe`.
    -   [ ] Điều tra phạm vi ảnh hưởng để sửa đổi  code hiện có trong mỗi service để lấy giá trị cấu hình bằng cách sử dụng `@Value` hoặc `@ConfigurationProperties`

### 1.4. マスターデータの初期化とデータ投入 | Khởi tạo master data và Nhập data

-   [x] **マスターデータスキーマの設計** | Thiết kế Schema Dữ liệu Chính
    -   [x] `roles`、`authorities`、`master_data`コレクションの構造定義完了
    -   [x] `lib-spring-boot-starter-masterdata`でのDocument/Repository実装済み
==================================================================================================
    -   [x] Định nghĩa cấu tạo của các collection `roles`, `authorities`, và `master_data` đã hoàn thành.
    -   [x] Triển khai Document/Repository trong `lib-spring-boot-starter-masterdata` đã hoàn thành.

-   [ ] **初期データの準備とデータ投入ツール開発** | Chuẩn bị data khởi tạo và phát triển tool nhập data
    -   [ ] 初期データJSONファイルの作成（`roles.json`、`authorities.json`、`master-data.json`）
    -   [ ] `DataInitializationService` - JSON読み込みとDB投入ロジック実装
    -   [ ] `MasterDataInitializer` - `CommandLineRunner`による起動時初期化実装
    -   [ ] プロファイル別データ管理（dev/test/prod環境対応）
==================================================================================================
    -   [ ] Tạo file JSON dữ liệu khởi tạo (`roles.json`, `authorities.json`, `master-data.json`)
    -   [ ] `DataInitializationService` - Triển khai logic đọc JSON và nhập vào DB
    -   [ ] `MasterDataInitializer` - Triển khai khởi tạo khi khởi động bằng `CommandLineRunner`
    -   [ ] Quản lý dữ liệu theo profile (hỗ trợ môi trường dev/test/prod)

-   [ ] **データ投入手順の文書化** | Tài liệu hóa quy trình nhập dữ liệu
    -   [ ] MongoDB直接投入コマンド例の提供
    -   [ ] 開発環境でのテストデータ準備手順書作成
    -   [ ] 本番環境でのデータ更新・運用手順書作成
    -   [ ] データバックアップ・復旧手順の策定
==================================================================================================
    -   [ ] Cung cấp ví dụ command nhập trực tiếp vào MongoDB
    -   [ ] Tạo sổ tay quy trình chuẩn bị dữ liệu test cho môi trường phát triển
    -   [ ] Tạo sổ tay quy trình vận hành/update dữ liệu cho môi trường master
    -   [ ] Hoạch định quy trình backup/phục hồi dữ liệu

-   [ ] **運用支援機能（オプション）** | Chức năng Hỗ trợ Vận hành (Tùy chọn)
    -   [ ] マスターデータCRUD操作用REST API実装
    -   [ ] キャッシュリフレッシュAPI実装
    -   [ ] データ整合性チェック機能実装
==================================================================================================
    -   [ ] Triển khai REST API cho thao tác CRUD master data
    -   [ ] Triển khai API refresh cache
    -   [ ] Triển khai chức năng kiểm tra tính toàn vẹn dữ liệu

#### データ投入方法 | Phương pháp Nhập Dữ liệu

**1. 開発環境での初期データ投入** | Nhập Dữ liệu Khởi tạo trong Môi trường Phát triển
```bash
# MongoDB直接投入（推奨） | Nhập Trực tiếp MongoDB (Được khuyến nghị)
mongosh your_database
db.roles.insertMany([
  {"name": "ADMIN", "description": "管理者"},  | Quản trị viên
  {"name": "USER", "description": "一般ユーザー"}, | Người dùng thông thường
  {"name": "DOCTOR", "description": "医師"} | Bác sĩ
])
```

**2. アプリケーション起動時の自動初期化** | Khởi tạo tự động khi khởi động ứng dụng
- `CommandLineRunner`による初期データ自動投入
- 環境別プロファイル対応（`application-{profile}.yml`）
- 既存データの重複チェック機能
====================================================================================================
- Tự động nhập dữ liệu khởi tạo bằng `CommandLineRunner`
- Hỗ trợ profile theo môi trường (`application-{profile}.yml`)
- Chức năng kiểm tra trùng lặp dữ liệu hiện có

**3. 本番環境でのデータ管理** | Quản lý dữ liệu trong môi trường master
- 管理画面経由での更新（推奨）
- MongoDB直接操作（緊急時のみ）
- 変更履歴の記録とバックアップ必須
====================================================================================================
- Cập nhật thông qua màn hình quản lý (Được khuyến nghị)
- Thao tác trực tiếp MongoDB (Chỉ trong trường hợp khẩn cấp)
- Ghi lại lịch sử thay đổi và bắt buộc backup

## lib-*プロジェクトのビルドと利用方法 | Build và Cách sử dụng Dự án lib-*

### ライブラリアーキテクチャ | Kiến trúc Thư viện

新しいフレームワークは以下の6つのライブラリで構成されています：
Framework mới bao gồm 6 thư viện sau:

#### 基盤ライブラリ | Thư viện Nền tảng
- **`lib-common-utils`** - 汎用ユーティリティクラス（文字列操作、日付操作等）
- **`lib-common-models`** - 共通DTOとPOJOクラス
=====================================================================================================
- `lib-common-utils` - các utility class chung (thao tác String, thao tác date, v.v.)
- `lib-common-models` - Các class DTO và POJO chung

#### Spring Boot Starterライブラリ   | Thư viện Spring Boot Starter
- **`lib-spring-boot-starter-grpc`** - gRPCクライアント/サーバー機能
- **`lib-spring-boot-starter-security`** - Spring Security 6設定とフィルター
- **`lib-spring-boot-starter-mongodb`** - MongoDB接続とRepository基盤
- **`lib-spring-boot-starter-web`** - Web関連機能とコントローラー基盤
======================================================================================================
- `lib-spring-boot-starter-grpc` - Chức năng gRPC client/server
- `lib-spring-boot-starter-security` - Cấu hình Spring Security 6 và filter
- `lib-spring-boot-starter-mongodb` - Kết nối MongoDB và nền tảng Repository
- `lib-spring-boot-starter-web` - Các chức năng liên quan đến Web và nền tảng Controller

#### 特殊ライブラリ | Thư viện Đặc biệt
- **`lib-spring-boot-starter-masterdata`** - マスターデータ管理機能（service-registrationから分離）
- `lib-spring-boot-starter-masterdata` - Chức năng quản lý master data (tách ra từ service-registration)

### ビルド方法 | Phương pháp Build

#### ローカル開発環境でのビルド | Build trong Môi trường Phát triển Local


**個別ライブラリのビルド:** | Build Thư viện Riêng lẻ:
```bash
# 各lib-*ディレクトリで実行 | Thực thi trong mỗi thư mục lib-*
cd work/lib-common-utils
mvn clean install

cd work/lib-common-models  
mvn clean install

# 依存順序でビルド（重要） | Build theo thứ tự phụ thuộc (Quan trọng)
cd work/lib-spring-boot-starter-mongodb
mvn clean install

cd work/lib-spring-boot-starter-security
mvn clean install

cd work/lib-spring-boot-starter-grpc
mvn clean install

cd work/lib-spring-boot-starter-web
mvn clean install
```

#### CI/CD環境でのビルド（推奨） | Build trong Môi trường CI/CD (Được khuyến nghị)

各lib-*リポジトリに個別の`.drone.yml`を設定し、自動ビルド・デプロイを行います：
Config `.drone.yml` riêng lẻ cho mỗi repository lib-* để thực hiện build và deploy tự động:

**CI/CD環境でのビルド例:** | Ví dụ Build trong Môi trường CI/CD:
各lib-*リポジトリに個別のCI/CD設定を行い、自動ビルド・デプロイを実装します。
Thực hiện cấu hình CI/CD riêng lẻ cho mỗi repository lib-* và triển khai build và deploy tự động.

### 利用方法 | Cách sử dụng

#### Mavenプロジェクトでの利用 | Sử dụng trong Dự án Maven

**pom.xmlに依存関係を追加:** | Thêm mối quan hệ phụ thuộc vào pom.xml:
```xml
<dependencies>
  <!-- 基盤ライブラリ --> | Thư viện nền tảng
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

#### アプリケーションコードでの利用 | Sử dụng trong code của App

**基本的な使用例:** | Ví dụ Sử dụng Cơ bản:
```java
// AutoConfigurationにより自動設定 | Tự động cấu hình bằng AutoConfiguration
@SpringBootApplication
public class MyApplication {
    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}

// ユーティリティクラスの使用 | Sử dụng utility class
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

### バージョン管理 | Quản lý Version

#### ブランチ別バージョニング | Versioning theo Branch
- **develop**: `0.1.DEVELOP-SNAPSHOT`
- **master**: `0.1.MASTER-SNAPSHOT`  
- **feature/xxx**: `0.1.FEATURE/XXX-SNAPSHOT`

#### 依存関係解決 | Giải quyết mối quan hệ phụ thuộc
1. **プライベートMavenリポジトリ**からの自動取得
2. **mvn-settings**シークレットによる認証
3. **Spring Boot repackaging**で最終JARに統合
================================================================================
1. Tự động lấy từ Private Maven Repository 
2. Xác thực bằng secret mvn-settings
3. Tích hợp vào JAR cuối cùng bằng Spring Boot repackaging


### 品質保証 | Đảm bảo Chất lượng

#### 自動テスト | Kiểm thử Tự động
- 単体テスト実行（`mvn test`）
- SonarQube静的解析
- 依存関係脆弱性チェック
================================================================================
- Thực thi unit test (`mvn test`)
- Phân tích tĩnh SonarQube
- Kiểm tra lỗ hổng trong mối quan hệ phụ thuộc

#### 継続的インテグレーション | Tích hợp liên tục (Continuous Integration)
- コード変更時の自動ビルド
- プルリクエスト時の品質チェック
- マスターブランチへの自動デプロイ
================================================================================
- Tự động build khi thay đổi code
- Kiểm tra chất lượng khi Pull Request
- Tự động deploy lên branch master


## フェーズ2: `service-security` の開発 | Phát triển `service-security`

### 2.1. プロジェクトのセットアップ | Setup của dự án

-   [x] `service-security` という名前で、Spring Boot 3 / JDK 17 ベースのMavenプロジェクトを新規作成する。
-   [x] `pom.xml` に、フェーズ1で作成した `lib-spring-boot-starter-*` ライブラリ群と、`spring-boot-starter-oauth2-authorization-server` を依存関係として追加する。
-   [x] `application.yml` の基本設定（サーバーポート、DB接続情報など）を行う。
-   [x] ローカルリポジトリを初期化し、リモートリポジトリにプッシュする。
===============================================================================================================================================================
-   [x] Tạo dự án Maven dựa trên Spring Boot 3 / JDK 17 với tên là `service-security`.
-   [x] Thêm nhóm thư viện lib-spring-boot-starter-* được tạo ở Phase 1 và spring-boot-starter-oauth2-authorization-server làm mối quan hệ phụ thuộc trong pom.xml.
-   [x] Thực hiện cấu hình cơ bản của application.yml (port server, thông tin kết nối DB, v.v.).
-   [x] Khởi tạo local repository và push lên remote repository.

### 2.2. 認証・認可ロジックの実装 | Triển khai Logic Xác thực/phân quyền

-   [x] `AuthorizationServerConfig` を作成し、基本的なエンドポイント (`/oauth2/authorize`, `/oauth2/token` など) を設定する。
-   [x] `UserDetailsService` を実装し、ユーザー情報をDBから取得するようにする。
-   [x] `RegisteredClientRepository` を実装し、クライアント情報をDBまたは設定ファイルから読み込むようにする。
-   [x] `SecurityConfig` を作成し、セキュリティ設定を構成する。
-   [x] カスタム認証ハンドラー (`CustomAuthenticationSuccessHandler`, `CustomAuthenticationFailureHandler`) を実装する。
-   [x] ログイン試行制限サービス (`LoginAttemptService`) を実装する。
-   [x] gRPC認証クライアント (`GrpcRegistrationAuthClient`) を実装する。
-   [x] **カスタム認証プロバイダーの実装**: `service-oauth2-server`に存在する以下のカスタム認証ロジックを、Spring Authorization Serverの`AuthenticationProvider`として再実装する。
    -   [x] `DrjoyPasswordAuthenticationProvider` (Dr.JOYユーザー向けID/PW認証)
    -   [x] `PrjoyPasswordAuthenticationProvider` (PR.JOYユーザー向けID/PW認証)
    -   [x] `AdminPasswordAuthenticationProvider` (管理者向けID/PW認証)
    -   [x] `QuickPersonalAuthenticationProvider` (個人利用向けクイックログイン)
    -   [x] `NologinMeetingAuthenticationProvider` (Web会議向け非ログイン認証)
    -   [x] `NologinAnswerSurveyAuthenticationProvider` (アンケート回答向け非ログイン認証)
    -   [x] `NologinPersonalInvitationAuthenticationProvider` (個人招待向け非ログイン認証)
    -   [x] `JoyPassAuthenticationProvider` (JoyPassユーザー向け認証)
    -   [x] `SchoolPasswordAuthenticationProvider` (スクール機能向けID/PW認証)
    -   [x] `SsoAuthenticationProvider` (SSO認証)
-   [x] **JWT署名方式の変更**: 現在の動的キー生成方式から、`service-oauth2-server`と同様のキーストア (`.jks`) を利用する方式に変更する。
    -   [x] キーストアファイル（oauth2.jks）の配置
    -   [x] application.ymlの設定追加
    -   [x] AuthorizationServerConfigの改善（エラーハンドリング、ログ出力）
    -   [x] ClassPathResourceフォールバック実装
-   [x] **トークンカスタマイザーの実装**: `service-oauth2-server`の`JwtTokenEnhancer`を参考に、`OAuth2TokenCustomizer`を実装してJWTに独自のクレーム（例: ユーザーの所属情報、権限）を追加する。
    -   [x] isSaveLoginメソッドの完全実装
    -   [x] ユーザー認証情報からのクレーム抽出ロジック追加
    -   [x] マスターデータサービスとの統合
    -   [x] 既存のUserAuthenticationConverterで定義された全フィールドをサポート
    -   [x] 単体テストの基盤作成
-   [x] フェーズ1で実装したマスターデータ管理の仕組みを利用して、ロールや権限の情報をトークンに含めるようにする。
-   [x] **カスタムフィルターの実装**: `service-oauth2-server`の以下のインターセプターを、Spring Securityの`Filter`として再実装し、`SecurityFilterChain`に組み込む。
    -   [x] `MaintenanceRequestInterceptor` → `MaintenanceRequestFilter` (メンテナンスモードのチェック)
    -   [x] `RecaptchaCheckerInterceptor` → `RecaptchaCheckerFilter` (reCAPTCHAの検証)
    -   [x] `TwoFactorAuthenticationInterceptor` → `TwoFactorAuthenticationFilter` (二要素認証の検証)
    -   [x] **実装完了**: これらのフィルターは `lib-spring-boot-starter-security` に移植され、AutoConfigurationにより `service-security` で自動的に有効化される。
    -   [x] **単体テスト作成**: 各フィルターの包括的なテストケースを作成し、動作確認済み。
==========================================================================================================================================
-   [x] Tạo `AuthorizationServerConfig` và cấu hình các endpoint cơ bản (`/oauth2/authorize`, `/oauth2/token`, v.v.).
-   [x] Triển khai `UserDetailsService` để lấy thông tin người dùng từ DB.
-   [x] Triển khai `RegisteredClientRepository` để đọc thông tin client từ DB hoặc file cấu hình.
-   [x] Tạo `SecurityConfig` và cấu hình bảo mật.
-   [x] Triển khai handler xác thực tùy chọn (`CustomAuthenticationSuccessHandler`, `CustomAuthenticationFailureHandler`).
-   [x] Triển khai service giới hạn số lần thử đăng nhập (`LoginAttemptService`).
-   [x] Triển khai gRPC authentication client (`GrpcRegistrationAuthClient`).
-   [x] Triển khai Custom Authentication Provider: Tái triển khai các logic xác thực tùy chỉnh có trong `service-oauth2-server` sau đây  dưới dạng Spring Authorization Server's `AuthenticationProvider`.
    -   [x] DrjoyPasswordAuthenticationProvider (Xác thực ID/PW cho người dùng Dr.JOY)
    -   [x] PrjoyPasswordAuthenticationProvider (Xác thực ID/PW cho người dùng PR.JOY)
    -   [x] AdminPasswordAuthenticationProvider (Xác thực ID/PW cho quản trị viên)
    -   [x] QuickPersonalAuthenticationProvider (Quick login cho người dùng cá nhân)
    -   [x] NologinMeetingAuthenticationProvider (Xác thực không đăng nhập cho Web Meeting)
    -   [x] NologinAnswerSurveyAuthenticationProvider (Xác thực không đăng nhập cho trả lời khảo sát)
    -   [x] NologinPersonalInvitationAuthenticationProvider (Xác thực không đăng nhập cho lời mời cá nhân)
    -   [x] JoyPassAuthenticationProvider (Xác thực cho người dùng JoyPass)
    -   [x] SchoolPasswordAuthenticationProvider (Xác thực ID/PW cho chức năng Trường học)
    -   [x] SsoAuthenticationProvider (Xác thực SSO)
-   [x] Thay đổi Phương thức Signature JWT: Thay đổi từ phương thức tạo key động hiện tại sang phương thức sử dụng keystore (`.jks`) tương tự `service-oauth2-server`.
    -   [x] Đặt file keystore (oauth2.jks)
    -   [x] Thêm cấu hình application.yml
    -   [x] Cải thiện AuthorizationServerConfig (error handling, log output)
    -   [x] Triển khai fallback ClassPathResource
-   [x] Triển khai Token Customizer: Triển khai `OAuth2TokenCustomizer`, tham khảo `JwtTokenEnhancer` của `service-oauth2-server`, để thêm claim tùy chỉnh (ví dụ: thông tin đơn vị người dùng, quyền hạn) vào JWT.
    -   [x] Triển khai đầy đủ method isSaveLogin
    -   [x] Thêm logic trích xuất claim từ thông tin xác thực người dùng
    -   [x] Tích hợp với master data service
    -   [x] Hỗ trợ tất cả các trường được định nghĩa trong UserAuthenticationConverter hiện có
    -   [x] Tạo nền tảng unit test
-   [x] Sử dụng cơ chế quản lý master data đã triển khai ở Phase 1, để bao gồm thông tin role và authority trong token.
-   [x] Triển khai Custom Filter: Tái triển khai interceptor sau đây của `service-oauth2-server` dưới dạng `Filter` của Spring Security và tích hợp vào `SecurityFilterChain`.
    -   [x] MaintenanceRequestInterceptor → MaintenanceRequestFilter (Kiểm tra maintainace mode)
    -   [x] RecaptchaCheckerInterceptor → RecaptchaCheckerFilter (kiểm chứng reCAPTCHA)
    -   [x] TwoFactorAuthenticationInterceptor → TwoFactorAuthenticationFilter (kiểm chứng xác thực hai yếu tố)
    -   [x] Triển khai Hoàn tất: Các filter này được chuyển giao sang `lib-spring-boot-starter-security` và tự động được kích hoạt trong `service-security` bằng AutoConfiguration.
    -   [x] Tạo Unit Test: Test cases toàn diện cho mỗi filter và hoạt động đã được xác nhận.


### 2.2.1. カスタムAPIエンドポイントの移行 | Chuyển giao Endpoint custom API 

-   [x] **証明書情報APIの移行**: `service-oauth2-server`の`/v1/certificate/check`に相当する機能を`service-security`に実装するか、責務がより適切な別サービスへの移管を検討・実施する。
    -   [x] **CertificateInfoResponse実装**: `{"approved": boolean}` JSON形式のレスポンスモデル
    -   [x] **GrpcRegistrationAuthClient拡張**: getUserLoginInfoResponse メソッド追加とUserLoginInfo POJOモデル
    -   [x] **CertificateService実装**: 証明書検証ロジック（オフィス承認状態・FP21権限・クライアント証明書検証）
    -   [x] **CertificateController実装**: GET /v1/certificate/check エンドポイント（入力検証・エラーハンドリング）
    -   [x] **TwoFactorAuthenticationFilter連携**: ThreadLocalとヘッダー両方からの証明書抽出対応
    -   [x] **単体・結合テスト**: Web層とサービス層のテスト作成・コンパイル確認済み
-   [x] **FirebaseトークンAPIの移行**: `service-oauth2-server`の`/fb/access/token`に相当する機能を`service-security`に再実装する。
    -   [x] **Firebase Admin SDK統合**: Firebase Admin SDK依存関係追加とFirebaseConfig設定クラス実装
    -   [x] **FirebaseAuthService実装**: SecurityContextHolderからユーザー情報取得、カスタムクレーム生成、RxJava3統合
    -   [x] **FirebaseAuthController実装**: GET/POST /fb/access/token エンドポイント（DeferredResult非同期処理）
    -   [x] **認証コンテキスト統合**: JWT認証情報からFirebaseカスタムトークン生成、PaymentFunctionType対応
    -   [x] **単体・結合テスト**: FirebaseAuthServiceのMockito単体テストと統合テスト作成完了
-   [ ] `NologinChatAuthenticationProvider` (チャット向け非ログイン認証、**要調査**: `data.sql`にクライアント定義はあるがProvider実装が見当たらないため、利用状況を確認の上、必要であれば移行する)
-   [x] **gRPCサービスの移行**: `service-oauth2-server`が公開している以下のgRPCサービスについて、`service-security`への移行要否を判断し、必要なものを実装する。
    -   [x] **GrpcActuatorServer実装**: protobuf依存関係有効化、Spring Cloud Context Refresher統合、設定リフレッシュ・再起動・シャットダウン機能
    -   [x] **GrpcHealthServer実装**: 標準gRPC Health Check Protocol実装、Spring Boot Actuatorヘルスインジケーター統合
    -   [x] **Spring設定統合**: GrpcConfig設定クラス、ContextRefresher・HealthIndicator bean設定、application.yml gRPC設定追加
    -   [x] **セキュリティ強化**: 本番環境での認証・認可考慮、エラーハンドリング改善、適切なログ出力
    -   [x] **包括的テスト**: GrpcActuatorServer・GrpcHealthServer・GrpcConfigの単体テスト、gRPC統合テスト作成完了
==========================================================================================================================================
-   [x] Chuyển giao API Certificate: Triển khai chức năng tương ứng với `/v1/certificate/check` của `service-oauth2-server` vào `service-security`, hoặc cân nhắc và thực hiện chuyển giao sang service khác có trách nhiệm phù hợp hơn.
    -   [x] Triển khai CertificateInfoResponse: Model response định dạng JSON `{"approved": boolean}`
    -   [x] Mở rộng GrpcRegistrationAuthClient: Thêm method getUserLoginInfoResponse và model UserLoginInfo POJO
    -   [x] Triển khai CertificateService: Logic xác thực certificate (trạng thái office approved, quyền hạn FP21, xác thực client certificate)
    -   [x] Triển khai CertificateController: Endpoint GET /v1/certificate/check (check đầu vào, error handling)
    -   [x] Phối hợp TwoFactorAuthenticationFilter: Hỗ trợ trích xuất certificate từ cả ThreadLocal và header
    -   [x] Unit/Integration Test: Tạo test lớp Web và lớp service / compile đã được xác nhận
-   [x] Chuyển giao API Firebase Token: Tái triển khai chức năng tương ứng với ` /fb/access/token` của `service-oauth2-server` trong `service-security.`
    -   [x] Tích hợp Firebase Admin SDK: Thêm mối quan hệ phụ thuộc Firebase Admin SDK và triển khai class cấu hình FirebaseConfig
    -   [x] Triển khai FirebaseAuthService: Lấy thông tin người dùng từ SecurityContextHolder, gen ra custom claim , tích hợp RxJava3
    -   [x] Triển khai FirebaseAuthController: Endpoint GET/POST /fb/access/token (xử lý bất đồng bộ DeferredResult)
    -   [x] Tích hợp Context Xác thực: Tạo Firebase custom token từ thông tin xác thực JWT, hỗ trợ PaymentFunctionType
    -   [x] Unit/Integration Test: Unit test Mockito và integration test của FirebaseAuthService đã được tạo
-   [ ] `NologinChatAuthenticationProvider` (Xác thực không đăng nhập cho chat, CẦN ĐIỀU TRA: Định nghĩa client có trong data.sql nhưng không tìm thấy phần triển khai Provider, nên kiểm tra tình trạng sử dụng và sẽ chuyển giao nếu cần).
-   [x] Chuyển giao gRPC Service: Xác định sự cần thiết chuyển giao sang `service-security` cho các gRPC services sau được public bởi `service-oauth2-server`, và triển khai các service cần thiết.
    -   [x] Triển khai GrpcActuatorServer: Kích hoạt mối quan hệ phụ thuộc protobuf, tích hợp Spring Cloud Context Refresher, chức năng: refresh/restart/shutdown cấu hình
    -   [x] Triển khai GrpcHealthServer: Triển khai Standard gRPC Health Check Protocol, tích hợp Spring Boot Actuator health indicator
    -   [x] Tích hợp Cấu hình Spring: Class cấu hình GrpcConfig, cấu hình bean ContextRefresher/HealthIndicator, thêm cấu hình gRPC application.yml
    -   [x] Tăng cường Bảo mật: Xem xét xác thực/phân quyền cho môi trường master, cải thiện error handling, output log thích hợp
    -   [x] Test Toàn diện: Unit test cho GrpcActuatorServer/GrpcHealthServer/GrpcConfig, và integration test gRPC đã được tạo.

### 2.2.2. その他の設定移行 | 

-   [x] **CORS設定の移行**: `service-oauth2-server`の`CorsPreflightConfiguration`および`CorsPreflightSecureConfiguration`を参考に、環境に応じたCORS設定を`service-security`に実装する。
    -   [x] **CorsAutoConfiguration実装**: 開発環境（許可的）と本番環境（制限的）の自動切替設定
    -   [x] **CorsProperties設定**: application.ymlによる柔軟な設定管理
    -   [x] **AuthorizationServerConfig統合**: Spring Security 6のCORS設定との統合
    -   [x] **単体テスト**: 環境別CORS設定の動作テスト完了
-   [x] **トークン有効期限のカスタムロジック移行**: `service-oauth2-server`の`CustomTokenServices`に含まれる、リクエストパラメータ（モバイルアプリ判定、ログイン維持）に応じてトークン有効期限を動的に変更するロジックを`service-security`で再現する。
    -   [x] **OAuth2TokenSettingsProvider実装**: 複雑なトークン期間ロジックの移植完了
    -   [x] **優先順位制御**: モバイル > オフィスセッション > save_login + プロダクト > デフォルト
    -   [x] **プロダクト別期間**: DRJOY/PRJOY/SCHOOL（90日）、ADMIN（30日）対応
    -   [x] **CustomTokenSettings拡張**: OAuth2Authentication コンテキスト対応
    -   [x] **包括的単体テスト**: 全ケースとモック使用テスト作成完了
==========================================================================================================================================
-   [x] Migrate config  CORS: Dựa theo `CorsPreflightConfiguration` và `CorsPreflightSecureConfiguratio`n của `service-oauth2-server`, triển khai config CORS tương ứng theo từng môi trường trong `service-security`.
    -   [x] Triển khai CorsAutoConfiguration: Config tự động chuyển đổi giữa môi trường phát triển (mở quyền truy cập) và môi trường master (hạn chế).
    -   [x] Config CorsProperties: Quản lý cấu hình linh hoạt thông qua application.yml.
    -   [x] Tích hợp AuthorizationServerConfig: Hợp nhất với cấu hình CORS trong Spring Security 6.
    -   [x] Unit Test: Đã hoàn tất kiểm thử hoạt động của config CORS theo từng môi trường.

 -   [x] Migrate custom logic về thời hạn hiệu lực của token: Tái hiện lại logic trong `CustomTokenServices` của `service-oauth2-server`, nơi thời hạn token được thay đổi động tùy theo request parameter (phân biệt ứng dụng di động, duy trì đăng nhập) trong `service-security`.
    -   [x] Triển khai OAuth2TokenSettingsProvider: Đã hoàn tất việc di chuyển logic phức tạp về thời gian hiệu lực token.
    -   [x] Kiểm soát mức độ ưu tiên: Ưu tiên theo thứ tự: mobile > phiên bản office > save_login + product > default.  
    -   [x] Thời hạn theo từng product: DRJOY / PRJOY / SCHOOL (90 ngày), ADMIN (30 ngày).
    -   [x] Mở rộng CustomTokenSettings: Hỗ trợ context của OAuth2Authentication.
    -   [x] Unit Test toàn diện: Đã tạo và hoàn tất tất cả các trường hợp kiểm thử, bao gồm cả test sử dụng mock.

### 2.3. データベースの準備 | Chuẩn bị DB

-   [ ] `service-security` が使用するMongoDBのコレクション（ユーザー、クライアント情報など）のスキーマを設計する。
-   [ ] **データ移行計画の具体化とスクリプト作成**:
    -   [ ] **クライアント情報**: 旧 `oauth_client_details` に相当する情報を、Spring Authorization Serverが要求する `RegisteredClient` のフォーマットに変換して移行する。
    -   [ ] **ユーザー情報**: 既存のユーザー情報を新サービスのDBスキーマに合わせて移行する。パスワードの再ハッシュ化が必要か検討する。
    -   [ ] **リフレッシュトークン**: 既存のリフレッシュトークンを無効化するか、あるいは新システムでも利用可能な形で移行するかの戦略を決定する。
=====================================================================================================================
-   [ ] Thiết kế Schema của các collection MongoDB mà `service-security` sử dụng (thông tin user/client ...etc)
-   [ ] Tạo script và cụ thể hóa kế hoạch migrate data
    -   [ ] Thông tin client: Chuyển đổi dữ liệu tương ứng với bảng cũ `oauth_client_details` sang định dạng `RegisteredClien`t mà Spring Authorization Server yêu cầu.
    -   [ ] Thông tin người dùng: Di chuyển dữ liệu người dùng hiện có sang schema DB của service mới. Cần xem xét việc re-hash lại mật khẩu hay không.
    -   [ ] Refresh Token: Quyết định chiến lược là vô hiệu hóa token hiện có, hay chuyển đổi để vẫn có thể sử dụng trong hệ thống mới.

## フェーズ3: 段階的なクライアント移行 | Di chuyển từng bước các client

### 3.1. テストの実施 | Thực hiện kiểm thử

-   [ ] **単体テスト:** `service-security` の各コンポーネントに対して、JUnit/Mockito等を用いた単体テストを実装する。
-   [ ] **結合テスト:** Springのテストフレームワークを使い、実際のHTTPリクエスト/レスポンスを伴う結合テストを実装する。主要なグラントタイプ（Authorization Code, Client Credentialsなど）を網羅する。
-   [ ] **E2Eテスト:**
    -   テスト用のクライアントアプリケーションを準備する。
    -   `service-security` をステージング環境等にデプロイする。
    -   クライアントからの認証フロー全体が正常に動作することを確認する。
====================================================================================================================================================================================================
-   [ ] Unit Test: Triển khai unit test cho từng component của `service-security` bằng JUnit / Mockito.
-   [ ] Integration Test: Sử dụng Spring Test Framework để thực hiện các bài integration test có request/response HTTP thực tế, bao phủ các loại grant chính (Authorization Code, Client Credentials, v.v.).
-   [ ] Test E2E :
    -   Chuẩn bị ứng dụng client dành cho kiểm thử.
    -   Deploy  `service-security` lên môi trường staging (hoặc môi trường nào đó).
    -   Xác nhận toàn bộ luồng xác thực từ client hoạt động bình thường.

### 3.2. 移行戦略の策定と実行 | Lập và thực thi chiến lược di chuyển

**Note:** 全てのサービスを一度に移行するのは困難なため、まずは `service-web-front` と `service-registration` をモデルケースとして移行作業を進める。これらのサービスでの移行が成功した後、他のサービスへ展開する。

-   [ ] 移行対象となるクライアントサービス（`service-admin`, `web-drjoy`など）のリストを作成する。
-   [ ] 影響の少ない内部サービスから移行を開始する計画を立てる。
-   [ ] APIゲートウェイやリバースプロキシの設定を変更し、一部のトラフィックを `service-security` に向ける（カナリアリリース）。
-   [ ] 各クライアントアプリケーションの設定ファイル（`.yml`）を更新し、OAuth2サーバーのエンドポイントURLを新しいものに変更する。
-   [ ] 段階的にトラフィックの割合を増やしていく。
====================================================================================================================================================================================================
Ghi chú: Do khó có thể di chuyển tất cả dịch vụ cùng lúc, trước tiên sẽ tiến hành di chuyển thử nghiệm (mô hình mẫu) với `service-web-front` và `service-registration`. Sau khi hoàn tất thành công, sẽ mở rộng sang các service khác.
-   [ ] Tạo danh sách các service client nằm trong phạm vi di chuyển (`service-admin`, `web-drjoy`, v.v.).
-   [ ] Lập kế hoạch bắt đầu từ các service nội bộ ít ảnh hưởng nhất.
-   [ ] Thay đổi cấu hình của API Gateway hoặc Reverse Proxy, điều hướng một phần traffic sang `service-security` (Canary Release).
-   [ ] Cập nhật file cấu hình (.yml) của từng ứng dụng client để thay đổi URL endpoint OAuth2 server sang URL mới.
-   [ ] Tăng dần tỷ lệ traffic theo từng giai đoạn.

### 3.4. service-registration の移行（モデルケース）🎉 **移行ほぼ完了** | Di chuyển service-registration (mô hình mẫu) 🎉 Gần như hoàn tất

**📊 現在の進捗状況**: 約95%完了（2024年12月時点で既に大部分の移行が完了済み） | Tiến độ hiện tại: Hoàn thành khoảng 95% (tính đến tháng 12/2024, phần lớn đã hoàn tất).

#### 3.4.1. 事前準備 ✅ **完了済み** | Khâu chuẩn bị trước: Đã hoàn thành

-   [x] `feature/renew_framework` ブランチの作成
-   [x] 現在の依存ライブラリと `service-framework` 使用箇所の分析
-   [x] 影響範囲調査（コントローラー、サービス、設定クラス）
-   [x] 既存機能の動作確認とテストケース整理
====================================================================================================================
-   [x] Tạo branch `feature/renew_framework`
-   [x] Phân tích các thư viện phụ thuộc hiện tại và vị trí sử dụng `service-framework`
-   [x] Điều tra phạm vi ảnh hưởng (Controller, Service, Class cấu hình)
-   [x] Xác nhận hoạt động của các chức năng hiện có và chỉnh sửa lại test case

#### 3.4.2. pom.xml の更新 ✅ **完了済み** | Cập nhật pom.xml ✅ Đã hoàn thành

-   [x] JDK 11 → **17** への更新 *(実装完了)*
-   [x] Spring Boot 2.x → **3.2.0** への更新 *(実装完了)*
-   [x] `service-framework` → `lib-spring-boot-starter-*` への置換 *(実装完了)*
-   [x] Maven compiler/surefire プラグインの更新 *(実装完了)*
-   [x] 新ライブラリの依存関係追加 *(実装完了)*
-   [x] **親POMの変更**: `spring-boot-starter-parent` 3.2.0 使用中 *(実装完了)*
-   [x] **古いライブラリの更新**: *(実装完了)*
    -   [x] Jackson → Spring Boot 3標準版使用
    -   [x] commons-lang3 使用
    -   [x] lombok 1.18.30 使用
    -   [x] reactor-core Spring Boot 3標準版使用
-   [x] **protobuf依存関係**の整合性確認 *(実装完了)*
-   [x] **依存関係バージョン統一**: Maven設定完了 *(実装完了)*
====================================================================================================================
-   [x] Cập nhật JDK 11 → 17 (hoàn tất)
-   [x] Cập nhật Spring Boot 2.x → 3.2.0 (hoàn tất)
-   [x] Thay thế `service-framework` bằng `lib-spring-boot-starter-*` (hoàn tất)
-   [x] Cập nhật plugin Maven compiler/surefire (hoàn tất)
-   [x] Thêm các mối quan hệ phụ thuộc của thư viện mới (hoàn tất)
-   [x] Thay đổi parent POM: Đang sử dụng `spring-boot-starter-parent` 3.2.0 (hoàn tất)
-   [x] Cập nhật các thư viện cũ: (hoàn tất)
    -   [x] Jackson → sử dụng bản chuẩn của Spring Boot 3
    -   [x] Sử dụng commons-lang3
    -   [x] Sử dụng lombok 1.18.30
    -   [x] reactor-core → sử dụng bản chuẩn của Spring Boot 3
-   [x] Kiểm tra tính tương thích của mối quan hệ phụ thuộc protobuf (hoàn tất)
-   [x] Thống nhất phiên bản mối quan hệ phụ thuộc trong cấu hình Maven (hoàn tất)

#### 3.4.3. コード修正 🔄 **95%完了（残存2ファイル）** | Chỉnh sửa mã nguồn 🔄 Hoàn thành 95% (còn 2 file) |

-   [x] `javax` → `jakarta` パッケージの一括置換 *(実装完了)*
-   [x] Spring Security 6 対応（認証フィルター、設定クラス） *(実装完了)*
-   [x] MongoDB 設定クラスの更新 *(実装完了)*
-   [x] gRPC クライアント設定の新ライブラリ対応 *(実装完了)*
-   [x] 非推奨API の修正 *(実装完了)*
-   [x] enum のマスターデータサービス利用への変更 *(実装完了)*
-   [x] **service-framework import の置換**: *(95%完了)*
    -   [x] `jp.drjoy.service.framework.grpc.*` → `jp.drjoy.lib.grpc.*`
    -   [x] `jp.drjoy.service.framework.security.*` → `jp.drjoy.lib.security.*`
    -   [x] `jp.drjoy.service.framework.utils.*` → `jp.drjoy.lib.utils.*`
    -   [x] `jp.drjoy.service.framework.model.*` → `jp.drjoy.lib.models.*`
    -   [x] `jp.drjoy.service.framework.publisher.*` → `jp.drjoy.lib.grpc.*`
    -   [ ] **残存作業**: 2ファイルのコメントアウト済み参照削除
        - `LoginService.java:30` - `Settings`クラス参照削除
        - `ExternalRegistrationGrpcServerConfiguration.java` - インターセプター設定削除
-   [x] **Spring Security 6 廃止API対応**: *(実装完了)*
    -   [x] `WebSecurityConfigurerAdapter` → `SecurityFilterChain` Bean
    -   [x] 認証設定の書き換え
-   [x] **テストクラス移行**: *(既存テスト確認済み)*
====================================================================================================================
-   [x] Thay thế toàn bộ package javax → jakarta (đã hoàn tất)
-   [x] Hỗ trợ Spring Security 6 (filter xác thực, class cấu hình) (đã hoàn tất)
-   [x] Cập nhật class cấu hình MongoDB (đã hoàn tất)
-   [x] Điều chỉnh cấu hình gRPC client theo thư viện mới (đã hoàn tất)
-   [x] Sửa các API không còn được khuyến nghị (Deprecated) (đã hoàn tất)
-   [x] Thay đổi cách sử dụng enum sang service dữ liệu master (đã hoàn tất)
-   [x] Thay thế import từ service-framework: (hoàn thành 95%)
    -   [x] `jp.drjoy.service.framework.grpc.*` → `jp.drjoy.lib.grpc.*`
    -   [x] `jp.drjoy.service.framework.security.*` → `jp.drjoy.lib.security.*`
    -   [x] `jp.drjoy.service.framework.utils.*` → `jp.drjoy.lib.utils.*`
    -   [x] `jp.drjoy.service.framework.model.*` → `jp.drjoy.lib.models.*`
    -   [x] `jp.drjoy.service.framework.publisher.*` → `jp.drjoy.lib.grpc.*`
    -   [ ] Công việc còn lại: Xóa các tham chiếu đã được comment trong 2 file
        - `LoginService.java:30` – Xóa tham chiếu đến class `Settings`
        - `ExternalRegistrationGrpcServerConfiguration.java` – Xóa cấu hình Interceptor
-   [x] Xử lý các API bị loại bỏ trong Spring Security 6: (đã hoàn tất)
    -   [x] `WebSecurityConfigurerAdapter` → `SecurityFilterChain` Bean
    -   [x] Viết lại cấu hình xác thực
-   [x] Di chuyển class test: (đã xác nhận test hiện có)

#### 3.4.4. 設定ファイル更新 🔄 **OAuth2設定のみ残存** | Cập nhật file cấu hình 🔄 Chỉ còn phần cấu hình OAuth2

-   [x] `application.yml` の Spring Boot 3 対応 *(実装完了)*
-   [ ] **OAuth2 クライアント設定**（`service-security` エンドポイント） *※追加作業必要*
-   [x] ログ設定とアクチュエーター設定の調整 *(実装完了)*
-   [x] gRPC 接続設定の更新 *(実装完了)*
-   [x] **gRPC設定の新ライブラリ対応**: *(実装完了)*
    -   [x] `grpc.server.*` 設定の互換性確認済み
    -   [x] `grpc.client.channels.*` 設定完了済み
====================================================================================================================
-   [x] Xử lý `application.yml` tương thích với Spring Boot 3 (đã hoàn tất)
-   [ ] Cấu hình OAuth2 client (`service-securit`y endpoint) → cần thêm công việc
-   [x] Điều chỉnh cấu hình log và actuator (đã hoàn tất)
-   [x] Cập nhật cấu hình kết nối gRPC (đã hoàn tất)
-   [x] Điều chỉnh cấu hình gRPC cho thư viện mới: (đã hoàn tất)
    -   [x] Đã xác nhận tính tương thích của `grpc.server.*`
    -   [x] Đã hoàn tất cấu hình `grpc.client.channels.*`

#### 3.4.5. テスト・検証 🔄 **実行段階** | Kiểm thử & xác minh 🔄 Đang thực hiện

-   [x] 単体テストの存在確認（85ファイル）
-   [ ] 単体テストの実行と結果確認
-   [ ] 統合テストの実行と修正  
-   [ ] `service-security` との連携テスト
-   [ ] ローカル環境での動作確認
-   [ ] パフォーマンステストの実施
-   [x] **service-framework依存箇所の移行状況確認**: *(調査完了)*
    -   [x] import文の一括置換結果チェック（2箇所のみ残存）
    -   [x] 未対応クラスの特定完了
-   [x] **gRPC通信の基盤確認**: *(設定完了)*
    -   [ ] サーバー起動テスト
    -   [ ] クライアント接続テスト
    -   [ ] インターセプター動作テスト
====================================================================================================================
-   [x] Đã xác nhận tồn tại 85 file unit test
-   [ ] Thực thi unit test và xác nhận kết quả
-   [ ] -   [x] Thực thi và điều chỉnh integration test
-   [ ] Kiểm thử tích hợp với `service-security`
-   [ ] Kiểm thử hoạt động trên môi trường local
-   [ ] Thực hiện kiểm thử Performance 
-   [x] Xác nhận tình trạng di chuyển các phần phụ thuộc vào service-framework: (đã điều tra xong)
    -   [x] Đã kiểm tra kết quả thay thế import (còn 2 vị trí)
    -   [x] Đã xác định các class chưa xử lý
-   [x] Xác nhận nền tảng giao tiếp gRPC: (đã cấu hình xong)
    -   [ ] Kiểm thử khởi động server
    -   [ ] Kiểm thử kết nối client
    -   [ ] Kiểm thử hoạt động Interceptor

#### 3.4.6. 事前調査 ✅ **完了済み** | Nghiên cứu trước ✅ Đã hoàn tất

-   [x] **lib-*ライブラリでの機能提供状況確認**: *(調査完了)*
    -   [x] `service-registration`で使用されている全機能の新ライブラリでの提供状況確認完了
    -   [x] 残存する微細な課題のみ特定済み
-   [x] **段階的移行戦略の策定**: *(戦略確定)*
    -   [x] 残存作業の具体化完了
    -   [x] ロールバック戦略不要（移行ほぼ完了のため）
====================================================================================================================
-   [x] Xác nhận tình trạng hỗ trợ chức năng của các thư viện lib-* (đã điều tra xong)
    -   [x] Đã xác nhận toàn bộ chức năng `service-registration` đều được hỗ trợ trong thư viện mới
    -   [x] Chỉ còn lại một số vấn đề nhỏ cần xử lý
-   [x] Lập chiến lược migrate theo từng giai đoạn: (chiến lược đã xác định)
    -   [x] Đã cụ thể hóa các công việc còn lại
    -   [x] Không cần chiến lược rollback (vì migrate gần như hoàn tất)

#### 3.4.7. 最終完了作業 🎯 **実行予定** | Hoàn tất cuối cùng 🎯 Dự kiến thực hiện

-   [ ] **残存service-framework参照の完全削除**:
    -   [ ] `LoginService.java` のコメントアウト行削除
    -   [ ] `ExternalRegistrationGrpcServerConfiguration.java` のコメントアウト行削除
-   [ ] **OAuth2クライアント設定追加**:
    -   [ ] `application.yml` にservice-security接続設定追加
    -   [ ] 環境別設定の追加
-   [ ] **最終動作確認**:
    -   [ ] アプリケーション起動テスト
    -   [ ] gRPCサービス動作確認
    -   [ ] 認証機能動作確認（service-security連携後）
====================================================================================================================
-   [ ] Xóa hoàn toàn các tham chiếu còn lại đến service-framework:
    -   [ ] Xóa dòng comment trong `LoginService.java`
    -   [ ] Xóa dòng comment trong `ExternalRegistrationGrpcServerConfiguration.java`
-   [ ] Thêm cấu hình OAuth2 client:
    -   [ ] Thêm cấu hình kết nối service-security vào `application.yml`
    -   [ ] Thêm cấu hình riêng cho từng môi trường
-   [ ] Xác nhận hoạt động cuối cùng:
    -   [ ] Kiểm thử khởi động ứng dụng
    -   [ ] Xác nhận hoạt động gRPC service
    -   [ ] Xác nhận hoạt động chức năng xác thực (sau khi liên kết với service-security)

### 3.5. モニタリング | Giám sát

-   [ ] `service-security` のメトリクス（リクエスト数、レイテンシ、エラーレート）を監視するためのダッシュボードを準備する (例: Prometheus, Grafana)。
-   [ ] ログ集約システム (例: ELK Stack, Splunk) で、エラーログや警告ログをリアルタイムに監視する。
-   [ ] 移行に伴う問題が発生した場合のロールバック手順を事前に定義しておく。
====================================================================================================================
-   [ ] Chuẩn bị dashboard để theo dõi các metric của `service-security` (số lượng request, độ trễ, tỷ lệ lỗi) – ví dụ: Prometheus, Grafana.
-   [ ] Sử dụng hệ thống tập trung log (ví dụ: ELK Stack, Splunk) để giám sát log lỗi và cảnh báo theo realtime.
-   [ ] Định nghĩa trước quy trình rollback trong trường hợp xảy ra sự cố sau khi di chuyển.

## フェーズ4: 旧システムの廃止 | Loại bỏ hệ thống cũ

### 4.1. 移行完了の確認 | Xác nhận hoàn tất di chuyển

-   [ ] 全てのクライアントアプリケーションが `service-security` を向いていることを、設定ファイルやAPIゲートウェイのルーティングルールから確認する。
-   [ ] 旧 `service-oauth2-server` へのトラフィックがゼロになったことを、アクセスログやメトリクスから確認する。
-   [ ] 一定期間（例: 1週間）監視を続け、問題が発生しないことを確認する。
====================================================================================================================
-   [ ] Xác nhận tất cả ứng dụng client đã chuyển hướng sang sử dụng service-security (qua file cấu hình hoặc rule routing của API Gateway).
-   [ ] Xác nhận lượng truy cập đến `service-oauth2-serve`r cũ đã về 0 (qua access log và metrics).
-   [ ] Tiếp tục giám sát trong khoảng thời gian nhất định (ví dụ: 1 tuần) để đảm bảo không phát sinh vấn đề.

### 4.2. 廃止作業 | Thao tác loại bỏ

-   [ ] 旧 `service-oauth2-server` のデプロイメントを停止・削除する。
-   [ ] 旧 `service-framework` を利用しているサービスが残っていないことを確認し、リポジトリをアーカイブまたは削除する。
-   [ ] 関連するCI/CDパイプラインやドキュメントから、旧システムへの参照を削除する。
====================================================================================================================
-   [ ] Dừng và xóa deployment của `service-oauth2-server` cũ.
-   [ ] Đảm bảo không còn dịch vụ nào sử dụng `service-framework`, sau đó lưu trữ (archive) hoặc xóa repository đó.
-   [ ] Xóa mọi tham chiếu đến hệ thống cũ trong pipeline CI/CD và tài liệu liên quan.