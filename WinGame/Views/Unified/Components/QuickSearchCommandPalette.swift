//
//  QuickSearchCommandPalette.swift
//  WinGame
//
//  Created for WinGame UI modernization.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI

struct QuickSearchCommandPalette: View {
    @Binding var isPresented: Bool
    @Bindable var gameDataStore: GameDataStore = .shared

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0

    private var matchingGames: [Game] {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return Array(gameDataStore.library.prefix(8))
        }
        return gameDataStore.library.filter {
            $0.title.localizedStandardContains(query)
        }
    }

    var body: some View {
        ZStack {
            // Blurred dark overlay
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Floating Command Window
            VStack(spacing: 0) {
                // Search Input Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.cyan)

                    TextField("Search all games across Steam, Epic, EA, GOG...", text: $query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)

                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("ESC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(Color(white: 0.12).opacity(0.9))

                Divider()
                    .background(Color.white.opacity(0.1))

                // Results list
                ScrollView {
                    LazyVStack(spacing: 4) {
                        if matchingGames.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "questionmark.folder")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary)
                                Text("No matching games found")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 40)
                        } else {
                            ForEach(Array(matchingGames.enumerated()), id: \.element.id) { index, game in
                                CommandResultRow(game: game) {
                                    isPresented = false
                                }
                            }
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 380)

                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Text("↑↓")
                            .font(.system(size: 11, weight: .bold))
                        Text("Navigate")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("↵")
                            .font(.system(size: 11, weight: .bold))
                        Text("Select / Launch")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(white: 0.08))
            }
            .frame(width: 580)
            .background(Color(red: 16/255, green: 18/255, blue: 26/255))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.4), Color.purple.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.7), radius: 30, x: 0, y: 15)
        }
    }
}

private struct CommandResultRow: View {
    let game: Game
    let onSelect: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Mini Thumbnail
            ZStack {
                if let url = game.horizontalImageURL ?? game.verticalImageURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            fallbackThumb
                        }
                    }
                } else {
                    fallbackThumb
                }
            }
            .frame(width: 52, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            }

            // Title & Storefront
            VStack(alignment: .leading, spacing: 2) {
                Text(game.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let sf = game.storefront {
                        Text(sf.description)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    if case .installed = game.installationState {
                        Text("• Installed")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            // Action Button
            if case .installed = game.installationState {
                Button {
                    onSelect()
                    Task(priority: .userInitiated) {
                        try? await game.launch()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                        Text("Play")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.2), in: Capsule())
                    .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovering ? Color.white.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture {
            onSelect()
            if case .installed = game.installationState {
                Task(priority: .userInitiated) {
                    try? await game.launch()
                }
            }
        }
    }

    private var fallbackThumb: some View {
        ZStack {
            Color.white.opacity(0.08)
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}
