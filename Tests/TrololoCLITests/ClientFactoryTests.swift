import Foundation
import Testing
@testable import TrololoCLI

@Suite("ClientFactory")
struct ClientFactoryTests {
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

    @Test("makeClient throws when the API key is missing")
    func missingAPIKey() {
        #expect(throws: ClientFactoryError.missingCredential(ClientFactory.apiKeyEnvVar)) {
            try ClientFactory.makeClient(environment: [
                ClientFactory.apiTokenEnvVar: "token-123",
            ], paths: [])
        }
    }

    @Test("makeClient throws when the API token is missing")
    func missingAPIToken() {
        #expect(throws: ClientFactoryError.missingCredential(ClientFactory.apiTokenEnvVar)) {
            try ClientFactory.makeClient(environment: [
                ClientFactory.apiKeyEnvVar: "key-123",
            ], paths: [])
        }
    }

    @Test("makeClient builds an authenticated Trello client from injected credentials")
    func makeClientUsesInjectedCredentials() throws {
        let client = try ClientFactory.makeClient(environment: [
            ClientFactory.apiKeyEnvVar: "key-123",
            ClientFactory.apiTokenEnvVar: "token-456",
        ], paths: [])

        let request = try client.makeRequest(path: "/members/me")
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(components.queryItems)

        #expect(queryItems.contains(URLQueryItem(name: "key", value: "key-123")))
        #expect(queryItems.contains(URLQueryItem(name: "token", value: "token-456")))
    }

    @Test("makeClient can merge an injected environment with dotenv fallbacks")
    func makeClientMergesEnvironmentWithDotEnv() throws {
        let contents = "TRELLO_API_TOKEN=dotenv-token"

        try withTempDotEnv(contents: contents) { path in
            let client = try ClientFactory.makeClient(
                environment: [ClientFactory.apiKeyEnvVar: "env-key"],
                paths: [path]
            )

            let request = try client.makeRequest(path: "/members/me")
            let url = try #require(request.url)
            let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let queryItems = try #require(components.queryItems)

            #expect(queryItems.contains(URLQueryItem(name: "key", value: "env-key")))
            #expect(queryItems.contains(URLQueryItem(name: "token", value: "dotenv-token")))
        }
    }
}
