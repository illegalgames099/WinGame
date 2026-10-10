//
//  SemanticVersion.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 11/12/24.
//

// Copyright © 2023-2025 vapidinfinity

import Foundation

public struct SemanticVersion: Codable, Comparable, Hashable, CustomStringConvertible, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let preRelease: String
    public let build: String

    public init(_ major: Int, _ minor: Int, _ patch: Int, _ preRelease: String = "", _ build: String = "") {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.preRelease = preRelease
        self.build = build
    }
    
    public init?(_ string: String) {
        let parts = string.split(separator: "+", maxSplits: 1)
        let verParts = parts[0].split(separator: "-", maxSplits: 1)
        let nums = verParts[0].split(separator: ".")
        guard nums.count >= 1, let maj = Int(nums[0]) else { return nil }
        self.major = maj
        self.minor = nums.count > 1 ? Int(nums[1]) ?? 0 : 0
        self.patch = nums.count > 2 ? Int(nums[2]) ?? 0 : 0
        self.preRelease = verParts.count > 1 ? String(verParts[1]) : ""
        self.build = parts.count > 1 ? String(parts[1]) : ""
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        return false // ignoring prerelease and build to simplify
    }
    
    public static var macOSVersion: Self? {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return .init(version.majorVersion, version.minorVersion, version.patchVersion)
    }

    public var prettyString: String {
        var versionString = "\(major).\(minor).\(patch)"
        if !preRelease.isEmpty {
            versionString += "-\(preRelease)"
        }
        if !build.isEmpty {
            versionString += " (\(build))"
        }
        return versionString
    }

    public init?(fromRelaxedString string: String) {
        guard let match = string.wholeMatch(of: relaxedSemanticVersionRegex) else { return nil }
        guard
            let major = Int(match.major),
            let minor = Int(match.minor)
        else { return nil }
        self = .init(major, minor, 0,
                     match.prerelease.map(String.init) ?? "",
                     match.buildmetadata.map(String.init) ?? "")
    }

    public var description: String {
        let pre = preRelease.isEmpty ? "" : "-" + preRelease
        let bld = build.isEmpty ? "" : "+" + build
        return "\(major).\(minor)\(pre)\(bld)"
    }
}

nonisolated(unsafe) let relaxedSemanticVersionRegex = #/
    ^
    v?                              # SPI extension: allow leading 'v'
    (?<major>0|[1-9]\d*)
    \.
    (?<minor>0|[1-9]\d*)
    (?:-
        (?<prerelease>
          (?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)
          (?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*
        )
    )?
    (?:\+
      (?<buildmetadata>[0-9a-zA-Z-]+
        (?:\.[0-9a-zA-Z-]+)
      *)
    )?
    $
    /#
