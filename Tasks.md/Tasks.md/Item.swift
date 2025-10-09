//
//  Item.swift
//  Tasks.md
//
//  Created by Mason Earl on 10/9/25.
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
