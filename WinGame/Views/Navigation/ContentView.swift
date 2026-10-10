//
//  ContentView.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 8/9/2023.
//

// Copyright © 2023-2026 vapidinfinity

import Foundation
import SwiftUI

enum GameHubNavTab: Hashable {
    case home
    case stats
    case containers
    case myGames
    case devices
    case operations
    case settings
}

struct ContentView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor

    @ObservedObject private var updateController: SparkleUpdateController = .shared
    @Bindable private var operationManager: GameOperationManager = .shared
    @Bindable private var gameListViewModel: GameListViewModel = .shared
    @Bindable private var gameDataStore: GameDataStore = .shared

    @State private var selectedTab: GameHubNavTab = .myGames
    @State private var engineVersion: SemanticVersion?
    @State private var isSearchPalettePresented: Bool = false

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // MARK: - Left Icon Rail (GameHub Style)
                iconRail
                    .frame(width: 74)
                    .background(Color(red: 11/255, green: 12/255, blue: 18/255).ignoresSafeArea())

                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .ignoresSafeArea()

                // MARK: - Content Area
                Group {
                    switch selectedTab {
                    case .myGames:
                        GameHubMyGamesView(gameDataStore: gameDataStore, viewModel: gameListViewModel)
                    case .home:
                        HomeView()
                    case .stats:
                        GameHubStatsView(gameDataStore: gameDataStore)
                    case .containers:
                        ContainersView()
                    case .devices:
                        GameHubDevicesView()
                    case .operations:
                        OperationsView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 14/255, green: 16/255, blue: 23/255),
                        Color(red: 9/255, green: 10/255, blue: 15/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )

            // MARK: - Quick Command Palette Overlay (⌘K)
            if isSearchPalettePresented {
                QuickSearchCommandPalette(isPresented: $isSearchPalettePresented)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSearchPalettePresented)
        .task { @MainActor in
            engineVersion = await Engine.installedVersion
        }
        .toolbar {
            ToolbarItem(placement: .status) {
                if !networkMonitor.isConnected {
                    Image(systemName: "network.slash")
                        .help("WinGame is not connected to the internet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Navigation Rail
    private var iconRail: some View {
        VStack(spacing: 10) {
            // Stylized Modern WinGame Logo
            WinGameLogoView(size: 42, showGlow: true, interactive: true)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .onTapGesture {
                    selectedTab = .myGames
                }
                .help("WinGame Home")

            // Top Rail Items
            RailButton(
                icon: "square.grid.2x2.fill",
                title: "My Games",
                isSelected: selectedTab == .myGames,
                badgeCount: nil
            ) {
                selectedTab = .myGames
            }

            RailButton(
                icon: "magnifyingglass",
                title: "Quick Search (⌘K)",
                isSelected: isSearchPalettePresented,
                badgeCount: nil
            ) {
                isSearchPalettePresented.toggle()
            }

            RailButton(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == .home,
                badgeCount: nil
            ) {
                selectedTab = .home
            }

            RailButton(
                icon: "chart.bar.xaxis",
                title: "Activity & Stats",
                isSelected: selectedTab == .stats,
                badgeCount: nil
            ) {
                selectedTab = .stats
            }

            RailButton(
                icon: "cube.transparent.fill",
                title: "Wine Containers",
                isSelected: selectedTab == .containers,
                badgeCount: nil
            ) {
                selectedTab = .containers
            }

            RailButton(
                icon: "gamecontroller",
                title: "Controllers & Devices",
                isSelected: selectedTab == .devices,
                badgeCount: nil
            ) {
                selectedTab = .devices
            }

            Spacer()

            // Bottom Rail Items
            RailButton(
                icon: "arrow.down.circle.fill",
                title: "Downloads & Tasks",
                isSelected: selectedTab == .operations,
                badgeCount: operationManager.queue.filter(\.isExecuting).count
            ) {
                selectedTab = .operations
            }

            RailButton(
                icon: "gearshape.fill",
                title: "Settings",
                isSelected: selectedTab == .settings,
                badgeCount: nil
            ) {
                selectedTab = .settings
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Navigation Rail Button
private struct RailButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let badgeCount: Int?
    let action: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Background Pill
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.14), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 2)
                    } else if isHovering {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    }

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(
                            isSelected ? .white : (isHovering ? .white.opacity(0.9) : .white.opacity(0.45))
                        )

                    // Active badge count
                    if let count = badgeCount, count > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 14, height: 14)
                            Text("\(count)")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 12, y: -12)
                    }
                }
                .frame(width: 46, height: 46)

                // Neon active indicator strip on the leading edge
                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3.5, height: 22)
                        .shadow(color: Color.cyan.opacity(0.8), radius: 5, x: 0, y: 0)
                        .offset(x: -8)
                }
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .help(title)
        .onHover { isHovering = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}
