//
//  IncomeExpenseView.swift
//  Chronos
//

import SwiftUI

/// 收入/支出視圖 (Tab 3)
struct IncomeExpenseView: View {
    let appointments: [Appointment]
    @Binding var generalTransactions: [GeneralTransaction]
    let members: [Member]
    var saveAction: () -> Void

    @State private var currentDate = Date()
    @State private var isAddingTransaction = false
    @State private var selectedDate: Date?

    var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentDate))!
    }

    var monthEnd: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
    }

    var daysInMonth: [Date] {
        var dates: [Date] = []
        let range = Calendar.current.range(of: .day, in: .month, for: monthStart)!
        for i in range {
            if let date = Calendar.current.date(byAdding: .day, value: i - 1, to: monthStart) {
                dates.append(date)
            }
        }
        return dates
    }

    func getDailyTransactions(for date: Date) -> (totalExpense: Double, totalIncome: Double, expenseMembers: [String: Double]) {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        var totalExpense = 0.0
        var totalIncome = 0.0
        var expenseMembers: [String: Double] = [:]

        let dailyAppointments = appointments.filter { $0.date >= dayStart && $0.date < dayEnd && $0.amount != nil }
        for appt in dailyAppointments {
            totalExpense += appt.amount!
            expenseMembers[appt.name, default: 0] += appt.amount!
        }

        let dailyTransactions = generalTransactions.filter { $0.date >= dayStart && $0.date < dayEnd }
        for transaction in dailyTransactions {
            if transaction.type == .expense {
                totalExpense += transaction.amount
                expenseMembers[transaction.memberName, default: 0] += transaction.amount
            } else {
                totalIncome += transaction.amount
            }
        }

        return (totalExpense, totalIncome, expenseMembers)
    }

    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 月份導航
                HStack {
                    Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(monthStart, format: .dateTime.year().month())
                        .font(.title2).fontWeight(.bold)
                    Spacer()
                    Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right") }
                }
                .padding()
                .background(Color(.systemBackground))

                // 日曆網格
                CalendarGridView(
                    daysInMonth: daysInMonth,
                    members: members,
                    getDailyTransactions: getDailyTransactions
                ) { date in
                    selectedDate = date
                    isAddingTransaction = true
                }
                .padding(.horizontal)

                // 成員圖例
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(members.sorted { $0.name < $1.name }) { member in
                            HStack {
                                Circle()
                                    .fill(Color(hex: member.colorHex))
                                    .frame(width: 10, height: 10)
                                Text(member.name).font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("收支月曆")
            .sheet(isPresented: $isAddingTransaction) {
                AddGeneralTransactionView(
                    generalTransactions: $generalTransactions,
                    members: members,
                    saveAction: saveAction,
                    initialDate: selectedDate ?? Date()
                )
            }
        }
    }
}
