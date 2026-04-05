//
//  ReportView.swift
//  KinKeep
//

internal import SwiftUI

/// 支出報告視圖 (Tab 4)
struct ReportView: View {
    let appointments: [Appointment]
    let generalTransactions: [GeneralTransaction]
    let members: [Member]

    enum ReportCategory: String, CaseIterable, Identifiable {
        case service  = "預約服務"
        case category = "支出類別"   // 🆕
        case member   = "成員"
        case month    = "月份"
        var id: String { self.rawValue }
    }

    @State private var selectedCategory: ReportCategory = .category

    var overallTotalExpense: Double {
        let apptExpense = appointments.reduce(0) { $0 + ($1.amount ?? 0) }
        let generalExpense = generalTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return apptExpense + generalExpense
    }

    var overallTotalIncome: Double {
        generalTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    // 按預約服務分類
    var serviceTotals: [(label: String, value: Double)] {
        let grouped = Dictionary(grouping: appointments.compactMap { $0.amount != nil ? ($0.service, $0.amount!) : nil }) { $0.0 }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.1 }) }.sorted { $0.1 > $1.1 }
    }

    // 🆕 按支出類別分類（一般交易）
    var categoryTotals: [(label: String, value: Double)] {
        let expenses = generalTransactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses) { $0.category }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
    }

    // 按成員分類
    var memberTotals: [(label: String, value: Double, colorHex: String)] {
        var totals: [String: Double] = [:]
        for appt in appointments where appt.amount != nil { totals[appt.name, default: 0] += appt.amount! }
        for t in generalTransactions where t.type == .expense { totals[t.memberName, default: 0] += t.amount }
        return totals.map { name, total in
            let color = members.first(where: { $0.name == name })?.colorHex ?? "#5C5CFF"
            return (name, total, color)
        }.sorted { $0.1 > $1.1 }
    }

    // 按月份分類
    var monthTotals: [(label: String, value: Double)] {
        var totals: [String: Double] = [:]
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy年 MM月"
        for appt in appointments where appt.amount != nil { totals[fmt.string(from: appt.date), default: 0] += appt.amount! }
        for t in generalTransactions where t.type == .expense { totals[fmt.string(from: t.date), default: 0] += t.amount }
        return totals.map { ($0, $1) }.sorted { $0.0 > $1.0 }
    }

    var currentChartData: [(label: String, value: Double)] {
        switch selectedCategory {
        case .service:  return serviceTotals
        case .category: return categoryTotals
        case .member:   return memberTotals.map { ($0.label, $0.value) }
        case .month:    return monthTotals
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if overallTotalExpense == 0 && overallTotalIncome == 0 {
                    ContentUnavailableView {
                        Label("無收支資料", systemImage: "chart.bar.xaxis.ascending")
                    } description: {
                        Text("請新增預約或在「收入/支出」頁面記錄日常收支。")
                    }
                } else {
                    List {
                        // 總覽
                        Section("家庭收支總覽") {
                            HStack {
                                Label("累積總支出", systemImage: "arrow.down.circle.fill")
                                    .foregroundColor(.red)
                                Spacer()
                                Text("$\(overallTotalExpense, specifier: "%.0f")")
                                    .font(.title2).fontWeight(.bold).foregroundColor(.red)
                            }
                            HStack {
                                Label("累積總收入", systemImage: "arrow.up.circle.fill")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("$\(overallTotalIncome, specifier: "%.0f")")
                                    .font(.title2).fontWeight(.bold).foregroundColor(.green)
                            }
                            HStack {
                                Label("淨餘額", systemImage: "equal.circle.fill")
                                    .foregroundColor(.indigo)
                                Spacer()
                                let net = overallTotalIncome - overallTotalExpense
                                Text("$\(net, specifier: "%.0f")")
                                    .font(.title2).fontWeight(.bold)
                                    .foregroundColor(net >= 0 ? .green : .red)
                            }
                        }

                        if overallTotalExpense > 0 {
                            // 分類切換
                            Section {
                                Picker("分類方式", selection: $selectedCategory) {
                                    ForEach(ReportCategory.allCases) { cat in
                                        Text(cat.rawValue).tag(cat)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

                            // 比例圖表
                            Section("支出比例分析") {
                                if currentChartData.isEmpty {
                                    Text("此分類暫無資料").foregroundColor(.secondary)
                                } else {
                                    ProportionChart(data: currentChartData, total: overallTotalExpense)
                                        .listRowInsets(EdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0))
                                }
                            }

                            // 詳細列表
                            Section("\(selectedCategory.rawValue)明細") {
                                if selectedCategory == .member {
                                    ForEach(memberTotals, id: \.label) { item in
                                        HStack {
                                            Circle().fill(Color(hex: item.colorHex)).frame(width: 10, height: 10)
                                            Text(item.label)
                                            Spacer()
                                            Text("$\(item.value, specifier: "%.0f")")
                                                .fontWeight(.medium).foregroundColor(.red)
                                        }
                                    }
                                } else {
                                    ForEach(currentChartData, id: \.label) { item in
                                        HStack {
                                            Text(item.label)
                                            Spacer()
                                            Text("$\(item.value, specifier: "%.0f")")
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

