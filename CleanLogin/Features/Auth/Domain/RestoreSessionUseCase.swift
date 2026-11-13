import Foundation

@MainActor
protocol RestoreSessionUseCaseProtocol {
    /// `true` nếu đã có phiên đăng nhập lưu trên máy.
    /// Token hết hạn sẽ được `APIClient` tự refresh ở request đầu tiên.
    func execute() throws -> Bool
}

@MainActor
final class RestoreSessionUseCase: RestoreSessionUseCaseProtocol {
    private let repository: any AuthRepository
    init(repository: any AuthRepository) { self.repository = repository }
    func execute() throws -> Bool { try repository.hasSavedSession() }
}
