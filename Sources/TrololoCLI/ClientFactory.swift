import Foundation
import TrelloAPI

enum ClientFactory {
    static let apiKeyEnvVar = "TRELLO_API_KEY"
    static let apiTokenEnvVar = "TRELLO_API_TOKEN"

    static func makeClient() throws -> TrelloClient {
        Environment.load()

        guard let apiKey = ProcessInfo.processInfo.environment[apiKeyEnvVar],
              !apiKey.isEmpty else {
            throw TrelloAPIError.missingCredentials
        }
        guard let apiToken = ProcessInfo.processInfo.environment[apiTokenEnvVar],
              !apiToken.isEmpty else {
            throw TrelloAPIError.missingCredentials
        }
        return TrelloClient(apiKey: apiKey, apiToken: apiToken)
    }
}
