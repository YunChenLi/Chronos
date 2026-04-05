//
//  Appointment.swift
//  KinKeep
//

import Foundation

/// 預約資料的結構
struct Appointment: Identifiable, Codable {
    var id = UUID()
    var name: String
    var date: Date
    var service: String
    var email: String?
    var phone: String?
    var amount: Double?
    var photoDescription: String?
    var photoData: Data?          // 🔴 真實照片資料
    var extraServiceDetail: String?

    // 提醒選項（可複選）
    var reminderOptions: [ReminderOption] = [.thirtyMin]

    // 重複預約設定
    var recurrence: RecurrenceOption = .none
    var recurrenceGroupID: UUID?

    // 照片是否已附加（由 photoData 決定，不再是獨立欄位）
    var isPhotoAttached: Bool { photoData != nil }

    var displayAmount: Double { amount ?? 0.0 }
}

// MARK: - 提醒選項
enum ReminderOption: String, Codable, CaseIterable, Identifiable {
    case oneDay    = "提前 1 天"
    case oneHour   = "提前 1 小時"
    case thirtyMin = "提前 30 分鐘"
    case tenMin    = "提前 10 分鐘"

    var id: String { self.rawValue }

    var minutesBefore: Int {
        switch self {
        case .oneDay:    return 1440
        case .oneHour:   return 60
        case .thirtyMin: return 30
        case .tenMin:    return 10
        }
    }

    var icon: String {
        switch self {
        case .oneDay:    return "calendar.badge.clock"
        case .oneHour:   return "clock"
        case .thirtyMin: return "clock.badge.exclamationmark"
        case .tenMin:    return "bell.badge"
        }
    }
}

// MARK: - 重複週期選項
enum RecurrenceOption: String, Codable, CaseIterable, Identifiable {
    case none      = "不重複"
    case weekly    = "每週"
    case biweekly  = "每兩週"
    case monthly   = "每月"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .none:     return "slash.circle"
        case .weekly:   return "repeat"
        case .biweekly: return "repeat.1"
        case .monthly:  return "calendar.badge.clock"
        }
    }

    func generateDates(from startDate: Date, count: Int) -> [Date] {
        guard self != .none else { return [startDate] }
        var dates: [Date] = []
        for i in 0..<count {
            let (component, value): (Calendar.Component, Int) = {
                switch self {
                case .weekly:   return (.weekOfYear, i)
                case .biweekly: return (.weekOfYear, i * 2)
                case .monthly:  return (.month, i)
                case .none:     return (.day, 0)
                }
            }()
            if let date = Calendar.current.date(byAdding: component, value: value, to: startDate) {
                dates.append(date)
            }
        }
        return dates
    }
}

