```mermaid
gantt
    title OAuth2サーバー近代化移行プロジェクト ガントチャート
    dateFormat  YYYY-MM-DD
    axisFormat %Y-%m-%d
    
    section フェーズ1: service-framework の再設計と分割
    機能分割 (Starter化)      :active, 2025-07-14, 15d
    enumの排除 (DB/Config化) :after 機能分割 (Starter化), 10d
    
        section フェーズ2: service-security の開発
    service-oauth2-server-new の開発 :after enumの排除 (DB/Config化), 15d
    
    section フェーズ3: サンプルサービス移行
    依存関係の再マッピング (pom.xml修正) :crit, after service-oauth2-server-new の開発, 2d
    名前空間とAPIの移行 (jakarta化)   :after 依存関係の再マッピング (pom.xml修正), 3d
    ロジックのリファクタリング (enum置換) :after 名前空間とAPIの移行 (jakarta化), 3d
    
    section フェーズ4: クライアント移行
    段階的なクライアント移行          :after ロジックのリファクタリング (enum置換), 10d
    
    section フェーズ5: 旧システム廃止
    旧システムの廃止作業            :milestone, after 段階的なクライアント移行, 3d

```
Phần Gant Chart này tham khảo 2 file ảnh (Mermaid Chart - JP và Mermaid Chart - VN ) đính kèm trong thư mục

### スケジュールサマリー | Summary Schedule

*   **プロジェクト開始日:** 2025年7月14日 (月) | Ngày bắt đầu Project : 2025/07/14 (Thứ 2)
*   **フェーズ1完了予定日:** 2025年8月15日 (金) | Ngày dự kiến kết thúc phase 1 : 2025/08/15 (Thứ 6)
*   **フェーズ2完了予定日:** 2025年9月5日 (金) | Ngày dự kiến kết thúc phase 2 : 2025/09/5 (Thứ 6)
*   **フェーズ3完了予定日:** 2025年9月17日 (水) | Ngày dự kiến kết thúc phase 3 : 2025/09/17 (Thứ tư)
*   **フェーズ4完了予定日:** 2025年10月1日 (水) | Ngày dự kiến kết thúc phase 4 : 2025/10/01 (Thứ tư)
*   **プロジェクト完了予定日:** 2025年10月6日 (月) | Ngày dự kiến kết thúc dự án : 2025/10/06 (Thứ 2)

**注:** このガントチャートは、各フェーズが直列に進むことを前提としています。実際には、テストやドキュメント作成などのタスクは各フェーズで並行して行われます。
========================================
**Chú ý:** Biểu đồ Gantt này được lập với giả định rằng các giai đoạn sẽ được tiến hành tuần tự.
Tuy nhiên, trên thực tế, các tác vụ như kiểm thử và soạn tài liệu sẽ được thực hiện song song trong từng giai đoạn.
