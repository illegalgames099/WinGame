//
//  ContainersView.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 12/9/2023.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI
import OSLog

struct ContainersView: View {
    @State private var isContainerCreationViewPresented = false
    @State private var configuringContainerURL: URL?
    @State private var deletingContainer: Wine.Container?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // Header Bar
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Wine Containers")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Isolated Windows 64-bit environments with DXVK and D3DMetal translation.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if Engine.isInstalled {
                        HStack(spacing: 12) {
                            if let containersDirectory = Wine.containersDirectory {
                                Button {
                                    NSWorkspace.shared.open(containersDirectory)
                                } label: {
                                    Label("Open Folder", systemImage: "folder")
                                }
                                .buttonStyle(.bordered)
                            }

                            Button {
                                isContainerCreationViewPresented = true
                            } label: {
                                Label("New Container", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                // Containers List
                if Wine.containerObjects.isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 76, height: 76)
                            Image(systemName: "cube.transparent")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 6) {
                            Text("No Containers Configured")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Create a Wine prefix to install and execute Windows games.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            isContainerCreationViewPresented = true
                        } label: {
                            Label("Create Default Container", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }
                } else {
                    VStack(spacing: 14) {
                        ForEach(Wine.containerObjects) { container in
                            containerCard(container)
                        }
                    }
                }

                Spacer()
            }
            .padding(32)
        }
        .sheet(isPresented: $isContainerCreationViewPresented) {
            ContainerCreationView(isPresented: $isContainerCreationViewPresented)
        }
        .sheet(item: Binding(
            get: { configuringContainerURL.map { IdentifiableURL(url: $0) } },
            set: { configuringContainerURL = $0?.url }
        )) { item in
            ContainerConfigurationView(
                containerURL: .constant(item.url),
                isPresented: Binding(
                    get: { configuringContainerURL != nil },
                    set: { if !$0 { configuringContainerURL = nil } }
                )
            )
        }
        .alert(item: $deletingContainer) { container in
            Alert(
                title: Text("Delete \"\(container.name)\"?"),
                message: Text("This will permanently remove the container prefix and any Windows files installed inside it."),
                primaryButton: .destructive(Text("Delete")) {
                    try? Wine.deleteContainer(containerURL: container.url)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func containerCard(_ container: Wine.Container) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.18))
                    .frame(width: 48, height: 48)

                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(container.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Win64")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }

                Text(container.url.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    NSWorkspace.shared.open(container.url)
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 13))
                }
                .buttonStyle(.bordered)
                .help("Open in Finder")

                Button {
                    configuringContainerURL = container.url
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                }
                .buttonStyle(.bordered)
                .help("Container Settings")

                Button {
                    deletingContainer = container
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
                .help("Delete Container")
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
