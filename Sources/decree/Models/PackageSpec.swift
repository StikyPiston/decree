import Foundation

struct PackageSpec: Codable {
    struct Commands: Codable {
        let install: String
        let remove: String
        let upgrade_all: String?
    }

    let name: String
    let commands: Commands
}
