import Foundation

enum EnvironmentError: Error, LocalizedError, Equatable, Sendable {
    case unreadableFile(String)

    var errorDescription: String? {
        switch self {
        case .unreadableFile(let path):
            return "Failed to read .env file at \(path)."
        }
    }
}

/// Resolves environment values from process env and `.env` files.
///
/// Lookup order:
/// 1. `.env` in the current working directory
/// 2. `$XDG_CONFIG_HOME/trololo/env` (fallback; defaults to `~/.config/trololo/env`)
///
/// Missing files are ignored. Real environment variables always take priority
/// over values from `.env` files. Existing but unreadable files surface as
/// errors while the CLI is still resolving missing required values.
enum Environment {
    static var defaultPaths: [String] {
        let xdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
            ?? NSString("~/.config").expandingTildeInPath
        return [
            ".env",
            "\(xdgConfigHome)/trololo/env",
        ]
    }

    static func mergedEnvironment(
        base: [String: String] = ProcessInfo.processInfo.environment,
        paths: [String] = defaultPaths,
        requiredKeys: Set<String> = []
    ) throws -> [String: String] {
        var environment = base
        if containsRequiredKeys(in: environment, requiredKeys: requiredKeys) {
            return environment
        }

        for path in paths {
            do {
                let values = try DotEnv.values(path: path)
                for (key, value) in values where environment[key] == nil {
                    environment[key] = value
                }
                if containsRequiredKeys(in: environment, requiredKeys: requiredKeys) {
                    return environment
                }
            } catch {
                throw EnvironmentError.unreadableFile(path)
            }
        }

        return environment
    }

    private static func containsRequiredKeys(
        in environment: [String: String],
        requiredKeys: Set<String>
    ) -> Bool {
        guard !requiredKeys.isEmpty else { return false }
        return requiredKeys.allSatisfy { key in
            guard let value = environment[key] else { return false }
            return !value.isEmpty
        }
    }
}
