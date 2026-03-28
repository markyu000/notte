//
//  AppLogger.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/28.
//

import Foundation

protocol AppLogger {
    func debug(_ message: String)
    func info(_ message: String)
    func error(_ message: String, error: Error?)
}
