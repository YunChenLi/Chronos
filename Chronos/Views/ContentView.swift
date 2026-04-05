//
//  ContentView.swift
//  Chronos
//

internal import SwiftUI
import UserNotifications

@MainActor

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
                Label("預約列表", systemImage: "list.bullet.clipboard")
            }

            // Tab 2: 預約歷史
            HistoryView(appointments: appointments)
                  .tabItem {
                      Label("預約歷史", systemImage: "clock.fill")
                  }

            // Tab 3: 收入/支出
            IncomeExpenseView(
                appointments: appointments,
                generalTransactions: $generalTransactions,
                members: members,
                saveAction: saveTransactions
            )
            .tabItem {
                Label("收入/支出", systemImage: "dollarsign.circle.fill")
            }

            // Tab 4: 支出報告
            ReportView(
                appointments: appointments,
                generalTransactions: generalTransactions,
                members: members
            )
            .tabItem {
                Label("支出報告", systemImage: "chart.bar.fill")
            }

            // Tab 5: 成員管理
            MemberManagementView(members: $members, saveAction: saveMembers)
                .tabItem {
                    Label("成員管理", systemImage: "person.3.fill")
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
                // 🆕 使用 NotificationManager 取消所有提醒
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

