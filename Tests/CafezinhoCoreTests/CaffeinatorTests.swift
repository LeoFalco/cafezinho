import Foundation
import Testing
@testable import CafezinhoCore

@MainActor
@Suite(.serialized)
struct CaffeinatorTests {
    private func makeCaffeinator(executable: String = "/usr/bin/caffeinate") -> Caffeinator {
        let defaults = UserDefaults(suiteName: "cafezinho-tests-\(UUID().uuidString)")!
        return Caffeinator(defaults: defaults, executable: URL(fileURLWithPath: executable))
    }

    private func isAlive(_ pid: Int32) -> Bool { kill(pid, 0) == 0 }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<50 where !condition() { try await Task.sleep(for: .milliseconds(100)) }
    }

    @Test func buildsArgumentsFromOptions() {
        let args = Caffeinator.arguments(
            display: true, idle: false, disk: true, onAC: true, seconds: 900, ownerPID: 42)
        #expect(args == ["-d", "-m", "-s", "-t", "900", "-w", "42"])
    }

    @Test func omitsTimerWhenUnlimited() {
        let args = Caffeinator.arguments(
            display: false, idle: true, disk: false, onAC: false, seconds: nil, ownerPID: 7)
        #expect(args == ["-i", "-w", "7"])
    }

    @Test func defaultsToDisplayIdleAndAC() {
        let caffeinator = makeCaffeinator()
        #expect(caffeinator.display && caffeinator.idle && caffeinator.onAC)
        #expect(!caffeinator.disk)
    }

    @Test func startsAndStopsRealProcess() async throws {
        let caffeinator = makeCaffeinator()
        caffeinator.start(seconds: nil)
        let pid = try #require(caffeinator.pid)
        #expect(caffeinator.isActive)
        #expect(isAlive(pid))
        #expect(caffeinator.activeArguments?.contains("-w") == true)
        #expect(caffeinator.status == "Ligado sem limite")

        caffeinator.stop()
        try await waitUntil { !isAlive(pid) }
        #expect(!caffeinator.isActive)
        #expect(!isAlive(pid))
    }

    @Test func turnsOffWhenTimerEnds() async throws {
        let caffeinator = makeCaffeinator()
        caffeinator.start(seconds: 1)
        #expect(caffeinator.isActive)
        #expect(caffeinator.status.hasPrefix("Ligado até"))

        try await waitUntil { !caffeinator.isActive }
        #expect(!caffeinator.isActive)
        #expect(caffeinator.endsAt == nil)
        #expect(caffeinator.status == "Desligado: o Mac dorme normalmente")
    }

    @Test func restartsWithNewOptionKeepingRemainingTime() async throws {
        let caffeinator = makeCaffeinator()
        caffeinator.start(seconds: 600)
        let oldPID = try #require(caffeinator.pid)

        caffeinator.disk = true
        let args = try #require(caffeinator.activeArguments)
        #expect(args.contains("-m"))
        let timer = try #require(args.firstIndex(of: "-t")).advanced(by: 1)
        #expect((598...600).contains(Int(args[timer])!))
        #expect(caffeinator.pid != oldPID)
        try await waitUntil { !isAlive(oldPID) }
        #expect(!isAlive(oldPID))
        #expect(caffeinator.isActive)
        caffeinator.stop()
    }

    @Test func refusesToStartWithoutOptions() {
        let caffeinator = makeCaffeinator()
        caffeinator.display = false
        caffeinator.idle = false
        caffeinator.onAC = false
        caffeinator.start(seconds: nil)
        #expect(!caffeinator.isActive)
        #expect(caffeinator.status == "Marque ao menos uma opção para ligar")
    }

    @Test func uncheckingLastOptionWhileActiveTurnsOff() async throws {
        let caffeinator = makeCaffeinator()
        caffeinator.idle = false
        caffeinator.onAC = false
        caffeinator.start(seconds: nil)
        let pid = try #require(caffeinator.pid)

        caffeinator.display = false
        #expect(!caffeinator.isActive)
        try await waitUntil { !isAlive(pid) }
        #expect(!isAlive(pid))
    }

    @Test func reportsErrorWhenExecutableIsMissing() {
        let caffeinator = makeCaffeinator(executable: "/nonexistent/caffeinate")
        caffeinator.start(seconds: nil)
        #expect(!caffeinator.isActive)
        #expect(caffeinator.status.hasPrefix("Falha ao ligar"))
    }

    @Test func persistsOptions() {
        let defaults = UserDefaults(suiteName: "cafezinho-tests-\(UUID().uuidString)")!
        Caffeinator(defaults: defaults).disk = true
        #expect(Caffeinator(defaults: defaults).disk)
    }
}
