//
//  EAGameManager.swift
//  WinGame
//
//  Created for WinGame EA (Electronic Arts) Integration.
//

// Copyright © 2023-2026 vapidinfinity

import Foundation
import AppKit
import OSLog

struct EAGameManager: StorefrontGameManager {
    static var log: Logger { .custom(category: "EAGameManager") }

    @MainActor
    @discardableResult
    static func launch(game: Game) async throws -> GameOperation {
        guard case .electronicArts = game.storefront,
              let castGame = game as? EAGame else { throw CocoaError(.coderInvalidValue) }
        
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
            } else if let url = URL(string: "origin://launchgame/\(castGame.id)") {
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
        guard case .electronicArts = game.storefront,
              let castGame = game as? EAGame else { throw CocoaError(.coderInvalidValue) }
        
        let operation: GameOperation = .init(game: castGame, type: .uninstall) { _ in
            if let url = URL(string: "origin://launchgame/\(castGame.id)") {
                NSWorkspace.shared.open(url)
            }
        }
        Game.operationManager.queueOperation(operation)
        return operation
    }

    @MainActor
    @discardableResult
    static func install(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        guard case .electronicArts = game.storefront,
              let castGame = game as? EAGame else { throw CocoaError(.coderInvalidValue) }
        
        let operation: GameOperation = .init(game: castGame, type: .install) { _ in
            if let url = URL(string: "origin://launchgame/\(castGame.id)") {
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
            if let url = URL(string: "origin://launchgame/\(game.id)") {
                NSWorkspace.shared.open(url)
            }
        }
        Game.operationManager.queueOperation(operation)
        return operation
    }

    static func fetchUpdateAvailability(for game: Game) throws -> Bool {
        return false // Managed by EA
    }

    static func isFileVerificationRequired(for game: Game) throws -> Bool {
        return false // Managed by EA
    }

    @MainActor
    static func importGame(_ game: Game, platform: Game.Platform, at location: URL) async throws {
        // Handled via scanLocalInstalledGames
    }

    // MARK: - Game Discovery & Library Sync
    static func scanLocalInstalledGames() -> [EAGame] {
        var games: [EAGame] = []
        let fileManager = FileManager.default

        var searchDirs: [(URL, Game.Platform, URL?)] = []

        if let containersDir = Wine.containersDirectory,
           let enumerator = fileManager.enumerator(at: containersDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsSubdirectoryDescendants]) {
            for case let containerURL as URL in enumerator {
                let paths = [
                    containerURL.appendingPathComponent("drive_c/Program Files/EA Games"),
                    containerURL.appendingPathComponent("drive_c/Program Files (x86)/Origin Games"),
                    containerURL.appendingPathComponent("drive_c/Program Files/Electronic Arts")
                ]
                for candidatePath in paths where fileManager.fileExists(atPath: candidatePath.path) {
                    searchDirs.append((candidatePath, .windows, containerURL))
                }
            }
        }

        for (dir, platform, containerURL) in searchDirs {
            guard let fileURLs = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey]) else { continue }
            for gameFolderURL in fileURLs {
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: gameFolderURL.path, isDirectory: &isDir), isDir.boolValue else { continue }
                
                let gameTitle = gameFolderURL.lastPathComponent
                let gameID = "ea-\(gameTitle.lowercased().filter { $0.isLetter || $0.isNumber })"

                let game = EAGame(
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

    static func fetchLibraryGames() async -> [EAGame] {
        guard StorefrontAccountManager.shared.isEAConnected else { return [] }
        let defaults = UserDefaults.standard
        if let storedGames = defaults.stringArray(forKey: "ea_library_titles"), !storedGames.isEmpty {
            return storedGames.map { title in
                let safeID = "ea-\(title.lowercased().filter { $0.isLetter || $0.isNumber })"
                return EAGame(id: safeID, title: title, installationState: .uninstalled)
            }
        }
        return []
    }
}
