import Foundation
import SwiftUI

// A lightweight manager that provides main and sub categories for expenses.
// Expand or replace with your app's real data source as needed.
final class LifestyleManager: ObservableObject {
    // Top-level categories displayed in the picker
    @Published var mainCategories: [String]

    // Mapping from main category to its subcategories
    @Published private var subcategoryMap: [String: [String]]

    init(
        mainCategories: [String] = ["食", "衣", "住", "行", "育", "樂", "其他"],
        subcategoryMap: [String: [String]] = [
            "食": ["早餐", "午餐", "晚餐", "零食", "飲料"],
            "衣": ["上衣", "褲子", "外套", "鞋子", "配件"],
            "住": ["房租", "水電瓦斯", "網路", "清潔"],
            "行": ["大眾運輸", "計程車", "油費", "停車"],
            "育": ["學費", "書籍", "課程", "育兒"],
            "樂": ["電影", "旅遊", "遊戲", "聚餐"],
            "其他": ["雜項"]
        ]
    ) {
        self.mainCategories = mainCategories
        self.subcategoryMap = subcategoryMap
    }

    // Return subcategories for a given main category. Empty array if none.
    func getSubCategories(for main: String) -> [String] {
        subcategoryMap[main] ?? []
    }
}
