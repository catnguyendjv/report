# 既存サービス移行ガイド | Hướng dẫn migrate service hiện có
## service-framework → lib-* ライブラリ移行の実践手順書 | Tài liệu thực hành: migration từ service-framework → lib-*

このガイドは、`service-registration`の移行実績（95%完了）を基に、同様の構成を持つマイクロサービスを効率的に移行するための汎用的な手順書です。
Hướng dẫn này là tài liệu tổng quát để di chuyển các microservice có cấu trúc tương tự, dựa trên kết quả di chuyển `service-registration` (đã hoàn thành 95%).

## 🏗️ 移行アーキテクチャ概要 | Tổng quan kiến trúc di chuyển

### 移行前 (現状) | Trước khi di chuyển (hiện trạng)
```
マイクロサービス → service-framework (Spring Boot 2.x, Java 8/11) → 各種機能
Microservice → service-framework (Spring Boot 2.x, Java 8/11) → các loại chức năng
```

### 移行後 (目標) | Sau khi di chuyển (mục tiêu)
```
マイクロサービス → lib-spring-boot-starter-* (Spring Boot 3.x, Java 17) → 各種機能
Microservice → lib-spring-boot-starter-* (Spring Boot 3.x, Java 17) → các loại chức năng
```

### 新ライブラリ構成 | Cấu trúc thư viện mới
- **基盤**: `lib-common-utils`, `lib-common-models`
- **Spring Boot Starter**: `lib-spring-boot-starter-{grpc,security,mongodb,web,masterdata}`
============================================================================================
- **Nền tảng:** `lib-common-utils, lib-common-models`
- **Spring Boot Starter:** `lib-spring-boot-starter-{grpc,security,mongodb,web,masterdata}`
---

## 📋 移行対象の判定 | Tiêu chí xác định dịch vụ cần di chuyển

### 移行が必要なサービスの特徴 | Đặc điểm dịch vụ cần di chuyển
- [ ] `service-framework` への依存関係あり
- [ ] Spring Boot 2.x系使用
- [ ] Java 8 または 11 使用
- [ ] gRPC通信を使用
- [ ] MongoDB データベース使用
- [ ] OAuth2認証機能使用
==============================================
- [ ] Có mối quan hệ phụ thuộc tới `service-framework`
- [ ] Sử dụng Spring Boot 2.x
- [ ] Sử dụng Java 8 hoặc 11
- [ ] Sử dụng gRPC communication
- [ ] Sử dụng MongoDB database
- [ ] Sử dụng tính năng OAuth2 authentication

### 移行優先度の判定 | Xếp hạng ưu tiên di chuyển
- **🔴 高**: 活発に開発中、本番稼働中の重要サービス
- **🟡 中**: 定期的にメンテナンスされるサービス
- **🟢 低**: レガシーまたは使用頻度の低いサービス
===============================================
- **Cao:** Dịch vụ đang phát triển tích cực, đang chạy production, quan trọng
- **Trung:** Dịch vụ được bảo trì định kỳ
- **Thấp:** Legacy hoặc ít dùng
---

## 📂 Phase 1: 事前準備 (所要時間: 30分) | Chuẩn bị trước (thời gian: 30 phút)

### 1.1. ブランチ作成と現状分析 | Tạo branch và phân tích hiện trạng

```bash
# 移行対象サービスのディレクトリに移動 | di chuyển vào thư mục service sẽ migrate
cd [TARGET_SERVICE_DIRECTORY]

# feature/renew_framework ブランチを作成・切り替え | tạo/chuyển sang branch feature/renew_framework
git checkout -b feature/renew_framework

# 現在の依存関係を確認 | kiểm tra mối quan hệ phụ thuộc hiện tại
mvn dependency:tree > dependency_analysis.txt

# service-framework使用箇所の分析 | phân tích các chỗ sử dụng service-framework
grep -r "jp.drjoy.service.framework" src/ > framework_usage.txt
```

### 1.2. 移行可能性チェック | Kiểm tra khả năng di chuyển

**必須チェック項目:** | Mục kiểm tra bắt buộc:
- [ ] 現在のSpring Bootバージョン確認
- [ ] Javaバージョン確認
- [ ] 使用している主要機能の特定
  - gRPC (Server/Client)
  - MongoDB Repository
  - Spring Security 設定
  - Web Controllers
  - マスターデータ管理
==================================================
- [ ] Xác nhận phiên bản Spring Boot hiện tại
- [ ] Xác nhận phiên bản Java
- [ ] Xác định các chức năng chính đang dùng:
  - gRPC (Server/Client)
  - MongoDB Repository
  - Cấu hình Spring Security 
  - Web Controllers
  - Master data management
---

## 📦 Phase 2: pom.xml 更新 (所要時間: 45分) | Update pom.xml (thời gian: 45 phút)

### 2.1. 基本バージョン更新 | Cập nhật version cơ bản

```xml
<!-- Spring Boot親POM更新 --> | Cập nhật Spring Boot parent POM
<parent>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-parent</artifactId>
  <version>3.2.0</version>
</parent>

<!-- Java バージョン更新 --> | Cập nhật Java version
<properties>
  <java.version>17</java.version>
  <maven.compiler.source>17</maven.compiler.source>
  <maven.compiler.target>17</maven.compiler.target>
</properties>
```

### 2.2. 依存関係の置換 | Thay thế mối quan hệ phụ thuộc

**service-framework の削除:** | Xóa service-framework
```xml
<!-- 削除対象 --> | Đối tượng xóa
<dependency>
  <groupId>jp.drjoy.service</groupId>
  <artifactId>service-framework</artifactId>
  <version>*</version>
</dependency>
```

**lib-* ライブラリの追加 (使用する機能に応じて選択):** | Thêm thư viện lib-* (chọn theo chức năng sử dụng):
```xml
<!-- 基盤ライブラリ（必須） --> | Thư viện nền tảng (bắt buộc)
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

<!-- Web機能使用時 --> | Khi dùng Web
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-web</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>

<!-- 認証機能使用時 --> | Khi dùng chức năng authentication
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-security</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>

<!-- MongoDB使用時 --> | Khi dùng MongoDB
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-mongodb</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>

<!-- gRPC使用時 --> | Khi dùng gRPC
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-grpc</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>

<!-- マスターデータ管理使用時 --> | Khi dùng master data
<dependency>
  <groupId>jp.drjoy</groupId>
  <artifactId>lib-spring-boot-starter-masterdata</artifactId>
  <version>0.1.MASTER-SNAPSHOT</version>
</dependency>
```

### 2.3. Maven プラグイン更新 | Cập nhật Maven plugin

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

## 🔧 Phase 3: コード修正 (所要時間: 2-3時間) | Sửa code (thời gian: 2–3 giờ)

### 3.1. パッケージ名一括置換 | Thay thế package hàng loạt

```bash
# javax → jakarta パッケージ一括置換 | thay package hàng loạt java → jakarta
find src/ -name "*.java" -exec sed -i 's/javax\.persistence\./jakarta.persistence./g' {} \;
find src/ -name "*.java" -exec sed -i 's/javax\.validation\./jakarta.validation./g' {} \;
find src/ -name "*.java" -exec sed -i 's/javax\.servlet\./jakarta.servlet./g' {} \;
find src/ -name "*.java" -exec sed -i 's/javax\.transaction\./jakarta.transaction./g' {} \;

# service-framework import 一括置換 | thay service-framework import hàng loạt
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.grpc\./jp.drjoy.lib.grpc./g' {} \;
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.security\./jp.drjoy.lib.security./g' {} \;
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.utils\./jp.drjoy.lib.utils./g' {} \;
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.model\./jp.drjoy.lib.models./g' {} \;
find src/ -name "*.java" -exec sed -i 's/jp\.drjoy\.service\.framework\.publisher\./jp.drjoy.lib.grpc./g' {} \;
```

### 3.2. Spring Security 6 対応 | Tương thích với Spring Security 6

**WebSecurityConfigurerAdapter 廃止対応:** | Tiến hành loại bỏ WebSecurityConfigurerAdapter

```java
// 更新前 | Trước update
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

// 更新後 | Sau update
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

### 3.3. MongoDB設定クラス更新 | Update class config MongoDB

```java
// 更新前 | Trước update
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

// 更新後 | Sau update
@Configuration
@EnableMongoRepositories
public class MongoConfig {
  @Bean
  public MongoClient mongoClient() {
    return MongoClients.create("mongodb://localhost:27017");
  }
}
```

### 3.4. 残存する手動修正が必要な箇所 | Các chỗ còn cần chỉnh tay

コンパイルエラーで特定される以下のパターンを個別に修正: | Sửa riêng lẻ các pattern được xác định bởi lỗi complie dưới đây

1. **削除されたクラス・メソッドの使用**
2. **enum のマスターデータサービス利用への変更**
3. **gRPC設定クラスの新ライブラリ対応**
============================================================
1. **Sử dụng class/method đã bị xóa**
2. **Chuyển enum sang sử dụng master data service**
3. **Cập nhật gRPC config classes để dùng thư viện mới**

---

## ⚙️ Phase 4: 設定ファイル更新 (所要時間: 30分) | Cập nhật file cấu hình (thời gian: 30 phút)

### 4.1. application.yml の Spring Boot 3 対応 | application.yml tương thích Spring Boot 3

**基本設定の更新:** | Cập nhật cấu hình cơ bản:
```yaml
spring:
  application:
    name: [SERVICE_NAME]
  
# gRPC設定 (gRPC使用時) | gRPC config (khi dùng gRPC)
grpc:
  server:
    port: [GRPC_PORT]
  client:
    channels:
      [TARGET_SERVICE]:
        address: static://localhost:[TARGET_PORT]
        negotiationType: plaintext

# MongoDB設定 (MongoDB使用時) | Config MongoDB (khi dùng MongoDB)
spring:
  data:
    mongodb:
      uri: mongodb://localhost:27017/[DATABASE_NAME]
```

### 4.2. 認証設定 (サービス種別による) | Cài đặt xác thực (tùy loại service)

#### 4.2.1. HTTP API サービスの場合 (JWT Resource Server設定) | Với trường hợp HTTP API services (config JWT Resource Server)

HTTPエンドポイントを公開するサービス（service-web-front, service-admin等）の場合：
Trường hợp service （service-web-front, service-admin..etc) công khai HTTP endpoint


```yaml
# JWT検証用設定 | Config dùng cho kiểm chứng JWT
service:
  oauth2:
    secret-public: ${OAUTH_SECRET_PUBLIC:secret/oauth2.pub}  # JWT公開鍵パス | path public key của JWT
    resource-id: ${OAUTH_RESOURCE_ID:demo}

# Spring Security 6 Resource Server設定 | Config Spring Security 6 Resource Server
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          public-key-location: ${service.oauth2.secret-public}
```

#### 4.2.2. gRPCサービスの場合 (OAuth2設定不要) | Với gRPC services (không cần OAuth2)

gRPC専用サービス（service-registration等）の場合：
Trường hợp service chuyên cho gRPC (service-registration..etc)

```yaml
# gRPC認証はGrpcAuthServerInterceptorで処理されるため
# OAuth2クライアント設定は不要
# 基本的なSpring Security設定のみ
========================================================
# Xác thực gRPC được xử lý bởi GrpcAuthServerInterceptor
# Config của OAuth2 client không cần
#Chỉ cần các thiết lập cơ bản của Spring Security
```

**重要**: gRPCサービスは独自のgRPC認証メカニズムを使用するため、OAuth2クライアント設定は追加不要です。
**Quan trọng:** gRPC services dùng cơ chế xác thực riêng , nên không cần thêm OAuth2 client config.

---

## 🧪 Phase 5: テスト・検証 (所要時間: 1-2時間) | Phase 5: Test & kiểm chứng (thời gian: 1–2 giờ)

### 5.1. 段階的な動作確認 | Kiểm tra hoạt động theo bước

```bash
# 1. 依存関係解決の確認 | Kiểm tra resolve các mối quan hệ phụ thuộc
mvn clean compile

# 2. 単体テスト実行 | Thực hiện Unit test
mvn clean test

# 3. アプリケーション起動テスト | Test khởi động App
mvn spring-boot:run
```

### 5.2. 機能別確認項目 | Các đầu mục kiểm tra từng tính năng

**gRPC機能 (該当する場合):** | Chức năng gRPC (nếu áp dụng)
- [ ] gRPCサーバー起動確認
- [ ] gRPCクライアント接続確認
- [ ] インターセプター動作確認
========================================================
- [ ] Xác nhận khởi động server gRPC
- [ ] Xác nhận kết nối gRPC Client
- [ ] Xác nhận hoạt động của interceptor

**MongoDB機能 (該当する場合):** | Chức năng MongoDB (nếu áp dụng)
- [ ] データベース接続確認
- [ ] Repository動作確認
- [ ] トランザクション動作確認
========================================================
- [ ] Xác nhận kết nối DB
- [ ] Xác nhận hoạt đông repository
- [ ] Xác nhận hoạt động của transaction

**Web機能 (HTTP API サービスの場合):** |  Chức năng Web (trường hợp là HTTP API service)
- [ ] コントローラー応答確認
- [ ] JWT認証・認可動作確認
- [ ] フィルター・インターセプター動作確認
========================================================
- [ ] xác nhận xem Controller trả về hợp lệ không
- [ ] Xác nhận hoạt động xác thực/phân quyền của JWT 
- [ ] Xác nhận hoạt động Filters / interceptors

**認証機能 (サービス種別による):** | Chức năng xác thực (tùy theo từng loại service)
- [ ] **HTTP API サービス**: JWT Resource Server 動作確認
- [ ] **gRPCサービス**: gRPC認証インターセプター動作確認
=======================================================
- [ ] **HTTP API service:** xác nhận hoạt động JWT Resource Server
- [ ] **gRPC service:** xác nhận hoạt động của gRPC authentication interceptor


---

## ✅ 汎用チェックリスト | Checklist tổng quát

### Phase 1: 事前準備 | Chuẩn bị
- [ ] feature/renew_framework ブランチ作成
- [ ] 現在の技術スタック分析完了
- [ ] 使用機能の特定完了
- [ ] 移行対象の依存関係特定
======================================================
- [ ] Tạo branch feature/renew_framework
- [ ] Hoàn tất phân tích tech stack hiện tại
- [ ] Hoàn tất xác định các chức năng sử dụng
- [ ] Xác định mối quan hệ phụ thuộc cần migrate

### Phase 2: pom.xml更新 | Cập nhật pom.xml
- [ ] Spring Boot 3.2.0 更新
- [ ] Java 17 更新
- [ ] service-framework依存削除
- [ ] 必要なlib-*ライブラリ追加
- [ ] Maven プラグイン更新
========================================================
- [ ] Cập nhật Spring Boot  3.2.0
- [ ] Cập nhật Java  17
- [ ] Xóa dependency service-framework
- [ ] Thêm thư viện lib-* cần thiết
- [ ] Cập nhật Maven plugins

### Phase 3: コード修正 | Sửa code
- [ ] javax → jakarta 一括置換完了
- [ ] service-framework import 一括置換完了
- [ ] Spring Security 6 対応完了
- [ ] MongoDB設定更新完了
- [ ] コンパイルエラー解決完了
========================================================
- [ ] Thay đồng loạt javax → jakarta, hoàn tất
- [ ] Thay đồng loạt import service-framework, hoàn tất
- [ ] Tương thích Spring Security 6, hoàn tất
- [ ] Cập nhật cấu hình MongoDB, hoàn tất
- [ ] Giải quyết lỗi compile, hoàn tất

### Phase 4: 設定更新 | Cập nhật cấu hình
- [ ] application.yml Spring Boot 3 対応
- [ ] サービス種別に応じた認証設定:
  - [ ] **HTTP API サービス**: JWT Resource Server 設定
  - [ ] **gRPCサービス**: 基本Spring Security設定のみ
- [ ] 使用機能別設定追加完了
- [ ] 環境別設定確認完了
=========================================================
- [ ] application.yml tương thích Spring Boot 3
- [ ] Cấu hình xác thực ứng với heo loại service:
  - [ ] **HTTP API service:** config JWT Resource Server
  - [ ] **gRPC service:** chỉ cấu hình Spring Security cơ bản
- [ ] Thêm cấu hình theo từng chức năng sử dụng, hoàn tất
- [ ] Kiểm tra cấu hình theo từng môi trường, hoàn tất

### Phase 5: テスト・検証 | Kiểm thử/Kiểm chứng
- [ ] `mvn clean compile` 成功
- [ ] `mvn clean test` 成功
- [ ] `mvn spring-boot:run` 起動成功
- [ ] 各機能の基本動作確認完了
=========================================================
- [ ] `mvn clean compile` thành công
- [ ] `mvn clean test` thành công
- [ ] `mvn spring-boot:run` khởi động thành công
- [ ] Hoàn tất kiểm tra hoạt động cơ bản của các chức năng 
---

## 🔥 共通トラブルシューティング | Troubleshooting chung

### よくある問題と解決方法 | Vấn đề thường gặp và cách giải quyết

#### 1. コンパイルエラー: パッケージが見つからない | Lỗi compile: package not found
```bash
# 原因: javax → jakarta 置換漏れ | Nguyên nhân: còn sót chỗ chưa replace javax → jakarta
# 解決: 残存箇所の確認と手動修正 | Cách làm: tìm các file còn chưa replace và sửa thủ công
find src/ -name "*.java" -exec grep -l "javax\." {} \;
```

#### 2. Spring Security設定エラー | Lỗi cấu hình Spring Security
```
エラー: WebSecurityConfigurerAdapter関連のメソッドが見つからない
解決方法: SecurityFilterChain Bean 定義パターンに変更
==================================================================
Lỗi: các method liên quan WebSecurityConfigurerAdapter không tìm thấy
Giải pháp: chuyển sang pattern SecurityFilterChain Bean
```

#### 3. MongoDB接続エラー | Lỗi kết nối MongoDB
```
エラー: AbstractMongoConfiguration関連のメソッド呼び出しエラー
解決方法: MongoClient Bean 定義のみの簡略化パターンに変更
==================================================================
Lỗi: lỗi gọi các method liên quan AbstractMongoConfiguration
Giải pháp: đổi sang chỉ dùng pattern đơn giản hóa  của định nghĩa MongoClient Bean
```

#### 4. lib-*ライブラリ依存関係エラー | Lỗi về mối quan hệ phụ thuộc thư viện lib-*
```bash
# 原因: lib-*ライブラリが未ビルド
# 解決: 事前に全lib-*ライブラリをビルド
==================================================================
# Nguyên nhân: Thư viện lib-* chưa được build
# Giải pháp: build trước toàn bộ thư viện lib-*

./scripts/build-libs.sh
```

#### 5. gRPC関連エラー | Lỗi liên quan gRPC
```yaml
# 原因: gRPC設定の不整合
# 解決: application.yml のgrpc設定確認
=================================================================
# Nguyên nhân: cấu hình gRPC không khớp
# Giải pháp: xác nhận lại config grpc trong application.yml

grpc:
  server:
    port: [使用していないポート番号] | Số port chưa sử dụng
```

---

## 📊 移行工数見積もりガイドライン | Guiline của estimate công số cho migration

### サービス規模による分類 | Phân loại theo quy mô service
- **小規模** (10-30クラス): 2-3日
- **中規模** (30-100クラス): 3-5日  
- **大規模** (100+クラス): 5-7日
======================================================
- **quy mô nhỏ:** 10-30 class: 2-3 ngày
- **quy mô vừa:** 30-100 class: 3-5 ngày
- **quy mô lớn:** >100 class: 5-7 ngày

### 使用機能による追加工数 | Công số bổ sung bởi chức năng đang sử dụng
- **gRPC使用**: +0.5日
- **HTTP API + JWT認証**: +1日
- **多数のMongoDB Repository**: +0.5日
- **カスタムフィルター・インターセプター**: +1日
=======================================================
- **sử dụng gRPC:** + 0.5 ngày
- **HTTP API và JWT Authen:** +1 ngày
- **Nhiều MongoDB Repository:** +0.5 ngày
- **Custom filters / interceptors:** +1 ngày

### サービス種別による追加考慮 | Lưu ý thêm theo loại dịch vụ
- **HTTP API サービス**: JWT Resource Server設定が必要
- **gRPCサービス**: OAuth2設定不要、基本Spring Security設定のみ
=======================================================
- **HTTP API services:** cần cấu hình JWT Resource Server
- **gRPC services: không** cần OAuth2 config, chỉ cấu hình Spring Security cơ bản
---

## 🎯 成功のポイント | Điểm thành công

1. **service-registrationパターンの踏襲**: 実績のある手順を基本とする
2. **サービス種別の理解**: HTTP API サービス vs gRPCサービスの認証方式の違いを把握
3. **段階的アプローチ**: Phase毎に確実に進める
4. **自動化の活用**: 一括置換スクリプトを積極的に使用
5. **lib-*ライブラリの事前準備**: 依存関係を事前にビルドしておく
6. **継続的検証**: コンパイル→テスト→起動の順で各段階を確認
7. **機能別の確認**: 使用している機能に応じた動作確認を実施
====================================================================================
1. **Kế thừa pattern service-registration:** dùng quy trình đã có
2. **Hiểu rõ loại service:** nắm được sự khác biệt của phương thức xác thực của HTTP API vs gRPC
3. **Tiếp cận theo giai đoạn:** tiến hành chắc chắn theo Phase
4. **Tận dụng tự động hoá:** tích cực dùng scripts thay thế hàng loạt
5. **Chuẩn bị kỹ việc build sẵn lib-*:** buil sẵn các mối quan hệ phụ thuộc
6. **Kiểm chứng liên tục:** xác nhận lại xem có đúng thứ tự: compile → test → run ở các bước
7. **Kiểm tra theo chức năng:** thực hiện kiểm thử các hoạt động theo các chức năng thực tế đang dùng

## ⚠️ 重要な注意事項 | Lưu ý quan trọng

**認証設定の区別:** | Phân biệt cấu hình authentication:
- **HTTP API サービス**: JWT Resource Server設定が必要
- **gRPCサービス**: OAuth2設定は不要、gRPC認証インターセプターを使用
================================================================
- **HTTP API service:** cần JWT Resource Server config
- **gRPC services:** không cần OAuth2 config, dùng gRPC interceptor

このガイドに従うことで、service-registrationと同様の効率的な移行が可能です。各サービスの特性とアーキテクチャに応じて、適切な認証方式を選択して実施してください。
Bằng cách tuân theo hướng dẫn này, bạn có thể thực hiện việc chuyển đổi một cách hiệu quả tương tự như service-registration. Hãy lựa chọn và áp dụng phương thức xác thực phù hợp với đặc điểm và kiến trúc của từng dịch vụ.