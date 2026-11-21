import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Game.title) private var games: [Game]
    @State private var showImporter = false
    @State private var showSettings = false
    @State private var search = ""
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    private var filtered: [Game] {
        guard !search.isEmpty else { return games }
        return games.filter {
            $0.title.localizedCaseInsensitiveContains(search) ||
            ($0.gameID ?? "").localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if games.isEmpty {
                    ContentUnavailableView("Biblioteca vazia",
                                           systemImage: "opticaldisc",
                                           description: Text("Toque em + para importar suas ISOs."))
                        .padding(.top, 80)
                }
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filtered) { game in
                        NavigationLink { GameDetailView(game: game) } label: { GameCard(game: game) }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { context.delete(game) } label: {
                                    Label("Remover da biblioteca", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("PS2 Launcher")
            .searchable(text: $search)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showImporter = true } label: { Image(systemName: "plus") }
                }
            }
            .fileImporter(isPresented: $showImporter,
                          allowedContentTypes: [UTType(filenameExtension: "iso") ?? .data, .data],
                          allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls): importFiles(urls)
                case .failure(let error): errorMessage = error.localizedDescription
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .alert("Erro", isPresented: Binding(get: { errorMessage != nil },
                                                set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func importFiles(_ urls: [URL]) {
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let info = try? ISOReader.read(url: url)
                if games.contains(where: { $0.fileName == url.lastPathComponent && $0.gameID == info?.gameID }) { continue }
                let bookmark = try url.bookmarkData()
                let title = url.deletingPathExtension().lastPathComponent
                context.insert(Game(title: title, fileName: url.lastPathComponent,
                                    gameID: info?.gameID, bookmark: bookmark))
            } catch {
                errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
            }
        }
    }
}

struct GameCard: View {
    let game: Game

    private var gradient: LinearGradient {
        let h = Double(abs(game.title.hashValue % 360)) / 360.0
        return LinearGradient(colors: [Color(hue: h, saturation: 0.6, brightness: 0.55),
                                       Color(hue: h, saturation: 0.7, brightness: 0.3)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 14).fill(gradient)
            Image(systemName: "opticaldisc").font(.system(size: 44)).foregroundStyle(.white.opacity(0.25))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 2) {
                Text(game.title).font(.subheadline.bold()).lineLimit(2)
                if let id = game.gameID { Text(id).font(.caption2).opacity(0.8) }
            }
            .foregroundStyle(.white)
            .padding(10)
            if game.isFavorite {
                Image(systemName: "star.fill").foregroundStyle(.yellow).padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
    }
}
