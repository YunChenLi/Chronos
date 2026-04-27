//
//  AppUser.swift
//  KinKeep
//
//  用戶資料模型
//

import Foundation

/// 用戶角色
enum UserRole: String, Codable {
    case consumer   = "consumer"    // 消費者
    case shopOwner  = "shop_owner"  // 店家老闆
}

/// App 用戶資料
struct AppUser: Identifiable, Codable {
    var id: String          // Firebase Auth UID
    var name: String
    var email: String
    var phone: String?
    var role: UserRole
    var shopID: String?     // 如果是店家老闆，對應的店家 ID
    var createdAt: Date

    init(id: String, name: String, email: String, phone: String? = nil,
         role: UserRole = .consumer, shopID: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.shopID = shopID
        self.createdAt = Date()
    }
}

/// 預約狀態
enum BookingStatus: String, Codable {
    case pending    = "pending"     // 等待店家確認
    case confirmed  = "confirmed"   // 店家已確認
    case cancelled  = "cancelled"   // 已取消
    case completed  = "completed"   // 已完成

    var displayText: String {
        switch self {
        case .pending:   return "等待確認"
        case .confirmed: return "已確認"
        case .cancelled: return "已取消"
        case .completed: return "已完成"
        }
    }

    var color: String {
        switch self {
        case .pending:   return "#FF9500"
        case .confirmed: return "#34C759"
        case .cancelled: return "#FF3B30"
        case .completed: return "#8E8E93"
        }
    }

    var icon: String {
        switch self {
        case .pending:   return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .completed: return "star.circle.fill"
        }
    }
}

/// 線上預約記錄（Firebase 版）
struct OnlineBooking: Identifiable, Codable {
    var id: String          // Firestore 文件 ID
    var consumerID: String
    var consumerName: String
    var consumerPhone: String?
    var shopID: String
    var shopName: String
    var serviceName: String
    var servicePrice: Double
    var serviceDuration: Int
    var date: Date
    var status: BookingStatus
    var note: String?
    var createdAt: Date

    init(consumerID: String, consumerName: String, consumerPhone: String? = nil,
         shopID: String, shopName: String, serviceName: String,
         servicePrice: Double, serviceDuration: Int, date: Date, note: String? = nil) {
        self.id = UUID().uuidString
        self.consumerID = consumerID
        self.consumerName = consumerName
        self.consumerPhone = consumerPhone
        self.shopID = shopID
        self.shopName = shopName
        self.serviceName = serviceName
        self.servicePrice = servicePrice
        self.serviceDuration = serviceDuration
        self.date = date
        self.status = .pending
        self.note = note
        self.createdAt = Date()
    }
}
