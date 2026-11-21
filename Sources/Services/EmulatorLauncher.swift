import SwiftUI
import UIKit

enum LauncherError: LocalizedError {
    case noAccess
    var errorDescription: String? { "Sem permissão para acessar o arquivo. Reimporte a ISO." }
}

/// Ponto de integração com o emulador. Troque/estenda conforme o emulador usado.
protocol EmulatorBackend {
    @discardableResult func launch(isoURL: URL, game: Game) -> Bool
}

/// Abre o emulador por URL scheme. Template ex.: meuemulador://open?path={path}&id={id}
struct URLSchemeBackend: EmulatorBackend {
    let template: String

    @discardableResult
    func launch(isoURL: URL, game: Game) -> Bool {
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+"))
        let path = isoURL.path.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let id = game.gameID ?? ""
        let s = template
            .replacingOccurrences(of: "{path}", with: path)
            .replacingOccurrences(of: "{id}", with: id)
        guard let url = URL(string: s) else { return false }
        UIApplication.shared.open(url)
        return true
    }
}

/// Folha de compartilhamento ("Abrir em…") para enviar a ISO a outro app.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
