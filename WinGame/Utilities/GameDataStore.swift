//
//  GameDataStore.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 2/12/2025.
//

// Copyright © 2023-2026 vapidinfinity

import Foundation
import Combine
import OSLog

// TODO: eventually, migrate to SwiftData.
@Observable @MainActor final class GameDataStore {
    static let shared: GameDataStore = .init()
    let log: Logger = .custom(category: "GameDataStore")
    
    private let gamesObserver: CodableUserDefaultsObserver<[AnyGame]>
    private var isUpdatingFromObserver = false
    
    var library: Set<Game> = .init() {
        didSet {
            guard !isUpdatingFromObserver else { return }
            do { try UserDefaults.standard.encodeAndSet(library.map({ AnyGame($0) }), forKey: "games") } catch {}
        }
    }

    @MainActor private init() {
        // initialise observer
        gamesObserver = .init(key: "games",
                              defaultValue: [])
        
        // load library on initialisation
        library = Set(gamesObserver.value.map({ $0.base }))
        
        // observe external changes
        gamesObserver.$value
            .sink { [weak self] newGames in
                guard let self else { return }
                let newLibrary = Set(newGames.map({ $0.base }))
                
                guard newLibrary != self.library else { return }
                self.log.debug("Games key changed in UserDefaults, updating library")
                
                self.isUpdatingFromObserver = true
                defer { self.isUpdatingFromObserver = false }
                self.library = newLibrary
            }
            .store(in: &cancellables)
    }
    
    @ObservationIgnored
    private var cancellables: Set<AnyCancellable> = .init()

    var recent: Game? {
        guard !library.allSatisfy({ $0.lastLaunched == nil }) else { return nil }

        return library.max {
            $0.lastLaunched ?? .distantPast < $1.lastLaunched ?? .distantPast
        }
    }

    func refreshFromStorefronts(_ storefronts: Game.Storefront...) async throws {
        GameListViewModel.shared.isUpdatingLibrary = true
        defer {
            GameListViewModel.shared.isUpdatingLibrary = false
        }
        
        // if variadics are empty, default to all cases
        let storefronts = storefronts.isEmpty ? Game.Storefront.allCases : storefronts as [Game.Storefront]
        
        // MARK: - Epic Games
        if storefronts.contains(.epicGames) {
            do {
                if Legendary.isSignedIn {
                    await Legendary.updateMetadata(forced: false)
                    let installables = (try? Legendary.getInstallableGames()) ?? []
                    let installed = (try? Legendary.getInstalledGames()) ?? []
                    
                    // Add uninstalled games
                    for game in installables where !installed.contains(where: { $0.id == game.id }) {
                        if let existing = library.first(where: { $0.id == game.id && $0.storefront == .epicGames }) {
                            if case .uninstalled = existing.installationState {
                                library.update(with: game)
                            }
                        } else {
                            library.update(with: game)
                        }
                    }
                    
                    // Add/merge installed games
                    for fetchedGame in installed {
                        if let existing = library.first(where: { $0.id == fetchedGame.id && $0.storefront == .epicGames }) {
                            try? existing.merge(with: fetchedGame, requiring: .identicalIgnoredKeys)
                            library.update(with: existing)
                        } else {
                            library.update(with: fetchedGame)
                        }
                    }
                }
            } catch {
                log.error("Unable to refresh game data from Epic Games: \(error.localizedDescription)")
            }
        }
        
        // MARK: - Steam
        if storefronts.contains(.steam) {
            let localSteamGames = SteamGameManager.scanLocalInstalledGames()
            for game in localSteamGames {
                if let existing = library.first(where: { $0.id == game.id && $0.storefront == .steam }) {
                    try? existing.merge(with: game, requiring: .identicalIgnoredKeys)
                    library.update(with: existing)
                } else {
                    library.update(with: game)
                }
            }

            let steamID = StorefrontAccountManager.shared.steamID
            if !steamID.isEmpty {
                let ownedGames = await SteamGameManager.fetchOwnedGames(steamID: steamID)
                for game in ownedGames {
                    if let existing = library.first(where: { $0.id == game.id && $0.storefront == .steam }) {
                        // Keep existing state if already installed
                        if case .uninstalled = existing.installationState {
                            library.update(with: game)
                        }
                    } else {
                        library.update(with: game)
                    }
                }
            }
        }

        // MARK: - GOG
        if storefronts.contains(.gog) {
            let localGOGGames = GOGGameManager.scanLocalInstalledGames()
            for game in localGOGGames {
                if let existing = library.first(where: { $0.id == game.id && $0.storefront == .gog }) {
                    try? existing.merge(with: game, requiring: .identicalIgnoredKeys)
                    library.update(with: existing)
                } else {
                    library.update(with: game)
                }
            }

            if StorefrontAccountManager.shared.isGOGConnected {
                let ownedGames = await GOGGameManager.fetchOwnedGames()
                for game in ownedGames {
                    if let existing = library.first(where: { $0.id == game.id && $0.storefront == .gog }) {
                        if case .uninstalled = existing.installationState {
                            library.update(with: game)
                        }
                    } else {
                        library.update(with: game)
                    }
                }
            }
        }

        // MARK: - Electronic Arts (EA)
        if storefronts.contains(.electronicArts) {
            let localEAGames = EAGameManager.scanLocalInstalledGames()
            for game in localEAGames {
                if let existing = library.first(where: { $0.id == game.id && $0.storefront == .electronicArts }) {
                    try? existing.merge(with: game, requiring: .identicalIgnoredKeys)
                    library.update(with: existing)
                } else {
                    library.update(with: game)
                }
            }

            if StorefrontAccountManager.shared.isEAConnected {
                let ownedGames = await EAGameManager.fetchLibraryGames()
                for game in ownedGames {
                    if let existing = library.first(where: { $0.id == game.id && $0.storefront == .electronicArts }) {
                        if case .uninstalled = existing.installationState {
                            library.update(with: game)
                        }
                    } else {
                        library.update(with: game)
                    }
                }
            }
        }
    }
}
