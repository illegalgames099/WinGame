//
//  GameHubGameCard.swift
//  WinGame
//
//  Created for GameHub UI experience.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI

struct GameHubGameCard: View {
    @Binding var game: Game
    @Bindable private var operationManager: GameOperationManager = .shared

    @State private var isHovering: Bool = false
    @State private var isDetailsPresented: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            // MARK: - 16:9 Landscape Artwork Thumbnail
            ZStack {
                // Artwork Image
                artworkLayer

                // Cinematic Hover Vignette
                LinearGradient(
                    colors: [
                        .black.opacity(isHovering ? 0.4 : 0.05),
                        .clear,
                        .black.opacity(isHovering ? 0.75 : 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Top Pill Badges
                VStack {
                    HStack(spacing: 6) {
                        if let storefront = game.storefront {
                            storefrontBadge(storefront)
                        }

                        Spacer()

                        if game.isUpdateAvailable == true {
                            updateBadge
                        }

                        if isHovering {
                            Button {
                                game.isFavourited.toggle()
                            } label: {
                                Image(systemName: game.isFavourited ? "star.fill" : "star")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(game.isFavourited ? .yellow : .white.opacity(0.8))
                                    .padding(6)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(8)

                    Spacer()
                }

                // Center Action Button (Play / Install / Progress)
                if isHovering {
                    centerActionOverlay
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .aspectRatio(16/9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isHovering ? Color.white.opacity(0.38) : Color.white.opacity(0.12),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovering ? 1.5 : 1.0
                    )
            }
            .shadow(color: glowColor.opacity(isHovering ? 0.35 : 0.12), radius: isHovering ? 14 : 5, x: 0, y: isHovering ? 7 : 2)
            .scaleEffect(isHovering ? 1.025 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.76), value: isHovering)

            // MARK: - Game Title & Metadata Below Card
            VStack(alignment: .leading, spacing: 3) {
                Text(game.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(isHovering ? 1.0 : 0.92))
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 6) {
                    if let storefront = game.storefront {
                        Text(storefront.description)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    if case .installed = game.installationState {
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)

                        Text("Installed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.green.opacity(0.85))
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            isDetailsPresented = true
        }
        .contextMenu {
            if case .installed = game.installationState {
                Button {
                    Task(priority: .userInitiated) {
                        try? await game.launch()
                    }
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
            }

            Button {
                isDetailsPresented = true
            } label: {
                Label("Game Details", systemImage: "info.circle")
            }

            Button {
                game.isFavourited.toggle()
            } label: {
                Label(
                    game.isFavourited ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: game.isFavourited ? "star.fill" : "star"
                )
            }

            if case .installed(let location, _) = game.installationState {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([location])
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
            }
        }
        .sheet(isPresented: $isDetailsPresented) {
            GameSettingsView(game: $game, isPresented: $isDetailsPresented)
                .frame(minWidth: 760, idealWidth: 840, minHeight: 620, idealHeight: 740)
        }
    }

    // MARK: - Artwork Subviews
    @ViewBuilder
    private var artworkLayer: some View {
        if let url = game.horizontalImageURL ?? game.verticalImageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(white: 0.12))
                        .overlay {
                            ProgressView()
                                .controlSize(.small)
                        }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallbackThumbnail
                @unknown default:
                    fallbackThumbnail
                }
            }
        } else {
            fallbackThumbnail
        }
    }

    private var fallbackThumbnail: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 22/255, green: 26/255, blue: 38/255), Color(red: 14/255, green: 16/255, blue: 24/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Text(game.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
            }
        }
    }

    // MARK: - Center Overlay (Play / Install / Operation)
    @ViewBuilder
    private var centerActionOverlay: some View {
        if let currentOp = operationManager.queue.first(where: { $0.game == game && $0.isExecuting }) {
            VStack(spacing: 6) {
                ProgressView()
                    .controlSize(.regular)
                Text(currentOp.type.description)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        } else if case .installed = game.installationState {
            Button {
                Task(priority: .userInitiated) {
                    try? await game.launch()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                        }

                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: 2)
                }
                .shadow(color: .black.opacity(0.55), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        } else if case .uninstalled = game.installationState {
            Button {
                isDetailsPresented = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                        }

                    Image(systemName: "arrow.down")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.55), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Badges
    private func storefrontBadge(_ storefront: Game.Storefront) -> some View {
        HStack(spacing: 4) {
            switch storefront {
            case .steam:
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.blue)
                Text("STEAM")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.9))
            case .epicGames:
                Image(systemName: "shield.rhombohex.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.purple)
                Text("EPIC")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.9))
            case .electronicArts:
                Image(systemName: "triangle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.red)
                Text("EA")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.9))
            case .gog:
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.teal)
                Text("GOG")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.9))
            case .local:
                Image(systemName: "folder.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text("LOCAL")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        }
    }

    private var updateBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.orange)
                .frame(width: 5, height: 5)
            Text("UPDATE")
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule().stroke(Color.orange.opacity(0.35), lineWidth: 0.5)
        }
    }

    private var glowColor: Color {
        guard let sf = game.storefront else { return .white }
        switch sf {
        case .steam: return .blue
        case .epicGames: return .purple
        case .electronicArts: return .red
        case .gog: return .teal
        case .local: return .white
        }
    }
}
