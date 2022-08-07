//
//  ReduxFoundation.swift
//
//  Created by Farley Caesar on 2020-09-07.
//
import Foundation

public typealias Action<State> = Store<State>.Action

/// A `Store` is place that holds the current state, the store reducer, and store middleware. It provides a facility where external actors can dispatch actions to the store.
///  - The store runs the reducer when actions arive to produce a new state for the store to hold on to and publish.
///  - The store runs all middleware when actions arrive as well.
/// - Parameters:
///     - State: The set of values that represent the overall value of a an application at a point in time.

// Note: Usage of MainActor as per advice below: https://www.hackingwithswift.com/quick-start/concurrency/how-to-use-mainactor-to-run-code-on-the-main-queue
@MainActor
public final class Store<State>: ObservableObject {
    public enum ProcessDirective {
        case `continue`
        case terminate
    }

    /// A function given to middleware by the store, to give it a location to dispatch actions
    public typealias Dispatcher = @MainActor (Action) -> Void
    
    /// Middleware is where inpure functions of state and action are processed.
    /// That is, middleware functions can produce side effects based on the given action and state.
    /// They can also dispatch a resulting action using the dipatcher.
    /// Finally they return a `ProcessDirective` which tells the store whether to continue to process the action or to termiate processing.
    /// A directive to terminate means the action will not proceed to the reducer.
    ///
    /// GeneralMiddleware: A middleware function that takes a state, an action, and a dispatcher function.
    public typealias GeneralMiddleware = (State, Action, @escaping Dispatcher) -> ProcessDirective

    /// An  `Action` is a statement of intent to be interpreted by a reducer. Based on the current state, the action results in a new state.
    public struct Action {
        /// SpecificMiddleware: A middleware function tied to a specific action that takes a state and a dispatcher function.
        typealias SpecificMiddleware = (State, @escaping Dispatcher) -> ProcessDirective

        let name: String
        let reduce: (inout State) -> Void
        let middleware: SpecificMiddleware?
        
        init(name: String,
             reduce: @escaping (inout State) -> Void,
             middleware: SpecificMiddleware? = nil
        ) {
            self.name = name
            self.reduce = reduce
            self.middleware = middleware
        }
    }
    
    @Published public private (set) var state: State
    var middleware: [GeneralMiddleware]
    
    public init(state: State, middleware: [GeneralMiddleware] = []) {
        self.state = state
        self.middleware = middleware
    }
    
    public func dispatch(_ action: Action) {
        
        // General Middleware
        for middlewareInstance in middleware {
            if middlewareInstance(state, action, dispatch) == .terminate {
                return
            }
        }
        
        guard let specificMiddleware = action.middleware else {
            // No specific middleware, just reduce
            action.reduce(&state)
            return
        }
        
        // Run Specific Middleware, then reduce if allowed
        if specificMiddleware(state, dispatch) == .continue {
            action.reduce(&state)
        }
    }
}

