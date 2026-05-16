//
//  AppUser.swift
//  KinKeep
//

import Foundation

enum UserRole: String, Codable {
    case consumer  = "consumer"
    case shopOwner = "shop_owner"
}

struct AppUser: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var phone: String?
    var role: UserRole
    var shopID: String?
    var noShowCount: Int = 0        // 🆕 放鳥次數
    var requiresDeposit: Bool = false // 🆕 是否需要訂金
    var createdAt: Date

    init(id: String, name: String, email: String, phone: String? = nil,
         role: UserRole = .consumer, shopID: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.shopID = shopID
        self.noShowCount = 0
        self.requiresDeposit = false
        self.createdAt = Date()
    }
}

enum BookingStatus: String, Codable, CaseIterable {
    case pending   = "pending"
    case confirmed = "confirmed"
    case cancelled = "cancelled"
    case completed = "completed"
    case noShow    = "noShow"      // 🆕 放鳥

    var displayText: String {
        switch self {
        case .pending:   return "等待確認"
        case .confirmed: return "已確認"
        case .cancelled: return "已取消"
        case .completed: return "已完成"
        case .noShow:    return "未出現"
        }
    }

    var color: String {
        switch self {
        case .pending:   return "#FF9500"
        case .confirmed: return "#34C759"
        case .cancelled: return "#8E8E93"
        case .completed: return "#5C5CFF"
        case .noShow:    return "#FF3B30"
        }
    }

    var icon: String {
        switch self {
        case .pending:   return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .completed: return "star.circle.fill"
        case .noShow:    return "person.fill.xmark"
        }
    }
}

struct OnlineBooking: Identifiable, Codable {
    var id: String
    var consumerID: String
    var consumerName: String
    var consumerPhone: String?
    var shopID: String
    var shopName: String
    var shopAddress: String        // 🆕 店家地址
    var serviceName: String
    var servicePrice: Double
    var serviceDuration: Int
    var date: Date
    var status: BookingStatus
    var note: String?
    var depositPaid: Bool = false  // 🆕 訂金是否已付
    var depositAmount: Double = 0  // 🆕 訂金金額
    var cancelledAt: Date? = nil   // 🆕 取消時間
    var cancelReason: String? = nil // 🆕 取消原因
    var createdAt: Date

    // 是否可取消（提前 24 小時）
    var canCancel: Bool {
        guard status == .pending || status == .confirmed else { return false }
        let hoursUntil = date.timeIntervalSinceNow / 3600
        return hoursUntil >= 24
    }

    // 距離預約剩餘時間文字
    var timeUntilText: String {
        let interval = date.timeIntervalSinceNow
        if interval < 0 { return "已過期" }
        let hours = Int(interval / 3600)
        if hours < 24 { return "剩 \(hours) 小時" }
        let days = hours / 24
        return "剩 \(days) 天"
    }

    init(consumerID: String, consumerName: String, consumerPhone: String? = nil,
         shopID: String, shopName: String, shopAddress: String = "",
         serviceName: String, servicePrice: Double, serviceDuration: Int,
         date: Date, note: String? = nil) {
        self.id = UUID().uuidString
        self.consumerID = consumerID
        self.consumerName = consumerName
        self.consumerPhone = consumerPhone
        self.shopID = shopID
        self.shopName = shopName
        self.shopAddress = shopAddress
        self.serviceName = serviceName
        self.servicePrice = servicePrice
        self.serviceDuration = serviceDuration
        self.date = date
        self.status = .pending
        self.note = note
        self.createdAt = Date()
    }
}

