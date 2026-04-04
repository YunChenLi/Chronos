//
//  LifrstyleTag.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//

// MARK: - 生活型態管理 (Lifestyle Manager)

enum LifestyleTag: String, CaseIterable, Codable, Identifiable {
    case diningOut = "外食族"
    case beauty = "愛美族"
    case parent = "有小孩"
    case pet = "有寵物"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .diningOut: return "fork.knife"
        case .beauty: return "sparkles"
        case .parent: return "figure.and.child"
        case .pet: return "pawprint.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .diningOut: return .orange
        case .beauty: return .pink
        case .parent: return .blue
        case .pet: return .brown
        }
    }
}
