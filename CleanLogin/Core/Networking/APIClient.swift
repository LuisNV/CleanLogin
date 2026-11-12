
import Foundation
import Alamofire

@MainActor
final class APIClient {
    
    let baseURL: URL
    let session: Session
    
    // Đọc access token hiện tại từ Keychain
    private let tokenProvider: () throws -> String?
    private let refreshToken:() throws -> String?
    private let tokenStore: KeychainTokenStore
    
    private var refreshTask: Task<Void, Error>?
    
    init(
        baseURL: URL,
        session: Session? = nil,
        tokenStore: KeychainTokenStore,
        tokenProvider: @escaping () throws -> String?,
        refreshToken: @escaping () throws -> String?
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.refreshToken = refreshToken
        self.tokenStore = tokenStore
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
    
    private func buildRequest(
        path: String,
        method: HTTPMethod,
        body: Data?,
        requiresAuth: Bool
    ) throws -> URLRequest {
        
        var request = URLRequest(
            url: baseURL.appendingPathComponent(path)
        )
        
        request.method = method
        request.httpBody = body
        
        if body != nil {
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }
        
        if requiresAuth {
            guard let token = try tokenProvider(),
                  !token.isEmpty else {
                throw APIError.missingToken
            }
            
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }
        
        return request
    }
    
    private func refreshAccessToken() async throws {
        
        // Nếu đã có request refresh, chờ kết quả đó
        if let refreshTask {
            try await refreshTask.value
            return
        }
        
        let task = Task<Void, Error> { [self] in
            
            guard let refreshToken = try refreshToken(),
                  !refreshToken.isEmpty else {
                throw AuthError.sessionExpired
            }
            
            let body = RefreshRequestDTO(
                refreshToken: refreshToken
            )
            
            let data = try JSONEncoder().encode(body)
            
            let request = try buildRequest(
                path: "auth/refresh",
                method: .post,
                body: data,
                requiresAuth: false
            )
            
            let responseData: Data
            
            do {
                responseData = try await execute(request)
            } catch let error as APIError where error.statusCode == 401 {
                throw AuthError.sessionExpired
            } catch let error as APIError where error.statusCode == 403 {
                throw AuthError.sessionExpired
            }
            
            let response = try decodePayload(LoginResponseDTO.self, from: responseData)
            
            guard !response.accessToken.isEmpty,
                  !response.refreshToken.isEmpty else {
                throw AuthError.invalidResponse
            }
            
            try tokenStore.save(response)
        }
        
        refreshTask = task
        
        defer {
            refreshTask = nil
        }
        
        try await task.value
    }
    
    private func executeWithRefresh(
        path: String,
        method: HTTPMethod,
        body: Data?,
        requiresAuth: Bool
    ) async throws -> Data {
        
        let request = try buildRequest(
            path: path,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
        
        do {
            return try await execute(request)
            
        } catch let error as APIError where error.statusCode == 401 && requiresAuth {
            
            // Token được sử dụng trong request bị lỗi
            let oldAuthorization = request.value(
                forHTTPHeaderField: "Authorization"
            )
            
            // Token hiện tại trong Keychain
            let currentToken = try tokenStore.read()
            
            let currentAuthorization = currentToken.map {
                "Bearer \($0)"
            }
            
            // Chỉ refresh nếu token chưa được thay đổi
            if oldAuthorization == currentAuthorization {
                try await refreshAccessToken()
            }
            
            // Build lại request với token mới
            let retryRequest = try buildRequest(
                path: path,
                method: method,
                body: body,
                requiresAuth: true
            )
            
            // Retry đúng một lần
            do {
                return try await execute(retryRequest)
            } catch let error as APIError where error.statusCode == 401 {
                throw AuthError.sessionExpired
            }
        }
    }
    
    // MARK: - Execute Request
    
    private func execute(
        _ request: URLRequest
    ) async throws -> Data {
        
        let dataRequest = session.request(request)
            .redirect(
                using: Redirector(behavior: .doNotFollow)
            )
        
        let response = await dataRequest.serializingData(
            automaticallyCancelling: true
        ).response
        
        try Task.checkCancellation()
        
        if let error = response.error,
           error.isExplicitlyCancelledError {
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
        
        if response.error != nil {
            throw APIError.transport
        }
        
        guard let data = response.data else {
            throw APIError.invalidResponse
        }
        
        // HTTP 204 không có body; các response JSON còn lại dùng envelope chung.
        if http.statusCode != 204 {
            let metadata: APIResponseMetadata
            do {
                metadata = try JSONDecoder().decode(APIResponseMetadata.self, from: data)
            } catch {
                throw APIError.decoding
            }
            guard (200..<300).contains(metadata.httpStatus) else {
                throw APIError.server(statusCode: metadata.httpStatus, response: metadata)
            }
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
        
        let request = try buildRequest(
            path: path,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
        
        let data = try await executeWithRefresh(
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
        
        let request = try buildRequest(
            path: path,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
        
        _ = try await executeWithRefresh(
            path: path,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
    }
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
