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

/// An  `Action` is a statement of intent to be interpreted by a reducer.
/// Based on the current state, processing the action results in a new state.
public protocol MiddlewareProvider {
    associatedtype State
    associatedtype Environment

    /// Middleware: A fpotentially side effecting function tied to a specific action that takes a Store.
    typealias Middleware = (Store<Environment, State>) -> ProcessDirective

    var middleware: Middleware { get }
}

public protocol Action: MiddlewareProvider, Identifiable {
    
    typealias Reducer = (inout State) -> Void
    
    var reduce: Reducer { get }
}

public extension Action {
    var middleware: Middleware {
        { store in
            .continue
        }
    }
}

public protocol ParameterizedAction: MiddlewareProvider, Identifiable {
    associatedtype Parameters
    typealias Reducer = (inout State, Parameters) -> Void
    
    var argument: Parameters { get }
    var reduce: Reducer { get }
}

public extension ParameterizedAction {
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
    public typealias GeneralMiddleware = @MainActor (any Identifiable, Store<Environment, State>) -> ProcessDirective
    
    public typealias Logger = (String) -> Void
    
    @Published public private (set) var state: State
    
    public let middleware: [GeneralMiddleware]
    public let environment: Environment
    public let logger: Logger
    
    public init(
        environment: Environment,
        state: State,
        middleware: [GeneralMiddleware] = [],
        logger: @escaping Logger = { _ in }
    ) {
        self.state = state
        self.middleware = middleware
        self.environment = environment
        self.logger = logger
    }
    
    public func dispatch<T: Action>(_ action: T) where T.State == State, T.Environment == Environment {
        
        reduce(action: action) { state in
            // Run Specific Middleware, then reduce if allowed
            if action.middleware(self) == .continue {
                action.reduce(&state)
            }
        }
    }

    public func dispatch<T: ParameterizedAction>(_ action: T) where T.State == State, T.Environment == Environment {
        
        reduce(action: action) { state in
            // Run Specific Middleware, then reduce if allowed
            if action.middleware(self) == .continue {
                action.reduce(&state, action.argument)
            }
        }
    }
    
    private func reduce(
        action: any Identifiable,
        using reduce: (inout State) -> Void
    ) {
        logger("****\nState *before* action: '\(action)':\n\(state)\n****\n")
        
        // Run General Middleware
        for middlewareInstance in middleware {
            if middlewareInstance(action, self) == .terminate {
                return
            }
        }
        
        // Run the reduction
        reduce(&state)
        
        logger("****\nState *after* action: '\(action)':\n\(state)\n****\n")
    }
}

public struct StandardAction<Environment, State>: Action {
    public typealias State = State
    
    public let id: String
    public let reduce: Reducer
    public let middleware: Middleware
    
    public init(id: String, reduce: @escaping Reducer, middleware: Middleware? = nil) {
        self.id = id
        self.reduce = reduce
        self.middleware = middleware ?? { _ in .continue }
    }
}

extension StandardAction: CustomStringConvertible {
    public var description: String {
        id
    }
}

public struct StandardParameterizedAction<Environment, State, Parameters>: ParameterizedAction {
    public typealias State = State
    public typealias Parameters = Parameters
    
    public let id: String
    public let reduce: ParameterizedReducer
    public let middleware: Middleware
    public let argument: Parameters
    
    public typealias ParameterizedReducer = (inout State, Parameters) -> Void

    public init(id: String,
                argument: Parameters,
                reduce: @escaping ParameterizedReducer,
                middleware: Middleware? = nil
    ) {
        self.id = id
        self.argument = argument
        self.reduce = reduce
        self.middleware = middleware ?? { _ in .continue }
    }
}

extension StandardParameterizedAction: CustomStringConvertible {
    public var description: String {
        "\(id)(\(argument))"
    }
}
