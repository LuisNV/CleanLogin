import Foundation

@MainActor
protocol LogoutUseCaseProtocol {
    func execute() async throws
}

@MainActor
final class LogoutUseCase: LogoutUseCaseProtocol {
    private let repository: any AuthRepository
    init(repository: any AuthRepository) { self.repository = repository }
    func execute() async throws { try await repository.logout() }
}
