//
//  BundleIconView.swift
//  WinGame
//
//  Created by Josh on 10/23/24.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI

public struct BundleIconView: View {
    private let bundleIconName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconName") as? String

    public var body: some View {
        if let icon = (bundleIconName.flatMap { NSImage(named: $0) })
            ?? NSImage(named: "WinGameLogo")
            ?? NSImage(named: "AppIcon")
            ?? NSApplication.shared.applicationIconImage {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "gamecontroller.fill")
                .resizable()
                .scaledToFit()
        }
    }
}

#Preview {
    BundleIconView()
}
