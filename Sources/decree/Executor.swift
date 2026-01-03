import Foundation

struct ExecutedAction {
    let manager: String
    let package: String
    let action: String
}

struct Executor {

    static func switchPackages(diff: DiffResult, specs: [String: PackageSpec]) throws {
        var journal: [ExecutedAction] = []

        func rollback() {
            print("Rolling back…")
            for action in journal.reversed() {
                guard let spec = specs[action.manager] else { continue }
                let command = action.action == "install"
                    ? spec.commands.remove.replacingOccurrences(of: "{{package}}", with: action.package)
                    : spec.commands.install.replacingOccurrences(of: "{{package}}", with: action.package)
                _ = try? runShell(command)
            }
        }

        do {
            for (manager, pkgs) in diff.toInstall {
                guard let spec = specs[manager] else { continue }
                for pkg in pkgs {
                    let command = spec.commands.install.replacingOccurrences(of: "{{package}}", with: pkg)
                    print("→ \(command)")
                    guard try runShell(command) == 0 else { throw NSError() }
                    journal.append(.init(manager: manager, package: pkg, action: "install"))
                }
            }

            for (manager, pkgs) in diff.toRemove {
                guard let spec = specs[manager] else { continue }
                for pkg in pkgs {
                    let command = spec.commands.remove.replacingOccurrences(of: "{{package}}", with: pkg)
                    print("→ \(command)")
                    guard try runShell(command) == 0 else { throw NSError() }
                    journal.append(.init(manager: manager, package: pkg, action: "remove"))
                }
            }
        } catch {
            rollback()
            throw error
        }
    }

    static func rollback(to previousConfig: Config, currentConfig: Config, specs: [String: PackageSpec]) throws {
        let diff = computeDiff(current: currentConfig, desired: previousConfig)
        print("Rollback plan:")
        for (manager, pkgs) in diff.toInstall { for pkg in pkgs { print("  + \(manager): \(pkg)") } }
        for (manager, pkgs) in diff.toRemove { for pkg in pkgs { print("  - \(manager): \(pkg)") } }
        try switchPackages(diff: diff, specs: specs)
    }

    static func autoUpgrade(specs: [String: PackageSpec]) throws {
        for (_, spec) in specs {
            guard let cmd: String? = spec.commands.upgrade else { continue }
            print("→ Running autoUpgrade: \(cmd)")
            guard try runShell(cmd) == 0 else { throw NSError() }
        }
    }

    @discardableResult
    static func runShell(_ command: String) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            print(stdout)
            print(stderr)
        }

        return process.terminationStatus
    }
}
