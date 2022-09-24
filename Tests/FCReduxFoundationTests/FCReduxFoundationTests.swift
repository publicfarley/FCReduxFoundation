import os
import XCTest
@testable import FCReduxFoundation

final class ActionTests: XCTestCase {
    var store: Store<Environment, Counter>!
    
    @MainActor override func setUp() {
        super.setUp()
        store = Store(
            environment: Environment(),
            state: Counter(count: 0),
            logger: { Logger().info("\n\n\($0)") })
        
    }
    
    @MainActor override func tearDown() {
        store = nil
        super.tearDown()
    }
    
    @MainActor func testIncrement() throws {
        let increment = StandardAction<Environment, Counter>(id: "increment") { counter in
            counter.count += 1
        }

        store.dispatch(increment)
        
        XCTAssertEqual(store.state.count, 1)
    }

    @MainActor func testDecrement() throws {
        let decrement = StandardAction<Environment, Counter>(id: "decrement") { counter in
            counter.count -= 1
        }

        store.dispatch(decrement)
        
        XCTAssertEqual(store.state.count, -1)
    }

    @MainActor func testSet() throws {
        let specificValue = 42
        let set = StandardParameterizedAction<Environment, Counter, Int>(id: "set", argument: specificValue) { counter, value in
            counter.count = value
        }

        store.dispatch(set)
        
        XCTAssertEqual(specificValue, store.state.count)
    }
}

struct Environment {}

struct Counter {
    var count: Int
}
