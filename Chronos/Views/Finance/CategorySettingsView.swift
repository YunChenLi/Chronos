//
//  CategorySettingsView.swift
//  KinKeep
//
//  管理自訂支出／收入類別
//

import SwiftUI

struct CategorySettingsView: View {
    @StateObject private var categoryManager = CategoryManager.shared
    @State private var newExpenseInput = ""
    @State private var newIncomeInput = ""

    var body: some View {
        NavigationView {
            List {
                // MARK: 支出類別
                Section {
                    // 預設類別（唯讀）
                    ForEach(TransactionCategory.expenseCategories, id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            Text("預設").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    // 自訂類別（可刪除）
                    ForEach(categoryManager.customExpenseCategories, id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            Text("自訂").font(.caption).foregroundColor(.indigo)
                        }
                    }
                    .onDelete { offsets in
                        categoryManager.deleteExpenseCategory(at: offsets)
                    }

                    // 新增支出類別
                    HStack {
                        TextField("新增支出類別（含 Emoji）", text: $newExpenseInput)
                        Button {
                            categoryManager.addExpenseCategory(newExpenseInput)
                            newExpenseInput = ""
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundColor(.red)
                        }
                        .disabled(newExpenseInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill").foregroundColor(.red)
                        Text("💸 支出類別")
                    }
                }

                // MARK: 收入類別
                Section {
                    ForEach(TransactionCategory.incomeCategories, id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            Text("預設").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    ForEach(categoryManager.customIncomeCategories, id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            Text("自訂").font(.caption).foregroundColor(.indigo)
                        }
                    }
                    .onDelete { offsets in
                        categoryManager.deleteIncomeCategory(at: offsets)
                    }

                    HStack {
                        TextField("新增收入類別（含 Emoji）", text: $newIncomeInput)
                        Button {
                            categoryManager.addIncomeCategory(newIncomeInput)
                            newIncomeInput = ""
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundColor(.green)
                        }
                        .disabled(newIncomeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill").foregroundColor(.green)
                        Text("💰 收入類別")
                    }
                }
            }
            .navigationTitle("類別管理")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
