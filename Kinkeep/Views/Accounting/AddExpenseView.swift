//
//  AddExpenseView.swift
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

struct AddExpenseView: View {
    @Binding var expenses: [Expense]
    let members: [Member] // 接收成員列表
    var selectedDate: Date
    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lifestyleManager: LifestyleManager
    
    @State private var amount = ""
    @State private var mainCategory = "食"
    @State private var subCategory = ""
    @State private var customSubCategory = ""
    @State private var note = ""
    
    // 成員選擇
    @State private var selectedMemberId: UUID?
    
    @State private var isRecurring = false
    @State private var recurrenceFrequency = "每月固定日期"
    let recurrenceOptions = ["每天", "每兩個禮拜", "每月固定日期"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("金額") { TextField("輸入金額", text: $amount).keyboardType(.decimalPad) }
                
                // 新增：消費成員選擇
                Section("消費成員") {
                    Picker("選擇成員", selection: $selectedMemberId) {
                        Text("未指定").tag(UUID?.none)
                        ForEach(members) { member in
                            Text("\(member.role.icon) \(member.name)").tag(Optional(member.id))
                        }
                    }
                }
                
                Section("分類") {
                    Picker("主分類", selection: $mainCategory) {
                        ForEach(lifestyleManager.mainCategories, id: \.self) { Text($0).tag($0) }
                    }
                    .onChange(of: mainCategory) { _, newVal in
                        if let first = lifestyleManager.getSubCategories(for: newVal).first { subCategory = first } else { subCategory = "" }
                    }
                    if mainCategory == "其他" { TextField("類別名稱", text: $customSubCategory) }
                    else {
                        let subs = lifestyleManager.getSubCategories(for: mainCategory)
                        if !subs.isEmpty { Picker("子分類", selection: $subCategory) { ForEach(subs, id: \.self) { Text($0).tag($0) } } }
                    }
                }
                
                Section("固定/重複支出") {
                    Toggle("設為重複", isOn: $isRecurring)
                    if isRecurring {
                        Picker("頻率", selection: $recurrenceFrequency) { ForEach(recurrenceOptions, id: \.self) { Text($0) } }
                        Text("自動建立未來一年紀錄").font(.caption).foregroundStyle(.secondary)
                    }
                }
                
                Section("備註") { TextField("備註 (如：貸款、房租...)", text: $note) }
                
                Button("儲存") {
                    if let amt = Double(amount) {
                        let finalSub = (mainCategory == "其他") ? (customSubCategory.isEmpty ? "雜項" : customSubCategory) : subCategory
                        var expensesToAdd: [Expense] = []
                        let calendar = Calendar.current
                        
                        if isRecurring {
                            let count = recurrenceFrequency == "每天" ? 365 : (recurrenceFrequency == "每兩個禮拜" ? 26 : 12)
                            for i in 0..<count {
                                var dateComponent = DateComponents()
                                if recurrenceFrequency == "每天" { dateComponent.day = i }
                                else if recurrenceFrequency == "每兩個禮拜" { dateComponent.day = i * 14 }
                                else { dateComponent.month = i }
                                
                                if let nextDate = calendar.date(byAdding: dateComponent, to: selectedDate) {
                                    expensesToAdd.append(Expense(date: nextDate, amount: amt, mainCategory: mainCategory, subCategory: finalSub, note: note, memberId: selectedMemberId))
                                }
                            }
                        } else {
                            expensesToAdd.append(Expense(date: selectedDate, amount: amt, mainCategory: mainCategory, subCategory: finalSub, note: note, memberId: selectedMemberId))
                        }
                        expenses.append(contentsOf: expensesToAdd); saveAction(); dismiss()
                    }
                }.disabled(amount.isEmpty)
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("新增支出")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .onAppear {
                if subCategory.isEmpty, let first = lifestyleManager.getSubCategories(for: mainCategory).first { subCategory = first }
                // 預設選第一個成員
                if selectedMemberId == nil, let firstMember = members.first {
                    selectedMemberId = firstMember.id
                        
                }
            }
        }
    }
}
    
