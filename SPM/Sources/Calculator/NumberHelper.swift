import Foundation

/// NumberHelper service for number-related utility operations
/// 
/// NOTE: This file is intentionally NOT covered by tests.
/// It exists to demonstrate that code coverage is calculated separately
/// for different files within the same module. When running tests,
/// this file should show 0% coverage, while Calculator.swift will show
/// partial coverage based on which Calculator methods are tested.
public struct NumberHelper {
    
    /// Check if a number is even
    public func isEven(_ number: Int) -> Bool {
        return number % 2 == 0
    }
    
    /// Check if a number is odd
    public func isOdd(_ number: Int) -> Bool {
        return number % 2 != 0
    }
    
    /// Check if a number is prime
    public func isPrime(_ number: Int) -> Bool {
        guard number > 1 else { return false }
        guard number != 2 else { return true }
        guard number % 2 != 0 else { return false }
        
        let sqrt = Int(Double(number).squareRoot())
        for i in stride(from: 3, through: sqrt, by: 2) {
            if number % i == 0 {
                return false
            }
        }
        return true
    }
    
    /// Get greatest common divisor of two numbers
    public func gcd(_ a: Int, _ b: Int) -> Int {
        var a = abs(a)
        var b = abs(b)
        while b != 0 {
            let temp = b
            b = a % b
            a = temp
        }
        return a
    }
    
    /// Get least common multiple of two numbers
    public func lcm(_ a: Int, _ b: Int) -> Int {
        return abs(a * b) / gcd(a, b)
    }
    
    /// Round number to specified decimal places
    public func round(_ number: Double, toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return Foundation.round(number * multiplier) / multiplier
    }
}
