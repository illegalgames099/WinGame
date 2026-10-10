//
//  WinGameLogoView.swift
//  WinGame
//
//  Created for WinGame UI modernization.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI

public struct WinGameLogoView: View {
    public var size: CGFloat = 40
    public var showGlow: Bool = true
    public var interactive: Bool = true

    @State private var isHovering: Bool = false

    public init(size: CGFloat = 40, showGlow: Bool = true, interactive: Bool = true) {
        self.size = size
        self.showGlow = showGlow
        self.interactive = interactive
    }

    public var body: some View {
        ZStack {
            // Ambient Outer Glow (Electric blue / cyan matching logo)
            if showGlow {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.6, blue: 1.0).opacity(isHovering ? 0.75 : 0.45),
                                Color(red: 0.1, green: 0.4, blue: 0.95).opacity(isHovering ? 0.75 : 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .blur(radius: isHovering ? size * 0.35 : size * 0.22)
            }

            // Main Logo Image
            if let icon = NSImage(named: "WinGameLogo") ?? NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isHovering ? 0.5 : 0.25),
                                        Color.cyan.opacity(0.3),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: max(1.0, size * 0.025)
                            )
                    }
                    .shadow(color: .black.opacity(0.4), radius: size * 0.15, x: 0, y: size * 0.08)
            } else {
                fallbackEmblem
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isHovering && interactive ? 1.06 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            if interactive {
                isHovering = hovering
            }
        }
    }

    private var fallbackEmblem: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "display")
                .font(.system(size: size * 0.5))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}
