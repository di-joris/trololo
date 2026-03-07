import Foundation

/// Loads environment variables from `.env` files.
///
/// Lookup order:
/// 1. `.env` in the current working directory
/// 2. `~/.config/trololo/.env` (fallback)
///
/// Missing files are silently ignored. Real environment variables always
/// take priority over values from `.env` files.
enum Environment {

    static func load() {
        let paths = [
            ".env",
            NSString("~/.config/trololo/.env").expandingTildeInPath,
        ]

        for path in paths {
            try? DotEnv.load(path: path)
        }
    }
}
