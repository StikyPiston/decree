import Foundation

func nextGenerationNumber() -> Int {
    let dir = NSString(string: "~/.prev-decrees").expandingTildeInPath
    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    let files = (try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? []
    let numbers = files.compactMap { Int($0.components(separatedBy: ".").first ?? "") }
    return (numbers.max() ?? 0) + 1
}
