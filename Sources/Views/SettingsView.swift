import SwiftUI

struct SettingsView: View {
    @AppStorage("emulatorURLTemplate") private var template = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("meuemulador://open?path={path}", text: $template)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("URL scheme do emulador")
                } footer: {
                    Text("Use {path} para o caminho da ISO e {id} para o ID do jogo. Se ficar vazio, o app abre a folha \"Abrir em…\".")
                }
            }
            .navigationTitle("Ajustes")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } } }
        }
    }
}
