import Foundation

struct PackageSpec: Codable {
    struct Commands: Codable {
        let install: String
        let remove: String
        let upgrade: String
    }

    struct Detection: Codable {
        let command: String
    }

    let name: String
    let commands: Commands
    let detection: Detection?
}
