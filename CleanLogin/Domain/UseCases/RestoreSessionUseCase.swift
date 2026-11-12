import Foundation

@MainActor
protocol RestoreSessionUseCaseProtocol {
    func execute() async throws -> String?
}

@MainActor
final class RestoreSessionUseCase: RestoreSessionUseCaseProtocol {
    private let repository: any AuthRepository
    init(repository: any AuthRepository) { self.repository = repository }
    func execute() async throws -> String? { try await repository.restoreSession() }
}
