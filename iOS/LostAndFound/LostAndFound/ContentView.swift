//
//  ContentView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 9/18/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        if appState.isLoggedIn {
            HomePageView(appState: appState)
        } else {
            LandingPageView(appState: appState)
        }
    }
}

#Preview {
    ContentView()
}
