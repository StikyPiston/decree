import Foundation

enum Colors: String {
    case red    = "\u{001B}[0;31m"
    case green  = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue   = "\u{001B}[0;34m"
    case cyan   = "\u{001B}[0;36m"
    case reset  = "\u{001B}[0;0m"
}

func colored(_ text: String, color: Colors) -> String {
    return "\(color.rawValue)\(text)\(Colors.reset.rawValue)"
}
