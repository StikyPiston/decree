import Foundation

struct Executor {

    /// Execute a shell command and return its exit code
    static func runShell(_ command: String) throws -> Int32 {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/bash")

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print(output)
        }

        return task.terminationStatus
    }

    /// Install and remove packages according to a diff
    static func switchPackages(diff: DiffResult, specs: [String: PackageSpec]) throws {
        var journal: [PackageAction] = []

        // Remove packages first
        for (manager, packages) in diff.toRemove {
            guard let spec = specs[manager] else { continue }
            for pkg in packages {
                let command = spec.commands.remove.replacingOccurrences(of: "{{package}}", with: pkg)
                print(" \(command)")
                guard try runShell(command) == 0 else {
                    print(" Failed to remove \(pkg) from \(manager), rolling back...")
                    try rollbackJournal(journal, specs: specs)
                    throw ExecutorError.failed("Failed to remove \(pkg) from \(manager)")
                }
                journal.append(.init(manager: manager, package: pkg, action: "remove"))
            }
        }

        // Install packages
        for (manager, packages) in diff.toInstall {
            guard let spec = specs[manager] else { continue }
            for pkg in packages {
                let command = spec.commands.install.replacingOccurrences(of: "{{package}}", with: pkg)
                print(" \(command)")
                guard try runShell(command) == 0 else {
                    print(" Failed to install \(pkg) on \(manager), rolling back...")
                    try rollbackJournal(journal, specs: specs)
                    throw ExecutorError.failed("Failed to install \(pkg) on \(manager)")
                }
                journal.append(.init(manager: manager, package: pkg, action: "install"))
            }
        }
    }

    /// Rollback packages based on a previous config
    static func rollback(to targetConfig: Config, currentConfig: Config, specs: [String: PackageSpec]) throws {
        let diff = computeDiff(current: currentConfig, desired: targetConfig)
        try switchPackages(diff: diff, specs: specs)
    }

    /// Run all package managers' upgrade commands
    static func autoUpgrade(specs: [String: PackageSpec]) throws {
        for (manager, spec) in specs {
            guard let cmd = spec.commands.upgrade_all else { continue }
            print("󰚰 Running autoUpgrade for \(manager): \(cmd)")
            guard try runShell(cmd) == 0 else {
                throw ExecutorError.failed("Failed autoUpgrade for \(manager)")
            }
        }
    }

    /// Rollback previously executed actions in case of failure
    private static func rollbackJournal(_ journal: [PackageAction], specs: [String: PackageSpec]) throws {
        for action in journal.reversed() {
            guard let spec = specs[action.manager] else { continue }
            let cmd: String
            switch action.action {
            case "install":
                cmd = spec.commands.remove.replacingOccurrences(of: "{{package}}", with: action.package)
            case "remove":
                cmd = spec.commands.install.replacingOccurrences(of: "{{package}}", with: action.package)
            default:
                continue
            }
            print(" Rolling back: \(cmd)")
            _ = try runShell(cmd)
        }
    }

    // MARK: - Errors
    enum ExecutorError: Error {
        case failed(String)
    }

    /// Represents an action performed in a transaction
    struct PackageAction {
        let manager: String
        let package: String
        let action: String // "install" or "remove"
    }
}
