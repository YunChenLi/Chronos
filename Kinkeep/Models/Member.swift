//
//  Member.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//
// MARK: 成員管理 (Member Management)
import SwiftUI
import Foundation

struct Member: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var role: MemberRole = .other
}

enum MemberRole: String, CaseIterable, Codable, Identifiable {
    case father = "爸爸"
    case mother = "媽媽"
    case son = "兒子"
    case daughter = "女兒"
    case grandparent = "長輩"
    case pet = "寵物"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .father: return "👨🏻"
        case .mother: return "👩🏻"
        case .son: return "👦🏻"
        case .daughter: return "👧🏻"
        case .grandparent: return "👴🏻"
        case .pet: return "🐶"
        case .other: return "👤"
        }
    }
    
    var color: Color {
        switch self {
        case .father: return .blue
        case .mother: return .red
        case .son: return .cyan
        case .daughter: return .pink
        case .grandparent: return .gray
        case .pet: return .brown
        case .other: return .indigo
        }
    }
}


