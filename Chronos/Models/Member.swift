//
//  Member.swift
//  Chronos
//

import Foundation

/// 家庭成員資料結構
struct Member: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var colorHex: String // 用於 UI 標記的顏色
}
