import Foundation

@MainActor
protocol GetCurrentUserUseCaseProtocol {
    func execute() async throws -> User
}

@MainActor
final class GetCurrentUserUseCase: GetCurrentUserUseCaseProtocol {
    private let repository: any UserRepository

    init(repository: any UserRepository) {
        self.repository = repository
    }

    func execute() async throws -> User {
        try await repository.getCurrentUser()
    }
}
