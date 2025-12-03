# Hướng dẫn đồng bộ hóa quyền hạn service-framework → masterdata

## Tổng quan
Tài liệu này định nghĩa quy trình đồng bộ hóa khi có sự thay đổi quyền hạn trong service-framework trong giai đoạn vận hành song song service-framework và lib-spring-boot-starter-masterdata.

## Điều kiện tiên quyết
- enum của service-framework tiếp tục được tạo tự động từ Google Spreadsheet
- Dữ liệu chính của MongoDB cần được cập nhật thủ công hoặc bằng script
- Định nghĩa quyền hạn của cả hai hệ thống phải hoàn toàn khớp nhau

## Các trường hợp cần đồng bộ hóa

### 1. Thêm vai trò mới
Khi một vai trò mới được thêm vào `Role.java` của service-framework

### 2. Thay đổi vai trò hiện có
- Thay đổi mã vai trò
- Thay đổi mô tả vai trò
- Xóa vai trò

### 3. Thay đổi quyền hạn của nhân viên
Thay đổi trong `StaffAuthority.java` hoặc `StaffOperationAuthority.java`

## Quy trình đồng bộ hóa

### Bước 1: Xác nhận thay đổi trong service-framework

```bash
# Kiểm tra các tệp enum đã thay đổi
cd /path/to/service-framework
git diff src/main/java/jp/drjoy/service/framework/model/Role.java
git diff src/main/java/jp/drjoy/service/framework/model/StaffAuthority.java
```

### Bước 2: Trích xuất nội dung thay đổi

#### Ví dụ trích xuất vai trò mới từ Role.java

```java
// Ví dụ về vai trò mới được thêm vào
/** #12345: Quản trị viên tính năng mới */
NEW_FEATURE_MGT("NEW_FEATURE_MGT"),
```

Trong trường hợp này, trích xuất các thông tin sau:
- name: `NEW_FEATURE_MGT`
- description: `Quản trị viên tính năng mới`

### Bước 3: Nhập dữ liệu vào MongoDB

#### Phương pháp 1: Sử dụng MongoDB Shell

```javascript
// Kết nối với MongoDB
mongosh mongodb://localhost:27017/drjoy

// Thêm vai trò mới vào bộ sưu tập roles
db.roles.insertOne({
  name: "NEW_FEATURE_MGT",
  description: "Quản trị viên tính năng mới"
})

// Cập nhật vai trò hiện có
db.roles.updateOne(
  { name: "DOC_MGT" },
  { $set: { description: "Mô tả đã được cập nhật" } }
)

// Xóa vai trò (khuyến nghị xóa logic)
db.roles.updateOne(
  { name: "OLD_ROLE" },
  { $set: { deleted: true, deletedAt: new Date() } }
)
```

#### Phương pháp 2: Script di chuyển Java

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
        // Thêm vai trò mới
        RoleDocument newRole = new RoleDocument();
        newRole.setName("NEW_FEATURE_MGT");
        newRole.setDescription("Quản trị viên tính năng mới");
        roleRepository.save(newRole);
        
        System.out.println("Di chuyển hoàn tất");
    }
}
```

### Bước 4: Script đồng bộ hóa hàng loạt

#### Script tự động hóa phân tích enum → nhập MongoDB

```python
#!/usr/bin/env python3
# sync_roles.py

import re
import pymongo
from pathlib import Path

def parse_role_enum(file_path):
    """Trích xuất thông tin vai trò từ Role.java"""
    roles = []
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # Trích xuất các mục enum bằng biểu thức chính quy
        pattern = r'/\*\*\s*(.*?)\s*\*/\s*(\w+)\("(\w+)"\)'
        matches = re.findall(pattern, content, re.MULTILINE)
        
        for match in matches:
            description = match[0].strip()
            enum_name = match[1]
            code = match[2]
            
            # Xóa số vé khỏi mô tả
            description = re.sub(r'#\d+:\s*', '', description)
            
            roles.append({
                'name': code,
                'description': description,
                'enumName': enum_name
            })
    
    return roles

def sync_to_mongodb(roles, connection_string='mongodb://localhost:27017/', db_name='drjoy'):
    """Đồng bộ hóa vai trò với MongoDB"""
    client = pymongo.MongoClient(connection_string)
    db = client[db_name]
    collection = db['roles']
    
    # Lấy các vai trò hiện có
    existing_roles = {doc['name']: doc for doc in collection.find()}
    
    stats = {'added': 0, 'updated': 0, 'unchanged': 0}
    
    for role in roles:
        if role['name'] in existing_roles:
            # Nếu là vai trò hiện có, cập nhật nếu mô tả đã thay đổi
            existing = existing_roles[role['name']]
            if existing.get('description') != role['description']:
                collection.update_one(
                    {'name': role['name']},
                    {'$set': {'description': role['description']}}
                )
                stats['updated'] += 1
                print(f"Đã cập nhật: {role['name']}")
            else:
                stats['unchanged'] += 1
        else:
            # Thêm vai trò mới
            collection.insert_one({
                'name': role['name'],
                'description': role['description']
            })
            stats['added'] += 1
            print(f"Đã thêm: {role['name']}")
    
    # Phát hiện các vai trò trong DB không tồn tại trong enum
    enum_names = {role['name'] for role in roles}
    for db_role_name in existing_roles.keys():
        if db_role_name not in enum_names:
            print(f"Cảnh báo: Vai trò '{db_role_name}' tồn tại trong DB nhưng không có trong enum")
    
    return stats

if __name__ == '__main__':
    # Điều chỉnh đường dẫn tùy theo môi trường
    role_file = '/path/to/service-framework/src/main/java/jp/drjoy/service/framework/model/Role.java'
    
    roles = parse_role_enum(role_file)
    stats = sync_to_mongodb(roles)
    
    print(f"\nĐồng bộ hóa hoàn tất: Đã thêm={stats['added']}, Đã cập nhật={stats['updated']}, Không thay đổi={stats['unchanged']}")
```

### Bước 5: Xác minh

#### 1. Xác nhận tính toàn vẹn của dữ liệu

```javascript
// MongoDB Shell
db.roles.find().count()  // Xác nhận rằng số lượng khớp với số lượng vai trò trong enum

// Xác nhận vai trò cụ thể
db.roles.find({ name: "NEW_FEATURE_MGT" })
```

#### 2. Xác nhận khởi động ứng dụng

```bash
# Khởi động dịch vụ sử dụng masterdata
cd /path/to/service-using-masterdata
mvn spring-boot:run

# Kiểm tra nhật ký để xác nhận rằng việc tải bộ đệm đã thành công
# Xác nhận các thông báo như "Đang tải vai trò vào bộ đệm"
```

#### 3. Chạy kiểm thử đơn vị

```bash
cd /path/to/lib-spring-boot-starter-masterdata
mvn test
```

## Lưu ý vận hành

### 1. Thời điểm đồng bộ hóa
- Thực hiện đồng bộ hóa ngay sau khi các thay đổi của service-framework được hợp nhất
- Luôn xác minh trong môi trường dàn dựng trước khi áp dụng cho môi trường sản xuất

### 2. Quy trình khôi phục
```javascript
// Sao lưu trạng thái trước khi thay đổi
db.roles.find().forEach(doc => db.roles_backup.insert(doc))

// Khôi phục từ bản sao lưu nếu có sự cố
db.roles.drop()
db.roles_backup.find().forEach(doc => db.roles.insert(doc))
```

### 3. Các mục giám sát
- Sự khác biệt về số lượng vai trò giữa hai hệ thống
- Tải bộ đệm không thành công
- Tăng lỗi kiểm tra quyền hạn

### 4. Di chuyển theo giai đoạn
1. Chạy script đồng bộ hóa trong môi trường phát triển
2. Xác nhận hoạt động trong môi trường dàn dựng
3. Áp dụng cho môi trường sản xuất

## Khắc phục sự cố

### Q: Số lượng vai trò trong enum và DB không khớp
A: Kiểm tra nhật ký của script đồng bộ hóa và kiểm tra các thông báo cảnh báo

### Q: Bộ đệm không được cập nhật
A: Khởi động lại dịch vụ hoặc chạy API làm mới bộ đệm

### Q: Kiểm tra quyền hạn không thành công
A: Kiểm tra chữ hoa/chữ thường, sự hiện diện của dấu cách trong tên vai trò

## Thúc đẩy tự động hóa

### Tích hợp vào quy trình CI/CD
```yaml
# Ví dụ về .drone.yml
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

## Lộ trình di chuyển hoàn toàn

1. **Giai đoạn 1**: Đồng bộ hóa thủ công (hiện tại)
2. **Giai đoạn 2**: Đồng bộ hóa bán tự động (script hóa)
3. **Giai đoạn 3**: Đồng bộ hóa tự động (tích hợp CI/CD)
4. **Giai đoạn 4**: Loại bỏ service-framework, vận hành độc lập masterdata

## Tài liệu liên quan
- [Kế hoạch di chuyển hiện đại hóa máy chủ OAuth2](README.md)
- [Danh sách công việc chi tiết](detailed_plan.md)
- [Tài liệu thiết kế](architecture.md)