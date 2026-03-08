import Foundation
import TrelloAPI

enum ClientFactoryError: Error, LocalizedError, Equatable, Sendable {
    case missingCredential(String)

    var errorDescription: String? {
        switch self {
        case .missingCredential(let name):
            return "Missing \(name). Set it in your environment or a .env file."
        }
    }
}

enum ClientFactory {
    static let apiKeyEnvVar = "TRELLO_API_KEY"
    static let apiTokenEnvVar = "TRELLO_API_TOKEN"

    static func makeClient(
        environment: [String: String]? = nil,
        paths: [String] = Environment.defaultPaths,
        httpClient: HTTPClient = URLSession.shared
    ) throws -> TrelloClient {
        let baseEnvironment = environment ?? ProcessInfo.processInfo.environment
        let resolvedEnvironment = try Environment.mergedEnvironment(
            base: baseEnvironment,
            paths: paths,
            requiredKeys: [apiKeyEnvVar, apiTokenEnvVar]
        )

        guard let apiKey = resolvedEnvironment[apiKeyEnvVar],
              !apiKey.isEmpty else {
            throw ClientFactoryError.missingCredential(apiKeyEnvVar)
        }
        guard let apiToken = resolvedEnvironment[apiTokenEnvVar],
              !apiToken.isEmpty else {
            throw ClientFactoryError.missingCredential(apiTokenEnvVar)
        }
        return TrelloClient(apiKey: apiKey, apiToken: apiToken, httpClient: httpClient)
    }
}
