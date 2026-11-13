import Foundation

@MainActor
final class DefaultUserRepository: UserRepository {
    private let service: any UserService

    init(service: any UserService) {
        self.service = service
    }

    func getCurrentUser() async throws -> User {
        do {
            let dto = try await service.me()
            try Task.checkCancellation()
            return dto.toDomain()
        } catch {
            // Hết phiên: APIClient đã xóa token và báo cho AppCoordinator chuyển về Login.
            // Repository chỉ cần trả lỗi Domain tương ứng.
            throw AuthErrorMapper.map(error)
        }
    }
}
