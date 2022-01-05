//
//  ReduxFoundation.swift
//
//  Created by Farley Caesar on 2020-09-07.
//
import Foundation

/// `State` is the set of values that represent the overall value of a an application at a point in time.
/// An  `Action` is a statement of intent to be interpreted by a reducer. Based on the current state, the action results in a new state.

/// A function that takes in the current state and an action, to produce a new state. This is effectively a "swap" operation on the
/// immutable `State` value. The reducer communicates the new state by calling the callback `(State) -> Void` function.
public typealias Reducer<State, Action> = (Action, State, (State) -> Void) -> Void

/// A function given to middleware by the store, to give it a location to dispatch actions
public typealias Dispatcher<Action> = (Action) -> Void

/// A function that takes a state, an action, and a dispatcher function.
/// Middleware is where inpure functions of state and action are processed. That is, middleware functions can produce side
/// effects based on the given action and state. They can also dispatch a resulting action using the dipatcher.
public typealias Middleware<State, Action> = (State, Action, @escaping Dispatcher<Action>) -> Void

/// A `Store` is place that holds the current state, the store reducer, and store middleware. It provides a facility where external actors can dispatch actions to the store.
///  - The store runs the reducer when actions arive to produce a new state for the store to hold on to and publish.
///  - The store runs all middleware when actions arrive as well.
@MainActor public final class Store<State, Action>: ObservableObject {
    @Published public private(set) var state: State
    
    private let reducer: Reducer<State, Action>
    private let middleware: [Middleware<State, Action>]
    
    public init(initialState: State,
         reducer: @escaping Reducer<State, Action>,
         middleware: [Middleware<State, Action>]) {
        
        self.state = initialState
        self.reducer = reducer
        self.middleware = middleware
    }

    public func dispatch(_ action: Action) {
        reducer(action, state) { state in
            self.state = state
        }
                
        middleware.forEach { middlewareInstance in
            middlewareInstance(state, action) { action in
                DispatchQueue.main.async { [weak self] in
                    self?.dispatch(action)
                }
            }
        }
    }    
}

/// Combine takes two reducers and returns a single reducer function. This function first calls the first reducer
/// If it effected the state, then it "returns" the new state by calling the callback and returns early. Otherwise calls the 2nd reducer.
/// This way, only one reducer can affect the state. So each Action can only be acted on by a single reducer.
func combine<State, Action>(_ lhsReducer: @escaping Reducer<State, Action>,
                            with rhsReducer: @escaping Reducer<State, Action>) -> Reducer<State, Action> {
    
    { (action: Action, state: State, stateUpdater: (State) -> Void) -> Void in
        var isUpdaterCalled = false
        
        lhsReducer(action, state) { state in
            isUpdaterCalled = true
            stateUpdater(state)
        }
        
        guard !isUpdaterCalled else { return }
        
        rhsReducer(action, state, stateUpdater)
    }
}

/// Combines a list of reducers into one reducer.
func reduce<State, Action>(reducers: [Reducer<State, Action>]) -> Reducer<State, Action> {
    let noOpReducer: Reducer<State, Action> = { _, _, _ in }
    
    let singleReducer = reducers.reduce(noOpReducer) { currentReducer, nextReducer in
        return combine(currentReducer, with: nextReducer)
    }
    
    return singleReducer
}


