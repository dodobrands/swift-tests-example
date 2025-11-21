import Foundation
import XCTest
#if canImport(Calculator)
@testable import Calculator
#else
@testable import XcodeprojExample
#endif

class XCTestTests: XCTestCase {
    // Covers: success test case
    func test_success() {
        let calculator = Calculator()
        let result = calculator.add(2, 3)
        XCTAssertTrue(result == 5.0)
    }
    
    // Covers: failure test case
    func test_failure() {
        let calculator = Calculator()
        let result = calculator.multiply(2, 3)
        XCTFail("Expected 5.0 but got \(result)")
    }
    
    // Covers: skip test case
    func test_skip() throws {
        throw XCTSkip("Skip message")
    }
    
    // Covers: expected failure test case
    func test_expectedFailure() {
        let calculator = Calculator()
        XCTExpectFailure("Failure is expected")
        let result = calculator.subtract(1, 2)
        XCTAssertEqual(result, 2.0) // This will fail, but it's expected
    }
    
    static nonisolated(unsafe) var shouldFail = true
    // Covers: flaky test case
    func test_flacky() {
        let calculator = Calculator()
        if Self.shouldFail {
            let result = calculator.add(1, 1)
            XCTFail("Flacky failure message: result was \(result)")
        }
        
        Self.shouldFail = false
    }
    
    // Covers: async test case
    func test_async() async {
        let calculator = Calculator()
        // Simulate async operation
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        let result = calculator.add(2, 3)
        XCTAssertEqual(result, 5.0)
    }
    
    // Covers: async test case with expectation
    func test_asyncWithExpectation() {
        let calculator = Calculator()
        let expectation = expectation(description: "Async calculation")
        
        Task {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            let result = calculator.multiply(2, 3)
            XCTAssertEqual(result, 6.0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // Covers: throwing test case that throws error
    func test_throwing() throws {
        let calculator = Calculator()
        // This will throw CalculatorError.divisionByZero
        _ = try calculator.divide(10, 0)
    }
    
    // Covers: test attachment case
    func test_withAttachment() {
        let calculator = Calculator()
        let result = calculator.add(2, 3)
        XCTAssertEqual(result, 5.0)
        
        let attachment = XCTAttachment(string: "Test result: \(result)")
        attachment.name = "Calculation Result"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // Covers: performance measurement test case
    func test_performance() {
        let calculator = Calculator()
        measure {
            for i in 1...1000 {
                _ = calculator.add(Double(i), Double(i * 2))
            }
        }
    }
    
    func test_withWarning() {
#warning("Some warning from ExampleSUITests")
        XCTAssertTrue(Bool(true))
    }
}
