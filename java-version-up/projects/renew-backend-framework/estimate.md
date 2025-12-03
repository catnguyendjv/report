# Báo giá dự án di chuyển hiện đại hóa máy chủ OAuth2

Dựa trên `migration_plan.md` được cung cấp, dưới đây là ước tính về nguồn lực và thời gian với giả định sử dụng Gemini CLI.

### Điều kiện tiên quyết

*   **Người phụ trách:** Giả định một nhà phát triển cấp cao quen thuộc với Spring Boot, Java và kiến trúc hiện tại của Dr.JOY sẽ là người phụ trách chính, với sự hỗ trợ của các nhà phát triển khác khi cần thiết.
*   **Sử dụng Gemini CLI:** Giả định rằng Gemini CLI sẽ xử lý nhanh chóng nhiều tác vụ định kỳ và có khối lượng lớn như tạo tệp, tạo mã mẫu, tái cấu trúc (chẳng hạn như thay thế `javax` bằng `jakarta`), tạo mã kiểm thử và tạo tài liệu. Điều này cho phép các nhà phát triển tập trung vào thiết kế, đánh giá và kiểm thử thủ công phức tạp hơn, do đó giảm đáng kể thời gian.
*   **Đơn vị ước tính:** 1 ngày công = 8 giờ làm việc

---

### Ước tính theo từng giai đoạn

#### **Giai đoạn 1: Thiết kế lại và phân tách `service-framework` (Ước tính: 15–25 ngày công)**

Giai đoạn này có độ không chắc chắn cao nhất và đòi hỏi nhiều nỗ lực nhất. Gemini CLI sẽ tăng tốc việc sao chép mã, tạo mẫu và các tác vụ thay thế đơn giản, nhưng việc đánh giá tính hợp lệ của thiết kế và điều chỉnh các phụ thuộc nhỏ giữa các thư viện được phân tách sẽ chủ yếu dựa vào tư duy và đánh giá của nhà phát triển.

*   **Phân tách chức năng (10–15 ngày công):** Thiết kế và triển khai `starter-security` và `starter-grpc` sẽ tốn nhiều công sức nhất.
*   **Loại bỏ enum (5–10 ngày công):** Nếu việc sử dụng `enum` lan rộng, nỗ lực tái cấu trúc và kiểm thử sẽ tăng lên.

---

#### **Giai đoạn 2: Phát triển `service-security` (Ước tính: 10–15 ngày công)**

Do đã có nền tảng là các thư viện chung mới, quá trình phát triển dự kiến sẽ diễn ra tương đối suôn sẻ.

---

#### **Giai đoạn 3: Di chuyển microservice mẫu (`service-registration`) (Ước tính: 5–8 ngày công)**

Giai đoạn này sẽ là mẫu (khuôn mẫu) để di chuyển tất cả các microservice khác.

*   **Nội dung công việc:**
    1.  **Ánh xạ lại các phụ thuộc (1-2 ngày công):** Sửa đổi `pom.xml` để xóa phụ thuộc vào `service-framework` cũ và thêm phụ thuộc vào nhóm Starter mới.
    2.  **Di chuyển không gian tên và API (2-3 ngày công):** Thay thế không gian tên `javax.*` bằng `jakarta.*` và sửa các lỗi biên dịch do thay đổi API của Spring Boot 3/Spring Security 6.
    3.  **Tái cấu trúc logic (2-3 ngày công):** Thay thế các phần sử dụng `enum` và các thành phần chung của khung cũ bằng các phương pháp của thư viện mới (chẳng hạn như lấy giá trị động từ DB hoặc Config).
    4.  **Kiểm thử:** Cập nhật các kiểm thử hiện có và thêm các kiểm thử mới cho các phần đã thay đổi.

---

#### **Giai đoạn 4: Di chuyển máy khách theo từng giai đoạn (Ước tính: 5–10 ngày công + điều phối với các nhóm liên quan)**

Đây là công việc di chuyển sang `service-security`. Khối lượng công việc kỹ thuật không lớn, nhưng việc phối hợp với các nhóm khác là rất quan trọng.

---

#### **Giai đoạn 5: Loại bỏ hệ thống cũ (Ước tính: 2–3 ngày công)**

Sau khi hoàn thành việc di chuyển tất cả các máy khách, `service-oauth2-server` và `service-framework` cũ sẽ bị loại bỏ.

---

### **Tổng ước tính**

*   **Tổng thời gian:** **37–61 ngày công**
    *   *Lưu ý: Thời gian trên bao gồm cả việc di chuyển `service-registration`. Để di chuyển tất cả các dịch vụ còn lại (khoảng 50-60), sẽ cần thêm thời gian, giả định trung bình 3–5 ngày công cho mỗi dịch vụ. Tuy nhiên, hiệu quả của việc di chuyển các dịch vụ thứ hai trở đi sẽ được cải thiện đáng kể nhờ quy trình đã được thiết lập.*
*   **Nguồn lực:**
    *   **Người phụ trách chính:** 1 nhà phát triển cấp cao
    *   **Hỗ trợ:**
        *   Người phụ trách cơ sở hạ tầng
        *   Người phụ trách phát triển của từng ứng dụng máy khách
        *   Kỹ sư QA

### Hiệu quả của việc sử dụng Gemini CLI

*   **Rút ngắn thời gian:** Bằng cách tự động hóa các tác vụ định kỳ, Gemini CLI cho phép các nhà phát triển tập trung vào các công việc sáng tạo như thiết kế và đánh giá. Giả định rằng thời gian có thể được rút ngắn đáng kể so với việc thực hiện thủ công, vốn có thể mất **gấp 1,5 đến 2 lần thời gian**.
*   **Nâng cao chất lượng:** Việc tạo mã kiểm thử tự động giúp dễ dàng tăng phạm vi kiểm thử. Ngoài ra, nó có thể giảm các lỗi do con người gây ra như lỗi thay thế đơn giản.

---
*Ước tính này chỉ là sơ bộ vì nó không hoàn toàn nắm bắt được cơ sở mã hiện tại hoặc bộ kỹ năng của nhóm. Độ chính xác có thể được cải thiện bằng cách tiến hành một cuộc điều tra chi tiết hơn trước khi bắt đầu dự án.*