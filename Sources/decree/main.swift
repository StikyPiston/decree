import Foundation
import ArgumentParser
import Yams

// MARK: - Helpers to load configs/specs
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

// MARK: - Main CLI
struct Decree: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "decree",
        abstract: "Declarative package management CLI",
        subcommands: [Switch.self, Rollback.self, Upgrade.self],
        defaultSubcommand: Switch.self
    )
}

extension Decree {
    struct Switch: ParsableCommand {
        func run() throws {
            let currentConfig = try Generation.loadCurrentConfig()
            let desiredConfig = try loadConfig()
            let specs = try loadSpecs()

            let diff = computeDiff(current: currentConfig, desired: desiredConfig)

            print("Plan:")
            for (manager, pkgs) in diff.toInstall { for pkg in pkgs { print("  + \(manager): \(pkg)") } }
            for (manager, pkgs) in diff.toRemove { for pkg in pkgs { print("  - \(manager): \(pkg)") } }

            if diff.isEmpty {
                print("Nothing to do!")
                return
            }

            try Executor.switchPackages(diff: diff, specs: specs)

            var upgradeRan = false
            if desiredConfig.settings?.autoUpgrade == true {
                try Executor.autoUpgrade(specs: specs)
                upgradeRan = true
            }

            let nextGen = Generation.nextGenerationNumber()
            try Generation.saveGeneration(config: desiredConfig, number: nextGen)
            try Generation.writeCommit(
                from: currentConfig.packages.isEmpty ? nil : nextGen-1,
                number: nextGen,
                added: diff.toInstall,
                removed: diff.toRemove,
                autoUpgrade: desiredConfig.settings?.autoUpgrade ?? false,
                upgradeRan: upgradeRan
            )
        }
    }

    struct Rollback: ParsableCommand {
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

    struct Upgrade: ParsableCommand {
        func run() throws {
            let specs = try loadSpecs()
            try Executor.autoUpgrade(specs: specs)
        }
    }
}

Decree.main()
