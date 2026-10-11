//
//  SteamGameManager.swift
//  WinGame
//

import Foundation
import AppKit
import OSLog

struct SteamGameManager: StorefrontGameManager {
    static var log: Logger { .custom(category: "SteamGameManager") }

    @MainActor
    @discardableResult
    static func launch(game: Game) async throws -> GameOperation {
        guard case .steam = game.storefront,
              let castGame = game as? SteamGame else { throw CocoaError(.coderInvalidValue) }
        
        let targetAppID: String = {
            if castGame.id.allSatisfy({ $0.isNumber }) {
                return castGame.id
            }
            let cachedTitles = (UserDefaults.standard.dictionary(forKey: "steam_resolved_titles") as? [String: String]) ?? [:]
            for (id, title) in cachedTitles {
                if title.caseInsensitiveCompare(castGame.title) == .orderedSame {
                    return id
                }
            }
            return castGame.id
        }()

        let operation: GameOperation = .init(game: castGame, type: .launch) { _ in
            guard let url = URL(string: "steam://rungameid/\(targetAppID)") else {
                throw CocoaError(.serviceApplicationLaunchFailed)
            }
            NSWorkspace.shared.open(url)
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
        guard case .steam = game.storefront,
              let castGame = game as? SteamGame else { throw CocoaError(.coderInvalidValue) }
        
        let targetAppID: String = {
            if castGame.id.allSatisfy({ $0.isNumber }) {
                return castGame.id
            }
            let cachedTitles = (UserDefaults.standard.dictionary(forKey: "steam_resolved_titles") as? [String: String]) ?? [:]
            for (id, title) in cachedTitles {
                if title.caseInsensitiveCompare(castGame.title) == .orderedSame {
                    return id
                }
            }
            return castGame.id
        }()

        let operation: GameOperation = .init(game: castGame, type: .uninstall) { _ in
            guard let url = URL(string: "steam://uninstall/\(targetAppID)") else {
                throw CocoaError(.serviceApplicationLaunchFailed)
            }
            NSWorkspace.shared.open(url)
        }
        Game.operationManager.queueOperation(operation)
        return operation
    }

    @MainActor
    @discardableResult
    static func install(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        guard case .steam = game.storefront,
              let castGame = game as? SteamGame else { throw CocoaError(.coderInvalidValue) }
        
        let targetAppID: String = {
            if castGame.id.allSatisfy({ $0.isNumber }) {
                return castGame.id
            }
            let cachedTitles = (UserDefaults.standard.dictionary(forKey: "steam_resolved_titles") as? [String: String]) ?? [:]
            for (id, title) in cachedTitles {
                if title.caseInsensitiveCompare(castGame.title) == .orderedSame {
                    return id
                }
            }
            return castGame.id
        }()

        let operation: GameOperation = .init(game: castGame, type: .install) { _ in
            guard let url = URL(string: "steam://install/\(targetAppID)") else {
                throw CocoaError(.serviceApplicationLaunchFailed)
            }
            if !NSWorkspace.shared.open(url) {
                if let steamApp = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.valvesoftware.steam") {
                    NSWorkspace.shared.open([url], withApplicationAt: steamApp, configuration: NSWorkspace.OpenConfiguration())
                }
            }
        }
        Game.operationManager.queueOperation(operation)
        return operation
    }

    @MainActor
    @discardableResult
    static func update(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        // Handled by Steam Automatically
        fatalError("Not supported")
    }

    @MainActor
    @discardableResult
    static func repair(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        let operation: GameOperation = .init(game: game, type: .repair) { _ in
            guard let url = URL(string: "steam://validate/\(game.id)") else {
                throw CocoaError(.serviceApplicationLaunchFailed)
            }
            NSWorkspace.shared.open(url)
        }
        Game.operationManager.queueOperation(operation)
        return operation
    }

    static func fetchUpdateAvailability(for game: Game) throws -> Bool {
        return false // Managed by Steam
    }

    static func isFileVerificationRequired(for game: Game) throws -> Bool {
        return false // Managed by steam
    }

    @MainActor
    static func importGame(_ game: Game, platform: Game.Platform, at location: URL) async throws {
        // Handled via scanLocalInstalledGames
    }

    // MARK: - Game Discovery & Library Sync
    static func scanLocalInstalledGames() -> [SteamGame] {
        var games: [SteamGame] = []
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser

        var searchDirs: [(URL, Game.Platform, URL?)] = [
            (home.appendingPathComponent("Library/Application Support/Steam/steamapps"), .macOS, nil)
        ]

        if let containersDir = Wine.containersDirectory,
           let enumerator = fileManager.enumerator(at: containersDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsSubdirectoryDescendants]) {
            for case let containerURL as URL in enumerator {
                let p1 = containerURL.appendingPathComponent("drive_c/Program Files (x86)/Steam/steamapps")
                let p2 = containerURL.appendingPathComponent("drive_c/Steam/steamapps")
                if fileManager.fileExists(atPath: p1.path) {
                    searchDirs.append((p1, .windows, containerURL))
                } else if fileManager.fileExists(atPath: p2.path) {
                    searchDirs.append((p2, .windows, containerURL))
                }
            }
        }

        for (dir, platform, containerURL) in searchDirs {
            guard let fileURLs = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for fileURL in fileURLs where fileURL.lastPathComponent.hasPrefix("appmanifest_") && fileURL.pathExtension == "acf" {
                guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
                var appid = ""
                var name = ""
                var installdir = ""

                let lines = content.components(separatedBy: .newlines)
                for line in lines {
                    let parts = line.components(separatedBy: "\"").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    if parts.count >= 2 {
                        let key = parts[0].lowercased()
                        let val = parts[1]
                        if key == "appid" {
                            appid = val
                        } else if key == "name" {
                            name = val
                        } else if key == "installdir" {
                            installdir = val
                        }
                    }
                }

                guard !appid.isEmpty, !name.isEmpty, appid != "228980" else { continue }

                let commonDir = dir.appendingPathComponent("common").appendingPathComponent(installdir)
                let installLocation = fileManager.fileExists(atPath: commonDir.path) ? commonDir : dir

                let game = SteamGame(
                    id: appid,
                    title: name,
                    installationState: .installed(location: installLocation, platform: platform),
                    containerURL: containerURL
                )
                games.append(game)
            }
        }
        return games
    }

    static func fetchOwnedGames(steamID: String) async -> [SteamGame] {
        guard !steamID.isEmpty else { return [] }
        let urlString = steamID.allSatisfy(\.isNumber)
            ? "https://steamcommunity.com/profiles/\(steamID)/games?xml=1"
            : "https://steamcommunity.com/id/\(steamID)/games?xml=1"
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let xml = String(data: data, encoding: .utf8) else {
            return []
        }

        var games: [SteamGame] = []
        let gameTokens = xml.components(separatedBy: "<game>")
        for token in gameTokens.dropFirst() {
            guard let appidRange = token.range(of: "<appID>"),
                  let appidEnd = token.range(of: "</appID>"),
                  let nameRange = token.range(of: "<name>"),
                  let nameEnd = token.range(of: "</name>") else {
                continue
            }
            let appid = String(token[appidRange.upperBound..<appidEnd.lowerBound])
            let name = String(token[nameRange.upperBound..<nameEnd.lowerBound])
                .replacingOccurrences(of: "<![CDATA[", with: "")
                .replacingOccurrences(of: "]]>", with: "")

            if !appid.isEmpty && !name.isEmpty {
                games.append(SteamGame(id: appid, title: name, installationState: .uninstalled))
            }
        }
        return games
    }
}
