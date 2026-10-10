//
//  EAGameManager.swift
//  WinGame
//

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
        
        // Use generic origin/EA scheme if installed on macOS
        let operation: GameOperation = .init(game: castGame, type: .launch) { _ in
            guard let url = URL(string: "origin://launchgame/\(castGame.id)") else {
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
        fatalError("Not implemented")
    }

    @MainActor
    @discardableResult
    static func install(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        fatalError("Not implemented")
    }

    @MainActor
    @discardableResult
    static func update(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        fatalError("Not supported")
    }

    @MainActor
    @discardableResult
    static func repair(game: Game, qualityOfService: QualityOfService) async throws -> GameOperation {
        fatalError("Not implemented")
    }

    static func fetchUpdateAvailability(for game: Game) throws -> Bool {
        return false // Managed by EA
    }

    static func isFileVerificationRequired(for game: Game) throws -> Bool {
        return false // Managed by EA
    }

    @MainActor
    static func importGame(_ game: Game, platform: Game.Platform, at location: URL) async throws {
        fatalError("Not implemented")
    }
}
