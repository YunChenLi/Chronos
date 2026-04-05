//
//  Member.swift
//  KinKeep
//

import Foundation

/// 家庭成員資料結構
struct Member: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var colorHex: String = "#5C5CFF" // 預設顏色
}

