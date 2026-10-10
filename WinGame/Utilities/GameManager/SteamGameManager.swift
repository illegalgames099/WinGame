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
        
        let operation: GameOperation = .init(game: castGame, type: .launch) { _ in
            guard let url = URL(string: "steam://rungameid/\(castGame.id)") else {
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
        
        let operation: GameOperation = .init(game: castGame, type: .uninstall) { _ in
            guard let url = URL(string: "steam://uninstall/\(castGame.id)") else {
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
        
        let operation: GameOperation = .init(game: castGame, type: .install) { _ in
            guard let url = URL(string: "steam://install/\(castGame.id)") else {
                throw CocoaError(.serviceApplicationLaunchFailed)
            }
            NSWorkspace.shared.open(url)
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
        // In the future this can parse .acf files in steamapps directory
        fatalError("Not implemented")
    }
}
