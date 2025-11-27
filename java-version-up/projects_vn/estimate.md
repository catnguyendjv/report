# OAuth2サーバー近代化移行プロジェクト 見積書 | Dự án hiện đại hóa và mỉate OAuth2 Server – Tài liệu estimate

提示された`移行計画.md`に基づき、Gemini CLIを活用することを前提としたリソースと期間の見積もりを以下に示します。
Dựa trên tài liệu `移行計画.md` được đưa ra, dưới đây là ước tính về nguồn lực và thời gian khi sử dụng Gemini CLI.
### 前提条件 | Điều kiện tiên quyết

*   **担当者:** Spring Boot、Java、および現在のDr.JOYのアーキテクチャに精通したシニア開発者1名を主担当とし、必要に応じて他の開発者がサポートする体制を想定します。
*   **Gemini CLIの活用:** ファイル作成、コードのひな形生成、リファクタリング（`javax`から`jakarta`への置換など）、テストコード生成、ドキュメント作成といった定型的かつ量的な作業の多くをGemini CLIが高速に処理することを前提とします。これにより、開発者はより複雑な設計やレビュー、手動テストに集中できるため、期間が大幅に短縮されます。
*   **見積もり単位:** 1人日 = 8時間労働
=========================================================================================================================================
*   **Người phụ trách:** Dự định cần 1 kỹ sư senior am hiểu Spring Boot, Java, và kiến trúc hiện tại của Dr.JOY, đóng vai trò chủ đạo. Các lập trình viên khác sẽ hỗ trợ khi cần thiết.
*   **Sử dụng Gemini CLI**: Các tác vụ có tính lặp lại hoặc khối lượng lớn như tạo file, sinh code template, refactoring (chuyển javax → jakarta), sinh test code, tạo document… sẽ được Gemini CLI xử lý nhanh chóng. Nhờ đó, lập trình viên có thể tập trung vào các thiết kế phức tạp, review và test thủ công, giúp rút ngắn đáng kể thời gian.
*   **Đơn vị ước tính:** 1 man/day = 8 giờ làm việc
---

### フェーズ別見積もり | Ước tính theo từng phase

#### **フェーズ1: `service-framework` の再設計と分割 (見積もり: 15〜25人日)** | Phase 1: Thiết kế lại và tách service-framework (ước tính: 15–25 man/day)

このフェーズが最も不確実性が高く、工数も大きくなります。Gemini CLIはコードのコピーやひな形作成、単純な置換作業を高速化しますが、設計の妥当性判断や、分割したライブラリ間の細かな依存関係の調整は、開発者による思考とレビューが中心となります。

*   **機能分割 (10〜15人日):** `starter-security`と`starter-grpc`の設計と実装に最も工数がかかります。
*   **enumの排除 (5〜10人日):** `enum`の利用箇所が広範囲にわたる場合、リファクタリングとテストの工数が増加します。
=========================================================================================================================================
Đây là phase có độ bất định cao nhất và tiêu tốn nhiều công số nhất.Gemini CLI sẽ hỗ trợ tăng tốc các tác vụ sao chép code, tạo template, và thay thế đơn giản.Tuy nhiên, việc xác định thiết kế hợp lý và điều chỉnh phụ thuộc giữa các library được chia tách thì vai trò chủ đạo vẫn là kỹ sư đảm nhiệm

*   **Phân tách chức năng (10–15 man/day):** Công số sẽ tốn nhiều nhất vào thiết kế và triển khai `starter-security` và `starter-grpc`.
*   **Loại bỏ enum (5–10 man/day):** Nếu phạm vi sử dụng enum rộng, công số cho refactoring và test sẽ tăng lên.

---

#### **フェーズ2: `service-security` の開発 (見積もり: 10〜15人日)** | Phát triển service-security (ước tính: 10–15 man/day)

新しい共通ライブラリ群の土台があるため、開発は比較的スムーズに進むと予想されます。
Vì đã có nền tảng là các library chung mới, giai đoạn này được dự đoán sẽ diễn ra suôn sẻ hơn.

---

#### **フェーズ3: サンプルマイクロサービス移行 (`service-registration`) (見積もり: 5〜8人日)** | Phase 3: Migrate sample microservice (service-registration) (ước tính: 5–8 nhân-ngày)

このフェーズは、他の全マイクロサービスを移行するためのテンプレート（雛形）となります。
Phase này sẽ đóng vai trò như template (mẫu) để migrate các microservice khác.

*   **作業内容:** | Nội dung công việc:
    1.  **依存関係の再マッピング (1-2人日):** `pom.xml`を修正し、旧`service-framework`への依存を削除し、新しいStarter群への依存を追加します。
    2.  **名前空間とAPIの移行 (2-3人日):** `javax.*`から`jakarta.*`へ名前空間を置換し、Spring Boot 3/Spring Security 6のAPI変更に伴うコンパイルエラーを修正します。
    3.  **ロジックのリファクタリング (2-3人日):** 旧フレームワークの`enum`や共通コンポーネントを利用している箇所を、新しいライブラリの作法（DBやConfigからの動的な値取得など）に置き換えます。
    4.  **テスト:** 既存のテストを更新し、変更箇所に対する新しいテストを追加します。
========================================================================================================================================= 
    1.  **Mapping lại mối quan hệ phụ thuộc (1–2 man/day):** Sửa `pom.xml`,  loại bỏ phụ thuộc vào `service-framework` cũ, thêm phụ thuộc vào các Starter mới.
    2.  **Migrate namespace và API (2–3 man/day):** Thay thế namespace từ `javax.*` sang `jakarta.*`, sửa lỗi compile phát sinh do thay đổi API của Spring Boot 3 / Spring Security 6.
    3.  **Refactor logic (2–3 man/day):** Thay các phần đang sử dụng `enum` và component chung của frame cũ sang cơ chế mới (lấy giá trị động từ DB hoặc Config).
    4.  **Test:** Cập nhật test hiện có và bổ sung test cho các phần đã thay đổi.
---

#### **フェーズ4: 段階的なクライアント移行 (見積もり: 5〜10人日 + 関係チームとの調整)** | Phase 4: Migrate client theo từng giai đoạn (ước tính: 5–10 man/day + phối hợp với các team liên quan)

`service-security`への移行作業です。技術的な作業量は少ないですが、他チームとの連携が重要になります。
Là giai đoạn di chuyển sang `service-security`. Khối lượng công việc kỹ thuật ít, nhưng việc phối hợp với các team khác trở nên quan trọng.

---

#### **フェーズ5: 旧システムの廃止 (見積もり: 2〜3人日)** | Phase 5: Loại bỏ hệ thống cũ (ước tính: 2–3 man/day)

全クライアントの移行完了後、旧`service-oauth2-server`および旧`service-framework`を廃止します。
Sau khi toàn bộ client đã được migrate, tiến hành bỏ `service-oauth2-server` và `service-framework`

---

### **合計見積もり** | Tổng estimate

*   **総期間:** **37〜61人日** | Tổng thời gian: 37–61 man/day
    *   *備考: 上記は`service-registration`の移行までを含んだ期間です。残りの全サービス（約50-60）を移行するには、1サービスあたり平均3〜5人日と仮定すると、さらに追加で期間が必要となります。ただし、2つ目以降のサービス移行は、確立された手順により効率が大幅に向上します。*
    *   *Ghi chú: Công số ghi trên đã bao gồm cả giai đoạn migrate `service-registration`. Về việc migrate tất cả các service còn lại (khoảng 50~60) thì giả sử ước tính trung bình 3–5 man/day/service thì sẽ cần thêm thời gian. Tuy nhiên, từ service thứ hai trở đi, hiệu suất sẽ cải thiện nhờ quy trình đã được thiết lập.

*   **リソース:**| Nguồn lực:
    *   **主担当:** シニア開発者 1名
    *   **サポート:**
        *   インフラ担当者
        *   各クライアントアプリケーションの開発担当者
        *   QAエンジニア
=============================================================
    *   **Phụ trách chính:** 1 kỹ sư senior
    *   **Hỗ trợ:**
        *   Kỹ sư hạ tầng
        *   Developer của từng client application
        *   QA engineer

### Gemini CLIの活用による効果 | Hiệu quả khi sử dụng Gemini CLI

*   **期間短縮:** Gemini CLIが定型作業を自動化することで、開発者は設計やレビューといった創造的な作業に集中できます。手作業であれば**1.5倍〜2倍の期間**が見込まれるところを、大幅に圧縮できると想定しています。
*   **品質向上:** テストコードの自動生成により、テストカバレッジを容易に向上させることができます。また、単純な置換ミスなどのヒューマンエラーを削減できます。

---
*この見積もりは、現在のコードベースやチームのスキルセットを完全に把握したものではないため、あくまで概算です。プロジェクト開始前に、より詳細な調査を行うことで、精度を高めることができます。*
=========================================================================================================================================
*   **Rút ngắn thời gian:** Nhờ tự động hóa các tác vụ định hình, Gemini CLI giúp developer có thể tập trung vào các công việc mang tính sáng tạo như thiết kế và review. Nếu làm thủ công, thời gian có thể kéo dài 1.5 ~ 2 lần vậy nên dự đoán có thể giảm được nhiều thời gian
*   **Cải thiện chất lượng:** Nhờ việc tự động sinh test code giúp nâng test coverage, đồng thời giảm lỗi thao tác thủ công (human error).
---
Bản estimate này chỉ mang tính sơ bộ vì chưa nắm rõ toàn bộ codebase và kỹ năng của team.Trước khi bắt đầu dự án, cần tiến hành khảo sát chi tiết hơn để tăng độ chính xác.

