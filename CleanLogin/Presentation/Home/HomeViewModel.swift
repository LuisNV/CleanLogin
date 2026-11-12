import Foundation
import RxRelay
import RxCocoa

struct HomeViewState: Equatable {
    
    var isLoading = false
    var errorMessage: String?
}

@MainActor
final class HomeViewModel {
    
    private let stateRelay: BehaviorRelay<HomeViewState>
    
    var state: Driver<HomeViewState> { stateRelay.asDriver() }
    
    
    init() {
        
        stateRelay = BehaviorRelay(value: HomeViewState())
    }
    
    func refresh() async {
        guard !stateRelay.value.isLoading else { return }
        var next = stateRelay.value
        next.isLoading = true
        next.errorMessage = nil
        stateRelay.accept(next)
        
    }
    
    
}
