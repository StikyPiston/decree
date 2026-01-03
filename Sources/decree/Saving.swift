import Foundation
import Yams

func saveGeneration(config: Config, number: Int) throws {
    let dir = NSString(string: "~/.prev-decrees").expandingTildeInPath
    let path = "\(dir)/\(number).yaml"
    let yaml = try YAMLEncoder().encode(config)
    try yaml.write(toFile: path, atomically: true, encoding: .utf8)

    let symlink = "\(dir)/current.yaml"
    try? FileManager.default.removeItem(atPath: symlink)
    try FileManager.default.createSymbolicLink(atPath: symlink, withDestinationPath: path)
}

struct Commit: Codable {
    let from: Int?
    let timestamp: String
    let added: [String: [String]]
    let removed: [String: [String]]
    let autoUpgrade: Bool
    let upgradeRan: Bool
}

func writeCommit(from previous: Int?, number: Int, added: [String: [String]], removed: [String: [String]], autoUpgrade: Bool, upgradeRan: Bool) throws {
    let commit = Commit(
        from: previous,
        timestamp: ISO8601DateFormatter().string(from: Date()),
        added: added,
        removed: removed,
        autoUpgrade: autoUpgrade,
        upgradeRan: upgradeRan
    )
    let yaml = try YAMLEncoder().encode(commit)
    let path = NSString(string: "~/.prev-decrees/\(number).commit").expandingTildeInPath
    try yaml.write(toFile: path, atomically: true, encoding: .utf8)
}
