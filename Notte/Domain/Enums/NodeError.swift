//
//  NodeError.swift
//  Notte
//
//  Created by 余哲源 on 2026/6/6.
//

import Foundation

enum NodeError: Error, Equatable {
    case maxDepthExceeded
    
    static func == (lhs: NodeError, rhs: NodeError) -> Bool {
        switch (lhs, rhs) {
        case (.maxDepthExceeded, .maxDepthExceeded): return true
        default: return false
        }
    }
}
