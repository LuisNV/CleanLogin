//
//  ProfileViewModel.swift
//  CleanLogin
//
//  Created by Administrator on 27/10/26.
//
import Foundation
import RxRelay
import RxCocoa

struct ProfileViewState: Equatable {
    var user: User?
    var isLoading = false
    var errorMessage: String?
   
}
@MainActor
final class ProfileViewModel{
    private let getUserUseCase: any GetUserUseCaseProtocol
    private let logoutUseCase: any LogoutUseCaseProtocol
    
    private let stateRelay: BehaviorRelay<ProfileViewState>
    var onLogoutSuccess: (() -> Void)?
    var state: Driver<ProfileViewState> { stateRelay.asDriver() }
    init(getUserUseCase: any GetUserUseCaseProtocol,logoutUseCase: any LogoutUseCaseProtocol) {
        self.getUserUseCase = getUserUseCase
        self.logoutUseCase = logoutUseCase
        stateRelay = BehaviorRelay(value: ProfileViewState())
    }
    func loadUser() async {
        guard !stateRelay.value.isLoading else { return }
        stateRelay.accept(ProfileViewState(user: stateRelay.value.user, isLoading: true))
        LoadingManager.shared.show()
        defer { LoadingManager.shared.hide() }
        
        do {
            let user = try await getUserUseCase.execute()
            try Task.checkCancellation()
            stateRelay.accept(ProfileViewState(
                user: user,
                isLoading: false
            ))
        } catch {
            if error is CancellationError || Task.isCancelled {
                stateRelay.accept(ProfileViewState())
                return
            }
            let message = (error as? AuthError)?.localizedDescription
            ?? AuthError.serviceUnavailable.localizedDescription
            stateRelay.accept(ProfileViewState(errorMessage: message))
        }
    }
    func logoutTask() async {
        guard !stateRelay.value.isLoading else { return }
        stateRelay.accept(ProfileViewState( isLoading: true))
        
        do {
            try await logoutUseCase.execute()
            try Task.checkCancellation()
            stateRelay.accept(ProfileViewState(
                isLoading: false
            ))
            onLogoutSuccess?()
        } catch {
            if error is CancellationError || Task.isCancelled {
                stateRelay.accept(ProfileViewState())
                return
            }
            let message = (error as? AuthError)?.localizedDescription
            ?? AuthError.serviceUnavailable.localizedDescription
            stateRelay.accept(ProfileViewState(errorMessage: message))
        }
    }
}
