import Foundation
import Yams

func loadConfig() throws -> Config {
    let path = NSString(string: "~/.config/decree/config.yaml").expandingTildeInPath
    let yaml = try String(contentsOfFile: path)
    return try YAMLDecoder().decode(Config.self, from: yaml)
}

func loadSpecs() throws -> [String: PackageSpec] {
    let specDir = NSString(string: "~/.config/decree/spec").expandingTildeInPath
    let files   = try FileManager.default.contentsOfDirectory(atPath: specDir)
    var specs: [String: PackageSpec] = [:]

    for file in files where file.hasSuffix(".yaml") {
        let path = specDir + "/" + file
        let yaml = try String(contentsOfFile: path)
        let spec = try YAMLDecoder().decode(PackageSpec.self, from: yaml)

        specs[spec.name] = spec
    }

    return specs
}
