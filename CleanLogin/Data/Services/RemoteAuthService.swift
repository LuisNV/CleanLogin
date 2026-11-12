import Foundation

@MainActor
final class RemoteAuthService: AuthService {
    private let client: APIClient
    
    init(client: APIClient) {
        self.client = client
    }
    func logout(refreshToken: String) async throws {
        try await client.post(
            path: "auth/logout",
            body: LogoutRequestDTO(refreshToken: refreshToken)
            
        )
    }
    
    func me() async throws -> UserDTO? {
        return try await client.get(
            path: "auth/me",
            requiresAuth: true,
            as: UserDTO.self
        )
    }
    
    func getUser(id: String) async throws -> UserDTO? {
        return try await client.get(path: "users/\(id)",requiresAuth: true, as: UserDTO.self)
    }
    
    
    
    func login(
        email: String,
        password: String
    ) async throws -> LoginResponseDTO {
        
        let request = LoginRequestDTO(
            email: email,
            password: password
        )
        
        return try await client.post(
            path: "auth/login",
            body: request,
            as: LoginResponseDTO.self
        )
    }
    func refresh(refreshToken: String) async throws -> LoginResponseDTO {
        let request = RefreshRequestDTO(refreshToken: refreshToken)
        return try await client.post(path: "auth/refresh", body: request,as: LoginResponseDTO.self)
    }
    
}
