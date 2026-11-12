import Foundation

struct AppConfiguration {
    enum Mode: String { case mock, localAPI, remoteAPI }
    let mode: Mode
    let baseURL: URL?

    var title: String {
        switch mode {
        case .mock: return "Chế độ học thử"
        case .localAPI: return "Máy chủ thử nghiệm"
        case .remoteAPI: return "Máy chủ của bạn"
        }
    }

    var tokenNamespace: String {
        // Tách token giữa mock, local và từng base URL.
        "com.example.CleanLogin.\(mode.rawValue).\(baseURL?.absoluteString ?? "demo")"
    }

    static func load(environment: [String: String] = ProcessInfo.processInfo.environment) throws -> AppConfiguration {
        let rawMode = environment["AUTH_MODE"] ?? "mock"
        guard let mode = Mode(rawValue: rawMode) else { throw ConfigurationError.invalidMode }
        switch mode {
        case .mock:
            return AppConfiguration(mode: mode, baseURL: nil)
        case .localAPI:
            return AppConfiguration(mode: mode, baseURL: URL(string: "http://127.0.0.1:8081/api/v1/")!)
        case .remoteAPI:
            guard let text = environment["API_BASE_URL"],
                  let url = URL(string: text), url.scheme == "https",
                  let host = url.host, !host.isEmpty, host != "api.example.com",
                  url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else {
                throw ConfigurationError.invalidBaseURL
            }
            return AppConfiguration(mode: mode, baseURL: url)
        }
    }

    enum ConfigurationError: LocalizedError {
        case invalidMode, invalidBaseURL
        var errorDescription: String? {
            switch self {
            case .invalidMode: return "AUTH_MODE phải là mock, localAPI hoặc remoteAPI."
            case .invalidBaseURL: return "Đặt API_BASE_URL thành URL HTTPS backend của bạn trong Edit Scheme → Run → Arguments → Environment Variables."
            }
        }
    }
}
