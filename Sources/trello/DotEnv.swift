import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// Lightweight `.env` file parser.
///
/// Parses files in the standard dotenv format:
/// - `KEY=VALUE` pairs (one per line)
/// - `#` comments and blank lines are ignored
/// - Values may be wrapped in single or double quotes (quotes are stripped)
/// - Inline comments after unquoted values are stripped
enum DotEnv {

    /// Parses the file at `path` and sets each key-value pair in the process
    /// environment. Existing environment variables are **not** overwritten.
    ///
    /// - Parameter path: Absolute or relative path to a `.env` file.
    /// - Throws: Only if the file exists but cannot be read.
    static func load(path: String) throws {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let contents = try String(contentsOf: url, encoding: .utf8)

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            guard let separatorIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = trimmed[trimmed.startIndex..<separatorIndex]
                .trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { continue }

            var value = trimmed[trimmed.index(after: separatorIndex)...]
                .trimmingCharacters(in: .whitespaces)

            // Strip matching surrounding quotes
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
               (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            } else {
                // Strip inline comments for unquoted values
                if let commentIndex = value.firstIndex(of: "#") {
                    value = value[value.startIndex..<commentIndex]
                        .trimmingCharacters(in: .whitespaces)
                }
            }

            // overwrite = 0 → don't overwrite existing env vars
            setenv(key, value, 0)
        }
    }
}
