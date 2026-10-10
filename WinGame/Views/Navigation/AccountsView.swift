//
//  AccountsView.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 12/3/2024.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI

struct AccountsView: View {
    @Bindable private var accountManager: StorefrontAccountManager = .shared
    @ObservedObject private var epicWebAuthViewModel: EpicWebAuthViewModel = .shared

    @State private var isEpicSignOutConfirmationAlertPresented: Bool = false
    @State private var epicSignOutError: Error?
    @State private var isEpicSignOutErrorAlertPresented: Bool = false
    @State private var editingStorefront: Game.Storefront?

    @State private var usernameInput: String = ""
    @State private var idInput: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Connected Storefront Accounts")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Link your personal storefront accounts to manage games, synchronization, and launch environments.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                    // Epic Games Card
                    storefrontCard(
                        title: "Epic Games",
                        systemImage: "shield.rhombohex.fill",
                        color: .purple,
                        username: accountManager.epicUsername,
                        isConnected: accountManager.isEpicConnected,
                        onConnect: {
                            Task { @MainActor in
                                epicWebAuthViewModel.showSignInWindow()
                            }
                        },
                        onDisconnect: {
                            isEpicSignOutConfirmationAlertPresented = true
                        }
                    )

                    // Steam Card
                    storefrontCard(
                        title: "Steam",
                        systemImage: "circle.grid.cross.fill",
                        color: .blue,
                        username: accountManager.isSteamConnected ? accountManager.steamUsername : nil,
                        isConnected: accountManager.isSteamConnected,
                        onConnect: {
                            startEditing(.steam)
                        },
                        onDisconnect: {
                            accountManager.disconnectSteam()
                            Task { try? await GameDataStore.shared.refreshFromStorefronts(.steam) }
                        }
                    )

                    // Electronic Arts (EA) Card
                    storefrontCard(
                        title: "Electronic Arts (EA)",
                        systemImage: "triangle.fill",
                        color: .red,
                        username: accountManager.isEAConnected ? accountManager.eaUsername : nil,
                        isConnected: accountManager.isEAConnected,
                        onConnect: {
                            startEditing(.electronicArts)
                        },
                        onDisconnect: {
                            accountManager.disconnectEA()
                            Task { try? await GameDataStore.shared.refreshFromStorefronts(.electronicArts) }
                        }
                    )

                    // GOG Card
                    storefrontCard(
                        title: "GOG",
                        systemImage: "gamecontroller.fill",
                        color: .teal,
                        username: accountManager.isGOGConnected ? accountManager.gogUsername : nil,
                        isConnected: accountManager.isGOGConnected,
                        onConnect: {
                            startEditing(.gog)
                        },
                        onDisconnect: {
                            accountManager.disconnectGOG()
                            Task { try? await GameDataStore.shared.refreshFromStorefronts(.gog) }
                        }
                    )
                }
            }
            .padding(24)
        }
        .navigationTitle("Accounts")
        .alert(
            "Are you sure you want to sign out of Epic Games?",
            isPresented: $isEpicSignOutConfirmationAlertPresented
        ) {
            Button(role: .destructive) {
                Task {
                    do {
                        try await Legendary.signOut()
                    } catch {
                        epicSignOutError = error
                        isEpicSignOutErrorAlertPresented = true
                    }
                }
            } label: {
                Text("Sign Out")
            }
        }
        .sheet(item: $editingStorefront) { storefront in
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Link \(storefront.description) Account")
                        .font(.title3.weight(.bold))
                    Spacer()
                    Button("Close") {
                        editingStorefront = nil
                    }
                }

                Button {
                    let target = storefront
                    editingStorefront = nil
                    switch target {
                    case .steam:
                        PlatformWebAuthViewModel.shared.showSignIn(for: .steam)
                    case .electronicArts:
                        PlatformWebAuthViewModel.shared.showSignIn(for: .electronicArts)
                    case .gog:
                        PlatformWebAuthViewModel.shared.showSignIn(for: .gog)
                    default:
                        break
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Sign In via In-App Browser")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text("Or enter your account credentials manually:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    TextField("Username / Persona Name", text: $usernameInput)
                        .textFieldStyle(.roundedBorder)

                    TextField("Account ID / Profile URL", text: $idInput)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Button("Auto-Detect from Mac") {
                        accountManager.autoDetectLocalAccounts()
                        loadInputsFor(storefront)
                    }

                    Spacer()

                    Button("Save") {
                        saveInputsFor(storefront)
                        editingStorefront = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(usernameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(20)
            .frame(width: 400)
        }
    }

    private func storefrontCard(
        title: String,
        systemImage: String,
        color: Color,
        username: String?,
        isConnected: Bool,
        onConnect: @escaping () -> Void,
        onDisconnect: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: systemImage)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(isConnected ? "Connected as \(username ?? "User")" : "Not Linked")
                        .font(.caption)
                        .foregroundStyle(isConnected ? .green : .secondary)
                }

                Spacer()
            }

            HStack {
                if isConnected {
                    Button("Edit", action: onConnect)
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Button("Disconnect", role: .destructive, action: onDisconnect)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                } else {
                    Button("Connect Account", action: onConnect)
                        .buttonStyle(.borderedProminent)
                        .tint(color.opacity(0.85))
                        .controlSize(.small)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func startEditing(_ storefront: Game.Storefront) {
        editingStorefront = storefront
        loadInputsFor(storefront)
    }

    private func loadInputsFor(_ storefront: Game.Storefront) {
        switch storefront {
        case .steam:
            usernameInput = accountManager.steamUsername
            idInput = accountManager.steamID
        case .electronicArts:
            usernameInput = accountManager.eaUsername
            idInput = accountManager.eaID
        case .gog:
            usernameInput = accountManager.gogUsername
            idInput = accountManager.gogID
        default:
            usernameInput = ""
            idInput = ""
        }
    }

    private func saveInputsFor(_ storefront: Game.Storefront) {
        switch storefront {
        case .steam:
            accountManager.saveSteam(username: usernameInput, id: idInput)
            Task { try? await GameDataStore.shared.refreshFromStorefronts(.steam) }
        case .electronicArts:
            accountManager.saveEA(username: usernameInput, id: idInput)
            Task { try? await GameDataStore.shared.refreshFromStorefronts(.electronicArts) }
        case .gog:
            accountManager.saveGOG(username: usernameInput, id: idInput)
            Task { try? await GameDataStore.shared.refreshFromStorefronts(.gog) }
        default:
            break
        }
    }
}

extension Game.Storefront: Identifiable {
    public var id: String { description }
}
