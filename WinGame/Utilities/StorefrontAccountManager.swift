//
//  StorefrontAccountManager.swift
//  WinGame
//
//  Created for WinGame multi-storefront account management.
//

// Copyright © 2023-2026 vapidinfinity

import Foundation
import Combine
import OSLog

@Observable
final class StorefrontAccountManager: @unchecked Sendable {
    static let shared: StorefrontAccountManager = .init()
    private let log: Logger = .custom(category: "StorefrontAccountManager")

    // MARK: - Steam State
    var steamUsername: String = ""
    var steamID: String = ""
    var steamPlaytimeHours: Double = 0.0
    var steamFriendsCount: (online: Int, total: Int) = (0, 0)
    var steamIsOnline: Bool = true

    var isSteamConnected: Bool {
        !steamUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - EA State
    var eaUsername: String = ""
    var eaID: String = ""
    var eaAuthCode: String = ""

    var isEAConnected: Bool {
        !eaUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - GOG State
    var gogUsername: String = ""
    var gogID: String = ""
    var gogAccessToken: String = ""
    var gogRefreshToken: String = ""

    var isGOGConnected: Bool {
        !gogUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Epic Games State
    var manualEpicUsername: String = ""

    var epicUsername: String? {
        if let user = try? Legendary.retrieveUser(), !user.isEmpty {
            return user
        }
        return manualEpicUsername.isEmpty ? nil : manualEpicUsername
    }

    var isEpicConnected: Bool {
        epicUsername != nil
    }

    init() {
        loadSavedAccounts()
        autoDetectLocalAccounts()
    }

    // MARK: - Persistence
    func loadSavedAccounts() {
        let defaults = UserDefaults.standard
        steamUsername = defaults.string(forKey: "storefront_steam_username") ?? ""
        steamID = defaults.string(forKey: "storefront_steam_id") ?? ""
        steamPlaytimeHours = defaults.double(forKey: "storefront_steam_playtime")

        eaUsername = defaults.string(forKey: "storefront_ea_username") ?? ""
        eaID = defaults.string(forKey: "storefront_ea_id") ?? ""
        eaAuthCode = defaults.string(forKey: "storefront_ea_auth_code") ?? ""

        gogUsername = defaults.string(forKey: "storefront_gog_username") ?? ""
        gogID = defaults.string(forKey: "storefront_gog_id") ?? ""
        gogAccessToken = defaults.string(forKey: "storefront_gog_access_token") ?? ""
        gogRefreshToken = defaults.string(forKey: "storefront_gog_refresh_token") ?? ""

        manualEpicUsername = defaults.string(forKey: "storefront_epic_username") ?? ""
    }

    func saveSteam(username: String, id: String, playtime: Double = 0.0) {
        steamUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        steamID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        if playtime > 0 {
            steamPlaytimeHours = playtime
        }
        UserDefaults.standard.set(steamUsername, forKey: "storefront_steam_username")
        UserDefaults.standard.set(steamID, forKey: "storefront_steam_id")
        UserDefaults.standard.set(steamPlaytimeHours, forKey: "storefront_steam_playtime")
    }

    func disconnectSteam() {
        steamUsername = ""
        steamID = ""
        steamPlaytimeHours = 0.0
        UserDefaults.standard.removeObject(forKey: "storefront_steam_username")
        UserDefaults.standard.removeObject(forKey: "storefront_steam_id")
        UserDefaults.standard.removeObject(forKey: "storefront_steam_playtime")
    }

    func saveEA(username: String, id: String, authCode: String = "") {
        eaUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        eaID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        if !authCode.isEmpty {
            eaAuthCode = authCode
            UserDefaults.standard.set(eaAuthCode, forKey: "storefront_ea_auth_code")
        }
        UserDefaults.standard.set(eaUsername, forKey: "storefront_ea_username")
        UserDefaults.standard.set(eaID, forKey: "storefront_ea_id")
    }

    func disconnectEA() {
        eaUsername = ""
        eaID = ""
        eaAuthCode = ""
        UserDefaults.standard.removeObject(forKey: "storefront_ea_username")
        UserDefaults.standard.removeObject(forKey: "storefront_ea_id")
        UserDefaults.standard.removeObject(forKey: "storefront_ea_auth_code")
    }

    func saveGOG(username: String, id: String, accessToken: String = "", refreshToken: String = "") {
        gogUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        gogID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        if !accessToken.isEmpty {
            gogAccessToken = accessToken
            UserDefaults.standard.set(gogAccessToken, forKey: "storefront_gog_access_token")
        }
        if !refreshToken.isEmpty {
            gogRefreshToken = refreshToken
            UserDefaults.standard.set(gogRefreshToken, forKey: "storefront_gog_refresh_token")
        }
        UserDefaults.standard.set(gogUsername, forKey: "storefront_gog_username")
        UserDefaults.standard.set(gogID, forKey: "storefront_gog_id")
    }

    func disconnectGOG() {
        gogUsername = ""
        gogID = ""
        gogAccessToken = ""
        gogRefreshToken = ""
        UserDefaults.standard.removeObject(forKey: "storefront_gog_username")
        UserDefaults.standard.removeObject(forKey: "storefront_gog_id")
        UserDefaults.standard.removeObject(forKey: "storefront_gog_access_token")
        UserDefaults.standard.removeObject(forKey: "storefront_gog_refresh_token")
    }

    func saveEpic(username: String) {
        manualEpicUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(manualEpicUsername, forKey: "storefront_epic_username")
    }

    func disconnectEpic() {
        manualEpicUsername = ""
        UserDefaults.standard.removeObject(forKey: "storefront_epic_username")
        Task {
            try? await Legendary.signOut()
        }
    }

    // MARK: - Auto-Detection of Local Accounts
    func autoDetectLocalAccounts() {
        if !isSteamConnected {
            detectSteamFromLocalInstall()
        }
        if !isEAConnected {
            detectEAFromLocalInstall()
        }
        if !isGOGConnected {
            detectGOGFromLocalInstall()
        }
    }

    private func detectSteamFromLocalInstall() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let loginUsersPath = homeDir.appendingPathComponent("Library/Application Support/Steam/config/loginusers.vdf")

        guard FileManager.default.fileExists(atPath: loginUsersPath.path),
              let content = try? String(contentsOf: loginUsersPath, encoding: .utf8) else {
            return
        }

        // Parse VDF format for PersonaName, AccountName, and SteamID
        let lines = content.components(separatedBy: .newlines)
        var currentSteamID: String = ""
        var mostRecentID: String = ""
        var userDict: [String: [String: String]] = [:]

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("\"7656") {
                currentSteamID = line.replacingOccurrences(of: "\"", with: "")
                if userDict[currentSteamID] == nil {
                    userDict[currentSteamID] = [:]
                }
            } else if !currentSteamID.isEmpty {
                let parts = line.components(separatedBy: "\"")
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                if parts.count >= 2 {
                    let key = parts[0]
                    let val = parts[1]
                    userDict[currentSteamID]?[key] = val
                    if key.lowercased() == "mostrecent", val == "1" {
                        mostRecentID = currentSteamID
                    }
                }
            }
        }

        let targetID = !mostRecentID.isEmpty ? mostRecentID : (userDict.keys.first ?? "")
        if let targetUser = userDict[targetID] {
            let persona = targetUser["PersonaName"] ?? targetUser["AccountName"] ?? ""
            if !persona.isEmpty {
                log.info("Auto-detected local Steam account: \(persona) (\(targetID))")
                saveSteam(username: persona, id: targetID, playtime: 0.0)
            }
        }
    }

    private func detectEAFromLocalInstall() {
        // Detect local Electronic Arts / Origin preferences
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let originConfig = homeDir.appendingPathComponent("Library/Application Support/Origin/local.xml")
        if FileManager.default.fileExists(atPath: originConfig.path),
           let content = try? String(contentsOf: originConfig, encoding: .utf8) {
            if let userMatch = content.range(of: "user.*", options: .regularExpression) {
                let found = String(content[userMatch])
                log.debug("Found local Origin config entry: \(found)")
            }
        }
    }

    private func detectGOGFromLocalInstall() {
        // Detect local GOG Galaxy database or preferences
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let gogConfig = homeDir.appendingPathComponent("Library/Application Support/GOG.com/Galaxy/Configuration/config.json")
        if FileManager.default.fileExists(atPath: gogConfig.path),
           let data = try? Data(contentsOf: gogConfig),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let user = json["username"] as? String {
            log.info("Auto-detected local GOG account: \(user)")
            saveGOG(username: user, id: json["userId"] as? String ?? "")
        }
    }
}
