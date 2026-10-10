//
//  GOGGameManager.swift
//  WinGame
//
//  Created for WinGame GOG Galaxy Integration.
//

// Copyright © 2023-2026 vapidinfinity

import Foundation
import AppKit
import OSLog

struct GOGGameManager: StorefrontGameManager {
    static var log: Logger { .custom(category: "GOGGameManager") }

    @MainActor
    @discardableResult
    static func launch(game: Game) async throws -> GameOperation {
        guard case .gog = game.storefront,
              let castGame = game as? GOGGame else { throw CocoaError(.coderInvalidValue) }
        
        let operation: GameOperation = .init(game: castGame, type: .launch) { _ in
            if case .installed(let location, let platform) = castGame.installationState {
                switch platform {
                case .macOS:
                    NSWorkspace.shared.open(location)
                case .windows:
                    guard Engine.isInstalled else { throw Engine.NotInstalledError() }
                    let containerURL: URL
                    if let existing = castGame.containerURL, Wine.containerExists(at: existing) {
                        containerURL = existing
                    } else if let firstExisting = Wine.containerURLs.first(where: { Wine.containerExists(at: $0) }) {
                        containerURL = firstExisting
                    } else {
                        let defaultContainer = try await Wine.createContainer(name: "Default")
                        containerURL = defaultContainer.url
                    }

                    let container = try Wine.getContainerObject(at: containerURL)
                    let environment = try Wine.assembleEnvironmentVariables(forContainerAtURL: container.url)

                    let process = Process()
                    process.currentDirectoryURL = location.deletingLastPathComponent()
                    process.arguments = [location.path] + castGame.launchArguments
                    process.environment = environment
                    Wine.transformProcess(process, containerURL: containerURL)

                    try await withTaskCancellationHandler {
                        try process.run()
                        process.waitUntilExit()
                    } onCancel: {
                        process.terminate()
                    }
                }
            } else if let url = URL(string: "goggalaxy://openGameView/\(castGame.id)") {
                NSWorkspace.shared.open(url)
            }
        }
        Game.operationManager.queueOperation(operation)
        return operation
    }

    @MainActor
    @discardableResult
    static func move(game: Game, to newLocation: URL) async throws -> GameOperation {
        fatalError("Storefront manages file locations")
    }

    @MainActor
    @discardableResult
    static func uninstall(game: Game, persistFiles: Bool) async throws -> GameOperation {
        guard case .gog = game.storefront,
              let castGame = game as? GOGGame else { throw CocoaError(.coderInvalidValue) }
        
        let operation: GameOperation = .init(game: castGame, type: .uninstall) { _ in
            if let url = URL(string: "goggalaxy://openGameView/\(castGame.id)") {
                NSWorkspace.shared.open(url)
            }
        }
        Game.operationManager.queueOperation(operation)
        return operation
    }

    @MainActor
    @discardableResult
    static func install(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        guard case .gog = game.storefront,
              let castGame = game as? GOGGame else { throw CocoaError(.coderInvalidValue) }
        
        let operation: GameOperation = .init(game: castGame, type: .install) { _ in
            if let url = URL(string: "goggalaxy://openGameView/\(castGame.id)") {
                NSWorkspace.shared.open(url)
            }
        }
        Game.operationManager.queueOperation(operation)
        return operation
    }

    @MainActor
    @discardableResult
    static func update(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        fatalError("Not supported")
    }

    @MainActor
    @discardableResult
    static func repair(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        let operation: GameOperation = .init(game: game, type: .repair) { _ in
            if let url = URL(string: "goggalaxy://openGameView/\(game.id)") {
                NSWorkspace.shared.open(url)
            }
        }
        Game.operationManager.queueOperation(operation)
        return operation
    }

    static func fetchUpdateAvailability(for game: Game) throws -> Bool {
        return false // Managed by GOG
    }

    static func isFileVerificationRequired(for game: Game) throws -> Bool {
        return false // Managed by GOG
    }

    @MainActor
    static func importGame(_ game: Game, platform: Game.Platform, at location: URL) async throws {
        // Handled via scanLocalInstalledGames
    }

    // MARK: - Game Discovery & Library Sync
    static func scanLocalInstalledGames() -> [GOGGame] {
        var games: [GOGGame] = []
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser

        var searchDirs: [(URL, Game.Platform, URL?)] = [
            (home.appendingPathComponent("Library/Application Support/GOG.com/Galaxy/applications"), .macOS, nil),
            (home.appendingPathComponent("GOG Games"), .macOS, nil)
        ]

        if let containersDir = Wine.containersDirectory,
           let enumerator = fileManager.enumerator(at: containersDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsSubdirectoryDescendants]) {
            for case let containerURL as URL in enumerator {
                let candidates = [
                    containerURL.appendingPathComponent("drive_c/GOG Games"),
                    containerURL.appendingPathComponent("drive_c/Program Files (x86)/GOG Galaxy/Games"),
                    containerURL.appendingPathComponent("drive_c/Program Files/GOG Galaxy/Games")
                ]
                for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
                    searchDirs.append((candidate, .windows, containerURL))
                }
            }
        }

        for (dir, platform, containerURL) in searchDirs {
            guard let fileURLs = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey]) else { continue }
            for gameFolderURL in fileURLs {
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: gameFolderURL.path, isDirectory: &isDir), isDir.boolValue else { continue }
                
                var gameTitle = gameFolderURL.lastPathComponent
                var gameID = "\(gameTitle.lowercased().filter { $0.isLetter || $0.isNumber })"
                
                if let infoFiles = try? fileManager.contentsOfDirectory(at: gameFolderURL, includingPropertiesForKeys: nil) {
                    for infoURL in infoFiles where infoURL.lastPathComponent.hasPrefix("goggame-") && infoURL.pathExtension == "info" {
                        if let infoData = try? Data(contentsOf: infoURL),
                           let infoJSON = try? JSONSerialization.jsonObject(with: infoData) as? [String: Any] {
                            if let name = infoJSON["name"] as? String { gameTitle = name }
                            if let idVal = infoJSON["gameId"] as? String { gameID = idVal }
                        }
                    }
                }

                guard !gameTitle.isEmpty, !gameID.isEmpty else { continue }

                let game = GOGGame(
                    id: gameID,
                    title: gameTitle,
                    installationState: .installed(location: gameFolderURL, platform: platform),
                    containerURL: containerURL
                )
                games.append(game)
            }
        }
        return games
    }

    static func fetchOwnedGames() async -> [GOGGame] {
        var games: [GOGGame] = []
        let token = StorefrontAccountManager.shared.gogAccessToken

        // 1. Fetch filtered products list with Bearer token
        if !token.isEmpty,
           let url = URL(string: "https://embed.gog.com/account/getFilteredProducts?mediaType=1&page=1") {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if let (data, response) = try? await URLSession.shared.data(for: request),
               let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let products = json["products"] as? [[String: Any]] {
                for item in products {
                    let gameID = "\(item["id"] ?? "")"
                    let title = item["title"] as? String ?? "GOG Game \(gameID)"
                    if !gameID.isEmpty {
                        let game = GOGGame(
                            id: gameID,
                            title: title,
                            installationState: .uninstalled
                        )
                        if let imgStr = item["image"] as? String {
                            let fullStr = imgStr.hasPrefix("http") ? imgStr : "https:\(imgStr)"
                            game._verticalImageURL = URL(string: fullStr)
                        }
                        games.append(game)
                    }
                }
                if !games.isEmpty {
                    return games
                }
            }
        }

        // 2. Fallback: User owned games IDs list
        guard let url = URL(string: "https://embed.gog.com/user/data/games") else { return [] }
        var request = URLRequest(url: url)
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ownedIDs = json["owned"] as? [Int] else {
            return []
        }

        for id in ownedIDs {
            let gameID = "\(id)"
            let game = GOGGame(
                id: gameID,
                title: "GOG Game #\(gameID)",
                installationState: .uninstalled
            )
            games.append(game)
        }
        return games
    }
}
