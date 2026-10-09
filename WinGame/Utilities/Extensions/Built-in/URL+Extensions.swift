//
//  URL.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 28/1/2024.
//

// Copyright © 2023-2025 vapidinfinity

import Foundation

extension URL {
    public var prettyPath: String {
        return path(percentEncoded: false)
            .replacingOccurrences(of: Bundle.main.bundleIdentifier!, with: "(WinGame)")
            .replacingOccurrences(of: "/Users/\(NSUserName())", with: "~")
            .replacingOccurrences(of: "file://", with: "")
    }
}
