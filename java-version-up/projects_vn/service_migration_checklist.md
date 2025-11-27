# サービス移行チェックリスト & トラブルシューティング | checklist của việc migrate service & Troubleshooting

## 📋 移行作業チェックリスト | Checklist công việc migrate

### 事前確認 | Xác nhận trước
- [ ] 移行対象サービスの特定
- [ ] 現在の技術スタック確認 (Spring Boot バージョン、Java バージョン)
- [ ] service-framework 使用機能の特定
- [ ] lib-* ライブラリの事前ビルド完了
===========================================================================
- [ ] Xác định service cần di chuyển
- [ ] Kiểm tra stack kỹ thuật hiện tại (phiên bản Spring Boot, phiên bản Java)
- [ ] Xác định các chức năng sử dụng của service-framework
- [ ] Hoàn tất việc build các thư viện lib-*

### Phase 1: 環境準備 | Chuẩn bị môi trường
- [ ] feature/renew_framework ブランチ作成
- [ ] 依存関係分析 (`mvn dependency:tree`)
- [ ] framework使用箇所分析 (`grep -r "jp.drjoy.service.framework"`)
===========================================================================
- [ ] Tạo branch cho feature/renew_framework
- [ ] Phân tích mối quan hệ phụ thuộc (`mvn dependency:tree`)
- [ ] Phân tích vị trí sử dụng framework (`grep -r "jp.drjoy.service.framework"`)

### Phase 2: pom.xml 更新 | Update pom.xml
- [ ] Spring Boot バージョン → 3.2.0
- [ ] Java バージョン → 17
- [ ] service-framework 依存関係削除
- [ ] lib-common-utils 追加
- [ ] lib-common-models 追加
- [ ] 機能別lib-* ライブラリ追加:
  - [ ] lib-spring-boot-starter-web (Web機能使用時)
  - [ ] lib-spring-boot-starter-security (認証機能使用時)
  - [ ] lib-spring-boot-starter-mongodb (MongoDB使用時)
  - [ ] lib-spring-boot-starter-grpc (gRPC使用時)
  - [ ] lib-spring-boot-starter-masterdata (マスターデータ使用時)
- [ ] Maven プラグインバージョン更新
===========================================================================
- [ ] Spring Boot version → 3.2.0
- [ ] Java version → 17
- [ ] Xóa bỏ mối quan hệ phụ thuộc của service-framework
- [ ] Thêm lib-common-utils
- [ ] Thêm lib-common-models
- [ ] Thêm thư viện lib-* theo từng chức năng:
  - [ ] lib-spring-boot-starter-web (khi sử dụng chức năng Web)
  - [ ] lib-spring-boot-starter-security (khi sử dụng chức năng xác thực)
  - [ ] lib-spring-boot-starter-mongodb (khi sử dụng MongoDB)
  - [ ] lib-spring-boot-starter-grpc (khi sử dụng gRPC)
  - [ ] lib-spring-boot-starter-masterdata (khi sử dụng master data)
- [ ] Cập nhật phiên bản plugin của Maven

### Phase 3: コード修正 | Chỉnh sửa code
- [ ] javax → jakarta パッケージ一括置換実行
- [ ] service-framework import 一括置換実行
- [ ] Spring Security 6 対応:
  - [ ] WebSecurityConfigurerAdapter → SecurityFilterChain
  - [ ] authorizeRequests → authorizeHttpRequests
- [ ] MongoDB 設定更新:
  - [ ] AbstractMongoConfiguration → MongoClient Bean定義
- [ ] コンパイルエラー個別修正
===========================================================================
- [ ] Thay thế đồng loạt package javax → jakarta
- [ ] Thay thế đồng loạt import  service-framework
- [ ] Hỗ trợ Spring Security 6:
  - [ ] WebSecurityConfigurerAdapter → SecurityFilterChain
  - [ ] authorizeRequests → authorizeHttpRequests
- [ ] Cập nhật cấu hình MongoDB:
  - [ ] AbstractMongoConfiguration → định nghĩa Bean MongoClient
- [ ] Sửa lỗi compile riêng lẻ

### Phase 4: 設定ファイル更新 lẻUpdate file config
- [ ] application.yml Spring Boot 3 対応
- [ ] gRPC設定追加 (gRPC使用時)
- [ ] 認証設定 (サービス種別による):
  - [ ] **HTTP API サービス**: JWT Resource Server設定
  - [ ] **gRPCサービス**: 基本設定のみ (OAuth2設定不要)
- [ ] 環境別設定確認
===========================================================================
- [ ] Cập nhật application.yml cho Spring Boot 3
- [ ] Thêm cấu hình gRPC (khi sử dụng gRPC)
- [ ] Cài đặt xác thực (tùy loại dịch vụ):
  - [ ] HTTP API Service: config JWT Resource Server
  - [ ] gRPC Service: chỉ cần config cơ bản (không cần config OAuth2)
- [ ] Kiểm tra cấu hình các môi trường

### Phase 5: テスト・検証 | Test/Kiểm thử
- [ ] `mvn clean compile` 成功
- [ ] `mvn clean test` 成功
- [ ] `mvn spring-boot:run` 起動成功
- [ ] 機能別動作確認:
  - [ ] **HTTP API サービス**: Web API 応答・JWT認証確認
  - [ ] **gRPCサービス**: gRPC 通信・認証インターセプター確認
  - [ ] **MongoDB使用時**: 接続・リポジトリ動作確認
===========================================================================
- [ ] `mvn clean compile` thành công
- [ ] `mvn clean test` thành công
- [ ] `mvn spring-boot:run` khởi động thành công
- [ ] Kiểm tra hoạt động theo chức năng:
  - [ ] HTTP API Service: xác nhận phản hồi Web API & xác thực JWT
  - [ ] gRPC Service: xác minh giao tiếp gRPC & interceptor xác thực
  - [ ] Lúc sử dụng MongoDB: kiểm tra kết nối & hoạt động repository

### Phase 6: 統合確認 | Xác nhận tổng hợp
- [ ] 他サービスとの連携確認
- [ ] 認証連携確認 (サービス種別による):
  - [ ] **HTTP API サービス**: service-securityかservice-oauth2-serverとのJWT連携
  - [ ] **gRPCサービス**: gRPC認証インターセプター連携
- [ ] パフォーマンステスト実施
===========================================================================
- [ ] Kiểm tra liên kết với các dịch vụ khác
- [ ] Kiểm tra liên kết xác thực (tùy loại dịch vụ):
  - [ ] HTTP API Service: xác minh liên kết JWT với service-security hoặc service-oauth2-server
  - [ ] gRPC Service: xác minh liên kết gRPC interceptor
- [ ] Thực hiện kiểm thử perfomance
---

## 🔥 トラブルシューティングガイド | Hướng dẫn troubleshooting
### コンパイルエラー  | Lỗi Compile

#### 1. `javax.*` パッケージが見つからない  | Không tìm thấy package `javax.*`
```
エラー例: cannot find symbol javax.persistence.Entity
Ví dụ lỗi: cannot find symbol javax.persistence.Entity
```
**原因**: javax → jakarta 置換漏れ  | Nguyên nhân bỏ sót thay thế từ javax sang jakarta
**解決方法**: | Cách khắc phục:
```bash
# 残存箇所を特定 |  Tìm nơi còn sót
find src/ -name "*.java" -exec grep -l "javax\." {} \;

# 手動で修正するか、追加の置換実行 | Sửa thủ công hoặc chạy thay thế thêm 
sed -i 's/javax\.annotation\./jakarta.annotation./g' [対象ファイル]
```

#### 2. service-framework クラスが見つからない | Không tìm thấy class trong service-framework
```
エラー例: cannot find symbol jp.drjoy.service.framework.*
Ví dụ lỗi: cannot find symbol jp.drjoy.service.framework.*
```
**原因**: import 文の置換漏れまたは新ライブラリに未移植の機能使用  | Nguyên nhân: Bỏ sót import hoặc dùng chức năng chưa được chuyển sang thư viện mới
**解決方法**: | Cách khắc phục: 
```bash
# 残存箇所を特定 | Xác định chỗ sót
grep -r "jp.drjoy.service.framework" src/

# 対応するlib-*ライブラリのクラスに置換 | Thay sang class của thư viện lib-* tương ứng
# 例: jp.drjoy.service.framework.utils.Strings → jp.drjoy.lib.utils.Strings | Ví dụ: jp.drjoy.service.framework.utils.Strings → jp.drjoy.lib.utils.Strings
```

#### 3. Spring Security関連エラー | Lỗi liên quan đến Spring Security
```
エラー例: cannot find symbol WebSecurityConfigurerAdapter
Ví dụ lỗi: cannot find symbol WebSecurityConfigurerAdapter
```
**原因**: Spring Security 6 で削除されたクラス使用   | Nguyên nhân: dùng class đã bị xóa trong Spring Security 6
**解決方法**: | Cách khắc phục:
```java
// 更新前 | Trước update
public class SecurityConfig extends WebSecurityConfigurerAdapter {
  @Override
  protected void configure(HttpSecurity http) throws Exception {
    // 設定 | config
  }
}

// 更新後 | Sau update 
@Configuration
public class SecurityConfig {
  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    // 設定を return http.build(); で終了 |  Kết thúc config bằng return http.build();
    return http.build();
  }
}
```

#### 4. MongoDB設定エラー | Lỗi config MongoDB
```
エラー例: cannot find symbol AbstractMongoConfiguration
Ví dụ lỗi : cannot find symbol AbstractMongoConfiguration
```
**原因**: 非推奨クラス使用  | Nguyên nhân: sử dụng class không khuyến nghị
**解決方法**: | Cách khắc phục:
```java
// 更新前 | Trước update
@Configuration
public class MongoConfig extends AbstractMongoConfiguration {
  // 複雑な設定 | Config phức tạp
}

// 更新後 | Sau Update
@Configuration
public class MongoConfig {
  @Bean
  public MongoClient mongoClient() {
    return MongoClients.create("mongodb://localhost:27017");
  }
}
```

### 依存関係エラー | Lỗi quan hệ phụ thuộc 

#### 5. lib-* ライブラリが見つからない | Không tìm thấy thư viện lib-*
```
エラー例: Could not find artifact jp.drjoy:lib-common-utils
Ví dụ lỗi: Could not find artifact jp.drjoy:lib-common-utils
```
**原因**: lib-*ライブラリが未ビルドまたはバージョン不一致   | Nguyên nhân: Thư viện lib-* chưa được build hoặc sai version
**解決方法**: | Cách khắc phục:
```bash
# 全lib-*ライブラリを事前ビルド | Build trước toàn bộ thư viện lib-* 
./scripts/build-libs.sh

# または個別ビルド | Hoặc build riêng 
cd work/lib-common-utils && mvn clean install
cd work/lib-common-models && mvn clean install
# 他のlib-*も同様 |  các thư viện lib-* khác cũng tương tự
```

#### 6. バージョン競合エラー | Lỗi xung đột version
```
エラー例: Dependency convergence error
Ví dụ lỗi: Dependency convergence error
```
**原因**: Spring Boot 3 と古い依存関係の競合   | Nguyên nhân: Spring Boot 3 xung đột với mối quan hệ phụ thuộc cũ
**解決方法**: | Cách khắc phục:
```xml
<!-- pom.xml で明示的にバージョン指定 --> | Chỉ định version rõ ràng bằng pom.xml
<properties>
  <spring-boot.version>3.2.0</spring-boot.version>
</properties>

<!-- または dependencyManagement で管理 --> | Và quản lý bằng dependencyManagement
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

### 実行時エラー | Lỗi lúc chạy

#### 7. アプリケーション起動失敗 | Ứng dụng khởi động thất bại
```
エラー例: Failed to configure a DataSource
Ví dụ lỗi: Failed to configure a DataSource
```
**原因**: 設定ファイルの Spring Boot 3 非互換   | Nguyên nhân: cấu hình không tương thích với Spring Boot 3
**解決方法**: | Cách khắc phục:
```yaml
# application.yml 確認・修正 | Xác nhận/Sửa application.yml
spring:
  application:
    name: [SERVICE_NAME]
  data:
    mongodb:
      uri: mongodb://localhost:27017/[DATABASE_NAME]
```

#### 8. gRPC サーバー起動失敗 | Server gRPC khởi động thất bại
```
エラー例: Port already in use: 9091
Ví dụ lỗi: Port already in use: 9091
```
**原因**: ポート競合またはgRPC設定不正   | Nguyên nhân: trùng port hoặc config sai
**解決方法**: | Cách khắc phục:
```bash
# ポート使用状況確認 | Xác nhận tình trạng sử dụng của port
netstat -tulpn | grep 9091

# 別ポートに変更 | Đổi sang port khác
# application.yml
grpc:
  server:
    port: 9092  # 使用可能なポート | Port có thể sử dụng
```

#### 9. 認証エラー (サービス種別による) | Lỗi xác thực (tùy loại dịch vụ)

**HTTP API サービスの場合:** | Trường hợp HTTP API Service
```
エラー例: 401 Unauthorized / JWT validation error
Ví dụ lỗi: 401 Unauthorized / JWT validation error
```
**原因**: JWT Resource Server設定不正または認証サーバー未起動   | Nguyên nhân: Server xác thực chưa khởi động hoặc config của JWT Resource Server chưa đúng 
**解決方法**: | Cách khắc phục:
```yaml
# application.yml でJWT設定確認 | Xác nhận config JWT bằng application.yml
service:
  oauth2:
    secret-public: secret/oauth2.pub  # 公開鍵ファイルのパス確認 | Xác nhận path của file public key
    resource-id: demo
```

**gRPCサービスの場合:** | Trường hợp gRPC service
```
エラー例: PERMISSION_DENIED (gRPC Status)
Ví dụ lỗi: PERMISSION_DENIED (gRPC Status)
```
**原因**: gRPC認証インターセプターの認証失敗   | Nguyên nhân: Xác thực của gRPC Authentication Interceptor bị thất bại 
**解決方法**: | Cách khắc phục:
```bash
# gRPCクライアントが適切な認証トークンを送信しているか確認 | Xác nhận xem gRPC Client có gửi token xác thực đúng không
# GrpcAuthServerInterceptorの設定確認 | Xác nhận config của GrpcAuthServerInterceptor
```

#### 10. MongoDB 接続エラー | Lỗi kết nối MongoDB
```
エラー例: Connection refused to MongoDB
Ví dụ lỗi: Connection refused to MongoDB
```
**原因**: MongoDB 未起動またはURI設定不正  |  Nguyên nhân: MongoDB chưa khởi động hoặc config của URI sai
**解決方法**: | Cách khắc phục:
```bash
# MongoDB 起動確認 | Xác nhận MongoDB khởi động chưa
sudo systemctl status mongod

# 接続文字列確認 | Xác nhận Connection String
# application.yml
spring:
  data:
    mongodb:
      uri: mongodb://localhost:27017/[正しいDB名]
```

### テストエラー | Lỗi test

#### 11. 単体テスト失敗 | Lỗi Unit Test
```
エラー例: NoSuchMethodError in test
Ví dụ lỗi: NoSuchMethodError in test
```
**原因**: テストコードの Spring Boot 3 非互換   | Nguyên nhân: code test không tương thích với Spring Boot 3
**解決方法**: | Cách khắc phục:
```java
// 更新前 | Trước update
@SpringBootTest
@TestPropertySource(locations = "classpath:application-test.yml")

// 更新後 | Sau update
@SpringBootTest
@TestPropertySource(properties = {
  "spring.test.database.replace=none"
})
```

#### 12. MockMvc テストエラー | Lỗi test MockMvc
```
エラー例: IllegalArgumentException in MockMvc
Ví dụ lỗi: IllegalArgumentException in MockMvc
```
**原因**: Spring Security 6 のテスト方式変更   | Nguyên nhân: thay đổi phương thức test trong Spring Security 6
**解決方法**: | Cách khắc phục:
```java
// 更新前 | Trước update
@Test
@WithMockUser
public void testEndpoint() throws Exception {
  mockMvc.perform(get("/api/test"))
    .andExpect(status().isOk());
}

// 更新後 (必要に応じて@MockBean等でSecurityを無効化) | Sau update (Vô hiệu hóa Security bằng @MockBean nếu cần)
@Test
@WithMockUser
@MockBean(SecurityFilterChain.class)
public void testEndpoint() throws Exception {
  // テスト実装 | Triển khai test
}
```

---

## 🚨 エマージェンシー対応 | Xử lý khẩn cấp

### ロールバック手順 | Quy trình rollback

移行作業中に重大な問題が発生した場合: | Trường hợp có vấn đề lớn trong quá trình migrate

```bash
# 1. 作業ブランチから元ブランチに戻る | Từ branch đang làm quay lại branch cũ
git checkout develop

# 2. 作業ブランチを削除 (必要に応じて) | Xóa Branch đang làm (nếu cần)
git branch -D feature/renew_framework

# 3. または特定のコミットに戻す | Hoặc revert một commit cụ thể
git reset --hard [前のコミットハッシュ] | Commit hash trước

# 4. 強制プッシュ (慎重に実行) | force push (thực hiện thận trọng)
git push origin develop --force
```

### 段階的復旧 | Khôi phục theo từng giai đoạn
一部機能のみ問題がある場合: | Trường hợp chỉ có vấn đề ở 1 số chức năng

```bash
# 1. 問題のあるファイルのみ元に戻す | Revert riêng file có vấn đề 
git checkout HEAD~1 -- [問題のファイルパス] | path của file có vấn đề

# 2. 段階的にコミットを戻す | Revert commit theo từng giai đoạn
git revert [問題のコミットハッシュ] | commit hash của vấn đề

# 3. 個別の設定を一時的に無効化 | Tạm thời vô hiệu hóa cài đặt riêng lẻ 
# application.yml で問題のある設定をコメントアウト | Comment phần cấu hình có vấn đề trong file application.yml
```

---

---

## ⚠️ 重要な注意事項 | Đầu mục quan trọng cần chú ý

### 認証アーキテクチャの理解 | Hiểu rõ kiến trúc xác thực

**HTTP API サービス (service-web-front, service-admin等):** | HTTP API Service (service-web-front, service-admin, v.v.):
- JWT Tokenを使用した認証・認可が必要
- service-oauth2-server または service-security からJWTを取得し、各リクエストで検証
- JWT Resource Server設定が必須
================================================================================
- Cần xác thực và phân quyền bằng JWT Token
- Lấy JWT từ service-oauth2-server hoặc service-security, rồi kiểm thử bằng các request
- Bắt buộc cấu hình JWT Resource Server

**gRPCサービス (service-registration等):** 
- 独自のgRPC認証メカニズムを使用
- GrpcAuthServerInterceptorで認証処理
- **OAuth2クライアント設定は不要**
================================================================================
- Dùng cơ chế xác thực gRPC riêng
- Xử lý xác thực qua GrpcAuthServerInterceptor
- Không cần cấu hình OAuth2 Client

### 移行時のチェックポイント | Điểm cần kiểm tra khi di chuyển
1. サービスのアーキテクチャを最初に特定する
2. HTTP API エンドポイントの有無を確認する
3. 適切な認証方式を選択して設定する
================================================================================
1. Xác định kiến trúc của service trước
2. Kiểm tra có endpoint HTTP API hay không
3. Chọn và cấu hình phương thức xác thực phù hợp

## 📞 サポート情報 | Thông tin hỗ trợ

### 相談先 
- **技術的問題**: 開発チームリーダー 
- **lib-* ライブラリ問題**: フレームワーク担当者 
- **認証アーキテクチャ**: 認証基盤チーム 
===============================================================================
### Đầu mối liên hệ
  - **Vấn đề kỹ thuật:** Leader nhóm phát triển
  - **Vấn đề thư viện lib-*:** Người phụ trách framework
  - **Kiến trúc xác thực:** Nhóm nền tảng xác thực

### 参考資料 | Tài liệu tham khảo
- `projects/renew-backend-framework/detailed_plan.md` - 詳細移行計画
- `service-registration` 移行実績 - gRPCサービスの実践例
- Spring Boot 3 Migration Guide - 公式ドキュメント
- Spring Security 6 Migration Guide - 認証関連
================================================================================
- `projects/renew-backend-framework/detailed_plan.md` – Kế hoạch di chuyển chi tiết
- `service-registration` kinh nghiệm migrate – ví dụ thực tế của gRPC service 
- Spring Boot 3 Migration Guide – tài liệu chính thức
- Spring Security 6 Migration Guide – tài liệu xác thực


### ログ確認場所 | Nơi kiểm tra log
- アプリケーションログ: `logs/application.log`
- gRPCログ: `logs/grpc.log`
- Spring Bootログ: コンソール出力
- JWT認証ログ: Spring Security デバッグログ
================================================================================
- Log App: `logs/application.log`
- Log gRPC: `logs/grpc.log`
- Log Spring Boot: xuất ra console
- Log JWT xác thực: log debug của Spring Security