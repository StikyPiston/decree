import Foundation

struct DiffResult {
    var toInstall: [String: [String]] = [:]
    var toRemove: [String: [String]] = [:]
    
    var isEmpty: Bool { toInstall.isEmpty && toRemove.isEmpty }
}

func computeDiff(current: Config, desired: Config) -> DiffResult{
    var result   = DiffResult()
    var managers = Set(current.packages.keys).union(desired.packages.keys)

    for manager in managers {
        let currentPkgs = Set(current.packages[manager] ?? [])
        let desiredPkgs = Set(desired.packages[manager] ?? [])

        let install = desiredPkgs.subtracting(currentPkgs)
        let remove  = currentPkgs.subtracting(desiredPkgs)

        if !install.isEmpty { result.toInstall[manager] = Array(install).sorted() }
        if !remove.isEmpty  { result.toRemove[manager]  = Array(remove).sorted() }
    }

    return result
}
