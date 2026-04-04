//
//  AddIncome.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//
import SwiftUI
import Foundation
import EventKit
import UserNotifications
import PhotosUI
import UIKit
import CoreImage.CIFilterBuiltins
import Charts
internal import Combine

struct AddIncomeView: View {
    @Binding var incomes: [Income]
    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var amount = ""; @State private var category: IncomeCategory = .active; @State private var date = Date(); @State private var note = ""
    var body: some View {
        NavigationView {
            Form {
                Section("金額") { TextField("金額", text: $amount).keyboardType(.decimalPad) }
                Section("分類") { Picker("類型", selection: $category) { ForEach(IncomeCategory.allCases) { cat in HStack { Image(systemName: cat.icon); Text(cat.rawValue) }.tag(cat) } }; Text(category.description).font(.caption).foregroundColor(.secondary) }
                Section("資訊") { DatePicker("日期", selection: $date, displayedComponents: .date); TextField("備註", text: $note) }
                Button("儲存") { if let val = Double(amount) { incomes.append(Income(date: date, amount: val, category: category, note: note)); saveAction(); dismiss() } }.disabled(amount.isEmpty)
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("新增收入").toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
        }
    }
}

