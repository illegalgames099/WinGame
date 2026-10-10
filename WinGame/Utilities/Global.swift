//
//  Global.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 11/10/2023.
//

// Copyright © 2023-2025 vapidinfinity

import Foundation
import SwiftUI
import UserNotifications

public struct RichPresence { public var details: String = ""; public var state: String = ""; public struct Timestamps { public var start: Date = .now; public var end: Date = .now; public init() {} }; public struct Assets { public var largeImage: String = ""; public var largeText: String = ""; public var smallImage: String = ""; public var smallText: String = ""; public init() {} }; public var timestamps = Timestamps(); public var assets = Assets(); public init() {} }
public class SwordRPC { public var isDiscordInstalled: Bool = false; public init(appId: String) {}; public func setPresence(_ presence: RichPresence) {}; public func connect() -> Bool { return false }; public func disconnect() {} }
nonisolated(unsafe) let discordRPC: SwordRPC = .init(appId: "1191343317749870712")

var appVersion: SemanticVersion? {
    guard let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
          let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
          let appVersion: SemanticVersion = .init("\(shortVersion)+\(bundleVersion)") else {
        return nil
    }

    return appVersion
}

import SwiftUI
public struct ColorfulView: View {
    @Binding var color: [Color]
    @Binding var speed: Double
    @Binding var noise: Double
    public init(color: Binding<[Color]>, speed: Binding<Double> = .constant(1), noise: Binding<Double> = .constant(1)) {
        self._color = color
        self._speed = speed
        self._noise = noise
    }
    public var body: some View {
        Color.clear
    }
}

extension View {
    @ViewBuilder
    public func shimmering(active: Bool = true, animation: Animation = .default, gradient: Gradient = Gradient(colors: [.black, .white]), bandSize: CGFloat = 1) -> some View {
        self
    }
}

extension View {
    @ViewBuilder
    public func winGlassEffect() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect()
        } else {
            self.blur(radius: 18)
        }
    }
}

public struct JSON {
    var raw: [String: Any]?
    public init(data: Data) throws {
        self.raw = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
    public subscript(key: String) -> JSON {
        return JSON(dictionary: raw?[key] as? [String: Any], stringValue: raw?[key] as? String)
    }
    var dictionary: [String: Any]?
    var stringValue: String?
    public var string: String? { return stringValue }
    init(dictionary: [String: Any]? = nil, stringValue: String? = nil) {
        self.dictionary = dictionary
        self.stringValue = stringValue
    }
}
