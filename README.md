# PS2 Launcher (iOS)

Biblioteca de ISOs de PS2 em SwiftUI + SwiftData (iOS 17+).

## Gerar o IPA
**Sem Mac:** suba esta pasta num repositório do GitHub → aba Actions → "Build IPA" → baixe `PS2Launcher.ipa`
(sem assinatura). Assine/instale com AltStore, Sideloadly ou similar.

**Com Mac:** `brew install xcodegen && xcodegen generate`, abra `PS2Launcher.xcodeproj`, escolha seu Team em
Signing e rode ou use Product > Archive.

## Integração com o emulador
- Ajustes: URL scheme do emulador (`{path}` e `{id}`), ou deixe vazio para usar "Abrir em…".
- Para um núcleo embutido, implemente `EmulatorBackend` em `Services/EmulatorLauncher.swift`.
