//
//  ReportView.swift
//  Chronos
//

import SwiftUI

/// 支出報告視圖 (Tab 4)
struct ReportView: View {
    let appointments: [Appointment]
    let generalTransactions: [GeneralTransaction]
    let members: [Member]

    enum ReportCategory: String, CaseIterable, Identifiable {
        case service = "預約服務總計"
        case member  = "成員支出總結"
        case month   = "月份支出總計"
        var id: String { self.rawValue }
    }

    @State private var selectedCategory: ReportCategory = .service

    var overallTotalExpense: Double {
        let apptExpense = appointments.reduce(0) { $0 + ($1.amount ?? 0) }
        let generalExpense = generalTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return apptExpense + generalExpense
    }

    var overallTotalIncome: Double {
        generalTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var serviceTotals: [(service: String, total: Double)] {
        let grouped = Dictionary(grouping: appointments.compactMap { $0.amount != nil ? ($0.service, $0.amount!) : nil }) { $0.0 }
        return grouped.map { (service, items) in
            (service, items.reduce(0) { $0 + $1.1 })
        }.sorted { $0.total > $1.total }
    }

    var memberTotals: [(member: String, total: Double, colorHex: String)] {
        var totals: [String: Double] = [:]
        for appt in appointments where appt.amount != nil {
            totals[appt.name, default: 0] += appt.amount!
        }
        for transaction in generalTransactions where transaction.type == .expense {
            totals[transaction.memberName, default: 0] += transaction.amount
        }
        return totals.map { (name, total) in
            let color = members.first(where: { $0.name == name })?.colorHex ?? "#000000"
            return (name, total, color)
        }.sorted { $0.total > $1.total }
    }

    var monthTotals: [(month: String, total: Double)] {
        var monthlyTotals: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 MM月"

        for appt in appointments where appt.amount != nil {
            monthlyTotals[formatter.string(from: appt.date), default: 0] += appt.amount!
        }
        for transaction in generalTransactions where transaction.type == .expense {
            monthlyTotals[formatter.string(from: transaction.date), default: 0] += transaction.amount
        }
        return monthlyTotals.map { ($0, $1) }.sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationView {
            VStack {
                if overallTotalExpense == 0 && overallTotalIncome == 0 {
                    ContentUnavailableView {
                        Label("無營收或支出資料", systemImage: "chart.bar.xaxis.ascending")
                    } description: {
                        Text("請新增預約並填寫金額，或在「收入/支出」頁面記錄日常收支。")
                    }
                } else {
                    List {
                        Section("家庭收支總覽 (Total Overview)") {
                            HStack {
                                Text("累積總支出")
                                Spacer()
                                Text("$\(overallTotalExpense, specifier: "%.0f")")
                                    .font(.title2).fontWeight(.bold).foregroundColor(.red)
                            }
                            HStack {
                                Text("累積總收入")
                                Spacer()
                                Text("$\(overallTotalIncome, specifier: "%.0f")")
                                    .font(.title2).fontWeight(.bold).foregroundColor(.green)
                            }
                        }

                        if overallTotalExpense > 0 {
                            Section("支出比例分析 (Proportion Analysis)") {
                                let chartData: [(label: String, value: Double)] = {
                                    switch selectedCategory {
                                    case .service: return serviceTotals.map { ($0.service, $0.total) }
                                    case .member:  return memberTotals.map { ($0.member, $0.total) }
                                    case .month:   return monthTotals.map { ($0.month, $0.total) }
                                    }
                                }()

                                ProportionChart(data: chartData, total: overallTotalExpense)
                                    .listRowInsets(EdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0))
                            }

                            Picker("分類方式", selection: $selectedCategory) {
                                ForEach(ReportCategory.allCases) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)
                            .listRowInsets(EdgeInsets())
                            .padding([.horizontal, .top], 10)

                            switch selectedCategory {
                            case .service:
                                Section(ReportCategory.service.rawValue) {
                                    ForEach(serviceTotals, id: \.service) { item in
                                        HStack {
                                            Image(systemName: "tag.fill").foregroundColor(.indigo)
                                            Text(item.service)
                                            Spacer()
                                            Text("$\(item.total, specifier: "%.0f")").fontWeight(.medium)
                                        }
                                    }
                                }
                            case .member:
                                Section(ReportCategory.member.rawValue) {
                                    ForEach(memberTotals, id: \.member) { item in
                                        HStack {
                                            Circle().fill(Color(hex: item.colorHex)).frame(width: 10, height: 10)
                                            Text(item.member)
                                            Spacer()
                                            Text("$\(item.total, specifier: "%.0f")")
                                                .fontWeight(.medium).foregroundColor(.red)
                                        }
                                    }
                                }
                            case .month:
                                Section(ReportCategory.month.rawValue) {
                                    ForEach(monthTotals, id: \.month) { item in
                                        HStack {
                                            Image(systemName: "calendar").foregroundColor(.green)
                                            Text(item.month)
                                            Spacer()
                                            Text("$\(item.total, specifier: "%.0f")")
                                                .fontWeight(.medium).foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("支出報告")
        }
    }
}
