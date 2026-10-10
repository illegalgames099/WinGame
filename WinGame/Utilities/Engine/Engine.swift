//
//  Engine.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 24/10/2025.
//

// Copyright © 2023-2026 vapidinfinity

import Foundation
import OSLog
import AppKit

final class Engine {
    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "Engine"
    )
    
    static var releaseChannel: ReleaseChannel {
        get {
            UserDefaults.standard.register(defaults: ["engineChannel": ReleaseChannel.stable.rawValue])
            if let channelString = UserDefaults.standard.string(forKey: "engineChannel"),
               let channel: ReleaseChannel = .init(rawValue: channelString) {
                return channel
            }
            
            return .stable
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "engineChannel")
        }
    }
    
    static let directory = Bundle.appHome!.appending(path: "Engine")

    static var wineExecutableURL: URL {
        let candidates = [
            directory.appending(path: "wine/bin/wine64"),
            directory.appending(path: "Game Porting Toolkit.app/Contents/Resources/wine/bin/wine64"),
            directory.appending(path: "bin/wine64"),
            directory.appending(path: "wine/bin/wine"),
            directory.appending(path: "bin/wine")
        ]
        return candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) ?? directory.appending(path: "wine/bin/wine64")
    }

    static var isInstalled: Bool {
        let hasProperties = FileManager.default.fileExists(atPath: directory.appending(path: "Properties.plist").path)
        let hasWine = FileManager.default.fileExists(atPath: wineExecutableURL.path)
        return hasProperties || hasWine
    }
    
    static var installedVersion: SemanticVersion? {
        get async {
            let properties = try? await retrieveEngineProperties()
            return properties?.version
        }
    }
    
    static func retrieveUpdateCatalog() async throws -> UpdateCatalog {
        let catalogURL = URL(string: "https://dl.getwingame.app/engine/EngineUpdateStream.plist")!
        let (data, response) = try await URLSession.shared.data(from: catalogURL)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let decoder: PropertyListDecoder = .init()
        let catalog = try decoder.decode(UpdateCatalog.self, from: data)
        
        if catalog.version != UpdateCatalog.nativeVersion {
            log.warning("""
            UpdateCatalog was parsed, but its version does not match that of the currently implemented version.
            An app update may be necessary.
            """)
        }
        
        return catalog
    }
    
    static func retrieveEngineProperties() async throws -> EngineProperties {
        guard isInstalled else { throw NotInstalledError() }
        
        let properties = directory.appending(path: "Properties.plist")
        if FileManager.default.fileExists(atPath: properties.path),
           let data = try? Data(contentsOf: properties),
           let decoded = try? PropertyListDecoder().decode(EngineProperties.self, from: data) {
            return decoded
        }

        return EngineProperties(version: SemanticVersion(3, 0, 3))
    }
    
    static func getLatestCompatibleRelease(for channelName: ReleaseChannel = releaseChannel) async throws -> UpdateCatalog.Release {
        if let catalog = try? await retrieveUpdateCatalog(),
           let channel = catalog.channels[channelName],
           let latestCompatibleRelease = channel.latestCompatibleRelease {
            return latestCompatibleRelease
        }
        
        // Robust Fallback when primary update catalog server is unreachable: Game Porting Toolkit / Wine 64-bit release
        return UpdateCatalog.Release(
            version: SemanticVersion(3, 0, 3),
            releaseDate: Date(),
            downloadURL: "https://github.com/Gcenx/game-porting-toolkit/releases/download/Game-Porting-Toolkit-3.0-3/game-porting-toolkit-3.0-3.tar.xz",
            checksumURL: nil,
            size: 239200808,
            minimumMacOSVersion: SemanticVersion(14, 0, 0),
            minimumAppVersion: nil,
            releaseNotesURL: nil,
            critical: false,
            commitSHA: "gptk-3.0-3"
        )
    }
    
    static func checkIfUpdateAvailable(for channelName: ReleaseChannel = releaseChannel) async throws -> Bool {
        guard let latestRelease = try? await getLatestCompatibleRelease(for: channelName),
              let properties = try? await retrieveEngineProperties() else {
            return false
        }
        
        return latestRelease.version > properties.version
    }
    
    static func install() -> AsyncThrowingStream<InstallProgress, Error> {
        AsyncThrowingStream { continuation in
            Task(priority: .high) {
                do {
                    guard !isInstalled else { continuation.finish(); return } // silent exit
                    let release = try await getLatestCompatibleRelease()
                    
                    let task = URLSession.shared.downloadTask(with: URL(string: release.downloadURL)!) { file, response, error in
                        guard error == nil else { continuation.finish(throwing: error!); return }
                        if let httpResponse = response as? HTTPURLResponse,
                           !(200...299).contains(httpResponse.statusCode) {
                            continuation.finish(throwing: URLError(.badServerResponse)); return
                        }
                        guard let file else {
                            continuation.finish(throwing: CocoaError(.fileNoSuchFile)); return
                        }
                        
                        Task(priority: .userInitiated) {
                            let installationProgress: Progress = .init(totalUnitCount: 100)
                            
                            do {
                                // check for remnant/empty engine folder
                                if (try? FileManager.default.contentsOfDirectory(atPath: directory.path))?.isEmpty == false {
                                    try? FileManager.default.removeItem(at: directory)
                                }
                                // create engine directory if necessary
                                if !FileManager.default.fileExists(atPath: directory.path) {
                                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                                }
                                
                                continuation.yield(.init(stage: .installing, progress: installationProgress))
                                
                                let process: Process = .init()
                                process.executableURL = .init(filePath: "/usr/bin/tar")
                                process.arguments = ["-xJf", file.path, "-C", directory.path]
                                
                                let tarResult = try await process.runWrapped()
                                
                                guard process.terminationStatus == 0 else {
                                    log.error("""
                                        Engine installation unsuccessful, Tar exited with a nonzero termination status.
                                        Output (stderr): \(tarResult.standardError ?? "N/A")
                                        """)
                                    
                                    continuation.finish(throwing: CocoaError(.fileWriteUnknown)); return
                                }
                                
                                // Organize extracted files: if wrapped inside "Game Porting Toolkit.app/Contents/Resources/wine", link/copy to directory/wine
                                let gptkWineURL = directory.appending(path: "Game Porting Toolkit.app/Contents/Resources/wine")
                                let targetWineURL = directory.appending(path: "wine")
                                if FileManager.default.fileExists(atPath: gptkWineURL.path) && !FileManager.default.fileExists(atPath: targetWineURL.path) {
                                    try? FileManager.default.copyItem(at: gptkWineURL, to: targetWineURL)
                                }

                                // Write Properties.plist so engine version is recognized
                                let propertiesURL = directory.appending(path: "Properties.plist")
                                if !FileManager.default.fileExists(atPath: propertiesURL.path) {
                                    let prop = EngineProperties(version: release.version)
                                    let encoder = PropertyListEncoder()
                                    if let data = try? encoder.encode(prop) {
                                        try? data.write(to: propertiesURL)
                                    }
                                }

                                // Mark wine binary executable
                                let wineBin = wineExecutableURL.path
                                if FileManager.default.fileExists(atPath: wineBin) {
                                    try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: wineBin)
                                }
                                
                                installationProgress.completedUnitCount = 100
                                continuation.yield(.init(stage: .installing, progress: installationProgress))
                                
                                continuation.finish()
                            } catch {
                                try? FileManager.default.removeItem(atPath: file.path)
                                continuation.finish(throwing: error)
                            }
                        }
                    }
                    
                    Task(priority: .utility) {
                        while case .running = task.state {
                            continuation.yield(InstallProgress(stage: .downloading, progress: task.progress))
                            try? await Task.sleep(for: .milliseconds(100))
                        }
                        continuation.yield(InstallProgress(stage: .downloading, progress: task.progress))
                    }
                    
                    task.resume()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    static func remove() async throws {
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
    }
}

extension Engine {
    @MainActor
    static func displayUpdateChecker(userInitiated: Bool) async {
        guard let window = NSApp.windows.first else { return }
        
        let isUpdateAvailable: Bool
        do {
            isUpdateAvailable = try await checkIfUpdateAvailable()
        } catch {
            if userInitiated {
                let alert: NSAlert = .init()
                alert.alertStyle = .critical
                alert.messageText = String(localized: "Unable to check for WinGame Engine updates.")
                alert.informativeText = error.localizedDescription
                alert.addButton(withTitle: String(localized: "OK"))
                
                await alert.beginSheetModal(for: window)
            }
            
            return
        }
        
        guard isUpdateAvailable else {
            if userInitiated {
                let alert: NSAlert = .init()
                alert.alertStyle = .informational
                alert.messageText = String(localized: "No WinGame Engine updates available.")
                alert.informativeText = String(localized: "You're currently on the latest version, \(await installedVersion?.description ?? String(localized: "an unknown version")).")
                alert.addButton(withTitle: String(localized: "OK"))
                
                await alert.beginSheetModal(for: window)
            }
            return
        }
        
        let latestVersion = (try? await getLatestCompatibleRelease())?.version.description ?? String(localized: "Unknown")
        let currentVersion = await installedVersion?.description ?? String(localized: "an unknown version", comment: "Of WinGame Engine")
        
        let updateAlert: NSAlert = .init()
        updateAlert.messageText = String(localized: "WinGame Engine update available.")
        updateAlert.informativeText = String(localized: """
            A new version of WinGame Engine (\(latestVersion)) has released.
            You're currently using \(currentVersion).
            """)
        updateAlert.addButton(withTitle: String(localized: "Update"))
        updateAlert.addButton(withTitle: String(localized: "Cancel"))
        
        let updateResponse = await updateAlert.beginSheetModal(for: window)
        guard case .alertFirstButtonReturn = updateResponse else { return }
        
        let confirmationAlert: NSAlert = .init()
        confirmationAlert.messageText = String(localized: "Are you sure you want to update now?")
        confirmationAlert.informativeText = String(localized: "This will remove the current version of WinGame Engine.") + String(localized: "The latest version will be installed the next time you attempt to launch a Windows® game.")
        confirmationAlert.addButton(withTitle: String(localized: "Update"))
        confirmationAlert.addButton(withTitle: String(localized: "Cancel"))
        
        let confirmationResponse = await confirmationAlert.beginSheetModal(for: window)
        guard case .alertFirstButtonReturn = confirmationResponse else { return }
        
        do {
            try await remove()
            
            let successAlert: NSAlert = .init()
            successAlert.alertStyle = .informational
            successAlert.messageText = String(localized: "Successfully removed WinGame Engine.")
            successAlert.informativeText = String(localized: "The latest version will be installed the next time you attempt to launch a Windows® game.")
            successAlert.addButton(withTitle: String(localized: "OK"))
            
            await successAlert.beginSheetModal(for: window)
        } catch {
            let errorAlert: NSAlert = .init()
            errorAlert.alertStyle = .critical
            errorAlert.messageText = String(localized: "Unable to remove WinGame Engine.")
            errorAlert.informativeText = error.localizedDescription
            errorAlert.addButton(withTitle: String(localized: "OK"))
            
            await errorAlert.beginSheetModal(for: window)
        }
    }
}
