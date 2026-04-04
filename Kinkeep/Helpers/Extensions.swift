//
//  Extensions.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//

extension Optional where Wrapped == String {
    var isEmptyOrNil: Bool {
        self?.isEmpty ?? true
    }
}


// 新增：定義 App 主題背景顏色 (#e0f9f4)
//extension Color {
  //  static let themeBackground = Color(red: 224/255, green: 249/255, blue: 244/255)
//}
