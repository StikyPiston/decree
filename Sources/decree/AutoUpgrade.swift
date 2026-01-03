import Foundation

func runAutoUpgrade(specs: [String: PackageSpec]) throws {
    for (_, spec) in specs {
        guard let cmd = spec.commands.upgrade else { continue }
        print("→ Running autoUpgrade: \(cmd)")
        guard try runShell(cmd) == 0 else { throw NSError() }
    }
}
