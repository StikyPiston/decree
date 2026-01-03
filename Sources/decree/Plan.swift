import Foundation

func printPlan(_ diff: DiffResult) {
    print("Plan:")
    for (manager, pkgs) in diff.toInstall { for pkg in pkgs { print("  + \(manager): \(pkg)") } }
    for (manager, pkgs) in diff.toRemove { for pkg in pkgs { print("  - \(manager): \(pkg)") } }
}
