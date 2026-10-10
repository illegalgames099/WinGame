//
//  ContainerCreation.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 29/1/2024.
//

// Copyright © 2023-2025 vapidinfinity

import SwiftUI

struct ContainerCreationView: View {
    @Binding var isPresented: Bool

    @State private var containerName: String = "My Container"
    @State private var containerURL: URL = Wine.containersDirectory ?? FileManager.default.homeDirectoryForCurrentUser

    @State private var isContainerURLFileImporterPresented: Bool = false

    @State private var isBooting: Bool = false
    @State private var isCancellationAlertPresented: Bool = false
    
    @State private var bootErrorDescription: String = String(localized: "Unknown Error.")
    @State private var isBootFailureAlertPresented: Bool = false
    
    @State private var creationTask: Task<Void, Never>?
    
    var body: some View {
        VStack {
            Text("Create Container")
                .font(.title)
                .padding([.horizontal, .top])

            Form {
                TextField("Choose a name for your container:", text: $containerName)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Where do you want the container's base path to be located?")

                        Text(containerURL.prettyPath)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    
                    if !FileLocations.isWritableFolder(url: containerURL) {
                        Image(systemName: "exclamationmark.triangle")
                            .symbolVariant(.fill)
                            .help("Folder is not writable.")
                    }
                    
                    Button("Browse...") {
                        isContainerURLFileImporterPresented = true
                    }
                    .fileImporter(
                        isPresented: $isContainerURLFileImporterPresented,
                        allowedContentTypes: [.folder]
                    ) { result in
                        if case .success(let url) = result {
                            containerURL = url
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel", role: .cancel) {
                    if isBooting {
                        isCancellationAlertPresented = true
                    } else {
                        isPresented = false
                    }
                }
                .alert(isPresented: $isCancellationAlertPresented) {
                    Alert(
                        title: .init("Are you sure you want to cancel container creation?"),
                        message: .init("This will cancel \"\(containerName)\"'s creation."),
                        primaryButton: .destructive(.init("OK")) {
                            creationTask?.cancel()
                            isPresented = false
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                Spacer()

                if isBooting {
                    ProgressView()
                        .controlSize(.small)
                        .padding(0.5)
                }

                Button("Done") {
                    guard !isBooting else { return }
                    withAnimation { isBooting = true }
                    creationTask = Task(priority: .userInitiated) {
                        do {
                            _ = try await Wine.createContainer(baseURL: containerURL, name: containerName)
                            
                            guard !Task.isCancelled else { return }
                            
                            withAnimation { isBooting = false }
                            isPresented = false
                        } catch {
                            guard !Task.isCancelled else { return }
                            bootErrorDescription = error.localizedDescription
                            withAnimation { isBooting = false }
                            isBootFailureAlertPresented = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBooting)
                .disabled(!FileLocations.isWritableFolder(url: containerURL))
                .disabled((Wine.containerURLs.first(where: { $0.lastPathComponent == containerName}) != nil))
            }
            .padding()
        }
        
        .alert(isPresented: $isBootFailureAlertPresented) {
            Alert(
                title: .init("Failed to boot \"\(containerName)\"."),
                message: .init(bootErrorDescription)
            )
        }
        
        .task(priority: .background) {
            
        }
    }
}

#Preview {
    ContainerCreationView(isPresented: .constant(true))
}