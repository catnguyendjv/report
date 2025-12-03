```mermaid
gantt
    title Biểu đồ Gantt dự án di chuyển hiện đại hóa máy chủ OAuth2
    dateFormat  YYYY-MM-DD
    axisFormat %Y-%m-%d
    
    section Giai đoạn 1: Thiết kế lại và phân tách service-framework
    Phân tách chức năng (Starter hóa)      :active, 2025-07-14, 15d
    Loại bỏ enum (DB/Config hóa) :after Phân tách chức năng (Starter hóa), 10d
    
        section Giai đoạn 2: Phát triển service-security
    Phát triển service-oauth2-server-new :after Loại bỏ enum (DB/Config hóa), 15d
    
    section Giai đoạn 3: Di chuyển dịch vụ mẫu
    Ánh xạ lại các phụ thuộc (sửa đổi pom.xml) :crit, after Phát triển service-oauth2-server-new, 2d
    Di chuyển không gian tên và API (jakarta hóa)   :after Ánh xạ lại các phụ thuộc (sửa đổi pom.xml), 3d
    Tái cấu trúc logic (thay thế enum) :after Di chuyển không gian tên và API (jakarta hóa), 3d
    
    section Giai đoạn 4: Di chuyển máy khách
    Di chuyển máy khách theo từng giai đoạn          :after Tái cấu trúc logic (thay thế enum), 10d
    
    section Giai đoạn 5: Loại bỏ hệ thống cũ
    Công việc loại bỏ hệ thống cũ            :milestone, after Di chuyển máy khách theo từng giai đoạn, 3d

```

### Tóm tắt lịch trình

*   **Ngày bắt đầu dự án:** 14 tháng 7 năm 2025 (Thứ Hai)
*   **Ngày dự kiến hoàn thành Giai đoạn 1:** 15 tháng 8 năm 2025 (Thứ Sáu)
*   **Ngày dự kiến hoàn thành Giai đoạn 2:** 5 tháng 9 năm 2025 (Thứ Sáu)
*   **Ngày dự kiến hoàn thành Giai đoạn 3:** 17 tháng 9 năm 2025 (Thứ Tư)
*   **Ngày dự kiến hoàn thành Giai đoạn 4:** 1 tháng 10 năm 2025 (Thứ Tư)
*   **Ngày dự kiến hoàn thành dự án:** 6 tháng 10 năm 2025 (Thứ Hai)

**Lưu ý:** Biểu đồ Gantt này giả định rằng mỗi giai đoạn sẽ tiến hành tuần tự. Trong thực tế, các tác vụ như kiểm thử và tạo tài liệu sẽ được thực hiện song song trong mỗi giai đoạn.
