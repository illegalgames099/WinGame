//
//  HomeView.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 12/9/2023.
//

// Copyright © 2023-2025 vapidinfinity

import SwiftUI
import Cocoa

/**
 The main view displaying the home screen of the WinGame app.
 */
struct HomeView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Bindable var gameDataStore: GameDataStore = .shared
    
    @AppStorage("gameCardSize") private var gameCardSize: Double = 200.0
    
    @State private var isImageEmpty = true
    
    @State private var isFavouritesSectionExpanded: Bool = true
    @State private var isContainersSectionExpanded: Bool = true
    @State private var isRecentDetailsPresented: Bool = false

    private var favouriteGamesExcludingRecent: [Game] {
        gameDataStore.library
            .filter(\.self.isFavourited)
            .filter({ $0 != gameDataStore.recent })
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    if let recentGame = gameDataStore.recent {
                        ZStack(alignment: .bottomLeading) {
                            GameImageCard(url: recentGame.horizontalImageURL, isImageEmpty: $isImageEmpty)
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(width: geometry.size.width - 40, height: geometry.size.height * 0.6)
                                .clipped()
                                .overlay {
                                    LinearGradient(
                                        colors: [.black.opacity(0.9), .black.opacity(0.4), .clear],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    isRecentDetailsPresented = true
                                }
                                .winGlassEffect()
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)

                            HStack {
                                if isImageEmpty, recentGame.isFallbackImageAvailable {
                                    GameImageCard.FallbackGameImageCard(game: .constant(recentGame))
                                        .frame(width: 80, height: 80)
                                        .scaledToFit()
                                        .shadow(radius: 5)
                                        .padding(.trailing, 8)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("CONTINUE PLAYING")
                                        .foregroundStyle(.white.opacity(0.8))
                                        .font(.caption.weight(.semibold))
                                        .kerning(1.2)
                                    
                                    HStack {
                                        GameCard.TitleAndInformationView(game: .constant(recentGame), withSubscriptedInfo: true)
                                            .font(.title.weight(.bold))
                                            .foregroundStyle(.white)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                isRecentDetailsPresented = true
                                            }
                                    }
                                    HStack {
                                        GameCard.ButtonsView(game: .constant(recentGame), withLabel: true)
                                            .clipShape(.capsule)
                                            .controlSize(.large)
                                            .padding(.top, 4)
                                    }
                                }
                            }
                            .padding(24)
                        }
                        .padding(.top, 20)
                    } else {
                        ContentUnavailableView(
                            "Welcome to WinGame!",
                            systemImage: "hand.wave",
                            description: .init("""
                            This area is where your most recently played game will appear — try launching one now!
                            """)
                        )
                        .frame(
                            width: geometry.size.width - 40,
                            height: geometry.size.height * 0.6
                        )
                        .winGlassEffect(in: .rect(cornerRadius: 24))
                        .padding(.top, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        DisclosureGroup("Your Favourites", isExpanded: $isFavouritesSectionExpanded) {
                            if favouriteGamesExcludingRecent.isEmpty {
                                HStack(alignment: .center) {
                                    Spacer()
                                    ContentUnavailableView(
                                        "No Favourites",
                                        systemImage: "star.slash.fill",
                                        description: .init("""
                                        Games you favourite will appear here.
                                        You can favourite a game by pressing [􀍠] → [􀋂].
                                        """)
                                    )
                                    Spacer()
                                }
                                .padding(.vertical, 30)
                            } else {
                                LazyVGrid(columns: [.init(.adaptive(minimum: gameCardSize), spacing: 16)], spacing: 16) {
                                    ForEach(favouriteGamesExcludingRecent) { game in
                                        GameCard(game: .constant(game))
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .font(.title2.weight(.bold))
                        
                        DisclosureGroup("Your Containers", isExpanded: $isContainersSectionExpanded) {
                            ContainerListView()
                                .padding(.top, 8)
                        }
                        .font(.title2.weight(.bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .customTransform { view in
            if #available(macOS 15.0, *) {
                view
                    .toolbar(removing: .title)
                    .toolbarBackgroundVisibility(.hidden)
            } else {
                view
                    .toolbarBackground(.hidden)
            }
        }
        .navigationTitle("Home")
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: gameDataStore.recent)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFavouritesSectionExpanded)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isContainersSectionExpanded)
        .sheet(isPresented: $isRecentDetailsPresented) {
            if let recentGame = gameDataStore.recent {
                GameSettingsView(
                    game: Binding(
                        get: { recentGame },
                        set: { gameDataStore.library.update(with: $0) }
                    ),
                    isPresented: $isRecentDetailsPresented
                )
                .frame(minWidth: 760, idealWidth: 840, minHeight: 620, idealHeight: 740)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(NetworkMonitor.shared)
}
