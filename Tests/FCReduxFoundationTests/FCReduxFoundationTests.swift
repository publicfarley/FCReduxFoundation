import XCTest
@testable import FCReduxFoundation

final class FCReduxFoundationTests: XCTestCase {
    
    #warning("Write proper test cases")
    func testExample() throws {
        enum AppAction {
            case one, two, three
        }

        struct AppState: Equatable {
            var value: String
        }
        
        func reducer_1(action: AppAction, state: AppState, communicator: (AppState) -> Void) {
            switch action {
            case .one:
                var newState = state
                newState.value = "One"
                communicator(newState)
            default:
                return
            }
        }

        func reducer_2(action: AppAction, state: AppState, communicator: (AppState) -> Void) {
            switch action {
            case .two:
                var newState = state
                newState.value = "Two"
                communicator(newState)
            default:
                return
            }
        }

        func reducer_3(action: AppAction, state: AppState, communicator: (AppState) -> Void) {
            if case AppAction.three = action {
                var newState = state
                newState.value = "Three"
                communicator(newState)
            }
        }


        class AppStore_1 {
            private (set) var state: AppState
            let reducer: Reducer<AppState, AppAction>
            
            init(state: AppState, reducer: @escaping Reducer<AppState, AppAction>) {
                self.state = state
                self.reducer = reducer
            }
            
            func dispatch(_ action: AppAction) {
                reducer(action, state) { state in
                    self.state = state
                }
            }
        }

        let masterReducer_1 = reduce(reducers: [reducer_1, reducer_2, reducer_3])

        let store_1 = AppStore_1(state: AppState(value: "initial"), reducer: masterReducer_1)

        print("\n------------------------\n")

        print(store_1.state.value)

        store_1.dispatch(.one)
        print(store_1.state.value)

        store_1.dispatch(.three)
        print(store_1.state.value)

    }
}
