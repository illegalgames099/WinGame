//
//  SteamGame.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 15/11/2025.
//

// Copyright © 2023-2025 vapidinfinity

// haha you thought

import Foundation

@available(*, deprecated, message: "Soon...")
class SteamGame: Game {
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
}
import Foundation

@available(*, deprecated, message: "Soon...")
class GOGGame: Game {
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
}
import Foundation

@available(*, deprecated, message: "Soon...")
class EAGame: Game {
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
}
