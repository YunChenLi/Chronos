//
//  Item.swift
//  Chronos
//
//  Created by 李芸禎 on 2025/11/2.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
