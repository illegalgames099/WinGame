//
//  WinGameApp.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 9/9/2023.
//

// Copyright © 2023-2025 vapidinfinity

import SwiftUI
import Sparkle
import WhatsNewKit

@main
struct WinGameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @AppStorage("isOnboardingPresented") var isOnboardingPresented: Bool = true

    @StateObject private var networkMonitor: NetworkMonitor = .shared

    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("WinGame", id: "main") {
            Group {
                if isOnboardingPresented {
                    OnboardingView()
                        .task(priority: .high) {
                            await MainActor.run {
                                NSApp.mainWindow?.isImmersive = true
                            }
                        }
                } else {
                    ContentView()
                        .whatsNewSheet()
                        .environmentObject(networkMonitor)
                        .task(priority: .high) {
                            await MainActor.run {
                                NSApp.mainWindow?.isImmersive = false
                            }
                        }
                }
            }
            .modifier(SparkleUpdater())
            .frame(minWidth: 850, minHeight: 400)
        }
        .handlesExternalEvents(matching: ["open"])
        .environment(
            \.whatsNew,
             WhatsNewEnvironment(
                versionStore:
                    {
#if DEBUG
                        InMemoryWhatsNewVersionStore()
#else
                        UserDefaultsWhatsNewVersionStore()
#endif
                    }(),
                whatsNewCollection: self
             )
        )
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button {
                    openWindow(id: "about")
                } label: {
                    Text("About WinGame")
                }
            }

            CommandGroup(after: .appInfo) {
                Button("Check for WinGame Updates...", action: { SparkleUpdateController.shared.checkForUpdates(userInitiated: true) })
                
                Button("Check for WinGame Engine Updates...") {
                    Task(priority: .userInitiated) {
                        await Engine.displayUpdateChecker(userInitiated: true)
                    }
                }

                Button("Restart Onboarding...") {
                    withAnimation {
                        isOnboardingPresented = true
                    }
                }
                .disabled(isOnboardingPresented)
            }
            
            CommandGroup(replacing: .help) {
                Link("Documentation", destination: URL(string: "https://docs.getwingame.app/")!)
                Link("Discord server", destination: URL(string: "https://discord.gg/kQKdvjTVqh")!)
                Link("Games compability",
                     destination: URL(string: "https://docs.google.com/spreadsheets/d/1W_1UexC1VOcbP2CHhoZBR5-8koH-ZPxJBDWntwH-tsc/")!)

                Section("Support the project") {
                    Link("GitHub Sponsors", destination: URL(string: "https://github.com/sponsors/WinGameApp")!)
                    Link("Ko-Fi", destination: URL(string: "https://ko-fi.com/vapidinfinity")!)
                }
                
                Section("More") {
                    Link("GitHub repository", destination: URL(string: "https://github.com/WinGameApp/WinGame")!)
                    Link("Website", destination: URL(string: "https://getwingame.app/")!)
                }
            }
        }

        Window("About WinGame", id: "about") {
            AboutView()
                .frame(width: 285, height: 400)
                .onAppear {
                    if let window = NSApp.window(withID: "about") {
                        window.isImmersive = true
                    }
                }
        }
        
        Settings {
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NetworkMonitor.shared)
}
