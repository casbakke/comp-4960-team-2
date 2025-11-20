//
//  HeaderView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 11/19/25.
//

import SwiftUI

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

