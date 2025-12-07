//
//  LandingPageView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 9/18/25.
//

import SwiftUI

struct LandingPageView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        GeometryReader { geometry in
            
            let safeAreaTop = geometry.safeAreaInsets.top
            let screenHeight = geometry.size.height
            let screenWidth = geometry.size.width
            
            let welcomeFontSize = screenHeight * 0.06
            let buttonFontSize = screenHeight * 0.03
            let buttonHeight = screenHeight * 0.075
            let horizontalPadding = screenWidth * 0.06
            let bottomPadding = screenHeight * 0.04
            
            ZStack {
                // Main background
                ColorPalette.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(
                        safeAreaTop: safeAreaTop,
                        screenHeight: screenHeight
                    )
                    
                    Spacer()
                    
                    Text("Welcome")
                        .font(.custom("IBMPlexSans", size: welcomeFontSize))
                        .foregroundColor(ColorPalette.labelPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        appState.login()
                    }) {
                        Text("Log in")
                            .font(.custom("IBMPlexSans", size: buttonFontSize))
                            .foregroundColor(ColorPalette.witRichBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: buttonHeight)
                            .background(ColorPalette.witGold)
                            .cornerRadius(buttonHeight / 2)
                    }
                    .padding(.horizontal, horizontalPadding)
                }
            }
        }
    }
}


#Preview {
    LandingPageView(appState: AppState())
}
