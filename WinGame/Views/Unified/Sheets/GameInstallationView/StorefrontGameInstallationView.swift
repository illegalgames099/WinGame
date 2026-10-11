//
//  StorefrontGameInstallationView.swift
//  WinGame
//
//  Created for WinGame Storefront Game Installation.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct StorefrontGameInstallationView: View {
    @Binding var game: Game
    @Binding var isPresented: Bool

    @State private var isLocateFilePickerPresented: Bool = false
    @State private var isOperating: Bool = false
    @State private var errorMessage: String?
    @State private var isErrorAlertPresented: Bool = false

    var storefrontName: String {
        game.storefront?.description ?? "Storefront"
    }

    var appID: String {
        if game.id.allSatisfy({ $0.isNumber }) {
            return game.id
        }
        let cachedTitles = (UserDefaults.standard.dictionary(forKey: "steam_resolved_titles") as? [String: String]) ?? [:]
        for (id, title) in cachedTitles {
            if title.caseInsensitiveCompare(game.title) == .orderedSame {
                return id
            }
        }
        return game.id
    }

    var installActionTitle: String {
        switch game.storefront {
        case .steam:
            return "Install in Steam"
        case .electronicArts:
            return "Install via EA App"
        case .gog:
            return "Install via GOG GALAXY"
        default:
            return "Install Game"
        }
    }

    var storefrontSystemImage: String {
        switch game.storefront {
        case .steam: return "smoke.fill"
        case .electronicArts: return "circle.grid.2x2.fill"
        case .gog: return "shield.fill"
        default: return "arrow.down.circle.fill"
        }
    }

    var storefrontThemeColor: Color {
        switch game.storefront {
        case .steam: return .blue
        case .electronicArts: return .orange
        case .gog: return .purple
        default: return .accentColor
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with artwork and title
            HStack(spacing: 20) {
                // Vertical artwork
                Group {
                    if let url = game.verticalImageURL ?? game.horizontalImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                placeholderArt
                            }
                        }
                    } else {
                        placeholderArt
                    }
                }
                .frame(width: 130, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: storefrontSystemImage)
                            .foregroundStyle(storefrontThemeColor)
                        Text(storefrontName.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }

                    Text(game.title)
                        .font(.title2.weight(.bold))
                        .lineLimit(2)

                    Text(instructionsText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(24)

            Divider()

            // Info & Locate Existing options
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)

                    Text("Clicking \"\(installActionTitle)\" will launch the storefront client and open the download prompt for \(game.title). Once installed, WinGame will automatically detect it and mark it as Ready to Play.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                HStack {
                    Text("Already have this game downloaded?")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        isLocateFilePickerPresented = true
                    } label: {
                        Label("Locate Game Files...", systemImage: "folder")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.link)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Spacer()

            Divider()

            // Footer action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    triggerInstallation()
                } label: {
                    HStack(spacing: 8) {
                        if isOperating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(installActionTitle)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .tint(storefrontThemeColor)
                .keyboardShortcut(.defaultAction)
                .disabled(isOperating)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 580, height: 380)
        .fileImporter(
            isPresented: $isLocateFilePickerPresented,
            allowedContentTypes: [.application, .executable, .folder],
            allowsMultipleSelection: false
        ) { result in
            handleLocatedFile(result)
        }
        .alert("Installation Error", isPresented: $isErrorAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private var placeholderArt: some View {
        ZStack {
            Color.secondary.opacity(0.15)
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
    }

    private var instructionsText: String {
        switch game.storefront {
        case .steam:
            return "This will send an installation request to Steam for \(game.title) (App ID: \(appID))."
        case .electronicArts:
            return "This will launch the EA App to start downloading \(game.title)."
        case .gog:
            return "This will launch GOG GALAXY to download \(game.title)."
        default:
            return "Launch the installer for \(game.title)."
        }
    }

    private func triggerInstallation() {
        isOperating = true
        Task { @MainActor in
            defer { isOperating = false }
            do {
                switch game.storefront {
                case .steam:
                    try await SteamGameManager.install(game: game, qualityOfService: .default)
                    isPresented = false
                case .electronicArts:
                    try await EAGameManager.install(game: game, qualityOfService: .default)
                    isPresented = false
                case .gog:
                    try await GOGGameManager.install(game: game, qualityOfService: .default)
                    isPresented = false
                default:
                    errorMessage = "Installation not supported for this storefront."
                    isErrorAlertPresented = true
                }
            } catch {
                errorMessage = error.localizedDescription
                isErrorAlertPresented = true
            }
        }
    }

    private func handleLocatedFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            let isWindows = selectedURL.pathExtension.lowercased() == "exe" || selectedURL.hasDirectoryPath
            let platform: Game.Platform = isWindows ? .windows : .macOS
            game.installationState = .installed(location: selectedURL, platform: platform)
            GameDataStore.shared.library.update(with: game)
            isPresented = false
        case .failure(let error):
            errorMessage = error.localizedDescription
            isErrorAlertPresented = true
        }
    }
}
