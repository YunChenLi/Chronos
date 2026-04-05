//
//  NotificationManager.swift
//  KinKeep
//

import Foundation
import UserNotifications

struct NotificationManager {

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, error in
            if let error = error {
                print("通知權限錯誤: \(error.localizedDescription)")
            }
        }
    }

    static func scheduleReminders(for appointment: Appointment, options: [ReminderOption]) {
        cancelReminders(for: appointment)
        let center = UNUserNotificationCenter.current()

        for option in options {
            guard let reminderDate = Calendar.current.date(
                byAdding: .minute, value: -option.minutesBefore, to: appointment.date
            ), reminderDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "⏰ 預約提醒"
            content.body = "\(option.rawValue)：\(appointment.name) 的「\(appointment.service)」即將開始"
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let requestID = "\(appointment.id.uuidString)-\(option.rawValue)"
            let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error { print("排程通知失敗: \(error.localizedDescription)") }
            }
        }
    }

    static func cancelReminders(for appointment: Appointment) {
        let ids = ReminderOption.allCases.map { "\(appointment.id.uuidString)-\($0.rawValue)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ids + [appointment.id.uuidString]
        )
    }
}

