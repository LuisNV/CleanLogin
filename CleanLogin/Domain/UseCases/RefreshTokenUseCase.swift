//
//  RefreshTokenUseCase.swift
//  CleanLogin
//
//  Created by Administrator on 30/10/26.
//

import Foundation

@MainActor
protocol RefreshTokenUseCaseProtocol {
    func execute() async throws
}

@MainActor
final class RefreshTokenUseCase: LogoutUseCaseProtocol {
    private let repository: any AuthRepository
    init(repository: any AuthRepository) { self.repository = repository }
    func execute() async throws { try await repository.refresh() }
}
