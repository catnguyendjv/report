# service-framework → masterdata 権限同期手順書 | service-framework → masterdata Hướng dẫn đồng bộ quyền hạn

## 概要 | Tổng quan
service-frameworkとlib-spring-boot-starter-masterdataの並行運用期間中に、service-frameworkの権限修正が発生した場合の同期手順を定義します。
=====================================================
Tài liệu này định nghĩa quy trình đồng bộ cho trường hợp xảy ra thay đổi quyền hạn trong service-framework trong thời gian vận hành song song giữa service-framework và lib-spring-boot-starter-masterdata.


## 前提条件 | Điều kiện tiên quyết
- service-frameworkのenumは引き続きGoogle Spreadsheetから自動生成される
- MongoDBのマスターデータは手動またはスクリプトで更新する必要がある
- 両システムの権限定義は完全に一致させる必要がある
===========================================================
- Enum trong service-framework vẫn được tự động sinh ra từ Google Spreadsheet.
- Dữ liệu master trong MongoDB cần được cập nhật thủ công hoặc bằng script.
- Định nghĩa quyền hạn của cả hai hệ thống cần phải hoàn toàn khớp nhau.

## 同期が必要なケース | Các trường hợp cần đồng bộ

### 1. 新規ロール追加 | Thêm role mới
service-frameworkの`Role.java`に新しいロールが追加された場合
Trường hợp có role mới được thêm vào `Role.java` của service-framework

### 2. 既存ロールの変更 | Thay đổi role hiện có
- ロールコードの変更
- ロール説明の変更
- ロールの削除
==================================================
- Thay đổi role code
- Thay đổi mô tả role
- Xóa role

### 3. スタッフ権限の変更 | Thay đổi quyền hạn của staff
`StaffAuthority.java`や`StaffOperationAuthority.java`の変更
Thay đổi trong `StaffAuthority.java` hoặc `StaffOperationAuthority.java`
## 同期手順 | Quy trình đồng bộ

### Step 1: service-frameworkの変更確認 | Step 1: Xác nhận thay đổi trong service-framework

```bash
# 変更されたenumファイルを確認 | Kiểm tra file enum đã thay đổi
cd /path/to/service-framework
git diff src/main/java/jp/drjoy/service/framework/model/Role.java
git diff src/main/java/jp/drjoy/service/framework/model/StaffAuthority.java
```

### Step 2: 変更内容の抽出 | Step 2: Trích xuất nội dung thay đổi

#### Role.javaから新規ロールを抽出する例 | Ví dụ trích xuất role mới từ Role.java

```java
// 新規追加されたロール例 | Ví dụ role mới được thêm
/** #12345: 新機能管理者 */ | #12345: admin chức năng mới
NEW_FEATURE_MGT("NEW_FEATURE_MGT"),
```

この場合、以下の情報を抽出： | Trường hợp này, Chiết xuất thông tin bên dưới:
- name: `NEW_FEATURE_MGT`
- description: `新機能管理者` | admin chức năng mới

### Step 3: MongoDBへのデータ投入 | Step 3: Nhập data vào MongoDB

#### 方法1: MongoDB Shellを使用 | Phương pháp 1: Sử dụng MongoDB Shell

```javascript
// MongoDBに接続 | Kết nối với MongoDB
mongosh mongodb://localhost:27017/drjoy

// rolesコレクションに新規ロールを追加 | Thêm role mới vào collection roles
db.roles.insertOne({
  name: "NEW_FEATURE_MGT",
  description: "新機能管理者"
})

// 既存ロールの更新 |  Cập nhật role hiện có
db.roles.updateOne(
  { name: "DOC_MGT" },
  { $set: { description: "更新された説明" } }
)

// ロールの削除（論理削除推奨）| Xóa role (khuyến nghị xóa logic)
db.roles.updateOne(
  { name: "OLD_ROLE" },
  { $set: { deleted: true, deletedAt: new Date() } }
)
```

#### 方法2: Javaマイグレーションスクリプト | Phương pháp 2: Script Java Migration

```java
package jp.drjoy.migration;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.beans.factory.annotation.Autowired;
import jp.drjoy.masterdata.repository.RoleRepository;
import jp.drjoy.masterdata.document.RoleDocument;

@SpringBootApplication
public class RoleMigrationApplication implements CommandLineRunner {

    @Autowired
    private RoleRepository roleRepository;

    public static void main(String[] args) {
        SpringApplication.run(RoleMigrationApplication.class, args);
    }

    @Override
    public void run(String... args) {
        // 新規ロール追加 | Thêm role mới
        RoleDocument newRole = new RoleDocument();
        newRole.setName("NEW_FEATURE_MGT");
        newRole.setDescription("新機能管理者");
        roleRepository.save(newRole);
        
        System.out.println("Migration completed");
    }
}
```

### Step 4: 一括同期スクリプト | Step 4: Script đồng bộ hàng loạt

#### enum解析→MongoDB投入自動化スクリプト | Script tự động phân tích enum → nhập MongoDB

```python
#!/usr/bin/env python3
# sync_roles.py

import re
import pymongo
from pathlib import Path

def parse_role_enum(file_path):
    """Role.javaからロール情報を抽出""" | Trích xuất thông tin role từ Role.java
    roles = []
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # enumエントリーを正規表現で抽出 | Trích xuất enum entry bằng cách chính quy
        pattern = r'/\*\*\s*(.*?)\s*\*/\s*(\w+)\("(\w+)"\)'
        matches = re.findall(pattern, content, re.MULTILINE)
        
        for match in matches:
            description = match[0].strip()
            enum_name = match[1]
            code = match[2]
            
            # 説明からチケット番号を除去 | Loại bỏ số ticket trong phần giải thích
            description = re.sub(r'#\d+:\s*', '', description)
            
            roles.append({
                'name': code,
                'description': description,
                'enumName': enum_name
            })
    
    return roles

def sync_to_mongodb(roles, connection_string='mongodb://localhost:27017/', db_name='drjoy'):
    """MongoDBにロールを同期""" | Đồng bộ role vào MongoDB
    client = pymongo.MongoClient(connection_string)
    db = client[db_name]
    collection = db['roles']
    
    # 既存のロールを取得 | Lấy role sẵn có
    existing_roles = {doc['name']: doc for doc in collection.find()}
    
    stats = {'added': 0, 'updated': 0, 'unchanged': 0}
    
    for role in roles:
        if role['name'] in existing_roles:
            # 既存ロールの場合、説明が変更されていれば更新 | Trường hợp là role sẵn có, Phần giải thích mà bị thay đổi thì update
            existing = existing_roles[role['name']]
            if existing.get('description') != role['description']:
                collection.update_one(
                    {'name': role['name']},
                    {'$set': {'description': role['description']}}
                )
                stats['updated'] += 1
                print(f"Updated: {role['name']}")
            else:
                stats['unchanged'] += 1
        else:
            # 新規ロールを追加 | Thêm role mới
            collection.insert_one({
                'name': role['name'],
                'description': role['description']
            })
            stats['added'] += 1
            print(f"Added: {role['name']}")
    
    # enumに存在しないDBのロールを検出 | Phát hiện các role trong DB mà không tồn tại ở enum 
    enum_names = {role['name'] for role in roles}
    for db_role_name in existing_roles.keys():
        if db_role_name not in enum_names:
            print(f"Warning: Role '{db_role_name}' exists in DB but not in enum")
    
    return stats

if __name__ == '__main__':
    # パスは環境に応じて調整 | Điều chỉnh path tùy theo môi trường
    role_file = '/path/to/service-framework/src/main/java/jp/drjoy/service/framework/model/Role.java'
    
    roles = parse_role_enum(role_file)
    stats = sync_to_mongodb(roles)
    
    print(f"\nSync completed: Added={stats['added']}, Updated={stats['updated']}, Unchanged={stats['unchanged']}")
```

### Step 5: 検証 | Kiểm thử

#### 1. データ整合性確認 | Xác nhận tính nhất quán của data

```javascript
// MongoDB Shell
db.roles.find().count()  // enumのロール数と一致することを確認 | Xác nhận xem có khớp với số role trong enum hay không

// 特定ロールの確認 | Xác nhận role cụ thể
db.roles.find({ name: "NEW_FEATURE_MGT" })
```

#### 2. アプリケーション起動確認 | Xác nhận khởi động của App

```bash
# masterdataを使用するサービスを起動 | Khởi động service sử dụng masterdata
cd /path/to/service-using-masterdata
mvn spring-boot:run

# ログを確認してキャッシュロードが成功していることを確認 | Kiểm tra log để xác nhận rằng việc tải cache đã thành công
# "Loading roles to cache" などのメッセージを確認 | Kiểm tra xem có xuất hiện thông báo như ‘Loading roles to cache’ hay không
```

#### 3. 単体テスト実行 | Thực hiện Unit Test

```bash
cd /path/to/lib-spring-boot-starter-masterdata
mvn test
```

## 運用上の注意事項 | Các mục chú ý khi vận hành

### 1. 同期タイミング | Thời điểm đồng bộ
- service-frameworkの変更がマージされたらすぐに同期を実行
- 本番環境への反映前に必ずステージング環境で検証
======================================================
- Thay đổi của service-framework được merge thì thực hiện đồng bộ ngay lập tức
- Trước khi đẩy lên môi trường master thì nhất định phải kiểm thử trước ở môi trường stg

### 2. ロールバック手順 | Quy trình rollback
```javascript
// 変更前の状態をバックアップ | Backup trạng thái trước khi thay đổi
db.roles.find().forEach(doc => db.roles_backup.insert(doc))

// 問題発生時はバックアップから復元 | Khi vấn đề phát sinh, khôi phục lại bằng bản backup
db.roles.drop()
db.roles_backup.find().forEach(doc => db.roles.insert(doc))
```

### 3. 監視項目 | Đầu mục giám sát
- 両システムのロール数の差異
- キャッシュロード失敗
- 権限チェックエラーの増加
===================================
- Sự khác biệt giữa số role giữa 2 hệ thống
- Tải cache thất bại
- Sự gia tăng lỗi check quyền hạn

### 4. 段階的移行 | Migrate theo giai đoạn
1. 開発環境で同期スクリプトを実行
2. ステージング環境で動作確認
3. 本番環境への適用
=======================================
1. Chạy Script đồng bộ ở môi trường phát triển
2. Xác nhận hoạt động ở môi trường stg
3. Áp dụng lên môi trường master

## トラブルシューティング | Troubleshooting

### Q: enumとDBのロール数が一致しない | enum và số role trong DB không khớp nhau
A: 同期スクリプトのログを確認し、警告メッセージをチェック
A: Xác nhận log của script đồng bộ, check warning message

### Q: キャッシュが更新されない | Cache không được update
A: サービスの再起動またはキャッシュリフレッシュAPIを実行
A: Thực hiện restart service hoặc refresh API cache

### Q: 権限チェックが失敗する | Check quyền hạn thất bại
A: ロール名の大文字小文字、スペースの有無を確認
A: Xác nhận xem tên role có chữ in hoa, in thường, khoảng trống hay không

## 自動化の推進 | Khuyến khích tự động hóa

### CI/CDパイプラインへの組み込み | Tích hợp vào pipeline CI/CD
```yaml
# .drone.yml の例 | Ví dụ của .drone.yml
steps:
  - name: sync-masterdata
    image: python:3.9
    commands:
      - pip install pymongo
      - python sync_roles.py
    when:
      branch: develop
      event: push
      path:
        include:
          - "src/main/java/jp/drjoy/service/framework/model/*.java"
```

## 完全移行への道筋 | Con đường tới migrate hoàn toàn 

1. **Phase 1**: 手動同期（現在）
2. **Phase 2**: 半自動同期（スクリプト化）
3. **Phase 3**: 自動同期（CI/CD統合）
4. **Phase 4**: service-framework廃止、masterdata単独運用
==========================================================
1. **Phase 1** Đồng bộ thủ công (hiện tại)
2. **Phase 2** Đồng bộ bán thủ công (Script hóa)
3. **Phase 3** Đồng bộ tự động (Tích hợp CI/CD)
4. **Phase 4** Loại bỏ service-framework, Vận hành duy nhất masterdata

## 関連ドキュメント | Tài liệu liên quan
- [OAuth2サーバー近代化 移行計画書](README.md)
- [詳細タスクリスト](detailed_plan.md)
- [設計書](architecture.md)
==========================================
- [Bản kế hoạch migrate và hiện đại hóa OAuth2 service](README.md)
- [Danh sách task chi tiết](detailed_plan.md)
- [Bản thiết kế](architecture.md)