//
//  HeroFeaturedBanner.swift
//  WinGame
//
//  Created for WinGame UI modernization.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI

struct HeroFeaturedBanner: View {
    let game: Game
    var onDetailsRequested: () -> Void

    @State private var isHovering: Bool = false
    @State private var isLaunching: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Ambient Artwork Backdrop
            if let url = game.horizontalImageURL ?? game.verticalImageURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        fallbackGradient
                    }
                }
            } else {
                fallbackGradient
            }

            // Cinematic Vignette & Gradient Overlays
            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.65),
                    Color(red: 10/255, green: 12/255, blue: 18/255).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content Information
            HStack(alignment: .bottom, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    // Tagline Pill
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                            .shadow(color: .green, radius: 4)

                        Text("JUMP BACK IN")
                            .font(.system(size: 10, weight: .heavy))
                            .kerning(1.2)
                            .foregroundStyle(.green)

                        if let sf = game.storefront {
                            Text("•")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                            Text(sf.description.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())

                    // Game Title
                    Text(game.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)

                    // Buttons
                    HStack(spacing: 12) {
                        Button {
                            isLaunching = true
                            Task(priority: .userInitiated) {
                                try? await game.launch()
                                await MainActor.run { isLaunching = false }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isLaunching ? "hourglass" : "play.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text(isLaunching ? "Launching..." : "Play Now")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                            .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLaunching)

                        Button {
                            onDetailsRequested()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 13))
                                Text("Details & Settings")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.white.opacity(0.12), in: Capsule())
                            .overlay {
                                Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.4), radius: 14, x: 0, y: 6)
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [Color(red: 25/255, green: 30/255, blue: 45/255), Color(red: 14/255, green: 16/255, blue: 24/255)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
