//
//  LifestyleManager.swift
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

class LifestyleManager: ObservableObject {
    @Published var selectedTags: Set<LifestyleTag> = [] {
        didSet { saveTags() }
    }
    @Published var healthData: String = "良好"
    
    private let kSelectedTags = "StoredLifestyleTags"
    
    init() { loadTags() }
    
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
    
    var mainCategories: [String] {
        var base = ["食", "衣", "住", "行", "育", "樂"]
        base.append("預約服務")
        
        if selectedTags.contains(.beauty) {
            if let index = base.firstIndex(of: "衣") { base.insert("購物", at: index + 1) }
            else { base.append("購物") }
        }
        if selectedTags.contains(.parent) { base.insert("育兒", at: base.count - 1) }
        if selectedTags.contains(.pet) { base.insert("寵物", at: base.count - 1) }
        base.append("其他")
        return base
    }
    
    func getSubCategories(for main: String) -> [String] {
        switch main {
        case "食": return selectedTags.contains(.diningOut) ? ["早餐", "午餐", "晚餐", "宵夜", "零食", "飲料", "保健"] : ["三餐", "零食", "飲料", "保健"]
        case "衣": return ["服裝", "鞋子", "配件", "洗衣"]
        case "購物": return selectedTags.contains(.beauty) ? ["化妝品", "保養品", "服飾", "飾品"] : ["一般購物"]
        case "住": return ["房租", "水電", "家具", "維修", "日用品"]
        case "行": return ["交通費", "油錢", "停車費", "保養"]
        case "育": return ["書籍", "課程", "學習用品"]
        case "樂": return ["娛樂", "旅遊", "運動", "電影"]
        case "育兒": return ["奶粉", "尿布", "玩具", "教育", "醫療"]
        case "寵物": return ["飼料", "零食", "醫療", "美容", "用品"]
        case "預約服務": return ["剪髮", "美甲", "按摩", "其他服務"]
        case "其他": return []
        default: return ["其他"]
        }
    }
}
//Next: 固定支出會在APP行事曆提醒也可以同步到ios app calendar



extension Color {
    static let themeBackground = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let themePrimary = Color.blue
}

