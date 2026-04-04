//
//  DataManager.swift
//  Chronos
//
//  負責所有 UserDefaults 的存取邏輯
//

import Foundation
import UserNotifications

struct DataManager {

    // MARK: - Keys
    private static let appointmentKey = "StoredAppointments"
    private static let memberKey = "StoredMembers"
    private static let transactionKey = "StoredGeneralTransactions"

    // MARK: - Appointments

    static func loadAppointments() -> [Appointment] {
        if let savedData = UserDefaults.standard.data(forKey: appointmentKey),
           let decoded = try? JSONDecoder().decode([Appointment].self, from: savedData) {
            return decoded
        }
        return []
    }

    static func saveAppointments(_ appointments: [Appointment]) {
        if let encoded = try? JSONEncoder().encode(appointments) {
            UserDefaults.standard.set(encoded, forKey: appointmentKey)
        }
    }

    // MARK: - Members

    static func loadMembers() -> [Member] {
        if let savedData = UserDefaults.standard.data(forKey: memberKey),
           let decoded = try? JSONDecoder().decode([Member].self, from: savedData) {
            return decoded.sorted { $0.name < $1.name }
        }
        return []
    }

    static func saveMembers(_ members: [Member]) {
        if let encoded = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(encoded, forKey: memberKey)
        }
    }

    // MARK: - General Transactions

    static func loadTransactions() -> [GeneralTransaction] {
        if let savedData = UserDefaults.standard.data(forKey: transactionKey),
           let decoded = try? JSONDecoder().decode([GeneralTransaction].self, from: savedData) {
            return decoded
        }
        return []
    }

    static func saveTransactions(_ transactions: [GeneralTransaction]) {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionKey)
        }
    }
}
