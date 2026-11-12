import Foundation

@MainActor
final class MockAuthService: AuthService {
    func refresh(refreshToken: String) async throws -> LoginResponseDTO {
        return LoginResponseDTO(accessToken: "", tokenType: "", expiresIn: 900, refreshToken: "")
    }
    
    func logout(refreshToken: String) async throws {
        
    }
    
    
    
    func me() async throws -> UserDTO? {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard token == self.token else { throw APIError.http(401) }
        return user
    }
    
    func getUser(id: String) async throws -> UserDTO? {
        return user
    }
    
    private let token = "mock-token-for-learning-only"
    private let user = UserDTO(id: 1, fullName: "Nguyễn Thành", email: "demo@example.com",phone: "0776426233",address: "Hà Nội")
    
    func login(email: String, password: String) async throws -> LoginResponseDTO {
        try await Task.sleep(nanoseconds: 650_000_000)
        guard (email == user.email || email == user.phone), password == "123456" else { throw APIError.http(401) }
        return LoginResponseDTO(accessToken: token,tokenType: "",expiresIn: 90, refreshToken: "")
    }
    
    
}
