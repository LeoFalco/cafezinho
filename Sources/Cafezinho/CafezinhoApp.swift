import CafezinhoCore
import ServiceManagement
import SwiftUI

@main
struct CafezinhoApp: App {
    @StateObject private var caffeinator = Caffeinator()

    var body: some Scene {
        MenuBarExtra {
            AppMenu(caffeinator: caffeinator)
        } label: {
            Image(systemName: caffeinator.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
        }
    }
}

struct AppMenu: View {
    @ObservedObject var caffeinator: Caffeinator

    var body: some View {
        Text(caffeinator.status)

        Divider()

        Button("Ligar sem limite") { caffeinator.start(seconds: nil) }
            .disabled(!caffeinator.hasOption)
        Menu("Ligar por...") {
            ForEach([15, 30, 60, 120, 240, 480], id: \.self) { minutes in
                Button(minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h") {
                    caffeinator.start(seconds: minutes * 60)
                }
            }
        }
        .disabled(!caffeinator.hasOption)
        Button("Desligar") { caffeinator.stop() }.disabled(!caffeinator.isActive)

        Divider()

        Toggle(isOn: $caffeinator.display) { Label("Manter a tela acesa", systemImage: "display") }
        Toggle(isOn: $caffeinator.idle) { Label("Impedir sono por inatividade", systemImage: "moon.zzz") }
        Toggle(isOn: $caffeinator.disk) { Label("Impedir sono do disco", systemImage: "internaldrive") }
        Toggle(isOn: $caffeinator.onAC) { Label("Impedir sono no carregador", systemImage: "powerplug") }

        Divider()

        Toggle("Abrir ao iniciar o Mac", isOn: Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { setOpenAtLogin($0) }
        ))
        Button("Sair") { NSApplication.shared.terminate(nil) }.keyboardShortcut("q")
    }

    private func setOpenAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Cafezinho: failed to change open at login: \(error)")
        }
        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        caffeinator.objectWillChange.send()
    }
}
