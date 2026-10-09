//
//  SwordRPC.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 13/1/2025.
//

// Copyright © 2023-2025 vapidinfinity

import Foundation
import SwordRPC
import AppKit

extension SwordRPC {
    var isDiscordInstalled: Bool {
        let discordURLScheme: URL = .init(string: "discord://")!
        return NSWorkspace.shared.urlForApplication(toOpen: discordURLScheme) != nil
    }
}
