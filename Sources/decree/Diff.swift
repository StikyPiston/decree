import Foundation

/// Represents the differences between two configurations
struct DiffResult {
    var toInstall: [String: [String]] = [:] // manager -> packages
    var toRemove: [String: [String]] = [:] // manager -> packages

    var isEmpty: Bool {
        toInstall.isEmpty && toRemove.isEmpty
    }
}

/// Compute the difference between the current and desired config
func computeDiff(current: Config, desired: Config) -> DiffResult {
    var diff = DiffResult()

    // Loop through all package managers
    let managers = Set(current.packages.keys).union(desired.packages.keys)
    for manager in managers {
        let currentPkgs = Set(current.packages[manager] ?? [])
        let desiredPkgs = Set(desired.packages[manager] ?? [])

        let install = desiredPkgs.subtracting(currentPkgs)
        let remove = currentPkgs.subtracting(desiredPkgs)

        if !install.isEmpty {
            diff.toInstall[manager] = Array(install).sorted()
        }
        if !remove.isEmpty {
            diff.toRemove[manager] = Array(remove).sorted()
        }
    }

    return diff
}
