import Foundation

@MainActor
protocol UserService {
    func me() async throws -> UserDTO
}

@MainActor
final class RemoteUserService: UserService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func me() async throws -> UserDTO {
        try await client.get(path: "auth/me", requiresAuth: true, as: UserDTO.self)
    }
}

@MainActor
final class MockUserService: UserService {
    func me() async throws -> UserDTO {
        try await Task.sleep(nanoseconds: 300_000_000)
        return UserDTO(
            id: DemoAccount.id,
            fullName: DemoAccount.fullName,
            email: DemoAccount.email,
            phone: DemoAccount.phone,
            address: DemoAccount.address,
            dateOfBirth: DemoAccount.dateOfBirth,
            avatarUrl: "",
            emailVerified: false
        )
    }
}
