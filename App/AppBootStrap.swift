//
//  AppBootStrap.swift
//  Notte
//
//  Created by yuzheyuan on 2026/3/23.
//
import Combine

@MainActor
class AppBootStrap: ObservableObject {
    @Published var isReady: Bool = false
}
