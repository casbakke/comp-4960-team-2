//
//  LandingPageView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 9/18/25.
//

import SwiftUI

struct LandingPageView: View {
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let screenHeight = geometry.size.height
            let screenWidth = geometry.size.width
            
            // Calculate adaptive sizes based on screen dimensions
            let headerHeight = max(100, safeAreaTop + 60) // Minimum 100pt, scales with safe area
            let welcomeFontSize = screenHeight * 0.06
            let titleFontSize = screenHeight * 0.03
            let buttonFontSize = screenHeight * 0.03
            let buttonHeight = max(44, screenHeight * 0.075)
            let horizontalPadding = screenWidth * 0.06
            let bottomPadding = screenHeight * 0.04
            
            ZStack {
                // Main background
                ColorPalette.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with gradient - text is inside the gradient
                    HeaderView(
                        headerHeight: headerHeight,
                        safeAreaTop: safeAreaTop,
                        titleFontSize: titleFontSize
                    )
                    
                    // Main content area
                    Spacer()
                    
                    // Welcome text
                    Text("Welcome")
                        .font(.custom("IBMPlexSans", size: welcomeFontSize))
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.labelPrimary)
                    
                    Spacer()
                    
                    // Login button
                    Button(action: {
                        // TODO: Handle login action
                    }) {
                        Text("Log in")
                            .font(.custom("IBMPlexSans", size: buttonFontSize))
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.witRichBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: buttonHeight)
                            .background(ColorPalette.witGold)
                            .cornerRadius(buttonHeight / 2) // Fully rounded (pill shape)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, bottomPadding)
                }
            }
        }
    }
}

struct HeaderView: View {
    let headerHeight: CGFloat
    let safeAreaTop: CGFloat
    let titleFontSize: CGFloat
    
    var body: some View {
        
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: ColorPalette.witGradient1, location: 0.0),
                        .init(color: ColorPalette.witGradient2, location: 0.5),
                        .init(color: ColorPalette.witGradient3, location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: headerHeight)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomLeading) {
                Text("Wentworth Lost and Found")
                    .font(.custom("IBMPlexSans", size: titleFontSize))
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.witRichBlack)
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
            }
            .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    ContentView()
}
