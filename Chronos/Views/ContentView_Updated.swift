//
//  ContentView.swift
//  KinKeep
//
//  加入登入判斷：未登入顯示 AuthView，已登入顯示主介面
//

internal import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var appointments: [Appointment] = []
    @State private var members: [Member] = []
    @State private var generalTransactions: [GeneralTransaction] = []

    init() {
        _appointments = State(initialValue: DataManager.loadAppointments())
        _members = State(initialValue: DataManager.loadMembers())
        _generalTransactions = State(initialValue: DataManager.loadTransactions())
        NotificationManager.requestPermission()
    }

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                mainTabView
            } else {
                AuthView()
            }
        }
    }

    // MARK: - 主 TabView

    private var mainTabView: some View {
        TabView {
            // Tab 1: 預約
            AppointmentListView(
                appointments: $appointments,
                members: members,
                saveAction: saveAppointments,
                deleteAction: deleteAppointments
            )
            .tabItem { Label("預約", systemImage: "list.bullet.clipboard") }

            // Tab 2: 探索
            ExploreView(
                appointments: $appointments,
                members: members,
                saveAction: saveAppointments
            )
            .tabItem { Label("探索", systemImage: "map.fill") }

            // Tab 3: 我的線上預約（新增）
            MyBookingsView()
                .tabItem { Label("訂單", systemImage: "bag.fill") }

            // Tab 4: 收支
            IncomeExpenseView(
                appointments: appointments,
                generalTransactions: $generalTransactions,
                members: members,
                saveAction: saveTransactions
            )
            .tabItem { Label("收支", systemImage: "dollarsign.circle.fill") }

            // Tab 5: 更多
            MoreView(
                members: $members,
                appointments: appointments,
                saveMembersAction: saveMembers
            )
            .tabItem { Label("更多", systemImage: "ellipsis.circle.fill") }
        }
        .tint(.indigo)
    }

    // MARK: - 資料持久化

    func saveAppointments() { DataManager.saveAppointments(appointments) }

    func deleteAppointments(at offsets: IndexSet) {
        let sorted = appointments.sorted(by: { $0.date < $1.date })
        for appt in offsets.map({ sorted[$0] }) {
            if let idx = appointments.firstIndex(where: { $0.id == appt.id }) {
                NotificationManager.cancelReminders(for: appt)
                appointments.remove(at: idx)
            }
        }
        saveAppointments()
    }

    func saveMembers() { DataManager.saveMembers(members) }
    func saveTransactions() { DataManager.saveTransactions(generalTransactions) }
}
