import Foundation
import ArgumentParser
import Yams

// MARK: - Top-level Decree command
struct Decree: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "decree",
        abstract: "Declaratively manage your *nix system",
        subcommands: [Switch.self, Rollback.self, Upgrade.self],
    )
}

// MARK: - Switch
struct Switch: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Apply the desired configuration.")

    func run() throws {
        let currentConfig = try Generation.loadCurrentConfig()
        let desiredConfig = try loadConfig()
        let specs = try loadSpecs()

        let diff = computeDiff(current: currentConfig, desired: desiredConfig)

        print(colored(" Plan:", color: .blue))
        for (manager, pkgs) in diff.toInstall { for pkg in pkgs { print(colored("  + \(manager): \(pkg)", color: .green)) } }
        for (manager, pkgs) in diff.toRemove  { for pkg in pkgs { print(colored("  - \(manager): \(pkg)", color: .red)) } }

        if diff.isEmpty {
            print(colored(" Nothing to do!", color: .green))
            return
        }

        try Executor.switchPackages(diff: diff, specs: specs)

        if desiredConfig.settings?.autoUpgrade == true {
            try Executor.autoUpgrade(specs: specs)
        }

        let nextGen = Generation.nextGenerationNumber()
        try Generation.saveGeneration(config: desiredConfig, number: nextGen)
        try Generation.writeCommit(
            from: currentConfig.packages.isEmpty ? nil : nextGen - 1,
            number: nextGen,
            added: diff.toInstall,
            removed: diff.toRemove,
            autoUpgrade: desiredConfig.settings?.autoUpgrade ?? false,
            upgradeRan: desiredConfig.settings?.autoUpgrade ?? false
        )
    }
}

// MARK: - Rollback
struct Rollback: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Rollback to a previous generation.")

    @Argument(help: "Generation number to roll back to")
    var generation: Int

    func run() throws {
        let currentConfig = try Generation.loadCurrentConfig()
        let targetConfig = try Generation.loadPrevious(number: generation)
        let specs = try loadSpecs()

        try Executor.rollback(to: targetConfig, currentConfig: currentConfig, specs: specs)

        let diff = computeDiff(current: currentConfig, desired: targetConfig)
        let nextGen = Generation.nextGenerationNumber()
        try Generation.saveGeneration(config: targetConfig, number: nextGen)
        try Generation.writeCommit(
            from: generation,
            number: nextGen,
            added: diff.toInstall,
            removed: diff.toRemove,
            autoUpgrade: false,
            upgradeRan: false
        )
    }
}

// MARK: - Upgrade
struct Upgrade: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Upgrade all package managers.")

    func run() throws {
        let specs = try loadSpecs()
        try Executor.autoUpgrade(specs: specs)
    }
}

// MARK: - Helpers
func loadConfig() throws -> Config {
    let path = NSString(string: "~/.config/decree/config.yaml").expandingTildeInPath
    let yaml = try String(contentsOfFile: path, encoding: .utf8)
    return try YAMLDecoder().decode(Config.self, from: yaml)
}

func loadSpecs() throws -> [String: PackageSpec] {
    let dir = NSString(string: "~/.config/decree/spec").expandingTildeInPath
    let files = try FileManager.default.contentsOfDirectory(atPath: dir)
        .filter { $0.hasSuffix(".yaml") }

    var specs: [String: PackageSpec] = [:]
    for file in files {
        let path = "\(dir)/\(file)"
        let yaml = try String(contentsOfFile: path, encoding: .utf8)
        let spec = try YAMLDecoder().decode(PackageSpec.self, from: yaml)
        specs[spec.name] = spec
    }
    return specs
}

// MARK: - Run CLI
Decree.main()
