//
//  GeneralTransaction.swift
//  KinKeep
//

import Foundation

/// 日常交易資料結構
struct GeneralTransaction: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var memberName: String
    var amount: Double
    var description: String
    var type: TransactionType
    var category: String          // 🆕 支出／收入類別
    var invoiceCarrier: String?   // 🆕 雲端發票載具號碼（如 /ABC-DEF）
    var invoiceImageData: Data?   // 🆕 發票掃描照片

    enum TransactionType: String, Codable {
        case income  = "收入"
        case expense = "支出"
    }
}

// MARK: - 預設類別

struct TransactionCategory {
    static let expenseCategories: [String] = [
        "🍽 餐飲", "🚗 交通", "🏥 醫療", "🛍 購物",
        "🏠 居家", "📚 教育", "🎮 娛樂", "💇 美容美髮",
        "💪 運動健身", "✈️ 旅遊", "📱 通訊", "🔧 維修",
        "💡 水電瓦斯", "🎁 禮物", "📋 其他"
    ]

    static let incomeCategories: [String] = [
        "💼 薪資", "📈 投資獲利", "🎁 獎金", "🏠 租金收入",
        "💰 兼職收入", "🎉 紅包", "💳 退款", "📋 其他"
    ]
}

