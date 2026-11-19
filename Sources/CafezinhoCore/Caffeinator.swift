import Combine
import Foundation

/// Owns the `caffeinate` process: starts, stops and restarts it as options change.
@MainActor
public final class Caffeinator: ObservableObject {
    @Published public var display: Bool { didSet { optionChanged("tela", display) } }
    @Published public var idle: Bool { didSet { optionChanged("inatividade", idle) } }
    @Published public var disk: Bool { didSet { optionChanged("disco", disk) } }
    @Published public var onAC: Bool { didSet { optionChanged("carregador", onAC) } }
    @Published public private(set) var isActive = false
    @Published public private(set) var endsAt: Date?
    @Published public private(set) var error: String?

    public var pid: Int32? { process?.processIdentifier }
    public var activeArguments: [String]? { process?.arguments }

    private var process: Process?
    private let defaults: UserDefaults
    private let executable: URL

    // Keys stay in Portuguese so preferences saved by v1.0 keep working.
    public init(
        defaults: UserDefaults = .standard,
        executable: URL = URL(fileURLWithPath: "/usr/bin/caffeinate")
    ) {
        self.defaults = defaults
        self.executable = executable
        display = defaults.object(forKey: "tela") as? Bool ?? true
        idle = defaults.object(forKey: "inatividade") as? Bool ?? true
        disk = defaults.object(forKey: "disco") as? Bool ?? false
        onAC = defaults.object(forKey: "carregador") as? Bool ?? true
    }

    // With no flag at all, caffeinate falls back to -i, which would contradict the unchecked options.
    public var hasOption: Bool { display || idle || disk || onAC }

    public var status: String {
        if let error { return error }
        guard hasOption else { return "Marque ao menos uma opção para ligar" }
        guard isActive else { return "Desligado: o Mac dorme normalmente" }
        guard let endsAt else { return "Ligado sem limite" }
        return "Ligado até \(endsAt.formatted(date: .omitted, time: .shortened))"
    }

    public static func arguments(
        display: Bool, idle: Bool, disk: Bool, onAC: Bool, seconds: Int?, ownerPID: Int32
    ) -> [String] {
        var args = [String]()
        if display { args.append("-d") }
        if idle { args.append("-i") }
        if disk { args.append("-m") }
        if onAC { args.append("-s") }
        if let seconds { args += ["-t", String(seconds)] }
        // caffeinate exits together with the app, so it never lingers keeping the Mac awake.
        args += ["-w", String(ownerPID)]
        return args
    }

    public func start(seconds: Int?) {
        stop()
        guard hasOption else { return }

        let new = Process()
        new.executableURL = executable
        new.arguments = Self.arguments(
            display: display, idle: idle, disk: disk, onAC: onAC,
            seconds: seconds, ownerPID: ProcessInfo.processInfo.processIdentifier)
        new.terminationHandler = { [weak self] finished in
            Task { @MainActor in
                guard let self, self.process === finished else { return }
                self.process = nil
                self.isActive = false
                self.endsAt = nil
            }
        }

        do {
            try new.run()
        } catch {
            self.error = "Falha ao ligar: \(error.localizedDescription)"
            return
        }
        error = nil
        process = new
        isActive = true
        endsAt = seconds.map { Date().addingTimeInterval(Double($0)) }
    }

    public func stop() {
        let old = process
        process = nil
        old?.terminate()
        error = nil
        isActive = false
        endsAt = nil
    }

    private func optionChanged(_ key: String, _ value: Bool) {
        defaults.set(value, forKey: key)
        guard isActive else { return }
        // Restart with the new options, keeping the remaining time.
        start(seconds: endsAt.map { max(1, Int($0.timeIntervalSinceNow.rounded())) })
    }
}
