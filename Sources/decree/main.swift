import Foundation
import ArgumentParser
import Yams

struct Decree: ParsableCommand {
    static var configuration = CommandConfiguration(
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

            // Save new generation after rollback
            let nextGen = Generation.nextGenerationNumber()
            try Generation.saveGeneration(config: targetConfig, number: nextGen)
            try Generation.writeCommit(
                from: generation,
                number: nextGen,
                added: computeDiff(current: currentConfig, desired: targetConfig).toInstall,
                removed: computeDiff(current: currentConfig, desired: targetConfig).toRemove,
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
