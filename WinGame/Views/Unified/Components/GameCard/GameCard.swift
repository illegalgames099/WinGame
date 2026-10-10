//
//  GameCard.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 5/3/2024.
//

// Copyright © 2023-2025 vapidinfinity

import SwiftUI
import OSLog

struct GameCard: View {
    @Binding var game: Game

    @State private var isImageEmpty: Bool = true
    @State private var isImageEmptyPreMacOSTahoe: Bool = true
    @State private var isHovering: Bool = false
    @State private var isDetailsPresented: Bool = false

    var body: some View {
        GameImageCard(game: game, url: game.verticalImageURL, isImageEmpty: $isImageEmpty)
            .aspectRatio(3/4, contentMode: .fit)
            .overlay {
                // Add a subtle gradient at the bottom so text is always legible
                if !isImageEmpty {
                    LinearGradient(
                        colors: [.black.opacity(0.8), .black.opacity(0.0)],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isDetailsPresented = true
            }
            .overlay(alignment: .bottom) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        GameCard.TitleAndInformationView(game: $game, font: .title3.weight(.bold))
                    }
                    .layoutPriority(1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isDetailsPresented = true
                    }
                    
                    Spacer()
                    
                    GameCard.ButtonsView(game: $game)
                        .clipShape(.capsule)
                        .progressViewStyle(.circular)
                }
                .padding(12)
                // conditionally change view foreground style for macOS <26
                .onChange(of: isImageEmpty) {
                    if #unavailable(macOS 26.0) {
                        isImageEmptyPreMacOSTahoe = $1
                    }
                }
                .conditionalTransform(if: !isImageEmptyPreMacOSTahoe) { view in
                    view.foregroundStyle(.white)
                }
                .padding(.vertical, 4)
                .winGlassEffect(in: .rect(cornerRadius: 16.0))
                .padding(8)
            }
            .overlay(alignment: .top) {
                VStack {
                    if game.isUpdateAvailable == true {
                        VStack {
                            Label("Update available", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .winGlassEffect(in: .capsule)
                    }
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(isHovering ? 0.25 : 0.15), radius: isHovering ? 15 : 10, x: 0, y: isHovering ? 8 : 4)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
            .sheet(isPresented: $isDetailsPresented) {
                GameSettingsView(game: $game, isPresented: $isDetailsPresented)
                    .frame(minWidth: 760, idealWidth: 840, minHeight: 620, idealHeight: 740)
            }
    }
}

/// ViewModifier that enables views to have a fade in effect.
struct FadeInModifier: ViewModifier {
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    opacity = 1
                }
            }
    }
}

#Preview {
    GameCard(game: .constant(placeholderGame(type: Game.self)))
        .environmentObject(NetworkMonitor.shared)
}
