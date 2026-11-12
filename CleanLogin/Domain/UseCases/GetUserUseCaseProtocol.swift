//
//  GetUserUseCaseProtocol.swift
//  CleanLogin
//
//  Created by Administrator on 27/10/26.
//


@MainActor
protocol GetUserUseCaseProtocol {
    func execute() async throws -> User?
}

@MainActor
final class GetUserUseCase: GetUserUseCaseProtocol {
    
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func execute() async throws -> User? {
        return try await repository.getMe()
    }
}
