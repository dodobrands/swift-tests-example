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

    // Covers: multiple attachments on a single test
    @Test
    func withMultipleAttachments() {
        let calculator = Calculator()
        let sum = calculator.add(2, 3)
        let product = calculator.multiply(2, 3)
        #expect(sum == 5.0)
        #expect(product == 6.0)

        Attachment.record("Sum: \(sum)", named: "Sum result")
        Attachment.record("Product: \(product)", named: "Product result")
        Attachment.record("Inputs were 2 and 3", named: "Operands")
    }

    // Covers: attachment recorded on a test that also reports a failure —
    // exercised by Peekie's `isAssociatedWithFailure: true` codepath.
    @Test
    func failureWithAttachment() {
        let calculator = Calculator()
        let result = calculator.multiply(2, 3)
        Attachment.record(
            "Operands: 2 and 3, expected 5, got \(result)",
            named: "Failure context"
        )
        Issue.record("Expected 5.0 but got \(result)")
    }

    func withWarning() {
#warning("Some warning from ExampleSUITests")
        #expect(Bool(true))
    }
}

// MARK: - Root level tests (no enclosing @Suite)
//
// Demonstrates Swift Testing's ability to declare @Test functions at file
// scope, without wrapping them in a @Suite type. Peekie needs to surface
// these tests in its report (issue #127 / PR #151).

// Covers: root-level success test case
@Test
func rootLevelSuccess() {
    let calculator = Calculator()
    let result = calculator.add(2, 3)
    #expect(result == 5.0)
}

// Covers: root-level failure test case
@Test
func rootLevelFailure() {
    let calculator = Calculator()
    let result = calculator.multiply(2, 3)
    Issue.record("Expected 5.0 but got \(result)")
}

// Covers: root-level async test case
@Test
func rootLevelAsync() async {
    let calculator = Calculator()
    try? await Task.sleep(nanoseconds: 10_000_000)
    let result = calculator.add(2, 3)
    #expect(result == 5.0)
}

// Covers: attachment recorded from a root-level @Test (no enclosing @Suite).
@Test
func rootLevelWithAttachment() {
    let calculator = Calculator()
    let result = calculator.add(4, 4)
    #expect(result == 8.0)

    Attachment.record("Root-level recorded value: \(result)", named: "Root attachment")
}

// Covers: root-level test with a backtick-escaped name (spaces, punctuation)
@Test
func `root level with spaces in name`() {
    let calculator = Calculator()
    #expect(calculator.add(1, 2) == 3.0)
}

// Covers: root-level test whose name contains punctuation and operators
@Test
func `2 + 3 = 5`() {
    let calculator = Calculator()
    #expect(calculator.add(2, 3) == 5.0)
}

// Covers: backtick name with an emoji
@Test
func `success 🎯`() {
    let calculator = Calculator()
    #expect(calculator.add(1, 1) == 2.0)
}

// Covers: backtick name with parentheses and a slash
@Test
func `divide(10, 2) / returns 5`() {
    let calculator = Calculator()
    #expect((try? calculator.divide(10, 2)) == 5.0)
}

// Covers: backtick name with Cyrillic characters
@Test
func `сложение работает`() {
    let calculator = Calculator()
    #expect(calculator.add(7, 8) == 15.0)
}

// Covers: backtick name with square brackets and a question mark
@Test
func `array[0] is nil?`() {
    let array: [Int] = []
    #expect(array.first == nil)
}

// MARK: - Nested @Suite
//
// Demonstrates a @Suite type declared inside another @Suite type. The
// resulting hierarchy is multiple suite levels deep (PR #151).

@Suite
struct OuterSuite {
    // Covers: success in the outer level of a nested suite hierarchy
    @Test
    func outerSuccess() {
        let calculator = Calculator()
        let result = calculator.add(10, 20)
        #expect(result == 30.0)
    }

    // Covers: failure in the outer level of a nested suite hierarchy
    @Test
    func outerFailure() {
        let calculator = Calculator()
        let result = calculator.multiply(10, 20)
        Issue.record("Outer suite failure: result was \(result)")
    }

    // Covers: backtick-escaped name inside an outer suite
    @Test
    func `outer with spaces in name`() {
        let calculator = Calculator()
        #expect(calculator.add(5, 5) == 10.0)
    }

    @Suite
    struct InnerSuite {
        // Covers: success in the inner level of a nested suite hierarchy
        @Test
        func innerSuccess() {
            let calculator = Calculator()
            let result = calculator.subtract(10, 3)
            #expect(result == 7.0)
        }

        // Covers: failure in the inner level of a nested suite hierarchy
        @Test
        func innerFailure() {
            let calculator = Calculator()
            let result = calculator.multiply(3, 4)
            Issue.record("Inner suite failure: result was \(result)")
        }

        @Suite
        struct DeeplyNestedSuite {
            // Covers: success in a three-level nested suite hierarchy
            @Test
            func deeplyNestedSuccess() {
                let calculator = Calculator()
                let result = calculator.add(1, 1)
                #expect(result == 2.0)
            }

            // Covers: failure in a three-level nested suite hierarchy
            @Test
            func deeplyNestedFailure() {
                let calculator = Calculator()
                let result = calculator.subtract(1, 1)
                Issue.record("Deeply nested failure: result was \(result)")
            }

            // Covers: attachment recorded in a three-level nested @Suite.
            @Test
            func deeplyNestedWithAttachment() {
                let calculator = Calculator()
                let result = calculator.multiply(6, 7)
                #expect(result == 42.0)

                Attachment.record(
                    "Recorded inside DeeplyNestedSuite, result: \(result)",
                    named: "Deeply nested attachment"
                )
            }
        }
    }
}
