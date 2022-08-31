//
//  ReduxFoundation.swift
//
//  Created by Farley Caesar on 2020-09-07.
//
import Foundation

public enum ProcessDirective {
    case `continue`
    case terminate
}

/// An  `Action` is a statement of intent to be interpreted by a reducer. Based on the current state, the action results in a new state.
public protocol Action {
    associatedtype State
    associatedtype Environment
    
    typealias Reducer = (inout State) -> Void

    /// Middleware: A fpotentially side effecting function tied to a specific action that takes a Store.
    typealias Middleware = (Store<Environment, State>) -> ProcessDirective
    
    var name: String { get }
    var reduce: Reducer { get }
    var middleware: Middleware { get }
}

public extension Action {
    var middleware: Middleware {
        { store in
            .continue
        }
    }
}

/// A `Store` is place that holds the current state, and gemeral store middleware. It provides a facility where external actors can dispatch actions to the store.
///  - The store first runs all general middleware, then action specific middleware when actions arrive.
///  - The store then runs the action's reducer to produce a new state, derived from the old state, for the store to hold on to and publish.
/// - Parameters:
///     - State: The set of values that represent the overall value of a an application at a point in time.
@MainActor
public final class Store<Environment, State>: ObservableObject {
    /// Middleware is where inpure functions of state and action are processed.
    /// That is, middleware functions can produce side effects based on the given action and state.
    /// They can also dispatch a resulting action using the given store's dispatcher.
    /// Finally they return a `ProcessDirective` which tells the store whether to continue to process the action or to termiate processing.
    /// A directive to terminate means the action will not proceed to the reducer.
    ///
    /// GeneralMiddleware: A middleware function that takes an action, and the store. Returns a `ProcessDirective`
    public typealias GeneralMiddleware = @MainActor (any Action, Store<Environment, State>) -> ProcessDirective


    @Published public private (set) var state: State
    public var middleware: [GeneralMiddleware]
    
    public init(state: State, middleware: [GeneralMiddleware] = []) {
        self.state = state
        self.middleware = middleware
    }
    
    public func dispatch<T: Action>(_ action: T) where T.State == State, T.Environment == Environment {

        // General Middleware
        for middlewareInstance in middleware {
            if middlewareInstance(action, self) == .terminate {
                return
            }
        }
        
        // Run Specific Middleware, then reduce if allowed
        if action.middleware(self) == .continue {
            action.reduce(&state)
        }
    }
}

public struct StandardAction<Environment, State>: Action {
    public typealias State = State
    
    public let name: String
    public let reduce: Reducer
    public let middleware: Middleware
    
    public init(name: String, reduce: @escaping Reducer, middleware: Middleware? = nil) {
        self.name = name
        self.reduce = reduce
        self.middleware = middleware ?? { _ in .continue }
    }
}
