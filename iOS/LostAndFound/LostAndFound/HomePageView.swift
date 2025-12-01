//
//  HomePageView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 11/19/25.
//

import SwiftUI

struct HomePageView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        TabView {
            HomeTabView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            SettingsTabView(appState: appState)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

struct HomeTabView: View {
    @State private var navigationPath = NavigationPath()
    
    private enum Destination: Hashable {
        case foundItemsList
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                let safeAreaTop = geometry.safeAreaInsets.top
                let screenHeight = geometry.size.height
                let screenWidth = geometry.size.width
                
                let buttonFontSize = screenHeight * 0.03
                let buttonHeight = screenHeight * 0.10
                let horizontalPadding = screenWidth * 0.065
                let buttonSpacing = screenHeight * 0.02
                
                ZStack {
                    ColorPalette.backgroundPrimary
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        HeaderView(
                            safeAreaTop: safeAreaTop,
                            screenHeight: screenHeight
                        )
                        
                        Spacer()
                        
                        VStack(spacing: buttonSpacing) {
                            
                            ActionButton(
                                title: "Report an item you lost",
                                foregroundColor: ColorPalette.labelPrimary,
                                icon: nil,
                                fontSize: buttonFontSize,
                                height: buttonHeight
                            ) {
                                navigationPath.append(Destination.foundItemsList)
                            }
                            
                            ActionButton(
                                title: "Report an item you found",
                                foregroundColor: ColorPalette.labelPrimary,
                                icon: nil,
                                fontSize: buttonFontSize,
                                height: buttonHeight
                            ) {
                                // TODO: Handle action
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        
                        Spacer()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .foundItemsList:
                    FoundItemsListView()
                }
            }
        }
    }
}

struct SettingsTabView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let screenHeight = geometry.size.height
            let screenWidth = geometry.size.width
            
            let buttonFontSize = screenHeight * 0.03
            let buttonHeight = screenHeight * 0.10
            let horizontalPadding = screenWidth * 0.065
            let buttonSpacing = screenHeight * 0.02
            
            ZStack {
                // Main background
                ColorPalette.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HeaderView(
                        safeAreaTop: safeAreaTop,
                        screenHeight: screenHeight
                    )
                    
                    Spacer()
                    
                    // User Info Section
                    VStack(alignment: .leading, spacing: screenHeight * 0.015) {
                        if let displayName = appState.userDisplayName {
                            Text(displayName)
                                .font(.custom("IBMPlexSans", size: buttonFontSize * 1.1))
                                .fontWeight(.semibold)
                                .foregroundColor(ColorPalette.labelPrimary)
                        }
                        
                        if let email = appState.userEmail {
                            Text(email)
                                .font(.custom("IBMPlexSans", size: buttonFontSize * 0.9))
                                .fontWeight(.regular)
                                .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, screenHeight * 0.02)
                    .background(ColorPalette.actionButtonBackground)
                    .cornerRadius(16)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, buttonSpacing)
                    
                    // Log Out button
                    ActionButton(
                        title: "Log Out",
                        foregroundColor: ColorPalette.logoutButtonForeground,
                        icon: "rectangle.portrait.and.arrow.right",
                        fontSize: buttonFontSize,
                        height: buttonHeight,
                    ) {
                        appState.logout()
                    }
                    .padding(.horizontal, horizontalPadding)
                    
                    Spacer()
                }
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let foregroundColor: Color
    let icon: String?
    let fontSize: CGFloat
    let height: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Rectangle()
            .foregroundColor(.clear)
            .frame(width: .infinity, height: height)
            .background(ColorPalette.actionButtonBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
            .overlay(
                HStack(spacing: 12) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: fontSize))
                            .foregroundColor(foregroundColor)
                    }
                    Text(title)
                        .font(.custom("IBMPlexSans", size: fontSize))
                        .fontWeight(.semibold)
                        .foregroundColor(foregroundColor)
                }
            )
        }
    }
}

#Preview {
    HomePageView(appState: AppState())
}
