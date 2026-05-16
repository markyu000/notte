//
//  OnboardingViewModel.swift
//  Notte
//
//  Created by 余哲源 on 2026/5/12.
//

import Foundation
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    let totalPages: Int = 3

    func next() {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
    }

    func previous() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }
}
