//
//  ListGameCard.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 10/20/24.
//

// Copyright © 2023-2025 vapidinfinity

import SwiftUI

struct ListGameCard: View {
    @Binding var game: Game
    
    @State private var isImageEmpty: Bool = true
    @State private var isCardExpanded: Bool = false
    @State private var isDetailsPresented: Bool = false
    
    static let defaultHeight: CGFloat = 120
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                GameImageCard(url: game.horizontalImageURL, isImageEmpty: $isImageEmpty, withBlur: !isCardExpanded)
                    .aspectRatio(16/9, contentMode: .fill)
                    .blur(radius: isCardExpanded ? 0 : 30.0)
                    .frame(width: geometry.size.width,
                           height: geometry.size.height,
                           alignment: .center)
                    .conditionalTransform(if: isCardExpanded) { view in
                        view.winGlassEffect()
                    }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isDetailsPresented = true
            }
            
            HStack {
                if game.isFallbackImageAvailable, isImageEmpty {
                    GameImageCard.FallbackGameImageCard(game: $game)
                        .frame(width: 70, height: 70)
                }
                
                VStack(alignment: .leading) {
                    Text(game.title)
                        .font(.system(.title, weight: .bold))
                    
                    HStack {
                        GameCard.SubscriptedInfoView(game: $game)
                    }
                }
                .foregroundStyle(isImageEmpty ? .primary : Color.white)
                .contentShape(Rectangle())
                .onTapGesture {
                    isDetailsPresented = true
                }
                
                Spacer()
                
                HStack {
                    GameCard.ButtonsView(game: $game)
                        .clipShape(.capsule)
                        .foregroundStyle(isImageEmpty ? .primary : Color.white)
                }
                .frame(maxWidth: 250, alignment: .trailing)
            }
            .geometryGroup()
            .padding()
            .frame(maxHeight: .infinity, alignment: isCardExpanded ? .bottom : .center)
        }
        .frame(height: isCardExpanded ? ListGameCard.defaultHeight * 2 : ListGameCard.defaultHeight)
        .clipShape(.rect(cornerRadius: 20))
        .contentShape(.rect(cornerRadius: 20))
        .onHover { hovering in
            if !isImageEmpty {
                withAnimation { isCardExpanded = hovering }
            }
        }
        .sheet(isPresented: $isDetailsPresented) {
            GameSettingsView(game: $game, isPresented: $isDetailsPresented)
                .frame(minWidth: 760, idealWidth: 840, minHeight: 620, idealHeight: 740)
        }
    }
}

#Preview {
    ListGameCard(game: .constant(placeholderGame(type: Game.self)))
        .padding()
        .environmentObject(NetworkMonitor.shared)
}
