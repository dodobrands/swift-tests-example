import Foundation
import Testing
#if canImport(Calculator)
@testable import Calculator
#else
@testable import XcodeprojExample
#endif

@Suite
struct ExampleSUITests {
    // Covers: success test case
    @Test
    func success() {
        let calculator = Calculator()
        let result = calculator.add(2, 3)
        #expect(result == 5.0)
    }
    
    // Covers: failure test case
    @Test
    func failure() {
        let calculator = Calculator()
        let result = calculator.multiply(2, 3)
        Issue.record("Expected 5.0 but got \(result)")
    }
    
    // Covers: disabled test case
    @Test(.disabled("Disabled reason"))
    func disabled() {
        let calculator = Calculator()
        let result = calculator.add(1, 1)
        #expect(result == 2.0)
    }
    
    // Covers: expected failure test case
    @Test
    func expectedFailure() {
        let calculator = Calculator()
        withKnownIssue {
            let result = calculator.subtract(1, 2)
            #expect(Bool(result == 2.0), "Failure is expected")
        }
    }
    
    static nonisolated(unsafe) var shouldFail = true
    // Covers: flaky test case
    @Test
    func flacky() {
        let calculator = Calculator()
        if Self.shouldFail {
            let result = calculator.add(1, 1)
            Issue.record("Flacky failure message: result was \(result)")
        }
        Self.shouldFail = false
    }
    
    // Covers: parameterized test case
    @Test(arguments: [true, false])
    func flackyParameterized(value: Bool) {
        let calculator = Calculator()
        if value {
            let result = calculator.add(2, 2)
            #expect(result == 4.0)
        } else {
            let result = calculator.multiply(2, 2)
            #expect(result == 5.0) // This will fail for false case
        }
    }
    
    // Covers: async test case
    @Test
    func async() async {
        let calculator = Calculator()
        // Simulate async operation
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        let result = calculator.add(2, 3)
        #expect(result == 5.0)
    }
    
    // Covers: throwing test case that throws error
    @Test
    func throwing() throws {
        let calculator = Calculator()
        // This will throw CalculatorError.divisionByZero
        _ = try calculator.divide(10, 0)
    }
    
    // Covers: test attachment case
    @Test
    func withAttachment() {
        let calculator = Calculator()
        let result = calculator.add(2, 3)
        #expect(result == 5.0)
        
        Attachment.record("Test result: \(result)", named: "Calculation Result")
    }
    
    func withWarning() {
#warning("Some warning from ExampleSUITests")
        #expect(Bool(true))
    }
}
