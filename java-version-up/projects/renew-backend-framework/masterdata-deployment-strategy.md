# Chiến lược triển khai Masterdata MongoDB

## Hiểu biết về tình hình hiện tại
- Mỗi dịch vụ sử dụng cơ sở dữ liệu MongoDB riêng
- Dữ liệu chính (vai trò, quyền hạn) cần được tham chiếu chung trên tất cả các dịch vụ
- lib-spring-boot-starter-masterdata được tích hợp vào mỗi dịch vụ

## Phân tích các tùy chọn triển khai

### Tùy chọn 1: MongoDB chung (tập trung) ❌ Không khuyến khích

```
┌─────────────────────────────────────┐
│     MongoDB chung (masterdata)        │
│  ┌──────────────────────────────┐  │
│  │ roles / authorities / master │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
           ↑        ↑        ↑
      service-A  service-B  service-C
      (DB riêng)   (DB riêng)   (DB riêng)
```

**Ưu điểm:**
- Nguồn chân lý duy nhất (Single Source of Truth)
- Cập nhật được phản ánh ngay lập tức trên tất cả các dịch vụ
- Quản lý dữ liệu đơn giản

**Nhược điểm:**
- Rủi ro về điểm lỗi duy nhất (SPOF)
- Ảnh hưởng của độ trễ mạng
- Tính độc lập của mỗi dịch vụ bị tổn hại
- Yêu cầu thay đổi lớn đối với cấu hình cơ sở hạ tầng hiện có

### Tùy chọn 2: Sao chép vào mỗi DB dịch vụ (phân tán) ✅ Khuyến nghị

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

**Ưu điểm:**
- Duy trì tính độc lập của mỗi dịch vụ
- Tận dụng cấu hình cơ sở hạ tầng hiện có
- Không bị ảnh hưởng bởi lỗi mạng
- Hiệu suất tốt (truy cập cục bộ)

**Nhược điểm:**
- Cần có cơ chế đồng bộ hóa dữ liệu
- Khả năng không nhất quán tạm thời

### Tùy chọn 3: Hybrid (di chuyển theo giai đoạn) 🎯 Thực tế

```
Giai đoạn 1: Sao chép vào mỗi DB + tập lệnh đồng bộ hóa
Giai đoạn 2: Đồng bộ hóa tự động theo sự kiện
Giai đoạn 3: Xem xét DB chung nếu cần
```

## Phương pháp triển khai được đề xuất

### 1. Thiết lập ban đầu (mỗi DB dịch vụ)

```yaml
# application.yml
spring:
  data:
    mongodb:
      uri: ${MONGODB_URI:mongodb://localhost:27017/service-a}
      # Dữ liệu chính là một bộ sưu tập riêng trong cùng một DB
      
masterdata:
  collections:
    roles: roles_master
    authorities: authorities_master
  sync:
    enabled: true
    source: ${MASTERDATA_SOURCE_URI:mongodb://masterdata-source/admin}
```

### 2. Chiến lược đồng bộ hóa dữ liệu chính

#### 2.1 Tập lệnh nhập ban đầu

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

#### 2.2 Công việc đồng bộ hóa định kỳ

```java
@Component
@EnableScheduling
public class MasterDataSyncJob {
    
    @Value("${masterdata.sync.enabled:false}")
    private boolean syncEnabled;
    
    @Scheduled(cron = "${masterdata.sync.cron:0 0 * * * *}") // Hàng giờ
    public void syncMasterData() {
        if (!syncEnabled) return;
        
        // 1. Lấy dữ liệu mới nhất từ nguồn chính
        // 2. So sánh với DB cục bộ
        // 3. Cập nhật nếu có sự khác biệt
        // 4. Làm mới bộ đệm
    }
}
```

### 3. Sửa đổi chi tiết triển khai

#### 3.1 Thêm cấu hình lib-spring-boot-starter-masterdata

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

#### 3.2 Cấu hình mẫu MongoDB

```java
@Configuration
public class MasterDataMongoConfig {
    
    @Bean
    @ConditionalOnProperty(name = "masterdata.database", havingValue = "local")
    public MongoTemplate masterDataMongoTemplate(MongoClient mongoClient, 
                                                  @Value("${spring.data.mongodb.database}") String database) {
        // Sử dụng cùng một phiên bản DB
        return new MongoTemplate(mongoClient, database);
    }
    
    @Bean
    @ConditionalOnProperty(name = "masterdata.database", havingValue = "shared")
    public MongoTemplate masterDataMongoTemplate(@Value("${masterdata.shared.uri}") String uri) {
        // Kết nối với DB chung (tùy chọn trong tương lai)
        MongoClient client = MongoClients.create(uri);
        return new MongoTemplate(client, "masterdata");
    }
}
```

### 4. Quy trình triển khai

#### Bước 1: Tạo bộ sưu tập trong DB của mỗi dịch vụ

```javascript
// Chạy trong MongoDB của mỗi dịch vụ
use service_registration;
db.createCollection("roles_master");
db.createCollection("authorities_master");

use service_security;
db.createCollection("roles_master");
db.createCollection("authorities_master");
```

#### Bước 2: Nhập dữ liệu ban đầu

```bash
# Xuất dữ liệu chính
mongoexport --db=admin --collection=roles --out=roles.json

# Nhập vào mỗi dịch vụ
for SERVICE in service-registration service-security service-admin; do
    mongoimport --db=$SERVICE --collection=roles_master --file=roles.json --drop
done
```

#### Bước 3: Cấu hình ứng dụng

```yaml
# application.yml của mỗi dịch vụ
masterdata:
  database: local  # Sử dụng DB của mỗi dịch vụ
  collections:
    roles: roles_master
    authorities: authorities_master
  sync:
    enabled: true
    cron: "0 */30 * * * *"  # Đồng bộ hóa sau mỗi 30 phút
```

## Lộ trình di chuyển

### Giai đoạn 1: Đồng bộ hóa thủ công (hiện tại)
- Nhập dữ liệu chính thủ công vào mỗi DB dịch vụ
- Chạy tập lệnh khi triển khai

### Giai đoạn 2: Đồng bộ hóa bán tự động (3 tháng sau)
- Triển khai công việc đồng bộ hóa định kỳ
- Phát hiện thay đổi và phân phối tự động

### Giai đoạn 3: Theo sự kiện (6 tháng sau)
- Xuất bản sự kiện thay đổi dữ liệu chính
- Mỗi dịch vụ tự động lấy các bản cập nhật

### Giai đoạn 4: Đánh giá và tối ưu hóa (1 năm sau)
- Đánh giá hiệu suất hoạt động
- Xem xét lại việc sử dụng DB chung nếu cần

## Quyết định

### ✅ Khuyến nghị: Tùy chọn 2 (sao chép vào mỗi DB dịch vụ)

**Lý do:**
1. **Khả năng tương thích với cấu hình hiện có**: Thay đổi cơ sở hạ tầng ở mức tối thiểu
2. **Tính độc lập của dịch vụ**: Duy trì các nguyên tắc của microservice
3. **Khả năng chịu lỗi**: Không tạo ra điểm lỗi duy nhất
4. **Hiệu suất**: Nhanh chóng với quyền truy cập cục bộ
5. **Cải tiến theo giai đoạn**: Có thể tối ưu hóa trong khi vận hành

**Chính sách triển khai:**
- Tạo các bộ sưu tập `roles_master`, `authorities_master` trong DB của mỗi dịch vụ
- Nhập ban đầu bằng tập lệnh đồng bộ hóa khi triển khai
- Duy trì tính nhất quán với công việc đồng bộ hóa định kỳ
- Hướng tới việc điều khiển bằng sự kiện trong tương lai

## Rủi ro và biện pháp đối phó

| Rủi ro | Biện pháp đối phó |
|---|---|
| Dữ liệu không nhất quán | Đồng bộ hóa định kỳ + cảnh báo giám sát |
| Độ trễ đồng bộ hóa | Cài đặt TTL bộ đệm + API làm mới thủ công |
| Hoạt động phức tạp | Tập lệnh tự động hóa + tích hợp CI/CD |
| Quản lý phiên bản | Thêm trường phiên bản vào dữ liệu chính |

## Các mục giám sát

```yaml
monitoring:
  - name: masterdata_sync_status
    description: Trạng thái đồng bộ hóa của mỗi dịch vụ
    alert: Khi phát hiện sự không nhất quán
    
  - name: masterdata_version_diff
    description: Sự khác biệt về phiên bản
    alert: Chênh lệch từ 2 phiên bản trở lên
    
  - name: cache_hit_rate
    description: Tỷ lệ truy cập bộ đệm
    alert: Dưới 80%
```

## Kết luận

**Không cần MongoDB chung**. Cách tiếp cận tối ưu là thêm các bộ sưu tập dữ liệu chính vào DB hiện có của mỗi dịch vụ và duy trì tính nhất quán bằng cơ chế đồng bộ hóa. Điều này cho phép:

- Tận dụng tối đa cơ sở hạ tầng hiện có
- Duy trì tính độc lập của microservice
- Cải tiến theo giai đoạn
- Giảm thiểu rủi ro vận hành

Ngay cả khi các yêu cầu thay đổi trong tương lai, việc di chuyển từ cấu hình này sang DB chung vẫn có thể thực hiện được.