//
//  CalendarGridView.swift
//  Chronos
//

internal import SwiftUI

/// 月曆網格視圖
struct CalendarGridView: View {
    let daysInMonth: [Date]
    let members: [Member]
    let getDailyTransactions: (Date) -> (totalExpense: Double, totalIncome: Double, expenseMembers: [String: Double])
    let dayTapped: (Date) -> Void

    let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }

            // 填補月初的空白
            let firstDay = daysInMonth.first!
            let startOfWeek = Calendar.current.component(.weekday, from: firstDay) - 1
            ForEach(0..<startOfWeek, id: \.self) { _ in Spacer() }

            // 日期單元格
            ForEach(daysInMonth, id: \.self) { date in
                DayCellView(date: date, members: members, getDailyTransactions: getDailyTransactions)
                    .onTapGesture { dayTapped(date) }
            }
        }
    }
}

/// 月曆中單日的儲存格視圖
struct DayCellView: View {
    let date: Date
    let members: [Member]
    let getDailyTransactions: (Date) -> (totalExpense: Double, totalIncome: Double, expenseMembers: [String: Double])

    @State private var transactions: (totalExpense: Double, totalIncome: Double, expenseMembers: [String: Double]) = (0, 0, [:])

    var memberColors: [Color] {
        transactions.expenseMembers.keys
            .compactMap { name in members.first(where: { $0.name == name }) }
            .map { Color(hex: $0.colorHex) }
            .prefix(3)
            .map { $0 }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(date, format: .dateTime.day())
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .white : .primary)
                .frame(maxWidth: .infinity)
                .background(isToday ? Color.indigo : Color.clear)
                .clipShape(Circle())

            if transactions.totalExpense > 0 {
                HStack(spacing: 1) {
                    ForEach(memberColors.indices, id: \.self) { index in
                        Circle().fill(memberColors[index]).frame(width: 4, height: 4)
                    }
                    Text("-\(transactions.totalExpense, specifier: "%.0f")")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            } else {
                Spacer().frame(height: 14)
            }

            if transactions.totalIncome > 0 {
                Text("+\(transactions.totalIncome, specifier: "%.0f")")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            } else {
                Spacer().frame(height: 14)
            }
        }
        .padding(.vertical, 5)
        .frame(minHeight: 60)
        .background(Color.gray.opacity(Calendar.current.isDateInToday(date) ? 0.2 : 0.05))
        .cornerRadius(8)
        .onAppear {
            transactions = getDailyTransactions(date)
        }
    }
}
