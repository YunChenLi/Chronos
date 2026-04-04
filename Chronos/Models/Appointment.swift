//
//  Appointment.swift
//  Chronos
//

import Foundation

/// 預約資料的結構
struct Appointment: Identifiable, Codable {
    var id = UUID()
    var name: String          // 預約者姓名/家庭成員名稱
    var date: Date
    var service: String       // 服務項目，含 Emoji
    var email: String?
    var phone: String?
    var amount: Double?       // 消費金額 (可選)
    var photoDescription: String?
    var isPhotoAttached: Bool = false
    var extraServiceDetail: String? // 如果服務是「其他」，記錄額外詳情

    var displayAmount: Double {
        return amount ?? 0.0
    }
}
