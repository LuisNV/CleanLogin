import Foundation

enum APIError: Error {
    case transport
    case http(Int)
    case server(statusCode: Int, response: APIResponseMetadata)
    case invalidResponse
    case decoding
    case invalidURL
    case missingToken

    var statusCode: Int? {
        switch self {
        case .http(let status), .server(let status, _): return status
        default: return nil
        }
    }
}
