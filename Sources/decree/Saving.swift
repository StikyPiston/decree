import Foundation

func saveGeneration(config: Config, number: Int) throws {
    let dir = NSString(string: "~/.prev-decrees").expandingTildeInPath
    let path = "\(dir)/\(number).yaml"
    let yaml = try YAMLEncoder().encode(config)
    try yaml.write(toFile: path, atomically: true, encoding: .utf8)

    let symlink = "\(dir)/current.yaml"
    try? FileManager.default.removeItem(atPath: symlink)
    try FileManager.default.createSymbolicLink(atPath: symlink, withDestinationPath: path)
}
