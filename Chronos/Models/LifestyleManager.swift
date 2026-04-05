//
//  LifestyleManager.swift
//  KinKeep
//
//  生活型態管理：根據使用者標籤動態產生支出主類別與子類別
//

import Foundation
internal import Combine
internal import SwiftUI

// MARK: - 生活型態標籤

enum LifestyleTag: String, CaseIterable, Codable, Identifiable {
    case diningOut = "外食族"
    case beauty    = "愛美族"
    case parent    = "有小孩"
    case pet       = "有寵物"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .diningOut: return "fork.knife"
        case .beauty:    return "sparkles"
        case .parent:    return "figure.and.child"
        case .pet:       return "pawprint.fill"
        }
    }

    var color: Color {
        switch self {
        case .diningOut: return .orange
        case .beauty:    return .pink
        case .parent:    return .blue
        case .pet:       return .brown
        }
    }
}

// MARK: - 生活型態管理器

class LifestyleManager: ObservableObject {
    static let shared = LifestyleManager()

    @Published var selectedTags: Set<LifestyleTag> = [] {
        didSet { saveTags() }
    }

    private let kSelectedTags = "StoredLifestyleTags"

    init() { loadTags() }

    // MARK: - 動態主類別

    var mainCategories: [String] {
        var base = ["食", "衣", "住", "行", "育", "樂", "固定支出"]
        if selectedTags.contains(.beauty) {
            if let index = base.firstIndex(of: "衣") {
                base.insert("購物", at: index + 1)
            } else {
                base.append("購物")
            }
        }
        if selectedTags.contains(.parent) { base.insert("育兒", at: base.count - 1) }
        if selectedTags.contains(.pet)    { base.insert("寵物", at: base.count - 1) }
        base.append("其他")
        return base
    }

    // MARK: - 動態子類別

    func getSubCategories(for main: String) -> [String] {
        switch main {
        case "食":
            return selectedTags.contains(.diningOut)
                ? ["早餐", "午餐", "晚餐", "宵夜", "零食", "飲料", "保健"]
                : ["三餐", "零食", "飲料", "保健"]
        case "衣":
            return ["服裝", "鞋子", "配件", "洗衣"]
        case "購物":
            return selectedTags.contains(.beauty)
                ? ["化妝品", "保養品", "服飾", "飾品"]
                : ["一般購物"]
        case "住":
            return ["水電", "家具", "維修", "日用品"]
        case "行":
            return ["交通費", "油錢", "停車費", "保養"]
        case "育":
            return ["書籍", "課程", "學習用品"]
        case "樂":
            return ["娛樂", "旅遊", "運動", "電影"]
        case "育兒":
            return ["奶粉", "尿布", "玩具", "教育", "醫療"]
        case "寵物":
            return ["飼料", "零食", "醫療", "美容", "用品"]
        case "固定支出":
            return ["房貸/租金", "保險", "訂閱服務", "管理費", "電話費", "網路費"]
        case "其他":
            return ["雜項", "臨時支出"]
        default:
            return ["其他"]
        }
    }

    // MARK: - 收入主類別（固定）

    var incomeCategories: [String] {
        ["💼 薪資", "📈 投資獲利", "🎁 獎金", "🏠 租金收入",
         "💰 兼職收入", "🎉 紅包", "💳 退款", "📋 其他"]
    }

    // MARK: - 儲存／載入

    private func saveTags() {
        if let encoded = try? JSONEncoder().encode(Array(selectedTags)) {
            UserDefaults.standard.set(encoded, forKey: kSelectedTags)
        }
    }

    private func loadTags() {
        if let data = UserDefaults.standard.data(forKey: kSelectedTags),
           let decoded = try? JSONDecoder().decode([LifestyleTag].self, from: data) {
            selectedTags = Set(decoded)
        }
    }
}

