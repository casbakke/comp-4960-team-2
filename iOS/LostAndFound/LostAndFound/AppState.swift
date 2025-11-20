//
//  AppState.swift
//  LostAndFound
//
//  Created by Craig Bakke on 11/19/25.
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    func login() {
        isLoggedIn = true
    }
    
    func logout() {
        isLoggedIn = false
    }
}

