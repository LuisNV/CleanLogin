import Foundation
import Alamofire

/// Client HTTP dùng chung cho mọi feature.
///
/// Đây là nơi DUY NHẤT xử lý refresh token:
/// 1. Request cần đăng nhập bị 401 → refresh một lần (nhiều request cùng lúc chỉ refresh chung một lần).
/// 2. Retry request đúng một lần với access token mới.
/// 3. Nếu refresh token không còn hợp lệ → xóa token, gọi `onSessionExpired`, throw `APIError.unauthorized`.
@MainActor
final class APIClient {

    let baseURL: URL
    let session: Session

    /// Được gọi khi phiên không thể khôi phục. Token đã bị xóa trước khi gọi.
    /// `AppContainer` nối callback này tới coordinator để đưa người dùng về màn Login.
    var onSessionExpired: (() -> Void)?

    private let tokenStore: any TokenStore
    private let refreshPath: String
    private var refreshTask: Task<Void, Error>?

    init(
        baseURL: URL,
        session: Session? = nil,
        tokenStore: any TokenStore,
        refreshPath: String = "auth/refresh"
    ) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.refreshPath = refreshPath
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 40
            configuration.httpAdditionalHeaders = [
                "Accept": "application/json"
            ]
            self.session = Session(configuration: configuration)
        }
    }

    // MARK: - Build Request

    private func makeRequest(
        path: String,
        method: HTTPMethod,
        body: Data?,
        accessToken: String?
    ) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.method = method
        request.httpBody = body

        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // MARK: - Session

    private func currentAccessToken() throws -> String? {
        guard let token = try tokenStore.readAccessToken(), !token.isEmpty else {
            return nil
        }
        return token
    }

    /// Xóa phiên cục bộ, báo cho app biết và trả về lỗi để caller throw.
    private func expireSession() -> APIError {
        try? tokenStore.clear()
        onSessionExpired?()
        return .unauthorized
    }

    private func refreshAccessToken() async throws {
        // Nếu đã có request refresh đang chạy, chờ chung kết quả đó.
        if let refreshTask {
            try await refreshTask.value
            return
        }

        let task = Task<Void, Error> { [weak self] in
            guard let self else { throw CancellationError() }

            guard let refreshToken = try self.tokenStore.readRefreshToken(),
                  !refreshToken.isEmpty else {
                throw APIError.unauthorized
            }

            let body = try JSONEncoder().encode(TokenRefreshRequest(refreshToken: refreshToken))
            let request = self.makeRequest(
                path: self.refreshPath,
                method: .post,
                body: body,
                accessToken: nil
            )

            let data: Data
            do {
                data = try await self.execute(request)
            } catch let error as APIError where error.statusCode == 401 || error.statusCode == 403 {
                throw APIError.unauthorized
            }

            let response = try self.decodePayload(TokenRefreshResponse.self, from: data)
            guard !response.accessToken.isEmpty else {
                throw APIError.invalidResponse
            }

            // Backend có thể xoay vòng refresh token hoặc giữ nguyên token cũ.
            let newRefreshToken = response.refreshToken.flatMap { $0.isEmpty ? nil : $0 } ?? refreshToken
            try self.tokenStore.save(
                AuthTokens(accessToken: response.accessToken, refreshToken: newRefreshToken)
            )
        }

        refreshTask = task
        defer { refreshTask = nil }

        do {
            try await task.value
        } catch APIError.unauthorized {
            throw expireSession()
        }
    }

    /// Gửi request; với request cần đăng nhập sẽ tự refresh và retry đúng một lần khi gặp 401.
    private func perform(
        path: String,
        method: HTTPMethod,
        body: Data?,
        requiresAuth: Bool
    ) async throws -> Data {

        guard requiresAuth else {
            return try await execute(
                makeRequest(path: path, method: method, body: body, accessToken: nil)
            )
        }

        guard let usedToken = try currentAccessToken() else {
            throw expireSession()
        }

        do {
            return try await execute(
                makeRequest(path: path, method: method, body: body, accessToken: usedToken)
            )
        } catch let error as APIError where error.statusCode == 401 {
            // Chỉ refresh nếu chưa có request nào khác đổi token trong lúc chờ.
            if try currentAccessToken() == usedToken {
                try await refreshAccessToken()
            }

            guard let newToken = try currentAccessToken() else {
                throw expireSession()
            }

            do {
                return try await execute(
                    makeRequest(path: path, method: method, body: body, accessToken: newToken)
                )
            } catch let error as APIError where error.statusCode == 401 {
                throw expireSession()
            }
        }
    }

    // MARK: - Execute Request

    private func execute(_ request: URLRequest) async throws -> Data {

        let dataRequest = session.request(request)
            .redirect(using: Redirector(behavior: .doNotFollow))

        let response = await dataRequest.serializingData(
            automaticallyCancelling: true
        ).response

        try Task.checkCancellation()

        if let error = response.error, error.isExplicitlyCancelledError {
            throw CancellationError()
        }

        guard let http = response.response else {
            throw APIError.transport
        }

        guard (200..<300).contains(http.statusCode) else {
            if let data = response.data,
               let metadata = try? JSONDecoder().decode(APIResponseMetadata.self, from: data) {
                throw APIError.server(statusCode: http.statusCode, response: metadata)
            }
            throw APIError.http(http.statusCode)
        }

        // HTTP 204 không có body, Alamofire có thể báo lỗi serialize dữ liệu rỗng.
        if http.statusCode == 204 {
            return Data()
        }

        if response.error != nil {
            throw APIError.transport
        }

        guard let data = response.data else {
            throw APIError.invalidResponse
        }

        // Các response JSON còn lại dùng envelope chung.
        let metadata: APIResponseMetadata
        do {
            metadata = try JSONDecoder().decode(APIResponseMetadata.self, from: data)
        } catch {
            throw APIError.decoding
        }
        guard (200..<300).contains(metadata.httpStatus) else {
            throw APIError.server(statusCode: metadata.httpStatus, response: metadata)
        }
        return data
    }

    private func decodePayload<Response: Decodable & Sendable>(
        _ type: Response.Type,
        from data: Data
    ) throws -> Response {
        let envelope: APIResponse<Response>
        do {
            envelope = try JSONDecoder().decode(APIResponse<Response>.self, from: data)
        } catch {
            throw APIError.decoding
        }
        guard let payload = envelope.data else {
            throw APIError.invalidResponse
        }
        return payload
    }

    // MARK: - Request có Response

    func send<Response: Decodable & Sendable>(
        path: String,
        method: HTTPMethod,
        body: Data? = nil,
        requiresAuth: Bool = false,
        as type: Response.Type
    ) async throws -> Response {
        let data = try await perform(
            path: path,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
        return try decodePayload(type, from: data)
    }

    // MARK: - Request không có Response

    func send(
        path: String,
        method: HTTPMethod,
        body: Data? = nil,
        requiresAuth: Bool = false
    ) async throws {
        _ = try await perform(
            path: path,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
    }
}

// MARK: - Refresh payload
// Định nghĩa riêng trong Core để APIClient không phụ thuộc DTO của feature Auth.

private struct TokenRefreshRequest: Encodable, Sendable {
    let refreshToken: String
}

private struct TokenRefreshResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
}

// MARK: - HTTP Methods

extension APIClient {
    
    // MARK: GET
    
    func get<Response: Decodable & Sendable>(
        path: String,
        requiresAuth: Bool = false,
        as type: Response.Type
    ) async throws -> Response {
        
        try await send(
            path: path,
            method: .get,
            requiresAuth: requiresAuth,
            as: type
        )
    }
    
    func get(
        path: String,
        requiresAuth: Bool = false
    ) async throws {
        
        try await send(
            path: path,
            method: .get,
            requiresAuth: requiresAuth
        )
    }
    
    // MARK: POST
    
    func post<
        Body: Encodable & Sendable,
        Response: Decodable & Sendable
    >(
        path: String,
        body: Body,
        requiresAuth: Bool = false,
        as type: Response.Type
    ) async throws -> Response {
        
        let data = try JSONEncoder().encode(body)
        
        return try await send(
            path: path,
            method: .post,
            body: data,
            requiresAuth: requiresAuth,
            as: type
        )
    }
    
    func post<Body: Encodable & Sendable>(
        path: String,
        body: Body,
        requiresAuth: Bool = false
    ) async throws {
        
        let data = try JSONEncoder().encode(body)
        
        try await send(
            path: path,
            method: .post,
            body: data,
            requiresAuth: requiresAuth
        )
    }
    
    // POST không có body, không có response
    func post(
        path: String,
        requiresAuth: Bool = false
    ) async throws {
        
        try await send(
            path: path,
            method: .post,
            requiresAuth: requiresAuth
        )
    }
    
    // MARK: PUT
    
    func put<
        Body: Encodable & Sendable,
        Response: Decodable & Sendable
    >(
        path: String,
        body: Body,
        requiresAuth: Bool = false,
        as type: Response.Type
    ) async throws -> Response {
        
        let data = try JSONEncoder().encode(body)
        
        return try await send(
            path: path,
            method: .put,
            body: data,
            requiresAuth: requiresAuth,
            as: type
        )
    }
    
    func put<Body: Encodable & Sendable>(
        path: String,
        body: Body,
        requiresAuth: Bool = false
    ) async throws {
        
        let data = try JSONEncoder().encode(body)
        
        try await send(
            path: path,
            method: .put,
            body: data,
            requiresAuth: requiresAuth
        )
    }
    
    // MARK: PATCH
    
    func patch<
        Body: Encodable & Sendable,
        Response: Decodable & Sendable
    >(
        path: String,
        body: Body,
        requiresAuth: Bool = false,
        as type: Response.Type
    ) async throws -> Response {
        
        let data = try JSONEncoder().encode(body)
        
        return try await send(
            path: path,
            method: .patch,
            body: data,
            requiresAuth: requiresAuth,
            as: type
        )
    }
    
    func patch<Body: Encodable & Sendable>(
        path: String,
        body: Body,
        requiresAuth: Bool = false
    ) async throws {
        
        let data = try JSONEncoder().encode(body)
        
        try await send(
            path: path,
            method: .patch,
            body: data,
            requiresAuth: requiresAuth
        )
    }
    
    // MARK: DELETE
    
    func delete<Response: Decodable & Sendable>(
        path: String,
        requiresAuth: Bool = false,
        as type: Response.Type
    ) async throws -> Response {
        
        try await send(
            path: path,
            method: .delete,
            requiresAuth: requiresAuth,
            as: type
        )
    }
    
    func delete(
        path: String,
        requiresAuth: Bool = false
    ) async throws {
        
        try await send(
            path: path,
            method: .delete,
            requiresAuth: requiresAuth
        )
    }
}
