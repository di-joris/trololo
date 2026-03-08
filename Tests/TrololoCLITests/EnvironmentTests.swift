import Foundation
import Testing
@testable import TrololoCLI

@Suite("Environment")
struct EnvironmentTests {
    private func withTempDotEnv(contents: String, perform: (String) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let path = directory.appendingPathComponent(".env").path
        try contents.write(toFile: path, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        try perform(path)
    }

    @Test("mergedEnvironment uses .env values without overwriting explicit environment values")
    func mergedEnvironmentPreservesExplicitValues() throws {
        let contents = """
        TRELLO_API_KEY=dotenv-key
        TRELLO_API_TOKEN=dotenv-token
        """

        try withTempDotEnv(contents: contents) { path in
            let merged = try Environment.mergedEnvironment(
                base: [ClientFactory.apiKeyEnvVar: "env-key"],
                paths: [path]
            )

            #expect(merged[ClientFactory.apiKeyEnvVar] == "env-key")
            #expect(merged[ClientFactory.apiTokenEnvVar] == "dotenv-token")
        }
    }

    @Test("mergedEnvironment surfaces unreadable dotenv paths")
    func mergedEnvironmentUnreadableFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let path = directory.path
        #expect(throws: EnvironmentError.unreadableFile(path)) {
            try Environment.mergedEnvironment(paths: [path])
        }
    }

    @Test("mergedEnvironment skips unreadable fallback paths once required credentials are resolved")
    func mergedEnvironmentStopsAfterResolvingRequiredCredentials() throws {
        let goodContents = """
        TRELLO_API_KEY=dotenv-key
        TRELLO_API_TOKEN=dotenv-token
        """

        let unreadableDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: unreadableDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: unreadableDirectory)
        }

        try withTempDotEnv(contents: goodContents) { path in
            let merged = try Environment.mergedEnvironment(
                paths: [path, unreadableDirectory.path],
                requiredKeys: [ClientFactory.apiKeyEnvVar, ClientFactory.apiTokenEnvVar]
            )

            #expect(merged[ClientFactory.apiKeyEnvVar] == "dotenv-key")
            #expect(merged[ClientFactory.apiTokenEnvVar] == "dotenv-token")
        }
    }

    @Test("mergedEnvironment can skip dotenv paths when required credentials are already in the base environment")
    func mergedEnvironmentSkipsPathsWhenBaseAlreadyHasCredentials() throws {
        let unreadableDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: unreadableDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: unreadableDirectory)
        }

        let merged = try Environment.mergedEnvironment(
            base: [
                ClientFactory.apiKeyEnvVar: "env-key",
                ClientFactory.apiTokenEnvVar: "env-token",
            ],
            paths: [unreadableDirectory.path],
            requiredKeys: [ClientFactory.apiKeyEnvVar, ClientFactory.apiTokenEnvVar]
        )

        #expect(merged[ClientFactory.apiKeyEnvVar] == "env-key")
        #expect(merged[ClientFactory.apiTokenEnvVar] == "env-token")
    }

    // MARK: - Base Environment Contract
    // This test documents and validates the complete environment-loading contract.
    // The contract specifies:
    // 1. Resolution order: base (process env) → .env (cwd) → ~/.config/trololo/.env
    // 2. Priority: base environment values always override .env values (no overwriting)
    // 3. Early termination: stop processing paths once all requiredKeys are resolved
    // 4. Error handling: missing files are ignored; unreadable files throw only if needed
    // 5. Validation: both key and token must be non-empty strings for client creation

    @Test("Base environment resolution with fallback chain")
    func baseEnvironmentResolution() throws {
        let fallback1Contents = """
        CUSTOM_VAR=fallback1-value
        TRELLO_API_KEY=fallback1-key
        """

        let fallback2Contents = """
        CUSTOM_VAR=fallback2-value
        TRELLO_API_TOKEN=fallback2-token
        """

        try withTempDotEnv(contents: fallback1Contents) { path1 in
            try withTempDotEnv(contents: fallback2Contents) { path2 in
                // Base environment has some values that should NOT be overwritten
                let baseEnv = [
                    "BASE_VAR": "base-value",
                    "CUSTOM_VAR": "base-custom",  // Should override fallback values
                ]

                let merged = try Environment.mergedEnvironment(
                    base: baseEnv,
                    paths: [path1, path2],
                    requiredKeys: [ClientFactory.apiKeyEnvVar, ClientFactory.apiTokenEnvVar]
                )

                // Verify priority: base > path1 > path2
                #expect(merged["BASE_VAR"] == "base-value", "Base variables are preserved")
                #expect(merged["CUSTOM_VAR"] == "base-custom", "Base overrides .env values")
                #expect(merged[ClientFactory.apiKeyEnvVar] == "fallback1-key", "First fallback path provides missing keys")
                #expect(merged[ClientFactory.apiTokenEnvVar] == "fallback2-token", "Second fallback path provides remaining keys")
            }
        }
    }
}
