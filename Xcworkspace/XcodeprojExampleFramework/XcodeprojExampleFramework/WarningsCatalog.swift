import Foundation

// Intentional sample of compiler diagnostics: one trigger per known Xcode 26.x
// `issueType` value emitted in xcresult build-results. Peekie's regression
// suite asserts that each typed `IssueType` case shows up after parsing this
// bundle — so the day Apple renames one (or Peekie's enum mapping drifts),
// the suite breaks loudly instead of silently dropping warnings.
//
// Sendable / strict-concurrency diagnostics are intentionally NOT triggered
// here — under Swift 6 they hard-error and break the build. The
// `Main actor-isolated …` warnings already emitted by the existing test code
// cover the multiline-note shape Peekie's normalizer needs to handle.

// MARK: - DeprecatedDeclaration  (also exercises #161: dedup is dropped — 3 call sites)

@available(*, deprecated, message: "use newFoo()")
func oldFoo() -> Int { 0 }

func newFoo() -> Int { 1 }

@MainActor
struct DeprecatedUsage {
    func call1() -> Int { oldFoo() }
    func call2() -> Int { oldFoo() }
    func call3() -> Int { oldFoo() }
}

// MARK: - No-usage  (also exercises #161)

func unusedDeclarations() {
    let unusedA = 7
    let unusedB = "noisy"
    _ = unusedA
    _ = unusedB
}

// MARK: - Unreachable code / will never be executed

func unreachableExample() -> Int {
    return 1
    let after = 2  // warning: will never be executed
    return after
}

// MARK: - Result of call is unused (no @discardableResult)

func unusedResultProducer() -> Int { 42 }

func consumesNothing() {
    unusedResultProducer()  // warning: result of call to 'unusedResultProducer()' is unused
}

// MARK: - String interpolation of optional without explicit coercion

func interpolationProblem() -> String {
    let x: Int? = nil
    return "\(x)"  // warning: string interpolation produces a debug description for an optional value
}

// MARK: - Redundant conditional cast

class Foo {}
class Bar: Foo {}

func redundantCast(_ b: Bar) -> Foo? {
    return b as? Foo  // warning: conditional cast from 'Bar' to 'Foo' always succeeds
}

// MARK: - existential-any

protocol P {}

struct UsingExistential {
    let value: P  // warning: use of protocol 'P' as a type must be written 'any P'
}

// MARK: - useless-availability-check

func uselessAvailability() {
    if #available(iOS 1.0, *) {  // warning: unnecessary check for 'iOS'; minimum deployment target ensures guard will always be true
        _ = 0
    }
}

// MARK: - unnecessary-effect-marker

func nonThrowing() -> Int { 0 }

func unnecessaryTry() {
    _ = try? nonThrowing()  // warning: no calls to throwing functions occur within 'try' expression
}
