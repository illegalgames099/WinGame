//
//  GameHubAccountsView.swift
//  WinGame
//
//  Created for GameHub multi-storefront account management.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI

struct GameHubAccountsView: View {
    @Bindable var gameDataStore: GameDataStore = .shared
    @Bindable var accountManager: StorefrontAccountManager = .shared
    @ObservedObject private var epicWebAuthViewModel: EpicWebAuthViewModel = .shared

    @State private var activeSheetTarget: StorefrontAccountTarget?
    @State private var copiedNotice: String?

    enum StorefrontAccountTarget: Identifiable {
        case steam
        case epic
        case ea
        case gog

        var id: String {
            switch self {
            case .steam: return "steam"
            case .epic: return "epic"
            case .ea: return "ea"
            case .gog: return "gog"
            }
        }
    }

    private var epicGamesCount: Int {
        gameDataStore.library.filter { $0.storefront == .epicGames }.count
    }

    private var steamGamesCount: Int {
        gameDataStore.library.filter { $0.storefront == .steam }.count
    }

    private var eaGamesCount: Int {
        gameDataStore.library.filter { $0.storefront == .electronicArts }.count
    }

    private var gogGamesCount: Int {
        gameDataStore.library.filter { $0.storefront == .gog }.count
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // MARK: - Steam Card
                steamCard

                // MARK: - Epic Games Card
                epicGamesCard

                // MARK: - EA (Electronic Arts) Card
                eaCard

                // MARK: - GOG Card
                gogCard

                if let notice = copiedNotice {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(notice)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .frame(width: 310)
        .sheet(item: $activeSheetTarget) { target in
            AccountEditSheet(target: target)
        }
        .animation(.spring(response: 0.3), value: copiedNotice)
    }

    // MARK: - Steam Account Card
    private var steamCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)

                Text("Steam")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)

                if accountManager.isSteamConnected {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Online")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.18), in: Capsule())
                }

                Spacer()

                Button {
                    activeSheetTarget = .steam
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Manage Steam Account")

                Button {
                    accountManager.autoDetectLocalAccounts()
                    Task { try? await gameDataStore.refreshFromStorefronts(.steam) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh Steam Library")
            }

            if accountManager.isSteamConnected {
                // Connected User Details
                HStack(spacing: 10) {
                    Text("0")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))

                    Text(String(accountManager.steamUsername.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 8)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(accountManager.steamUsername)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if !accountManager.steamID.isEmpty {
                            Button {
                                copyToClipboard(accountManager.steamID, label: "Steam ID copied")
                            } label: {
                                HStack(spacing: 4) {
                                    Text(accountManager.steamID.prefix(12) + "...")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary.opacity(0.8))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()
                }

                // Friends row
                HStack {
                    Label("Friends", systemImage: "person.2.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))

                    Spacer()

                    Text("0 / 1  ›")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

                // Stats row
                HStack {
                    statBox(title: "STATUS", value: "Active")
                    Divider().frame(height: 24).background(Color.white.opacity(0.1))
                    statBox(title: "GAMES", value: "\(steamGamesCount)")
                    Divider().frame(height: 24).background(Color.white.opacity(0.1))
                    statBox(title: "PLAYTIME", value: "\(String(format: "%.1fh", accountManager.steamPlaytimeHours))")
                }
            } else {
                // Not Connected Prompt
                VStack(spacing: 10) {
                    Text("No Steam account linked")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        activeSheetTarget = .steam
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Connect Steam Account")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue.opacity(0.8))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(Color(white: 0.11).opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Epic Games Account Card
    private var epicGamesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "shield.rhombohex.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)

                Text("Epic Games")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    Task { @MainActor in
                        epicWebAuthViewModel.showSignInWindow()
                    }
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Sign in to Epic Games")

                Button {
                    Task { try? await gameDataStore.refreshFromStorefronts(.epicGames) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh Epic Games Library")
            }

            if let epicUser = accountManager.epicUsername {
                // Signed in Epic User
                HStack(spacing: 10) {
                    Text(String(epicUser.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.7), Color.indigo.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 8)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(epicUser)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text("Signed In")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(epicGamesCount)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Games")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // Not Signed In Prompt
                VStack(spacing: 10) {
                    Text("Not signed in to Epic Games")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        Task { @MainActor in
                            epicWebAuthViewModel.showSignInWindow()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.key.fill")
                            Text("Sign In with Epic Games")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple.opacity(0.8))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(Color(white: 0.11).opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Electronic Arts (EA) Card
    private var eaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)

                Text("EA")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    activeSheetTarget = .ea
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Manage EA Account")

                Button {
                    accountManager.autoDetectLocalAccounts()
                    Task { try? await gameDataStore.refreshFromStorefronts(.electronicArts) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh EA Library")
            }

            if accountManager.isEAConnected {
                HStack(spacing: 10) {
                    Text(String(accountManager.eaUsername.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.7), Color.orange.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 8)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(accountManager.eaUsername)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if !accountManager.eaID.isEmpty {
                            Button {
                                copyToClipboard(accountManager.eaID, label: "EA ID copied")
                            } label: {
                                HStack(spacing: 4) {
                                    Text(accountManager.eaID)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary.opacity(0.8))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(eaGamesCount)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Games")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Text("No EA account linked")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        activeSheetTarget = .ea
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Connect EA Account")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red.opacity(0.8))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(Color(white: 0.11).opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - GOG Account Card
    private var gogCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)

                Text("GOG")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    activeSheetTarget = .gog
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Manage GOG Account")

                Button {
                    accountManager.autoDetectLocalAccounts()
                    Task { try? await gameDataStore.refreshFromStorefronts(.gog) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh GOG Library")
            }

            if accountManager.isGOGConnected {
                HStack(spacing: 10) {
                    Text(String(accountManager.gogUsername.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.7), Color.blue.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 8)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(accountManager.gogUsername)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if !accountManager.gogID.isEmpty {
                            Button {
                                copyToClipboard(accountManager.gogID, label: "GOG ID copied")
                            } label: {
                                HStack(spacing: 4) {
                                    Text(accountManager.gogID.prefix(12) + "...")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary.opacity(0.8))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(gogGamesCount)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Games")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Text("No GOG account linked")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        activeSheetTarget = .gog
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Connect GOG Account")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal.opacity(0.8))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(Color(white: 0.11).opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private func copyToClipboard(_ text: String, label: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation {
            copiedNotice = label
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                copiedNotice = nil
            }
        }
    }
}

// MARK: - Account Edit Sheet
private struct AccountEditSheet: View {
    let target: GameHubAccountsView.StorefrontAccountTarget
    @Environment(\.dismiss) private var dismiss

    @State private var usernameInput: String = ""
    @State private var idInput: String = ""

    private var accountManager = StorefrontAccountManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(titleText)
                    .font(.title2.weight(.bold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text("Enter your account credentials or auto-detect from local installations on this Mac.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Username / Persona Name")
                        .font(.caption.weight(.medium))
                    TextField("Enter username", text: $usernameInput)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Account ID / Profile URL")
                        .font(.caption.weight(.medium))
                    TextField("Enter Account ID", text: $idInput)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                Button("Auto-Detect from Mac") {
                    accountManager.autoDetectLocalAccounts()
                    loadExistingValues()
                }
                .buttonStyle(.bordered)

                Spacer()

                if isConnected {
                    Button(role: .destructive) {
                        disconnectAccount()
                        dismiss()
                    } label: {
                        Text("Disconnect")
                    }
                    .buttonStyle(.bordered)
                }

                Button("Save and Link") {
                    saveAccount()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(usernameInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear {
            loadExistingValues()
        }
    }

    private var titleText: String {
        switch target {
        case .steam: return "Link Steam Account"
        case .epic: return "Link Epic Games Account"
        case .ea: return "Link Electronic Arts Account"
        case .gog: return "Link GOG Account"
        }
    }

    private var isConnected: Bool {
        switch target {
        case .steam: return accountManager.isSteamConnected
        case .epic: return accountManager.isEpicConnected
        case .ea: return accountManager.isEAConnected
        case .gog: return accountManager.isGOGConnected
        }
    }

    private func loadExistingValues() {
        switch target {
        case .steam:
            usernameInput = accountManager.steamUsername
            idInput = accountManager.steamID
        case .ea:
            usernameInput = accountManager.eaUsername
            idInput = accountManager.eaID
        case .gog:
            usernameInput = accountManager.gogUsername
            idInput = accountManager.gogID
        case .epic:
            usernameInput = accountManager.epicUsername ?? ""
            idInput = ""
        }
    }

    private func saveAccount() {
        switch target {
        case .steam:
            accountManager.saveSteam(username: usernameInput, id: idInput)
        case .ea:
            accountManager.saveEA(username: usernameInput, id: idInput)
        case .gog:
            accountManager.saveGOG(username: usernameInput, id: idInput)
        case .epic:
            break
        }
    }

    private func disconnectAccount() {
        switch target {
        case .steam:
            accountManager.disconnectSteam()
        case .ea:
            accountManager.disconnectEA()
        case .gog:
            accountManager.disconnectGOG()
        case .epic:
            break
        }
    }
}
