//
//  PlatformWebAuthWindow.swift
//  WinGame
//
//  Created for multi-storefront web sign-in (Steam, GOG, EA).
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI
import WebKit
import OSLog

final class PlatformWebAuthViewModel: NSObject, ObservableObject, NSWindowDelegate, @unchecked Sendable {
    static let shared = PlatformWebAuthViewModel()

    private var activeWindow: NSWindow?
    @Published var currentStorefront: Game.Storefront?
    @Published var isAuthenticating: Bool = false
    @Published var statusMessage: String = ""

    private override init() {
        super.init()
    }

    @MainActor
    func showSignIn(for storefront: Game.Storefront) {
        currentStorefront = storefront
        isAuthenticating = false
        statusMessage = "Sign in to \(storefront.description)"

        if let existing = activeWindow {
            existing.contentView = NSHostingView(rootView: PlatformWebAuthView(storefront: storefront, viewModel: self))
            existing.title = "Sign In to \(storefront.description)"
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: 880, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.identifier = .init("platform-signin")
        window.title = "Sign In to \(storefront.description)"
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: PlatformWebAuthView(storefront: storefront, viewModel: self))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.activeWindow = window
    }

    @MainActor
    func closeWindow() {
        activeWindow?.orderOut(nil)
        activeWindow = nil
        currentStorefront = nil
    }

    func windowWillClose(_ notification: Notification) {
        activeWindow = nil
        currentStorefront = nil
    }
}

struct PlatformWebAuthView: View {
    let storefront: Game.Storefront
    @ObservedObject var viewModel: PlatformWebAuthViewModel

    @State private var isLoading: Bool = true
    @State private var webView: WKWebView?
    @State private var manualUsername: String = ""
    @State private var manualAccountID: String = ""
    @State private var isManualInputVisible: Bool = false
    @State private var statusFeedback: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 12) {
                storefrontIcon(storefront)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign in to \(storefront.description)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(statusFeedback ?? "Log in with your credentials to connect your library")
                        .font(.caption)
                        .foregroundStyle(statusFeedback != nil ? .cyan : .secondary)
                }

                Spacer()

                if isLoading || viewModel.isAuthenticating {
                    ProgressView()
                        .controlSize(.small)
                }

                HStack(spacing: 6) {
                    Button {
                        webView?.goBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Go Back")

                    Button {
                        webView?.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Reload page")

                    Button {
                        viewModel.closeWindow()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Close window")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(white: 0.12))

            Divider()

            // In-App Web Browser
            PlatformWebViewRepresentable(
                storefront: storefront,
                isLoading: $isLoading,
                onWebViewCreated: { self.webView = $0 },
                onAuthProgress: { message in
                    statusFeedback = message
                },
                onSuccess: { username, identifier, extraToken in
                    handleAuthSuccess(username: username, accountID: identifier, extraToken: extraToken)
                }
            )

            Divider()

            // Connection Assistance Bar
            VStack(spacing: 8) {
                HStack {
                    Button {
                        withAnimation {
                            isManualInputVisible.toggle()
                        }
                    } label: {
                        Label(
                            isManualInputVisible ? "Hide Direct Details" : "Manual Username / ID Confirmation",
                            systemImage: "person.badge.key.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        completeFromWebSession()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Confirm Sign-In")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Extract signed-in session from the current page")
                }

                if isManualInputVisible {
                    HStack(spacing: 10) {
                        TextField("Username / Persona", text: $manualUsername)
                            .textFieldStyle(.roundedBorder)

                        TextField("Optional Account ID", text: $manualAccountID)
                            .textFieldStyle(.roundedBorder)

                        Button("Connect") {
                            let trimmedName = manualUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                            let trimmedID = manualAccountID.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedName.isEmpty {
                                handleAuthSuccess(username: trimmedName, accountID: trimmedID, extraToken: "")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(manualUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(white: 0.10))
        }
        .frame(minWidth: 780, minHeight: 600)
        .background(Color(white: 0.08))
    }

    private func completeFromWebSession() {
        guard let activeWebView = webView else { return }
        statusFeedback = "Verifying current session..."

        switch storefront {
        case .steam:
            activeWebView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                var foundSteamID = ""
                for cookie in cookies where cookie.name == "steamLoginSecure" {
                    let parts = cookie.value.components(separatedBy: "%7C%7C")
                    if let first = parts.first, first.allSatisfy(\.isNumber) {
                        foundSteamID = first
                    }
                }
                activeWebView.evaluateJavaScript("document.querySelector('.persona_name, .actual_persona_name')?.innerText || document.title") { response, _ in
                    let name = (response as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let finalName = name.isEmpty ? "Steam User" : name.replacingOccurrences(of: "Steam Community :: ", with: "")
                    handleAuthSuccess(username: finalName, accountID: foundSteamID, extraToken: "")
                }
            }
        case .gog:
            // Query userData inside the webView with native cookies
            let jsScript = """
            (function() {
                return fetch('https://embed.gog.com/userData', { credentials: 'include' })
                    .then(response => response.json())
                    .then(data => JSON.stringify(data))
                    .catch(err => JSON.stringify({ error: err.toString() }));
            })();
            """
            activeWebView.evaluateJavaScript(jsScript) { result, _ in
                if let jsonString = result as? String,
                   let jsonData = jsonString.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let username = dict["username"] as? String, !username.isEmpty {
                    let userID = "\(dict["userId"] ?? "")"
                    handleAuthSuccess(username: username, accountID: userID, extraToken: "")
                } else {
                    activeWebView.evaluateJavaScript("document.querySelector('.menu-username, .user-avatar, .header__user-avatar')?.innerText || document.title") { res, _ in
                        let name = (res as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "GOG User"
                        handleAuthSuccess(username: name.isEmpty ? "GOG User" : name, accountID: "", extraToken: "")
                    }
                }
            }
        case .electronicArts:
            let jsScript = """
            (function() {
                var el = document.querySelector('.profile-name, .ea-account-username, [data-testid="user-persona"], .user-tag, .logged-in-user, .user-name, ea-user, ea-player-network-nav, ea-nav-profile, #userPersona, .persona-name');
                if (el && el.innerText && el.innerText.trim().length > 0) return el.innerText.trim();
                return '';
            })();
            """
            activeWebView.evaluateJavaScript(jsScript) { result, _ in
                var personaName = (result as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if personaName.isEmpty || personaName.contains("Electronic Arts") {
                    personaName = "EA Player"
                }
                handleAuthSuccess(username: personaName, accountID: "", extraToken: "")
            }
        default:
            break
        }
    }

    private func handleAuthSuccess(username: String, accountID: String, extraToken: String) {
        statusFeedback = "Connected as \(username)!"
        switch storefront {
        case .steam:
            StorefrontAccountManager.shared.saveSteam(username: username, id: accountID)
            Task { @MainActor in
                try? await GameDataStore.shared.refreshFromStorefronts(.steam)
                viewModel.closeWindow()
            }
        case .gog:
            StorefrontAccountManager.shared.saveGOG(username: username, id: accountID, accessToken: extraToken)
            Task { @MainActor in
                try? await GameDataStore.shared.refreshFromStorefronts(.gog)
                viewModel.closeWindow()
            }
        case .electronicArts:
            StorefrontAccountManager.shared.saveEA(username: username, id: accountID, authCode: extraToken)
            Task { @MainActor in
                try? await GameDataStore.shared.refreshFromStorefronts(.electronicArts)
                viewModel.closeWindow()
            }
        default:
            viewModel.closeWindow()
        }
    }

    private func storefrontIcon(_ sf: Game.Storefront) -> some View {
        Group {
            switch sf {
            case .steam:
                Image(systemName: "circle.grid.cross.fill").foregroundStyle(.blue)
            case .gog:
                Image(systemName: "gamecontroller.fill").foregroundStyle(.teal)
            case .electronicArts:
                Image(systemName: "triangle.fill").foregroundStyle(.red)
            default:
                Image(systemName: "globe").foregroundStyle(.white)
            }
        }
        .font(.title2)
    }
}

private struct PlatformWebViewRepresentable: NSViewRepresentable {
    let storefront: Game.Storefront
    @Binding var isLoading: Bool
    let onWebViewCreated: (WKWebView) -> Void
    let onAuthProgress: (String) -> Void
    let onSuccess: (String, String, String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // Set modern desktop Safari User Agent to ensure full compatibility with EA, GOG & OAuth providers
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"

        onWebViewCreated(webView)

        if let initialURL = getInitialURL(for: storefront) {
            webView.load(URLRequest(url: initialURL))
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    private func getInitialURL(for storefront: Game.Storefront) -> URL? {
        switch storefront {
        case .steam:
            return URL(string: "https://steamcommunity.com/login/home/?goto=%2Fid%2Fme%2F")
        case .gog:
            return URL(string: "https://auth.gog.com/auth?client_id=46899977096215655&layout=client2&redirect_uri=https://embed.gog.com/on_login_success?origin=client&response_type=code")
        case .electronicArts:
            // Verified active EA OAuth endpoint used by GOG Galaxy integration
            return URL(string: "https://accounts.ea.com/connect/auth?response_type=code&client_id=EADOTCOM-WEB-SERVER&display=junoWeb/login&locale=en_US&release_type=prod&redirect_uri=https://www.ea.com/ea-play")
        default:
            return nil
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: PlatformWebViewRepresentable
        private var handledSuccess = false

        init(_ parent: PlatformWebViewRepresentable) {
            self.parent = parent
        }

        // Support popups and window.open links within the same webview
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }

            guard !handledSuccess, let url = webView.url else { return }
            let urlString = url.absoluteString

            switch parent.storefront {
            case .steam:
                handleSteamNavigation(webView: webView, url: url)
            case .gog:
                handleGOGNavigation(webView: webView, url: url)
            case .electronicArts:
                handleEANavigation(webView: webView, url: url)
            default:
                break
            }
        }

        private func handleSteamNavigation(webView: WKWebView, url: URL) {
            let urlString = url.absoluteString

            if urlString.contains("/id/") || urlString.contains("/profiles/") {
                webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                    var foundSteamID = ""
                    for cookie in cookies where cookie.name == "steamLoginSecure" {
                        let val = cookie.value
                        let parts = val.components(separatedBy: "%7C%7C")
                        if let firstPart = parts.first, firstPart.allSatisfy(\.isNumber) {
                            foundSteamID = firstPart
                        }
                    }

                    webView.evaluateJavaScript("document.querySelector('.persona_name')?.innerText || document.querySelector('.actual_persona_name')?.innerText || document.title") { res, _ in
                        var name = (res as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        if name.contains("::") {
                            name = name.components(separatedBy: "::").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? name
                        }
                        if name.hasPrefix("Steam Community :: ") {
                            name = name.replacingOccurrences(of: "Steam Community :: ", with: "")
                        }

                        if !foundSteamID.isEmpty || !name.isEmpty {
                            self.handledSuccess = true
                            DispatchQueue.main.async {
                                self.parent.onSuccess(name.isEmpty ? "Steam User" : name, foundSteamID, "")
                            }
                        }
                    }
                }
            }
        }

        private func handleGOGNavigation(webView: WKWebView, url: URL) {
            let urlString = url.absoluteString

            // 1. Check for OAuth authorization code callback
            if urlString.contains("on_login_success"), let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
               let authCode = queryItems.first(where: { $0.name == "code" })?.value, !authCode.isEmpty {
                self.handledSuccess = true
                DispatchQueue.main.async {
                    self.parent.onAuthProgress("Exchanging GOG authorization token...")
                }

                // Exchange code for GOG OAuth token
                let tokenEndpoint = "https://auth.gog.com/token?client_id=46899977096215655&client_secret=9d85c43b1482497dbbce61f6e4aa173a433796eeae2ca8c5f6129f2dc4de46d9&grant_type=authorization_code&code=\(authCode)&redirect_uri=https%3A%2F%2Fembed.gog.com%2Fon_login_success%3Forigin%3Dclient"
                guard let tokenURL = URL(string: tokenEndpoint) else { return }

                URLSession.shared.dataTask(with: tokenURL) { [weak self] data, _, error in
                    guard let self = self, error == nil, let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let accessToken = json["access_token"] as? String else {
                        // Fallback to cookie check if token exchange fails
                        self?.verifyGOGWithWebViewSession(webView)
                        return
                    }

                    let userID = "\(json["user_id"] ?? "")"

                    // Retrieve username via GOG API
                    var userReq = URLRequest(url: URL(string: "https://embed.gog.com/userData")!)
                    userReq.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                    URLSession.shared.dataTask(with: userReq) { uData, _, _ in
                        var userName = "GOG User"
                        if let uData = uData,
                           let uJson = try? JSONSerialization.jsonObject(with: uData) as? [String: Any],
                           let fetchedName = uJson["username"] as? String, !fetchedName.isEmpty {
                            userName = fetchedName
                        }

                        DispatchQueue.main.async {
                            self.parent.onSuccess(userName, userID, accessToken)
                        }
                    }.resume()
                }.resume()
                return
            }

            // 2. Fallback check if user navigated to account/embed page
            if urlString.contains("embed.gog.com") || urlString.contains("gog.com/account") {
                verifyGOGWithWebViewSession(webView)
            }
        }

        private func verifyGOGWithWebViewSession(_ webView: WKWebView) {
            let jsScript = """
            (function() {
                return fetch('https://embed.gog.com/userData', { credentials: 'include' })
                    .then(response => response.json())
                    .then(data => JSON.stringify(data))
                    .catch(err => JSON.stringify({ error: err.toString() }));
            })();
            """
            webView.evaluateJavaScript(jsScript) { [weak self] result, _ in
                guard let self = self else { return }
                if let jsonString = result as? String,
                   let jsonData = jsonString.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let username = dict["username"] as? String, !username.isEmpty {
                    self.handledSuccess = true
                    let userID = "\(dict["userId"] ?? "")"
                    DispatchQueue.main.async {
                        self.parent.onSuccess(username, userID, "")
                    }
                }
            }
        }

        private func handleEANavigation(webView: WKWebView, url: URL) {
            let urlString = url.absoluteString

            // 1. Check for OAuth code in redirect URL (e.g. ea.com/ea-play?code=...)
            let hasAuthCode = urlString.contains("code=")
            let isEAPlayOrLanding = urlString.contains("ea.com/ea-play") || (urlString.contains("ea.com") && !urlString.contains("accounts.ea.com/connect/auth"))

            if (isEAPlayOrLanding && hasAuthCode) || urlString.contains("myaccount.ea.com") {
                let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
                let authCode = queryItems?.first(where: { $0.name == "code" })?.value ?? ""

                let jsScript = """
                (function() {
                    var el = document.querySelector('.profile-name, .ea-account-username, [data-testid="user-persona"], .user-tag, .logged-in-user, .user-name, ea-user, ea-player-network-nav, ea-nav-profile, #userPersona, .persona-name');
                    if (el && el.innerText && el.innerText.trim().length > 0) return el.innerText.trim();
                    return '';
                })();
                """
                webView.evaluateJavaScript(jsScript) { [weak self] res, _ in
                    guard let self = self else { return }
                    var name = (res as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if name.isEmpty || name.contains("Electronic Arts") {
                        name = "EA Player"
                    }

                    // Only trigger if we got an authorization code or verified persona on account portal
                    if !authCode.isEmpty || (urlString.contains("myaccount.ea.com") && name != "EA Player") {
                        self.handledSuccess = true
                        DispatchQueue.main.async {
                            self.parent.onSuccess(name, "", authCode)
                        }
                    }
                }
            }
        }
    }
}
