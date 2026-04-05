# Chronos 📅

一個用 SwiftUI 開發的家庭預約與收支管理 App。

## 功能特色

- **預約列表** — 新增、編輯、刪除服務預約，自動設定本地通知提醒
- **預約歷史** — 依月份分類瀏覽所有歷史預約
- **收支月曆** — 以月曆形式查看每日收支，快速新增日常交易
- **支出報告** — 依服務項目、成員、月份分類的圖表分析
- **成員管理** — 管理家庭成員資料與代表顏色

## 技術架構

```
Chronos/
├── App/                    # App 入口 (@main)
    ChronosApp/
├── Models/                 # 資料模型 (Member, Appointment, GeneralTransaction/
    Appointment/
    Member/
    CategoryManager/
├── Views/
│   ├── Appointment/        # 預約相關視圖
        AppointmentListView/
        EditAppointView/
        AddAppointView/
│   ├── Finance/            # 收支相關視圖
        CategorySettingView/
        AddGeneralTransationView/
        IncomeExpenseView/
        ReportView/
│   ├── History/            # 歷史記錄視圖
        HistoryView/
│   ├── Member/             # 成員管理視圖
        MemberManagementView/
│   └── Components/         # 共用元件 (CalendarGridView, ProportionChart)
        CalendarGridView/
        ProportionChart/
        InvoiceView/
        ImagePicker/
├── Extensions/ # Swift 擴充 (Color+Hex)
    Color+Hex/
└── Persistence/            # 資料儲存邏輯 (DataManager)
    DataManager/
    NotificationManager/
```

## 系統需求

- iOS 17+
- Xcode 15+
- Swift 5.9+

## 權限需求

- **通知** — 預約提醒（30 分鐘前）
- **行事曆** — 將預約同步至 Apple 行事曆

## 安裝方式

1. Clone 此 Repository
2. 用 Xcode 開啟 `Chronos.xcodeproj`
3. 選擇目標裝置或模擬器
4. 按下 `Cmd + R` 執行

---

Made with ❤️ using SwiftUI
