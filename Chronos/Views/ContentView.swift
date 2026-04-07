//
//  ContentView.swift
//  KinKeep
//

internal import SwiftUI
import UserNotifications

/// 主內容視圖（TabView 入口）
struct ContentView: View {
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
        TabView {
            // Tab 1: 預約列表
            AppointmentListView(
                appointments: $appointments,
                members: members,
                saveAction: saveAppointments,
                deleteAction: deleteAppointments
            )
            .tabItem {
                Label("預約", systemImage: "list.bullet.clipboard")
            }

            // Tab 2: 收入/支出
            IncomeExpenseView(
                appointments: appointments,
                generalTransactions: $generalTransactions,
                members: members,
                saveAction: saveTransactions
            )
            .tabItem {
                Label("收支", systemImage: "dollarsign.circle.fill")
            }

            // Tab 3: 支出報告
            ReportView(
                appointments: appointments,
                generalTransactions: generalTransactions,
                members: members
            )
            .tabItem {
                Label("報告", systemImage: "chart.bar.fill")
            }

            // Tab 4: 更多（成員管理、預約歷史、設定）
            MoreView(
                members: $members,
                appointments: appointments,
                saveMembersAction: saveMembers
            )
            .tabItem {
                Label("更多", systemImage: "ellipsis.circle.fill")
            }
        }
        .tint(.indigo)
    }

    // MARK: - 資料持久化

    func saveAppointments() {
        DataManager.saveAppointments(appointments)
    }

    func deleteAppointments(at offsets: IndexSet) {
        let sortedAppointments = appointments.sorted(by: { $0.date < $1.date })
        let appointmentsToDelete = offsets.map { sortedAppointments[$0] }

        for appointment in appointmentsToDelete {
            if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
                NotificationManager.cancelReminders(for: appointment)
                appointments.remove(at: index)
            }
        }
        saveAppointments()
    }

    func saveMembers() {
        DataManager.saveMembers(members)
    }

    func saveTransactions() {
        DataManager.saveTransactions(generalTransactions)
    }
}

