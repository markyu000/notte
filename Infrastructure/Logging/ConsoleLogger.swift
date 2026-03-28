//
//  ConsoleLogger.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/28.
//

import Foundation

struct ConsoleLogger: AppLogger {

    func debug(_ message: String) {
        #if DEBUG
        print("[DEBUG] \(message)")
        #endif
    }

    func info(_ message: String) {
        #if DEBUG
        print("[INFO] \(message)")
        #endif
    }

    func error(_ message: String, error: Error? = nil) {
        #if DEBUG
        if let error = error {
            print("[ERROR] \(message) — \(error)")
        } else {
            print("[ERROR] \(message)")
        }
        #endif
    }
}
