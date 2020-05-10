import Foundation

internal func camel2snake(_ string: String) -> String {
    var parts: [String] = []
    var current = String()
    for char in string {
        if !current.isEmpty, char.isUppercase, current.last != "_" {
            parts.append(current)
            current = String()
        }
        current.append(char.lowercased())
    }
    if !current.isEmpty {
        parts.append(current)
    }
    return parts.joined(separator: "_")
}
