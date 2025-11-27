# OAuth2サーバー近代化 移行計画書 | OAuth2 Server Hiện Đại Hóa - Kế Hoạch Di Chuyển

## 📋 プロジェクト概要 | Tổng Quan Dự Án

**Dr.JOY バックエンドフレームワーク近代化プロジェクト** | Project Hiện Đại Hóa Framework Backend của Dr.Joy

現行 `service-oauth2-server` と `service-framework` を JDK 17 / Spring Boot 3 ベースの新しいアーキテクチャに段階的に移行するプロジェクト。
Đây là dự án nhằm migrate dần dần `service-oauth2-server` và `service-framework` sang kiến trúc mới dựa trên JDK 17 / Spring Boot 3.

### 🎯 **目標** | Mục Tiêu
- **技術的負債解消**: 古い技術スタックとモノリシックな構造の刷新 | Xóa bỏ nợ kỹ thuật: Làm mới lại công nghệ cũ và cấu trúc monolithic
- **マイクロサービス化**: 責務分離と独立性の向上  | Microservice hóa: Tăng tính phân tách trách nhiệm và độc lập
- **運用性向上**: 動的設定管理とデプロイの柔軟化 | Cải thiện vận hành: Quản lý cấu hình động và linh hoạt trong deploy
- **保守性向上**: テスト可能で拡張しやすい設計 | Tăng khả năng bảo trì: Dễ kiểm thử, dễ mở rộng

### 📊 **現在の進捗状況** (95%完了) | Tiến Độ Hiện Tại (hoàn thành 95%)
- ✅ **フェーズ1**: lib-*ライブラリ群 → **完成** | Phase 1: Nhóm thư viện lib-* → Hoàn thành
- ✅ **フェーズ2**: service-security → **95%完成** | Phase 2: service-security → Hoàn thành 95%
- 🔄 **フェーズ3**: service-registration移行 → **95%完成** | Phase 3: Di chuyển service-registration → Hoàn thành 95%
- ⏳ **フェーズ4**: 他サービス移行 → **準備中** | Phase 4: Di chuyển các service khác → Đang chuẩn bị

---

## 🏗️ 新アーキテクチャ | Kiến Trúc Mới

### **移行前 (現在)** | Trước Khi Di Chuyển (Hiện Tại)
```
service-oauth2-server (古い技術スタック)       | service-oauth2-server (stack kỹ thuật cũ)
           ↓                                            ↓
service-framework (モノリシック共通ライブラリ)  | service-framework (thư viện chung monolithic)
           ↓                                            ↓
各種サービス (JDK 1.8, Spring Boot 2.x)        | Các service khác (JDK 1.8, Spring Boot 2.x)
```

### **移行後 (目標)** | Sau Khi Di Chuyển (Mục Tiêu)
```
service-security (JDK 17, Spring Boot 3) 
           ↓
lib-*ライブラリ群 (責務分離) | Tập hợp thư viện lib-* (phân tách trách nhiệm)
├── lib-spring-boot-starter-grpc
├── lib-spring-boot-starter-security  
├── lib-spring-boot-starter-mongodb
├── lib-spring-boot-starter-masterdata
├── lib-spring-boot-starter-web
├── lib-common-models
└── lib-common-utils
           ↓
各種サービス (JDK 17, Spring Boot 3) | Các service khác (JDK 17, Spring Boot 3)
```

---

## 📚 ドキュメント一覧 | Danh Sách Tài Liệu

| ドキュメント | 説明 | 状態 | 
|------------|------|------|
| **[詳細タスクリスト](detailed_plan.md)** | フェーズ別の具体的作業内容 | ✅ 最新 |
| **[設計書](architecture.md)** | 技術アーキテクチャの詳細設計 | ✅ 最新 |
| **[lib-*進捗レポート](lib_projects_progress_report.md)** | ライブラリ群の実装状況 | ✅ 完成 |
| **[サービス移行ガイド](service_migration_guide.md)** | 各サービスの移行手順 | ✅ 運用中 |
| **[サービス移行チェックリスト](service_migration_checklist.md)** | 移行時の確認事項 | ✅ 運用中 |
| **[masterdata同期ガイド](service-framework-masterdata-sync-guide.md)** | 権限データ同期手順 | ✅ 運用中 |
| **[MongoDB配置戦略](masterdata-deployment-strategy.md)** | masterdataの配置方針 | ✅ 最新 |
| **[工数見積もり](estimate.md)** | プロジェクト工数とスケジュール | 📝 参考 |
| **[ガントチャート](gantt-chart.md)** | プロジェクト進行計画 | 📝 参考 |
========================================================================================
|Tài Liệu                                                                 |	Giải Thích	                                  |Trạng Thái
|-------------------------------------------------------------------------|-----------------------------------------------|--------------
|Danh sách Task chi tiết: (detailed_plan.md)                              |Nội dung công việc chi tiết theo từng giai đoạn|Mới nhất
|Bản thiết kế: (architecture.md)                                          |Thiết kế chi tiết kiến trúc kỹ thuật           |Mới nhất
|Báo cáo tiến độ lib-*: (lib_projects_progress_report.md)                 |Tình hình triển khai các thư viện              |Hoàn thành
|Hướng dẫn migrate service: (service_migration_guide.md)                  |Hướng dẫn migrate từng service                 |Đang sử dụng
|CheckList migrate service: (service_migration_checklist.md)              |Các mục cần kiểm tra khi migrate               |Đang sử dụng
|Hướng dẫn sync masterdata: (service-framework-masterdata-sync-guide.md)  |Hướng dẫn đồng bộ dữ liệu quyền hạn            |Đang sử dụng
|Chiến lược bố trí MongoDB: (masterdata-deployment-strategy.md)           |Chính sách bố trí masterdata                   |Mới nhất
|Estimate công số: (estimate.md)                                          |Công số project và Schedule                    |Tham khảo
|Gannt Chart: (gantt-chart.md)                                            |Kế hoạch tiến hành Project                     |Tham khảo

### 🛠️ **運用ツール** | Công Cụ Vận Hành
| スクリプト | 用途 |
|-----------|------|
| **[scripts/build-libs.sh](scripts/build-libs.sh)** | lib-*ライブラリの一括ビルド |
| **[scripts/sync-roles-to-mongodb.sh](scripts/sync-roles-to-mongodb.sh)** | service-framework→MongoDB権限同期 |
| **[scripts/dev-setup.sh](scripts/dev-setup.sh)** | 開発環境セットアップ |
| **[scripts/health-check.sh](scripts/health-check.sh)** | サービスヘルスチェック |
========================================================================================================
|Script                                                                | Mục Đích
|----------------------------------------------------------------------|------------------------------------------
|[scripts/build-libs.sh](scripts/build-libs.sh)                        |Build toàn bộ thư viện lib-*
|[scripts/sync-roles-to-mongodb.sh](scripts/sync-roles-to-mongodb.sh)  |Đồng bộ quyền từ service-framework → MongoDB
|[scripts/dev-setup.sh](scripts/dev-setup.sh)                          |Thiết lập môi trường phát triển
|[scripts/health-check.sh](scripts/health-check.sh)                    |Kiểm tra tình trạng service


---

## 🚀 クイックスタート | Quick Start

### **開発環境構築** | Thiết Lập Môi Trường Phát Triển
```bash
# 1. 全体セットアップ | Thiết lập toàn bộ môi trường
./scripts/dev-setup.sh

# 2. lib-*ライブラリビルド  | Build thư viện lib-*  
./scripts/build-libs.sh

# 3. service-securityビルド | Build service-security
cd ../work/service-security
mvn clean install

# 4. ヘルスチェック | Kiểm tra trạng thái
./scripts/health-check.sh
```

### **service-registration移行作業** | Công Việc Di Chuyển service-registration
```bash
# 現在95%完了 - 最終確認作業 | Hiện tại hoàn thành 95% - Công việc xác nhận cuối cùng
cd ../work/service-registration
mvn clean test  # テスト実行 | Thực hiện test
mvn spring-boot:run  # 動作確認 | Kiểm tra hoạt động
```

---

## 📋 移行フェーズ詳細 | Chi Tiết Từng Giai Đoạn Migrate

### ✅ **フェーズ1: service-framework分割** (完成) | Phase 1: Tách service-framework (Hoàn thành)

**作業内容**: モノリシックなservice-frameworkを7個のライブラリに分割 | Nội dung công việc: Tách service-framework dạng monolithic thành 7 thư viện độc lập
- `lib-spring-boot-starter-grpc` - gRPC機能 | Chức năng gRPC
- `lib-spring-boot-starter-security` - セキュリティ機能  | Chức năng bảo mật
- `lib-spring-boot-starter-mongodb` - MongoDB機能 | Chức năng MongoDB
- `lib-spring-boot-starter-masterdata` - マスターデータ管理 | Quản lý masterdata
- `lib-spring-boot-starter-web` - Web機能 | Chức năng web
- `lib-common-models` - 共通データモデル | model data chung
- `lib-common-utils` - 汎用ユーティリティ | utility dùng chung

**成果**: | Kết Quả:
- ✅ 全7ライブラリ実装完了 | Hoàn thành 7 thư viện
- ✅ Spring Boot 3.2.0 / JDK 17対応 | Hỗ trợ Spring Boot 3.2.0 / JDK 17
- ✅ 包括的なテストスイート | Bộ test tổng hợp đầy đủ
- ✅ CI/CD統合 | Tích hợp CI/CD

### ✅ **フェーズ2: service-security開発** (95%完了) | Phase 2: Phát Triển service-security (Hoàn thành 95%)

**作業内容**: Spring Authorization Serverベースの新OAuth2サーバー | Nội dung công việc: Xây dựng OAuth2 server mới dựa trên Spring Authorization Server
- 11種類のカスタム認証プロバイダー実装 | Triển khai 11 loại custom authentication provider
- JWT署名・トークンカスタマイザー | JWT signer và token customizer
- Firebase/証明書API統合 | Tích hợp Firebase / chứng chỉ API
- gRPCサービス実装 | Triển khai gRPC service

**成果**: | Thành quả:
- ✅ 78ファイル・コア機能実装完了 | 78file ・Hoàn thành triển khai chức năng core 
- ✅ 認証プロバイダー群実装完了 | Hoàn thành triển khai cụm provider xác thực
- ✅ 各種APIエンドポイント実装完了 | Hoàn thành triển khai các loại API endpoint
- 🔄 最終統合テスト中 | Đang chạy test tích hợp cuối

### 🔄 **フェーズ3: service-registration移行** (95%完了) | Phase 3: Migrate service-registration (Hoàn thành 95%)

**作業内容**: モデルケースとしてservice-registrationを新ライブラリに移行 | Nội dung công việc: Migrate service-registration sang thư viện mới để làm mẫu
- Spring Boot 2.x → 3.2.0
- JDK 1.8 → 17
- service-framework → lib-*置換 | Thay thế service-framework → lib-*

**現状**: | Hiện Trạng:
- ✅ pom.xml更新完了 | Cập nhật pom.xml xong
- ✅ javax→jakarta変換完了  | Chuyển đổi javax → jakarta xong
- ✅ 95%のコード移行完了 | 95% code đã migrate
- 🔄 残存2ファイルの最終調整 | Còn 2 file đang điều chỉnh
- 🔄 OAuth2設定追加 | Thêm cấu hình OAuth2

### ⏳ **フェーズ4: 他サービス展開** (準備中) | Phase 4: Mở Rộng Sang Các Service Khác (Đang Chuẩn Bị)

**対象サービス**: `service-admin`, `service-web-front`, などすべてのバックエンドサービス | Các Service Mục Tiêu: service-admin, service-web-front, và các backend service khác
**戦略**: service-registrationの知見を活用して順次展開 | Chiến Lược: Tận dụng kinh nghiệm từ service-registration để triển khai dần

並行して service-security の切り替えを実施する | Thực hiện chuyển đổi service-security song song

-------

## ⚠️ 重要な運用ポイント | Điểm Quan Trọng Khi Vận Hành

### **🔄 並行運用期間の注意事項** | Lưu Ý Trong Thời Gian Vận Hành Song Song
- service-frameworkとlib-*は当面並行運用
- 権限変更時は[同期ガイド](service-framework-masterdata-sync-guide.md)に従って両方を更新 
- MongoDB配置は[配置戦略](masterdata-deployment-strategy.md)に従い各サービスDBに複製 
================================================================================
- service-framework và lib-* sẽ chạy song song một thời gian
- Khi thay đổi quyền hạn, cần cập nhật cả hai theo hướng dẫn [sync guide](service-framework-masterdata-sync-guide.md)
- Về bố trí MongoDB thì sẽ theo [chiến lược bố trí](masterdata-deployment-strategy.md) để sao chép vào DB của các service

### **🛡️ ロールバック戦略** | Chiến Lược Rollback
- 各フェーズでバックアップ取得
- feature/renew_frameworkブランチでの作業
- 段階的切り替えによるリスク最小化
==============================================================================
- Lưu backup ở mỗi giai đoạn
- Thực hiện trên branch feature/renew_framework
- Chuyển đổi dần từng phần để giảm rủi ro
--------

## 🔧 トラブルシューティング | Troubleshooting

### **よくある問題** | Các vấn đề thường gặp
1. **lib-*ライブラリが見つからない**: `./scripts/build-libs.sh`を実行
2. **権限エラー**: 同期スクリプトでmasterdataを更新
3. **起動エラー**: JDK 17・Spring Boot 3の設定を確認
=============================================================================
1. **Không tìm thấy lib-*:** Chạy ./scripts/build-libs.sh
2. **Lỗi quyền hạn:** Cập nhật masterdata bằng script đồng bộ
3. **Lỗi khởi động**: Kiểm tra thiết lập JDK 17 / Spring Boot 3

### **サポート** | Support
- 詳細は各ドキュメントを参照
- 緊急時はロールバック手順を実行
==============================================
- Chi tiết trong các tài liệu liên quan
- Khi khẩn cấp, thực hiện quy trình rollback

---

*💡 より詳細な情報は、上記ドキュメント一覧から該当するドキュメントをご参照ください。*
Để biết thêm thông tin chi tiết, vui lòng tham khảo các tài liệu trong danh sách trên.
