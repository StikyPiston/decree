import Foundation

struct Config: Codable {
    struct Settings: Codable {
        var autoUpgrade: Bool?
    }

    var settings: Settings?
    var packages: [String: [String]] // managerName → [packageName]
}
