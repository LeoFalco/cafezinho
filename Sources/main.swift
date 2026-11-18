import ServiceManagement
import SwiftUI

@main
struct CafezinhoApp: App {
    @StateObject private var cafe = Cafe()

    var body: some Scene {
        MenuBarExtra {
            MenuCafe(cafe: cafe)
        } label: {
            Image(systemName: cafe.ativo ? "cup.and.saucer.fill" : "cup.and.saucer")
        }
    }
}

struct MenuCafe: View {
    @ObservedObject var cafe: Cafe

    var body: some View {
        Text(cafe.status)

        Divider()

        Button("Ligar sem limite") { cafe.ligar(segundos: nil) }.disabled(!cafe.temOpcao)
        Menu("Ligar por...") {
            ForEach([15, 30, 60, 120, 240, 480], id: \.self) { minutos in
                Button(minutos < 60 ? "\(minutos) min" : "\(minutos / 60) h") {
                    cafe.ligar(segundos: minutos * 60)
                }
            }
        }.disabled(!cafe.temOpcao)
        Button("Desligar") { cafe.desligar() }.disabled(!cafe.ativo)

        Divider()

        Toggle("Manter a tela acesa (-d)", isOn: $cafe.tela)
        Toggle("Impedir sono por inatividade (-i)", isOn: $cafe.inatividade)
        Toggle("Impedir sono do disco (-m)", isOn: $cafe.disco)
        Toggle("Impedir sono no carregador (-s)", isOn: $cafe.carregador)

        Divider()

        Toggle("Abrir ao iniciar o Mac", isOn: Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { cafe.abrirAoIniciar($0) }
        ))
        Button("Sair") { NSApplication.shared.terminate(nil) }.keyboardShortcut("q")
    }
}

@MainActor
final class Cafe: ObservableObject {
    @Published var tela = Cafe.lerOpcao("tela", padrao: true) { didSet { opcaoMudou("tela", tela) } }
    @Published var inatividade = Cafe.lerOpcao("inatividade", padrao: true) { didSet { opcaoMudou("inatividade", inatividade) } }
    @Published var disco = Cafe.lerOpcao("disco", padrao: false) { didSet { opcaoMudou("disco", disco) } }
    @Published var carregador = Cafe.lerOpcao("carregador", padrao: true) { didSet { opcaoMudou("carregador", carregador) } }
    @Published private(set) var ativo = false
    @Published private(set) var fim: Date?

    @Published private(set) var erro: String?

    private var processo: Process?

    // Sem nenhuma flag o caffeinate assume -i, o que contradiria as opções marcadas.
    var temOpcao: Bool { tela || inatividade || disco || carregador }

    var status: String {
        if let erro { return erro }
        guard temOpcao else { return "Marque ao menos uma opção para ligar" }
        guard ativo else { return "Desligado: o Mac dorme normalmente" }
        guard let fim else { return "Ligado sem limite" }
        return "Ligado até \(fim.formatted(date: .omitted, time: .shortened))"
    }

    func ligar(segundos: Int?) {
        desligar()
        guard temOpcao else { return }

        var argumentos = [String]()
        if tela { argumentos.append("-d") }
        if inatividade { argumentos.append("-i") }
        if disco { argumentos.append("-m") }
        if carregador { argumentos.append("-s") }
        if let segundos { argumentos += ["-t", String(segundos)] }
        // O caffeinate morre junto com o app, então nunca fica órfão segurando o Mac acordado.
        argumentos += ["-w", String(ProcessInfo.processInfo.processIdentifier)]

        let novo = Process()
        novo.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        novo.arguments = argumentos
        novo.terminationHandler = { [weak self] encerrado in
            Task { @MainActor in
                guard let self, self.processo === encerrado else { return }
                self.processo = nil
                self.ativo = false
                self.fim = nil
            }
        }

        do {
            try novo.run()
        } catch {
            erro = "Falha ao ligar: \(error.localizedDescription)"
            return
        }
        erro = nil
        processo = novo
        ativo = true
        fim = segundos.map { Date().addingTimeInterval(Double($0)) }
    }

    func desligar() {
        let antigo = processo
        processo = nil
        antigo?.terminate()
        ativo = false
        fim = nil
    }

    func abrirAoIniciar(_ ligado: Bool) {
        do {
            if ligado { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Cafezinho: falha ao alterar a abertura ao iniciar: \(error)")
        }
        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        objectWillChange.send()
    }

    private func opcaoMudou(_ chave: String, _ valor: Bool) {
        UserDefaults.standard.set(valor, forKey: chave)
        guard ativo else { return }
        // Religa com as opções novas, mantendo o tempo que faltava.
        ligar(segundos: fim.map { max(1, Int($0.timeIntervalSinceNow)) })
    }

    private static func lerOpcao(_ chave: String, padrao: Bool) -> Bool {
        UserDefaults.standard.object(forKey: chave) as? Bool ?? padrao
    }
}
