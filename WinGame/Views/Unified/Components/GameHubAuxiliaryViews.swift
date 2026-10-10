//
//  GameHubAuxiliaryViews.swift
//  WinGame
//
//  Created for GameHub UI experience.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI
import GameController

struct GameHubStatsView: View {
    @Bindable var gameDataStore: GameDataStore = .shared

    private var installedCount: Int {
        gameDataStore.library.filter {
            if case .installed = $0.installationState { return true }
            return false
        }.count
    }

    private var epicCount: Int {
        gameDataStore.library.filter { $0.storefront == .epicGames }.count
    }

    private var steamCount: Int {
        gameDataStore.library.filter { $0.storefront == .steam }.count
    }

    private var eaCount: Int {
        gameDataStore.library.filter { $0.storefront == .electronicArts }.count
    }

    private var gogCount: Int {
        gameDataStore.library.filter { $0.storefront == .gog }.count
    }

    private var localCount: Int {
        gameDataStore.library.filter { $0.storefront == .local }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Library Analytics")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Performance, platform distribution, and game statistics across all connected storefronts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Top Metric Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    metricCard(
                        title: "TOTAL TITLES",
                        value: "\(gameDataStore.library.count)",
                        icon: "gamecontroller.fill",
                        gradient: [Color.blue, Color.cyan]
                    )

                    metricCard(
                        title: "READY TO PLAY",
                        value: "\(installedCount)",
                        icon: "checkmark.seal.fill",
                        gradient: [Color.green, Color.mint]
                    )

                    metricCard(
                        title: "FAVORITES",
                        value: "\(gameDataStore.library.filter(\.isFavourited).count)",
                        icon: "star.fill",
                        gradient: [Color.orange, Color.yellow]
                    )
                }

                // Storefront Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("Storefront Distribution")
                        .font(.headline)
                        .foregroundStyle(.white)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        storefrontBadge(
                            name: "Steam",
                            count: steamCount,
                            icon: "circle.grid.cross.fill",
                            color: .blue
                        )

                        storefrontBadge(
                            name: "Epic Games",
                            count: epicCount,
                            icon: "shield.rhombohex.fill",
                            color: .purple
                        )

                        storefrontBadge(
                            name: "Electronic Arts",
                            count: eaCount,
                            icon: "triangle.fill",
                            color: .red
                        )

                        storefrontBadge(
                            name: "GOG Galaxy",
                            count: gogCount,
                            icon: "gamecontroller.fill",
                            color: .teal
                        )

                        storefrontBadge(
                            name: "Local Binaries",
                            count: localCount,
                            icon: "folder.fill",
                            color: .gray
                        )
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }

                Spacer()
            }
            .padding(32)
        }
    }

    private func metricCard(title: String, value: String, icon: String, gradient: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .kerning(1.0)
                    .foregroundStyle(.secondary)

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.25)
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(gradient.first ?? .white)
                }
            }

            Text(value)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private func storefrontBadge(name: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text("\(count) \(count == 1 ? "Game" : "Games")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if count > 0 {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
}

struct GameHubDevicesView: View {
    @State private var connectedControllers: [GCController] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Controllers & Devices")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Manage gamepads, keybindings, and display translation pipelines.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Gamepad Status
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Game Controllers", systemImage: "gamecontroller.fill")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Spacer()

                        Button("Refresh") {
                            updateControllers()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    if connectedControllers.isEmpty {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("No Physical Gamepads Connected")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)

                                Text("Connect an Xbox, PlayStation DualSense, Nintendo Switch Pro, or MFi controller via Bluetooth or USB.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        ForEach(connectedControllers, id: \.self) { controller in
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(controller.vendorName ?? "Game Controller")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)

                                    Text(controller.battery != nil ? "Battery: \(Int((controller.battery?.batteryLevel ?? 1.0) * 100))%" : "Connected via Apple GameController")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("Active")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.18), in: Capsule())
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }

                // Graphics Translation Info
                VStack(alignment: .leading, spacing: 14) {
                    Label("Graphics & Display Architecture", systemImage: "display")
                        .font(.headline)
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Wine 64-bit Translation Engine with Apple Game Porting Toolkit (GPTK) integration")
                        Text("• DXVK Direct3D 9/10/11 → Metal pipeline ready")
                        Text("• D3DMetal DirectX 12 acceleration pipeline enabled")
                        Text("• Automatic Retina display coordinate scaling enabled")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }

                Spacer()
            }
            .padding(32)
        }
        .onAppear {
            updateControllers()
        }
    }

    private func updateControllers() {
        connectedControllers = GCController.controllers()
    }
}
