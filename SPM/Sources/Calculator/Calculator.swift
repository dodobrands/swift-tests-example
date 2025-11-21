import Foundation

/// Calculator service for basic mathematical operations
public struct Calculator {
    
    /// Add two numbers
    public func add(_ a: Double, _ b: Double) -> Double {
        #warning("Some warning from Calculator")
        return a + b
    }
    
    /// Subtract two numbers
    public func subtract(_ a: Double, _ b: Double) -> Double {
        return a - b
    }
    
    /// Multiply two numbers
    public func multiply(_ a: Double, _ b: Double) -> Double {
        return a * b
    }
    
    /// Divide two numbers
    /// - Throws: CalculatorError.divisionByZero if divisor is zero
    public func divide(_ a: Double, _ b: Double) throws -> Double {
        guard b != 0 else {
            throw CalculatorError.divisionByZero
        }
        return a / b
    }
    
    /// Calculate power
    public func power(_ base: Double, _ exponent: Double) -> Double {
        return pow(base, exponent)
    }
    
    /// Calculate square root
    /// - Throws: CalculatorError.negativeNumber if number is negative
    public func squareRoot(_ number: Double) throws -> Double {
        guard number >= 0 else {
            throw CalculatorError.negativeNumber
        }
        return sqrt(number)
    }
    
    /// Calculate factorial
    /// - Throws: CalculatorError.negativeNumber if number is negative
    public func factorial(_ number: Int) throws -> Int {
        guard number >= 0 else {
            throw CalculatorError.negativeNumber
        }
        guard number > 1 else {
            return 1
        }
        return try factorial(number - 1) * number
    }
}

/// Calculator errors
public enum CalculatorError: Error {
    case divisionByZero
    case negativeNumber
}
