//
//  GeneralTransaction.swift
//  Chronos
//

import Foundation

/// 日常交易資料結構
struct GeneralTransaction: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var memberName: String // 誰的支出/收入
    var amount: Double
    var description: String
    var type: TransactionType

    enum TransactionType: String, Codable {
        case income = "收入"
        case expense = "支出"
    }
}
