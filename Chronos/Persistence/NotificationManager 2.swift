//
//  NotificationManager.swift
//  KinKeep
//
//  負責所有本地通知的排程與管理
//

import Foundation
import UserNotifications

/// 提醒時間選項
enum ReminderOption: String, Codable, CaseIterable, Identifiable {
    case oneDay     = "提前 1 天"
    case oneHour    = "提前 1 小時"
    case thirtyMin  = "提前 30 分鐘"
    case tenMin     = "提前 10 分鐘"

    var id: String { self.rawValue }

    /// 換算成「往前幾分鐘」
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

struct NotificationManager {

    // MARK: - 請求通知權限
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("通知權限錯誤: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 排程多重提醒
    static func scheduleReminders(for appointment: Appointment, options: [ReminderOption]) {
        let center = UNUserNotificationCenter.current()

        // 先清除這筆預約的所有舊通知
        cancelReminders(for: appointment)

        for option in options {
            guard let reminderDate = Calendar.current.date(
                byAdding: .minute,
                value: -option.minutesBefore,
                to: appointment.date
            ) else { continue }

            // 如果提醒時間已經過去，跳過
            guard reminderDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "⏰ 預約提醒"
            content.body = "\(option.rawValue)：\(appointment.name) 的「\(appointment.service)」即將開始"
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            // 每個提醒有獨立 ID：appointmentID + option
            let requestID = "\(appointment.id.uuidString)-\(option.rawValue)"
            let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("排程通知失敗: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 取消提醒
    static func cancelReminders(for appointment: Appointment) {
        let ids = ReminderOption.allCases.map { "\(appointment.id.uuidString)-\($0.rawValue)" }
        // 也清除舊版單一通知 ID
        let legacyID = appointment.id.uuidString
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ids + [legacyID]
        )
    }
}
