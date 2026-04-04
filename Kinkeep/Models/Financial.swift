import SwiftUI
import Foundation

struct Expense: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var amount: Double
    var mainCategory: String
    var subCategory: String
    var note: String
    var memberId: UUID
}

struct Income: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var amount: Double
    var category: IncomeCategory
    var note: String
}

enum IncomeCategory: String, CaseIterable, Codable, Identifiable {
    case active = "工作收入"
    case passive = "理財收入"
    case other = "其他收入"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .active: return "薪水、佣金、獎金"
        case .passive: return "房租、股利、利息"
        case .other: return "創業、斜槓、其他"
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "briefcase.fill"
        case .passive: return "chart.line.uptrend.xyaxis"
        case .other: return "star.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .blue
        case .passive: return .green
        case .other: return .orange
        }
    }
}
