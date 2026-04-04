//
//  DailyExpenseDetailView.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//

import SwiftUI
internal import Combine
import Foundation
import UserNotifications
import EventKit
import PhotosUI
import UIKit
import CoreImage.CIFilterBuiltins
import Charts

// 詳細頁面 - 日常支出 (改為 Pie Chart)
struct DailyExpenseDetailView: View {
    let expenses: [Expense]
    
    // 修正: 排除 "預約服務" 類別，顯示純日常支出
    var dailyOnlyExpenses: [Expense] { expenses.filter { $0.mainCategory != "預約服務" } }
    
    var groupedData: [(category: String, total: Double)] { Dictionary(grouping: dailyOnlyExpenses, by: { $0.mainCategory }).map { (key, value) in (key, value.reduce(0) { $0 + $1.amount }) }.sorted { $0.1 > $1.1 } }
    var total: Double { dailyOnlyExpenses.reduce(0) { $0 + $1.amount } }
    
    var body: some View {
        List {
            Section("主分類分佈圓餅圖") {
                if groupedData.isEmpty { Text("無資料").foregroundColor(.secondary) }
                else {
                    Chart(groupedData, id: \.category) { item in
                        SectorMark(
                            angle: .value("Amount", item.total),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", item.category))
                        .annotation(position: .overlay) {
                            if item.total / total > 0.05 {
                                Text("\(Int(item.total/total*100))%").font(.caption2).bold().foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 250)
                    .padding(.vertical)
                }
            }
            
            Section("詳細列表") {
                ForEach(groupedData, id: \.category) { item in
                    HStack {
                        Text(item.category)
                        Spacer()
                        Text("$\(Int(item.total))")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden).background(Color.themeBackground)
        .navigationTitle("日常支出詳情")
    }
}



