//
//  SteamGame.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 15/11/2025.
//

// Copyright © 2023-2025 vapidinfinity

// haha you thought

import Foundation
import AppKit

class SteamGame: Game, @unchecked Sendable {
    override var storefront: Game.Storefront? { .steam }

    override init(id: String = UUID().uuidString,
                  title: String,
                  installationState: InstallationState,
                  containerURL: URL? = nil) {
        super.init(id: id,
                   title: title,
                   installationState: installationState,
                   containerURL: containerURL)
    }

    required init(from decoder: any Decoder) throws {
        // super.init(from:) handles all decoding including subclass routing
        // say 'thank you, super.init❤️'
        try super.init(from: decoder)
    }

    override func _checkIfGameIsRunning(location: URL, platform: Platform) -> Bool {
        return false // Stub
    }
    
    nonisolated override func _launch() async throws {
        try await SteamGameManager.launch(game: self)
    }
    
    nonisolated override func _update() async throws {
        try await SteamGameManager.update(game: self, qualityOfService: .default)
    }
    
    nonisolated override func _move(from currentLocation: URL,
                                    to newLocation: URL) async throws {
        try await SteamGameManager.move(game: self, to: newLocation)
    }
    
    nonisolated override func _verifyInstallation() async throws {
        try await SteamGameManager.repair(game: self, qualityOfService: .default)
    }
}

class GOGGame: Game, @unchecked Sendable {
    override var storefront: Game.Storefront? { .gog }

    override init(id: String = UUID().uuidString,
                  title: String,
                  installationState: InstallationState,
                  containerURL: URL? = nil) {
        super.init(id: id,
                   title: title,
                   installationState: installationState,
                   containerURL: containerURL)
    }

    required init(from decoder: any Decoder) throws {
        try super.init(from: decoder)
    }

    override func _checkIfGameIsRunning(location: URL, platform: Platform) -> Bool {
        return false // Stub
    }
    
    nonisolated override func _launch() async throws {
        try await GOGGameManager.launch(game: self)
    }
    
    nonisolated override func _update() async throws {
        try await GOGGameManager.update(game: self, qualityOfService: .default)
    }
    
    nonisolated override func _move(from currentLocation: URL,
                                    to newLocation: URL) async throws {
        try await GOGGameManager.move(game: self, to: newLocation)
    }
    
    nonisolated override func _verifyInstallation() async throws {
        try await GOGGameManager.repair(game: self, qualityOfService: .default)
    }
}

class EAGame: Game, @unchecked Sendable {
    override var storefront: Game.Storefront? { .electronicArts }

    override init(id: String = UUID().uuidString,
                  title: String,
                  installationState: InstallationState,
                  containerURL: URL? = nil) {
        super.init(id: id,
                   title: title,
                   installationState: installationState,
                   containerURL: containerURL)
    }

    required init(from decoder: any Decoder) throws {
        try super.init(from: decoder)
    }

    override func _checkIfGameIsRunning(location: URL, platform: Platform) -> Bool {
        return false // Stub
    }
    
    nonisolated override func _launch() async throws {
        try await EAGameManager.launch(game: self)
    }
    
    nonisolated override func _update() async throws {
        try await EAGameManager.update(game: self, qualityOfService: .default)
    }
    
    nonisolated override func _move(from currentLocation: URL,
                                    to newLocation: URL) async throws {
        try await EAGameManager.move(game: self, to: newLocation)
    }
    
    nonisolated override func _verifyInstallation() async throws {
        try await EAGameManager.repair(game: self, qualityOfService: .default)
    }
}
