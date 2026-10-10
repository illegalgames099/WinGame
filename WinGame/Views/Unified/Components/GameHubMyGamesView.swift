//
//  GameHubMyGamesView.swift
//  WinGame
//
//  Created for GameHub UI experience.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI

struct GameHubMyGamesView: View {
    @Bindable var gameDataStore: GameDataStore = .shared
    @Bindable var viewModel: GameListViewModel = .shared

    enum StorefrontFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case installed = "Installed"
        case steam = "Steam"
        case epicGames = "Epic"
        case electronicArts = "EA"
        case gog = "GOG"
        case favorites = "Favorites"

        var id: String { rawValue }
    }

    enum SortOrder: String, CaseIterable, Identifiable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case recent = "Recently Played"

        var id: String { rawValue }
    }

    enum CardScale: CGFloat, CaseIterable, Identifiable {
        case compact = 175
        case standard = 215
        case expansive = 285

        var id: CGFloat { rawValue }
        var title: String {
            switch self {
            case .compact: return "Compact"
            case .standard: return "Standard"
            case .expansive: return "Large"
            }
        }
    }

    @State private var selectedFilter: StorefrontFilter = .all
    @State private var selectedSort: SortOrder = .nameAscending
    @State private var selectedCardScale: CardScale = .standard
    @State private var isAddGamePresented: Bool = false
    @State private var inspectedGame: Game?

    private var featuredGame: Game? {
        if let recent = gameDataStore.recent {
            return recent
        }
        return gameDataStore.library.first(where: {
            if case .installed = $0.installationState { return true }
            return false
        })
    }

    private var filteredGames: [Game] {
        var games = Array(gameDataStore.library)

        // Text Search
        if !viewModel.searchString.isEmpty {
            games = games.filter { $0.title.localizedStandardContains(viewModel.searchString) }
        }

        // Filter
        switch selectedFilter {
        case .all:
            break
        case .installed:
            games = games.filter {
                if case .installed = $0.installationState { return true }
                return false
            }
        case .steam:
            games = games.filter { $0.storefront == .steam }
        case .epicGames:
            games = games.filter { $0.storefront == .epicGames }
        case .electronicArts:
            games = games.filter { $0.storefront == .electronicArts }
        case .gog:
            games = games.filter { $0.storefront == .gog }
        case .favorites:
            games = games.filter { $0.isFavourited }
        }

        // Sort
        switch selectedSort {
        case .nameAscending:
            games.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .nameDescending:
            games.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .recent:
            games.sort { ($0.lastLaunched ?? .distantPast) > ($1.lastLaunched ?? .distantPast) }
        }

        return games
    }

    private var installedGames: [Game] {
        filteredGames.filter {
            if case .installed = $0.installationState { return true }
            return false
        }
    }

    private var notInstalledGames: [Game] {
        filteredGames.filter {
            if case .uninstalled = $0.installationState { return true }
            return false
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: selectedCardScale.rawValue, maximum: selectedCardScale.rawValue * 1.4), spacing: 20)]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // MARK: - Main Games Grid Area
            VStack(alignment: .leading, spacing: 18) {
                // Header Bar with Title, Search, and Sort
                headerBar

                // Quick Filter Chips Bar
                filterChipsBar

                // Games Scroll View
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        // Hero Spotlight Banner
                        if let featured = featuredGame, viewModel.searchString.isEmpty, selectedFilter == .all {
                            HeroFeaturedBanner(game: featured) {
                                inspectedGame = featured
                            }
                            .padding(.bottom, 6)
                        }

                        // Section: Installed
                        if !installedGames.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader(
                                    title: "Installed",
                                    count: installedGames.count,
                                    color: .green
                                )

                                LazyVGrid(columns: gridColumns, spacing: 22) {
                                    ForEach(installedGames) { game in
                                        GameHubGameCard(game: .constant(game))
                                    }
                                }
                            }
                        }

                        // Section: Not Installed
                        if !notInstalledGames.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader(
                                    title: "Not Installed",
                                    count: notInstalledGames.count,
                                    color: Color.white.opacity(0.4)
                                )

                                LazyVGrid(columns: gridColumns, spacing: 22) {
                                    ForEach(notInstalledGames) { game in
                                        GameHubGameCard(game: .constant(game))
                                    }
                                }
                            }
                        }

                        // Empty State
                        if installedGames.isEmpty && notInstalledGames.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding(.bottom, 36)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Vertical subtle glass divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1)
                .ignoresSafeArea()

            // MARK: - Right Storefront Accounts Panel
            GameHubAccountsView(gameDataStore: gameDataStore)
        }
        .sheet(isPresented: $isAddGamePresented) {
            GameImportView(isPresented: $isAddGamePresented)
        }
        .sheet(item: $inspectedGame) { game in
            GameSettingsView(
                game: Binding(
                    get: { game },
                    set: { _ in }
                ),
                isPresented: Binding(
                    get: { inspectedGame != nil },
                    set: { if !$0 { inspectedGame = nil } }
                )
            )
            .frame(minWidth: 760, idealWidth: 840, minHeight: 620, idealHeight: 740)
        }
    }

    // MARK: - Header Bar View
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 14) {
            // Main Title & Total Count
            HStack(spacing: 10) {
                Text("My Games")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(gameDataStore.library.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.1), in: Capsule())
            }

            Spacer()

            // Search Bar Capsule
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                TextField("Search library...", text: $viewModel.searchString)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)

                if !viewModel.searchString.isEmpty {
                    Button {
                        viewModel.searchString = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(width: 200)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }

            // Grid Zoom Scale Menu
            Menu {
                ForEach(CardScale.allCases) { scale in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedCardScale = scale
                        }
                    } label: {
                        HStack {
                            Text(scale.title)
                            if selectedCardScale == scale {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.resize")
                        .font(.system(size: 11, weight: .semibold))
                    Text(selectedCardScale.title)
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.06), in: Capsule())
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .help("Resize Game Cards")

            // Sort Pill Dropdown
            Menu {
                ForEach(SortOrder.allCases) { sort in
                    Button {
                        selectedSort = sort
                    } label: {
                        HStack {
                            Text(sort.rawValue)
                            if selectedSort == sort {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11, weight: .semibold))
                    Text(selectedSort.rawValue)
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.07), in: Capsule())
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            // Add Game Pill Button
            Button {
                isAddGamePresented = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add Game")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Quick Filter Chips Bar
    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StorefrontFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    let count = countForFilter(filter)

                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))

                            Text("\(count)")
                                .font(.system(size: 10, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.08),
                                    in: Capsule()
                                )
                        }
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            isSelected ? Color.white.opacity(0.14) : Color.white.opacity(0.04),
                            in: Capsule()
                        )
                        .overlay {
                            Capsule().stroke(
                                isSelected ? Color.white.opacity(0.28) : Color.white.opacity(0.07),
                                lineWidth: 1
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .animation(.easeOut(duration: 0.15), value: isSelected)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func countForFilter(_ filter: StorefrontFilter) -> Int {
        switch filter {
        case .all:
            return gameDataStore.library.count
        case .installed:
            return gameDataStore.library.filter {
                if case .installed = $0.installationState { return true }
                return false
            }.count
        case .steam:
            return gameDataStore.library.filter { $0.storefront == .steam }.count
        case .epicGames:
            return gameDataStore.library.filter { $0.storefront == .epicGames }.count
        case .electronicArts:
            return gameDataStore.library.filter { $0.storefront == .electronicArts }.count
        case .gog:
            return gameDataStore.library.filter { $0.storefront == .gog }.count
        case .favorites:
            return gameDataStore.library.filter(\.isFavourited).count
        }
    }

    // MARK: - Section Header
    private func sectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .shadow(color: color.opacity(0.8), radius: 4)

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Text("(\(count))")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            LinearGradient(
                colors: [Color.white.opacity(0.16), Color.white.opacity(0.02)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                Image(systemName: "gamecontroller")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("No Games Found")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text("Connect a storefront account or import a game executable to populate your library.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }

            HStack(spacing: 12) {
                Button {
                    PlatformWebAuthViewModel.shared.showSignIn(for: .steam)
                } label: {
                    Label("Link Steam", systemImage: "circle.grid.cross.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button {
                    Task { @MainActor in
                        EpicWebAuthViewModel.shared.showSignInWindow()
                    }
                } label: {
                    Label("Link Epic Games", systemImage: "shield.rhombohex.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button {
                    isAddGamePresented = true
                } label: {
                    Label("Add Local Game", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .padding(32)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
}
