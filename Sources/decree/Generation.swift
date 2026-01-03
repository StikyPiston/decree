import Foundation
import Yams

struct Commit: Codable {
    let from: Int?
    let timestamp: String
    let added: [String: [String]]
    let removed: [String: [String]]
    let autoUpgrade: Bool
    let upgradeRan: Bool
}

struct Generation {

    static let prevDir = NSString(string: "~/.prev-decrees").expandingTildeInPath
    static let currentSymlink = "\(prevDir)/current.yaml"

    // MARK: - Next generation number
    static func nextGenerationNumber() -> Int {
        try? FileManager.default.createDirectory(atPath: prevDir, withIntermediateDirectories: true)
        let files = (try? FileManager.default.contentsOfDirectory(atPath: prevDir)) ?? []
        let numbers = files.compactMap { Int($0.components(separatedBy: ".").first ?? "") }
        return (numbers.max() ?? 0) + 1
    }

    // MARK: - Save generation
    static func saveGeneration(config: Config, number: Int) throws {
        try FileManager.default.createDirectory(atPath: prevDir, withIntermediateDirectories: true)
        let path = "\(prevDir)/\(number).yaml"
        let yaml = try YAMLEncoder().encode(config)
        try yaml.write(toFile: path, atomically: true, encoding: .utf8)

        // Update symlink
        try? FileManager.default.removeItem(atPath: currentSymlink)
        try FileManager.default.createSymbolicLink(atPath: currentSymlink, withDestinationPath: path)
    }

    // MARK: - Write commit
    static func writeCommit(from previous: Int?, number: Int, added: [String: [String]], removed: [String: [String]], autoUpgrade: Bool, upgradeRan: Bool) throws {
        let commit = Commit(
            from: previous,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            added: added,
            removed: removed,
            autoUpgrade: autoUpgrade,
            upgradeRan: upgradeRan
        )
        let yaml = try YAMLEncoder().encode(commit)
        let path = "\(prevDir)/\(number).commit"
        try yaml.write(toFile: path, atomically: true, encoding: .utf8)
    }

    // MARK: - Load current generation config
    static func loadCurrentConfig() throws -> Config {
        let path = currentSymlink
        guard FileManager.default.fileExists(atPath: path) else { return Config(settings: nil, packages: [:]) }
        let yaml = try String(contentsOfFile: path)
        return try YAMLDecoder().decode(Config.self, from: yaml)
    }

    // MARK: - Load previous generation by number
    static func loadPrevious(number: Int) throws -> Config {
        let path = "\(prevDir)/\(number).yaml"
        let yaml = try String(contentsOfFile: path)
        return try YAMLDecoder().decode(Config.self, from: yaml)
    }
}
