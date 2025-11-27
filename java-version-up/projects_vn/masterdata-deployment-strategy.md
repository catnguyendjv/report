# Masterdata MongoDB デプロイメント戦略 | Chiến lược triển khai Masterdata MongoDB

## 現状の理解 | Hiểu hiện trạng
- 各サービスは独自のMongoDBデータベースを使用
- マスターデータ（ロール、権限）は全サービスで共通参照が必要
- lib-spring-boot-starter-masterdataは各サービスに組み込まれる
=====================================================================
- Các service hiện đang sử dụng MongoDB riêng
- Master data (roles, authorities) cần được tham chiếu chung giữa tất cả các service
- lib-spring-boot-starter-masterdata được nhúng trong từng service
## デプロイメントオプション分析 | Phân tích các option triển khai

### オプション1: 共通MongoDB（中央集約型）❌ 非推奨 | Option 1: MongoDB dùng chung (kiểu tập trung) ❌ Không khuyến khích

```
┌─────────────────────────────────────┐
│     共通MongoDB (masterdata)        │
│  ┌──────────────────────────────┐   │
│  │ roles / authorities / master │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
           ↑        ↑        ↑
      service-A  service-B  service-C
      (独自DB)   (独自DB)   (独自DB)

=============================================

┌─────────────────────────────────────┐
│     MongoDB chung (masterdata)      │
│  ┌──────────────────────────────┐   │
│  │ roles / authorities / master │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
           ↑        ↑        ↑
      service-A  service-B  service-C
      (DB riêng)   (DB riêng)   (DB riêng)

```

**メリット:** | Ưu điểm:
- 単一の真実の源（Single Source of Truth）
- 更新が即座に全サービスに反映
- データ管理が単純
=========================================
- Có Single Source of Truth (nguồn dữ liệu duy nhất).
- Cập nhật phản ánh ngay đến tất cả các service.
- Quản lý dữ liệu đơn giản.

**デメリット:** | Nhược điểm:
- 単一障害点（SPOF）のリスク
- ネットワーク遅延の影響
- 各サービスの独立性が損なわれる
- 既存のインフラ構成に大きな変更が必要
==========================================
- Rủi do điểm lỗi duy nhất (SPOF)
- Bị ảnh hưởng bởi network latency
- Mất tính độc lập của các service
- Cần thay đổi lớn trong hạ tầng hiện tại

### オプション2: 各サービスDBに複製（分散型）✅ 推奨 | Option 2: Sao chép vào DB của từng service (phân tán) ✅ Khuyến khích

```
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  service-A   │ │  service-B   │ │  service-C   │
│   MongoDB    │ │   MongoDB    │ │   MongoDB    │
│ ┌──────────┐ │ │ ┌──────────┐ │ │ ┌──────────┐ │
│ │ app data │ │ │ │ app data │ │ │ │ app data │ │
│ ├──────────┤ │ │ ├──────────┤ │ │ ├──────────┤ │
│ │masterdata│ │ │ │masterdata│ │ │ │masterdata│ │
│ └──────────┘ │ │ └──────────┘ │ │ └──────────┘ │
└──────────────┘ └──────────────┘ └──────────────┘
```

**メリット:** | Ưu điểm:
- 各サービスの独立性を維持
- 既存のインフラ構成を活用
- ネットワーク障害の影響を受けない
- パフォーマンスが良好（ローカルアクセス）
===========================================
- Giữ nguyên tính độc lập của từng service
- Tận dụng hạ tầng hiện có
- Không bị ảnh hưởng bởi sự cố mạng
- Hiệu năng cao (local access)

**デメリット:** | Nhược điểm:
- データ同期の仕組みが必要
- 一時的な不整合の可能性
===========================================
- Cần cơ chế đồng bộ dữ liệu
- Có khả năng không đồng nhất tạm thời giữa các service

### オプション3: ハイブリッド型（段階的移行）🎯 現実的 | Option 3: Kiểu hybrid (chuyển dần theo giai đoạn) 🎯 Thực tế nhất

```
Phase 1: 各DBに複製 + 同期スクリプト
Phase 2: イベント駆動の自動同期
Phase 3: 必要に応じて共通DB検討
==========================================
Phase 1: sao chép đến các DB + script đồng bộ
Phase 2: đồng bộ tự động dựa trên event
Phase 3: cân nhắc dùng DB chung nếu cần
```

## 推奨実装方法 | Phương án triển khai khuyến nghị

### 1. 初期セットアップ（各サービスDB） | Thiết lập ban đầu (DB của các service)

```yaml
# application.yml
spring:
  data:
    mongodb:
      uri: ${MONGODB_URI:mongodb://localhost:27017/service-a}
      # マスターデータは同じDBの別コレクション | master data thì ở cùng DB nhưng khác collection
      
masterdata:
  collections:
    roles: roles_master
    authorities: authorities_master
  sync:
    enabled: true
    source: ${MASTERDATA_SOURCE_URI:mongodb://masterdata-source/admin}
```

### 2. マスターデータ同期戦略 | Chiến lược đồng bộ master data

#### 2.1 初期投入スクリプト | Script khởi tạo ban đầu

```bash
#!/bin/bash
# deploy-masterdata.sh

MASTER_SOURCE="/path/to/masterdata.json"
SERVICES=("service-registration" "service-security" "service-admin")

for SERVICE in "${SERVICES[@]}"; do
    echo "Deploying masterdata to $SERVICE..."
    mongoimport --uri="mongodb://$SERVICE-mongodb:27017/$SERVICE" \
                --collection=roles_master \
                --file="$MASTER_SOURCE/roles.json" \
                --drop
done
```

#### 2.2 定期同期ジョブ | Job đồng bộ định kỳ

```java
@Component
@EnableScheduling
public class MasterDataSyncJob {
    
    @Value("${masterdata.sync.enabled:false}")
    private boolean syncEnabled;
    
    @Scheduled(cron = "${masterdata.sync.cron:0 0 * * * *}") // 毎時 | hàng giờ
    public void syncMasterData() {
        if (!syncEnabled) return;
        
        // 1. マスターソースから最新データ取得 | Lấy data mới nhất từ master source
        // 2. ローカルDBと比較                | So sánh với DB local
        // 3. 差分があれば更新                | Cập nhật nếu có khác biệt 
        // 4. キャッシュリフレッシュ          |Làm mới cache
    }
}
```

### 3. 実装の詳細修正 | Điều chỉnh chi tiết của bước triển khai

#### 3.1 lib-spring-boot-starter-masterdataの設定追加 | Bổ sung config cho lib-spring-boot-starter-masterdata

```java
@Configuration
@ConfigurationProperties(prefix = "masterdata")
public class MasterDataProperties {
    
    private String database = "local"; // local or shared
    private Map<String, String> collections = new HashMap<>();
    private SyncConfig sync = new SyncConfig();
    
    @Data
    public static class SyncConfig {
        private boolean enabled = false;
        private String sourceUri;
        private String cron = "0 0 * * * *";
    }
}
```

#### 3.2 MongoDBテンプレート設定 | Cấu hình MongoDB template

```java
@Configuration
public class MasterDataMongoConfig {
    
    @Bean
    @ConditionalOnProperty(name = "masterdata.database", havingValue = "local")
    public MongoTemplate masterDataMongoTemplate(MongoClient mongoClient, 
                                                  @Value("${spring.data.mongodb.database}") String database) {
        // 同じDBインスタンスを使用 | Dùng chung DB instance
        return new MongoTemplate(mongoClient, database);
    }
    
    @Bean
    @ConditionalOnProperty(name = "masterdata.database", havingValue = "shared")
    public MongoTemplate masterDataMongoTemplate(@Value("${masterdata.shared.uri}") String uri) {
        // 共通DBに接続（将来オプション）| kết nối với DB chung (option tương lai)
        MongoClient client = MongoClients.create(uri);
        return new MongoTemplate(client, "masterdata");
    }
}
```

### 4. デプロイメント手順 | Quy trình triển khai

#### Step 1: 各サービスのDBにコレクション作成 | Tạo collection cho từng DB của các service

```javascript
// 各サービスのMongoDBで実行 | Thực thi trong MongoDB của các service
use service_registration;
db.createCollection("roles_master");
db.createCollection("authorities_master");

use service_security;
db.createCollection("roles_master");
db.createCollection("authorities_master");
```

#### Step 2: 初期データ投入 | Nhập dữ liệu ban đầu

```bash
# マスターデータのエクスポート | export masterdata 
mongoexport --db=admin --collection=roles --out=roles.json

# 各サービスへインポート | import các service
for SERVICE in service-registration service-security service-admin; do
    mongoimport --db=$SERVICE --collection=roles_master --file=roles.json --drop
done
```

#### Step 3: アプリケーション設定 | Thiết lập ứng dụng

```yaml
# 各サービスのapplication.yml | application.yml của các service 
masterdata:
  database: local  # 各サービスのDBを使用 | Sử dụng DB của các service
  collections:
    roles: roles_master
    authorities: authorities_master
  sync:
    enabled: true
    cron: "0 */30 * * * *"  # 30分ごとに同期 | sync 30 phút 1 lần
```

## 移行パス | Lộ trình migrate

### Phase 1: 手動同期（現在） | Phase 1: Đồng bộ thủ công (hiện tại)
- 各サービスDBに手動でマスターデータ投入
- デプロイ時にスクリプト実行
======================================
- Cho master data thủ công vào DB của các service
- Chạy script lúc deploy

### Phase 2: 半自動同期（3ヶ月後）| Phase 2: Đồng bộ bán tự động (3 tháng sau)
- 定期同期ジョブ実装
- 変更検知と自動配布
======================================
- Triển khai Job đồng bộ định kỳ 
- Phát hiện thay đổi và phân phối tự động

### Phase 3: イベント駆動（6ヶ月後）| Phase 3: event-driven (6 tháng sau)
- マスターデータ変更イベントをPublish
- 各サービスが自動的に更新を取得
======================================
- Publish event thay đổi master data
- Các service nhận các update tự động

### Phase 4: 評価と最適化（1年後）| Phase 4: Đánh giá và tối ưu hóa (1 năm sau)
- 運用実績を評価
- 必要に応じて共通DB化を再検討
======================================
- Đánh giá kết quả vận hành thực tế
- Tùy tình hình có thể xem xét lại việc dùng DB chung

## 決定事項 | Đầu mục quyết định

### ✅ 推奨: オプション2（各サービスDBに複製）| Khuyến nghị: Option 2 (nhân bản vào DB riêng của từng service)

**理由:** | Lý do:
1. **既存構成との親和性**: インフラ変更が最小限
2. **サービス独立性**: マイクロサービスの原則を維持
3. **障害耐性**: 単一障害点を作らない
4. **パフォーマンス**: ローカルアクセスで高速
5. **段階的改善**: 運用しながら最適化可能
===============================================
1. **Tương thích với cấu trúc hiện có:** Thay đổi hạ tầng ở mức tối thiểu
2. **Giữ tính độc lập:**  Duy trì nguyên tắc microservice
3. **Khả năng chịu lỗi:** không có điểm lỗi đơn (no SPOF)
4. **Perfomance:** Nhanh vì là local access
5. **Cải tiến dần dần:** Có thể tối ưu trong quá trình vận hành

**実装方針:** | Phương hướng triển khai:
- 各サービスのDBに`roles_master`、`authorities_master`コレクションを作成
- デプロイ時に同期スクリプトで初期投入
- 定期同期ジョブで整合性維持
- 将来的にイベント駆動化
===============================================
- Tạo collection `roles_master` và `authorities_master` trong DB của từng service
- Khi deploy, chạy script đồng bộ để insert ban đầu
- Duy trì tính nhất quán bằng job đồng bộ định kỳ
- Trong tương lai sẽ chuyển sang kiến trúc event-driven

## リスクと対策 | Đối sách và rủi do

| リスク | 対策 |
|--------|------|
| データ不整合 | 定期同期 + 監視アラート |
| 同期遅延 | キャッシュTTL設定 + 手動リフレッシュAPI |
| 運用複雑化 | 自動化スクリプト + CI/CD統合 |
| バージョン管理 | マスターデータにversion フィールド追加 |
=========================================================
| Risk                    | Đối sách
|-------------------------|----------------------
|Data không nhất quán     |Đồng bộ định kỳ + Cảnh báo giám sát
|Đồng bộ bị trễ           |Thiết lập cache TTL + API làm mới thủ công
|Vận hành bị phức tạp hóa |Script tự động hóa + Tích hợp CI/CD
|Quản lý version          |Thêm trường version vào master data


## 監視項目 | Mục tiêu giám sát

```yaml
monitoring:
  - name: masterdata_sync_status
    description: 各サービスの同期状態 | Trạng thái đồng bộ của từng service
    alert: 不整合検出時 | Khi phát hiện không nhất quán
    
  - name: masterdata_version_diff
    description: バージョン差異 | Sai khác về version
    alert: 2バージョン以上の差 | Sai lệch từ 2 version trở lên
    
  - name: cache_hit_rate
    description: キャッシュヒット率 | Tỷ lệ cache hit
    alert: 80%以下 | Dưới 80%
```

## 結論 | Kết luận

**共通MongoDBは不要**です。各サービスの既存DBに マスターデータコレクションを追加し、同期メカニズムで整合性を保つアプローチが最適です。これにより：

- 既存のインフラを最大限活用
- マイクロサービスの独立性を維持
- 段階的な改善が可能
- 運用リスクを最小化

将来的に要件が変わった場合も、この構成から共通DB化への移行は可能です。

===========================================================================
Không cần sử dụng MongoDB chung. Giải pháp tối ưu là thêm collection master data vào DB hiện có của từng service, và duy trì tính nhất quán thông qua cơ chế đồng bộ. Cách tiếp cận này giúp:

- Tận dụng tối đa hạ tầng hiện có
- Duy trì tính độc lập của microservice
- Cho phép cải tiến theo từng giai đoạn
- Giảm thiểu rủi ro vận hành

Trong tương lai, nếu yêu cầu thay đổi, cấu trúc này vẫn có thể mở rộng để chuyển sang mô hình DB chung.