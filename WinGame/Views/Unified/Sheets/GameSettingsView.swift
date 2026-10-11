//
//  GameSettingsView.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 10/20/24.
//

// Copyright © 2023-2025 vapidinfinity

import SwiftUI

/// GameHub-style Game Details, Launch Center, and Configuration View
struct GameSettingsView: View {
    @Binding var game: Game
    @Binding var isPresented: Bool

    @Bindable private var operationManager: GameOperationManager = .shared
    @EnvironmentObject var networkMonitor: NetworkMonitor

    enum GameHubTab: String, CaseIterable, Identifiable {
        case general = "General"
        case compatibility = "Compatibility"
        case graphics = "Graphics & HUD"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .general: return "slider.horizontal.3"
            case .compatibility: return "cpu"
            case .graphics: return "gauge.with.dots.needle.bottom.50percent"
            }
        }
    }

    @State private var selectedTab: GameHubTab = .general
    @State private var isImageEmpty: Bool = true

    // Launch & Engine Installation States
    @State private var isLaunchErrorAlertPresented = false
    @State private var launchError: Error?
    @State private var isEngineInstallationViewPresented = false
    @State private var engineInstallationError: Error?
    @State private var engineInstallationSuccess = false

    // Install & Uninstall States
    @State private var isInstallSheetPresented = false
    @State private var isUninstallSheetPresented = false

    // Moving File States
    @State private var movingError: Error?
    @State private var isMovingErrorAlertPresented = false
    @State private var isMovingFileImporterPresented = false

    // Verification States
    @State private var verificationError: Error?
    @State private var isVerificationErrorAlertPresented = false

    // Launch Arguments & Thumbnail
    @State private var typingArgument: String = ""
    @State private var isThumbnailURLChangeSheetPresented = false

    // Hover States
    @State private var isHoveringFavorite = false
    @State private var isHoveringPlay = false

    var isWindowsGame: Bool {
        if case .installed(_, let platform) = game.installationState {
            return platform == .windows
        }
        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - GameHub Hero Header
            heroHeader

            // MARK: - GameHub Launch & Action Command Bar
            actionCommandBar
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)

            Divider()

            // MARK: - GameHub Segmented Tabs
            tabBar
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 8)

            // MARK: - Tab Content Area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .general:
                        generalTabContent
                    case .compatibility:
                        compatibilityTabContent
                    case .graphics:
                        graphicsTabContent
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }

            Divider()

            // MARK: - Bottom Footer
            bottomFooter
        }
        .frame(minWidth: 760, idealWidth: 840, minHeight: 620, idealHeight: 740)
        .background(Color(nsColor: .windowBackgroundColor))
        // Sheets
        .sheet(isPresented: $isEngineInstallationViewPresented) {
            EngineInstallationView(
                isPresented: $isEngineInstallationViewPresented,
                installationError: $engineInstallationError,
                installationComplete: $engineInstallationSuccess
            )
            .padding()
            .frame(width: 500, height: 320)
        }
        .sheet(isPresented: $isInstallSheetPresented) {
            switch game {
            case let epicGame as EpicGamesGame:
                EpicGamesGameInstallationView(
                    game: .init(get: { epicGame }, set: { game = $0 }),
                    isPresented: $isInstallSheetPresented
                )
                .padding()
                .frame(width: 700, height: 420)
            default:
                StorefrontGameInstallationView(
                    game: $game,
                    isPresented: $isInstallSheetPresented
                )
            }
        }
        .sheet(isPresented: $isUninstallSheetPresented) {
            switch game {
            case let epicGame as EpicGamesGame:
                EpicGamesGameUninstallationView(
                    game: .init(get: { epicGame }, set: { game = $0 }),
                    isPresented: $isUninstallSheetPresented
                )
                .padding()
                .frame(width: 700, height: 380)
            case let localGame as LocalGame:
                LocalGameUninstallationView(
                    game: .init(get: { localGame }, set: { game = $0 }),
                    isPresented: $isUninstallSheetPresented
                )
                .padding()
                .frame(width: 700, height: 380)
            default:
                EmptyView()
            }
        }
        .sheet(isPresented: $isThumbnailURLChangeSheetPresented) {
            ThumbnailURLChangeView(game: $game, isPresented: $isThumbnailURLChangeSheetPresented)
                .padding()
                .frame(width: 600, height: 320)
        }
        // Alerts
        .alert(isPresented: $isLaunchErrorAlertPresented) {
            if launchError is Engine.NotInstalledError {
                return Alert(
                    title: Text("WinGame Engine is not installed."),
                    message: Text("WinGame Engine is required to launch this game.\nWould you like to install it now?"),
                    primaryButton: .default(Text("Install")) {
                        isEngineInstallationViewPresented = true
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(
                    title: Text("Error launching \"\(game.title)\"."),
                    message: Text(launchError?.localizedDescription ?? "Unknown Error.")
                )
            }
        }
        .alert("Unable to verify installation.",
               isPresented: $isVerificationErrorAlertPresented,
               presenting: verificationError) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error?.localizedDescription ?? "Unknown error.")
        }
    }
}

// MARK: - Hero Header Component
private extension GameSettingsView {
    var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop horizontal banner art
            GeometryReader { geo in
                ZStack {
                    GameImageCard(url: game.horizontalImageURL, isImageEmpty: $isImageEmpty)
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(width: geo.size.width, height: 230)
                        .clipped()

                    // Top vignette
                    LinearGradient(
                        colors: [.black.opacity(0.75), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )

                    // Bottom atmospheric blend
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.85), Color(nsColor: .windowBackgroundColor)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .frame(height: 230)

            // Top Badges & Dismiss Button
            VStack {
                HStack(spacing: 8) {
                    // Storefront badge
                    HStack(spacing: 5) {
                        Image(systemName: storefrontIconName)
                        Text(game.storefront?.description ?? "Local")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())

                    // Platform badge
                    if case .installed(_, let platform) = game.installationState {
                        HStack(spacing: 4) {
                            Image(systemName: platform == .windows ? "terminal" : "apple.logo")
                            Text(platform == .windows ? "Windows® (Wine/GPTK)" : "macOS Native")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                    }

                    Spacer()

                    // Dismiss Close Button
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Close")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()
            }
            .frame(height: 230)

            // Hero Bottom: Floating Cover Card + Title & Metadata
            HStack(alignment: .bottom, spacing: 18) {
                // Vertical Poster Art
                GameImageCard(game: game, url: game.verticalImageURL, isImageEmpty: .constant(false))
                    .aspectRatio(3/4, contentMode: .fit)
                    .frame(width: 84, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

                VStack(alignment: .leading, spacing: 6) {
                    // Game Title
                    Text(game.title)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                        .lineLimit(2)

                    // Status and Info Row
                    HStack(spacing: 12) {
                        // Installation & Status indicator
                        statusPill

                        // Last played
                        if let lastLaunched = game.lastLaunched {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text("Last played: \(lastLaunched.formatted(date: .abbreviated, time: .omitted))")
                            }
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text("Never launched")
                            }
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        }

                        // Container badge (if Windows)
                        if let containerURL = game.containerURL,
                           let container = try? Wine.getContainerObject(at: containerURL) {
                            HStack(spacing: 4) {
                                Image(systemName: "cube")
                                Text(container.name)
                            }
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.bottom, 6)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
        .frame(height: 230)
    }

    var storefrontIconName: String {
        switch game.storefront {
        case .epicGames: return "gamecontroller.fill"
        case .steam: return "smoke.fill"
        case .local: return "internaldrive.fill"
        case .gog: return "shield.fill"
        case .electronicArts: return "circle.grid.2x2.fill"
        case .none: return "gamecontroller"
        }
    }

    @ViewBuilder
    var statusPill: some View {
        if case .installed = game.installationState {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Ready to Play")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.green.opacity(0.25), in: Capsule())
        } else {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                Text("Not Installed")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.15), in: Capsule())
        }
    }
}

// MARK: - GameHub Launch & Action Command Bar
private extension GameSettingsView {
    var actionCommandBar: some View {
        HStack(spacing: 16) {
            // MARK: Primary Action Button (Play / Install / Operation)
            if let currentOp = operationManager.queue.first(where: { $0.isExecuting && $0.game == game }) {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text(currentOp.type.description)
                        .font(.headline)
                        .bold()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.quaternary, in: Capsule())
            } else if case .installed = game.installationState {
                // Prominent GameHub Play Button
                Button {
                    launchGame()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("PLAY")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .kerning(1)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 11)
                    .foregroundStyle(.black)
                    .background(
                        LinearGradient(
                            colors: [Color.white, Color(white: 0.88)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: Capsule()
                    )
                    .shadow(color: .white.opacity(isHoveringPlay ? 0.35 : 0.15), radius: 10, x: 0, y: 3)
                    .scaleEffect(isHoveringPlay ? 1.02 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { isHoveringPlay = $0 }
                .disabled(operationManager.queue.contains(where: { $0.game == game && $0.type.modifiesFiles }))
                .help("Launch \"\(game.title)\"")
            } else {
                // Prominent GameHub Install Button
                Button {
                    isInstallSheetPresented = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.down.to.line.compact")
                            .font(.title3)
                        Text("INSTALL")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .kerning(1)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 11)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(networkMonitor.epicAccessibilityState != .accessible && game.storefront == .epicGames)
                .help("Install \"\(game.title)\"")
            }

            // MARK: Secondary Action Strip
            HStack(spacing: 8) {
                // Favorite Toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        game.isFavourited.toggle()
                    }
                } label: {
                    Image(systemName: game.isFavourited ? "star.fill" : "star")
                        .foregroundStyle(game.isFavourited ? .yellow : .primary)
                        .font(.body.weight(.medium))
                        .frame(width: 34, height: 34)
                        .background(Color.secondary.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .help(game.isFavourited ? "Remove from Favorites" : "Add to Favorites")

                // Reveal in Finder
                if case .installed(let location, _) = game.installationState {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([location])
                    } label: {
                        Image(systemName: "folder")
                            .font(.body.weight(.medium))
                            .frame(width: 34, height: 34)
                            .background(Color.secondary.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Show Game Files in Finder")
                }

                // Verify Files
                if game.storefront != .local {
                    Button {
                        verifyGameFiles()
                    } label: {
                        Image(systemName: "checkmark.shield")
                            .font(.body.weight(.medium))
                            .frame(width: 34, height: 34)
                            .background(Color.secondary.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(operationManager.queue.contains(where: { $0.game == game && $0.type == .repair }))
                    .help("Verify Game Files Integrity")
                }

                // Move Files
                if case .installed = game.installationState {
                    Button {
                        isMovingFileImporterPresented = true
                    } label: {
                        Image(systemName: "arrow.left.arrow.right.square")
                            .font(.body.weight(.medium))
                            .frame(width: 34, height: 34)
                            .background(Color.secondary.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(operationManager.queue.first?.game == game)
                    .fileImporter(
                        isPresented: $isMovingFileImporterPresented,
                        allowedContentTypes: [.folder],
                        allowsMultipleSelection: false
                    ) { result in
                        handleMoveFile(result: result)
                    }
                    .alert("Unable to move \"\(game.title)\".",
                           isPresented: $isMovingErrorAlertPresented,
                           presenting: movingError) { _ in
                        Button("OK", role: .cancel) { }
                    } message: { error in
                        Text(error?.localizedDescription ?? "Unknown error.")
                    }
                    .help("Move Game to Another Directory")
                }

                // Update Button (if available)
                if game.isUpdateAvailable == true {
                    Button {
                        Task(priority: .userInitiated) {
                            try? await game.update()
                        }
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.orange)
                            .frame(width: 34, height: 34)
                            .background(Color.orange.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(operationManager.queue.contains(where: { $0.game == game && $0.type == .update }))
                    .help("Update Available")
                }

                // Uninstall / Delete Button
                if case .installed = game.installationState {
                    Button {
                        isUninstallSheetPresented = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                            .background(Color.secondary.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(operationManager.queue.contains(where: { $0.game == game && $0.type == .uninstall }))
                    .help("Uninstall Game")
                }
            }

            Spacer()
        }
    }

    func launchGame() {
        Task(priority: .userInitiated) {
            do {
                try await game.launch()
            } catch {
                await MainActor.run {
                    launchError = error
                    isLaunchErrorAlertPresented = true
                }
            }
        }
    }

    func verifyGameFiles() {
        Task { [game] in
            do {
                try await game.verifyInstallation()
            } catch {
                await MainActor.run {
                    verificationError = error
                    isVerificationErrorAlertPresented = true
                }
            }
        }
    }

    func handleMoveFile(result: Result<[URL], Error>) {
        switch result {
        case .success(let success):
            guard let newLocation = success.first else { return }
            Task { @MainActor in
                do {
                    try await game.move(to: newLocation)
                } catch {
                    movingError = error
                    isMovingErrorAlertPresented = true
                }
            }
        case .failure(let failure):
            movingError = failure
            isMovingErrorAlertPresented = true
        }
    }
}

// MARK: - GameHub Tab Bar
private extension GameSettingsView {
    var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(GameHubTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.iconName)
                        Text(tab.rawValue)
                    }
                    .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        selectedTab == tab ? Color.accentColor.opacity(0.18) : Color.clear,
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                selectedTab == tab ? Color.accentColor.opacity(0.4) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

// MARK: - General Tab Content
private extension GameSettingsView {
    var generalTabContent: some View {
        VStack(spacing: 16) {
            // Card 1: Game Location & File Details
            VStack(alignment: .leading, spacing: 14) {
                Label("Game Files & Location", systemImage: "folder.badge.gearshape")
                    .font(.headline)

                if case .installed(let location, _) = game.installationState {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Installation Path")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(location.path)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .textSelection(.enabled)

                            Spacer()

                            Button("Show in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([location])
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button("Move...") {
                                isMovingFileImporterPresented = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(operationManager.queue.first?.game == game)
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                // File Verification Row
                if game.storefront != .local {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("File Integrity Verification")
                                .font(.subheadline.weight(.medium))
                            Text("Verify game files against storefront manifest to repair missing or corrupted assets.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let currentOp = operationManager.queue.first(where: { $0.game == game && $0.type == .repair }) {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Button("Verify Files") {
                                verifyGameFiles()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))

            // Card 2: Custom Launch Arguments
            VStack(alignment: .leading, spacing: 14) {
                Label("Launch Arguments", systemImage: "terminal")
                    .font(.headline)

                Text("Custom command-line parameters passed directly when starting the game executable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Current argument pills
                if !game.launchArguments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(game.launchArguments, id: \.self) { arg in
                                ArgumentItem(game: $game, launchArguments: $game.launchArguments, argument: arg)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Argument input bar
                HStack {
                    TextField("e.g. -novid -fullscreen -dx11", text: $typingArgument)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(submitLaunchArgument)

                    Button("Add") {
                        submitLaunchArgument()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(typingArgument.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))

            // Card 3: Artwork & Metadata Customization
            VStack(alignment: .leading, spacing: 14) {
                Label("Artwork Customization", systemImage: "photo.badge.plus")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Cover Poster")
                            .font(.subheadline.weight(.medium))
                        Text("Personalize the game artwork displayed in your library and dashboard.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Change Cover...") {
                        isThumbnailURLChangeSheetPresented = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    func submitLaunchArgument() {
        let cleanedArgument = typingArgument
            .trimmingCharacters(in: .illegalCharacters)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var wordExpansion = wordexp_t()
        defer { wordfree(&wordExpansion) }

        guard Darwin.wordexp(cleanedArgument, &wordExpansion, 0) == 0 else { return }

        let splitArguments: [String] = (0..<Int(wordExpansion.we_wordc))
            .compactMap({ String(cString: wordExpansion.we_wordv[$0]!) })

        if !cleanedArgument.isEmpty,
           !game.launchArguments.contains(typingArgument) {
            game.launchArguments += splitArguments
            typingArgument = ""
        }
    }
}

// MARK: - Compatibility Tab Content
private extension GameSettingsView {
    var compatibilityTabContent: some View {
        VStack(spacing: 16) {
            if isWindowsGame {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Wine Bottle & Engine Compatibility", systemImage: "cpu")
                        .font(.headline)

                    Text("Tune synchronization modes, Retina resolution, and the Windows version for this container prefix.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Form {
                        ContainerSettingsView(
                            selectedContainerURL: $game.containerURL,
                            withPicker: true,
                            sectionScope: .compatibilityOnly
                        )
                    }
                    .formStyle(.grouped)
                }
                .padding(16)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            } else {
                ContentUnavailableView(
                    "Native macOS Game",
                    systemImage: "apple.logo",
                    description: Text("This title is compiled for macOS and runs directly without requiring Wine container translation.")
                )
                .padding(24)
            }
        }
    }
}

// MARK: - Graphics & HUD Tab Content
private extension GameSettingsView {
    var graphicsTabContent: some View {
        VStack(spacing: 16) {
            if isWindowsGame {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Graphics Translation & Metal HUD", systemImage: "gauge.with.dots.needle.bottom.50percent")
                        .font(.headline)

                    Text("Configure Apple Metal Performance HUD overlays and DirectX translation layers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Form {
                        ContainerSettingsView(
                            selectedContainerURL: $game.containerURL,
                            withPicker: false,
                            sectionScope: .graphicsOnly
                        )
                    }
                    .formStyle(.grouped)
                }
                .padding(16)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))

                // Informational Stack Card
                VStack(alignment: .leading, spacing: 10) {
                    Label("Graphics Pipeline Architecture", systemImage: "info.circle")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("**D3DMetal (Default):** Apple's Game Porting Toolkit Direct3D 11/12 to Metal translation engine with shader compilation optimization.")
                                .font(.caption)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                            Text("**DXVK:** Translates Direct3D 9/10/11 calls into Vulkan, bridged to Metal via MoltenVK. Ideal for legacy titles.")
                                .font(.caption)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.purple)
                            Text("**Metal Performance HUD:** Real-time on-screen telemetry presenting live FPS, frame timings, and GPU memory usage.")
                                .font(.caption)
                        }
                    }
                }
                .padding(16)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            } else {
                ContentUnavailableView(
                    "Native Metal Rendering",
                    systemImage: "sparkles",
                    description: Text("This game renders directly via macOS Metal without translation.")
                )
                .padding(24)
            }
        }
    }
}

// MARK: - Bottom Footer Component
private extension GameSettingsView {
    var bottomFooter: some View {
        HStack {
            if case .installed(_, let platform) = game.installationState {
                SubscriptedTextView(platform.description)
            }
            GameCard.SubscriptedInfoView(game: $game)

            Spacer()

            Button("Done") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

// MARK: - Nested Helper Views
extension GameSettingsView {
    struct ArgumentItem: View {
        @Binding var game: Game
        @Binding var launchArguments: [String]
        var argument: String

        @State private var isHoveringOverArgument = false

        var body: some View {
            HStack(spacing: 6) {
                Text(argument)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(isHoveringOverArgument ? .red : .primary)

                if isHoveringOverArgument {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(isHoveringOverArgument ? 0.15 : 0.08), in: Capsule())
            .onHover { isHoveringOverArgument = $0 }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    launchArguments.removeAll(where: { $0 == argument })
                    if launchArguments.isEmpty {
                        game.launchArguments = []
                    }
                }
            }
            .help("Click to remove this argument")
        }
    }

    struct ThumbnailURLChangeView: View {
        @Binding var game: Game
        @Binding var isPresented: Bool

        @State private var isImageEmpty = true

        var body: some View {
            HStack(spacing: 20) {
                GameImageCard(game: game, url: game.verticalImageURL, isImageEmpty: $isImageEmpty)
                    .aspectRatio(3/4, contentMode: .fill)
                    .frame(width: 140, height: 187)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 16) {
                    Text("Change Cover Artwork")
                        .font(.title2.bold())

                    Form {
                        GameCard.ImageURLModifierView(game: $game, imageURL: $game._verticalImageURL)
                    }
                    .formStyle(.grouped)

                    HStack {
                        Button("Cancel") { isPresented = false }
                        Spacer()
                        Button("Done") { isPresented = false }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}

#Preview {
    GameSettingsView(
        game: .constant(placeholderGame(type: Game.self)),
        isPresented: .constant(true)
    )
    .environmentObject(NetworkMonitor.shared)
}
