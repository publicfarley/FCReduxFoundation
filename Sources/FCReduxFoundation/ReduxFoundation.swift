//
//  ReduxFoundation.swift
//  SimpleSteps
//
//  Created by Farley Caesar on 2020-09-07.
//
import Foundation

/// `State` is the set of values that represent the overall value of a an application at a point in time.
/// An  `Action` is a statement of intent to be interpreted by a reducer. Based on the current state, the action results in a new state.

/// A function that takes in the current state and an action, to produce a new state. Since this effectively a "swap" operation on the
/// immutable `State` value, the Swift `inout` keyword is leveraged so that the compiler handles wrting the boilerplate code
/// to replace the old state with the new state.
public typealias Reducer<State, Action> = (inout State, Action) -> Void

/// A function given to middleware by the store, to give it a location to dispatch actions
public typealias Dispatcher<Action> = (Action) -> Void

/// A function that takes a state, an action, and a dispatcher function.
/// Middleware is where inpure functions of state and action are processed. That is, middleware functions can produce side effects based on the given action and state. They can also dispatch a resulting action using the dipatcher.
public typealias Middleware<State, Action> = (State, Action, @escaping Dispatcher<Action>) -> Void

/// A `Store` is place that holds the current state, the store reducer, and store middleware. It provides a facility where external actors can dispatch actions to the store.
///  - The store runs the reducer when actions arive to produce a new state for the store to hold on to and publish.
///  - The store runs all middleware when actions arrive as well.
@MainActor public final class Store<State,Action>: ObservableObject {
    @Published private(set) var state: State
    
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
        reducer(&state,action)
                
        middleware.forEach { middlewareInstance in
            middlewareInstance(state, action) { action in
                DispatchQueue.main.async { [weak self] in
                    self?.dispatch(action)
                }
            }
        }
    }    
}



