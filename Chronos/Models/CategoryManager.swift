//
//  CategoryManager.swift
//  KinKeep
//
//  管理支出／收入類別（預設 + 使用者自訂）
//

import Foundation

class CategoryManager: ObservableObject {
    static let shared = CategoryManager()

    private let expenseKey = "CustomExpenseCategories"
    private let incomeKey  = "CustomIncomeCategories"

    @Published var customExpenseCategories: [String] = []
    @Published var customIncomeCategories: [String] = []

    init() {
        customExpenseCategories = load(key: expenseKey)
        customIncomeCategories  = load(key: incomeKey)
    }

    // 所有支出類別（預設 + 自訂）
    var allExpenseCategories: [String] {
        TransactionCategory.expenseCategories + customExpenseCategories
    }

    // 所有收入類別（預設 + 自訂）
    var allIncomeCategories: [String] {
        TransactionCategory.incomeCategories + customIncomeCategories
    }

    func addExpenseCategory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !allExpenseCategories.contains(trimmed) else { return }
        customExpenseCategories.append(trimmed)
        save(customExpenseCategories, key: expenseKey)
    }

    func addIncomeCategory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !allIncomeCategories.contains(trimmed) else { return }
        customIncomeCategories.append(trimmed)
        save(customIncomeCategories, key: incomeKey)
    }

    func deleteExpenseCategory(at offsets: IndexSet) {
        customExpenseCategories.remove(atOffsets: offsets)
        save(customExpenseCategories, key: expenseKey)
    }

    func deleteIncomeCategory(at offsets: IndexSet) {
        customIncomeCategories.remove(atOffsets: offsets)
        save(customIncomeCategories, key: incomeKey)
    }

    private func load(key: String) -> [String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return decoded
    }

    private func save(_ categories: [String], key: String) {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
