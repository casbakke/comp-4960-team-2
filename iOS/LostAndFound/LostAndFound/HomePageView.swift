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
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let screenHeight = geometry.size.height
            let screenWidth = geometry.size.width
            
            let headerHeight = safeAreaTop + 60
            let titleFontSize = screenHeight * 0.03
            let buttonFontSize = screenHeight * 0.03
            let buttonHeight = screenHeight * 0.10
            let horizontalPadding = screenWidth * 0.065
            let buttonSpacing = screenHeight * 0.02
            
            ZStack {
                ColorPalette.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(
                        headerHeight: headerHeight,
                        safeAreaTop: safeAreaTop,
                        titleFontSize: titleFontSize
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
                            // TODO: Handle action
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
    }
}

struct SettingsTabView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let screenHeight = geometry.size.height
            let screenWidth = geometry.size.width
            
            let headerHeight = safeAreaTop + 60
            let titleFontSize = screenHeight * 0.03
            let buttonFontSize = screenHeight * 0.03
            let buttonHeight = screenHeight * 0.10
            let horizontalPadding = screenWidth * 0.065
            
            ZStack {
                // Main background
                ColorPalette.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HeaderView(
                        headerHeight: headerHeight,
                        safeAreaTop: safeAreaTop,
                        titleFontSize: titleFontSize
                    )
                    
                    Spacer()
                    
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
