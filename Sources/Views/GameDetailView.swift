import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Bindable var game: Game
    @AppStorage("emulatorURLTemplate") private var template = ""
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var accessedURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                GameCard(game: game).frame(maxWidth: 180).frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                Button { play() } label: {
                    Label("Jogar", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            Section("Informações") {
                TextField("Título", text: $game.title)
                LabeledContent("ID do jogo", value: game.gameID ?? "não encontrado")
                LabeledContent("Arquivo", value: game.fileName)
                if let d = game.lastPlayed {
                    LabeledContent("Último jogo", value: d.formatted(date: .abbreviated, time: .shortened))
                }
                Toggle("Favorito", isOn: $game.isFavorite)
            }
            Section("Perfil do jogo") {
                Stepper("Resolução: \(game.resolutionScale)x", value: $game.resolutionScale, in: 1...6)
                Stepper("Frameskip: \(game.frameskip)", value: $game.frameskip, in: 0...4)
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare, onDismiss: stopAccess) {
            if let shareURL { ShareSheet(items: [shareURL]) }
        }
        .alert("Erro", isPresented: Binding(get: { errorMessage != nil },
                                            set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    private func play() {
        do {
            var stale = false
            let url = try URL(resolvingBookmarkData: game.bookmark, options: [],
                              relativeTo: nil, bookmarkDataIsStale: &stale)
            guard url.startAccessingSecurityScopedResource() else { throw LauncherError.noAccess }
            accessedURL = url
            if stale, let fresh = try? url.bookmarkData() { game.bookmark = fresh }
            game.lastPlayed = Date()

            if !template.isEmpty, URLSchemeBackend(template: template).launch(isoURL: url, game: game) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { stopAccess() }
            } else {
                shareURL = url
                showShare = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func stopAccess() {
        accessedURL?.stopAccessingSecurityScopedResource()
        accessedURL = nil
    }
}
