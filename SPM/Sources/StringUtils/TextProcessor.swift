import Foundation

/// TextProcessor service for text manipulation operations
/// 
/// NOTE: This module is intentionally NOT covered by tests.
/// It exists to demonstrate that code coverage is calculated separately
/// for different modules and files. When running tests, this module
/// should show 0% coverage, while the Calculator module
/// should show partial coverage based on which Calculator methods are tested.
public struct TextProcessor {
    
    /// Reverse a string
    public func reverse(_ text: String) -> String {
#warning("Some warning from StringUtils")
        return String(text.reversed())
    }
    
    /// Convert string to uppercase
    public func uppercase(_ text: String) -> String {
        return text.uppercased()
    }
    
    /// Convert string to lowercase
    public func lowercase(_ text: String) -> String {
        return text.lowercased()
    }
    
    /// Count words in a string
    public func wordCount(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    /// Remove whitespace from string
    public func removeWhitespace(_ text: String) -> String {
        return text.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
    }
    
    /// Capitalize first letter of each word
    public func capitalizeWords(_ text: String) -> String {
        return text.capitalized
    }
}
