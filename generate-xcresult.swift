#!/usr/bin/env swift

import Foundation

// Platform configurations
struct PlatformConfig {
    let name: String
    let simulatorName: String
    let deviceType: String
    let runtime: String
    
    var destination: String {
        if name == "macOS" {
            return "platform=macOS"
        } else {
            return "platform=\(name) Simulator,name=\(simulatorName)"
        }
    }
}

let platforms: [PlatformConfig] = [
    PlatformConfig(name: "macOS", simulatorName: "", deviceType: "", runtime: ""),
    PlatformConfig(name: "iOS", simulatorName: "iPhone 15", deviceType: "iPhone 15", runtime: "iOS"),
    PlatformConfig(name: "tvOS", simulatorName: "Apple TV", deviceType: "Apple TV", runtime: "tvOS"),
    PlatformConfig(name: "watchOS", simulatorName: "Apple Watch Series 9 (45mm)", deviceType: "Apple Watch Series 9 (45mm)", runtime: "watchOS"),
    PlatformConfig(name: "visionOS", simulatorName: "Apple Vision Pro", deviceType: "Apple Vision Pro", runtime: "visionOS")
]

let fileManager = FileManager.default

// Get current working directory
let currentDirectory = fileManager.currentDirectoryPath

// SPM package directory
let spmDirectory = "\(currentDirectory)/SPM"

// Xcworkspace directory and paths
let xcworkspaceDirectory = "\(currentDirectory)/Xcworkspace"
let xcworkspacePath = "\(xcworkspaceDirectory)/XcworkspaceExample.xcworkspace"
let workspaceScheme = "XcodeprojExample"
let workspaceTestPlan = "XcodeprojExample"

// Platforms supported by xcworkspace (iOS, macOS, visionOS)
let workspacePlatforms: [PlatformConfig] = [
    PlatformConfig(name: "macOS", simulatorName: "", deviceType: "", runtime: ""),
    PlatformConfig(name: "iOS", simulatorName: "iPhone 15", deviceType: "iPhone 15", runtime: "iOS"),
    PlatformConfig(name: "visionOS", simulatorName: "Apple Vision Pro", deviceType: "Apple Vision Pro", runtime: "visionOS")
]

// Helper function to run shell command
func runCommand(_ command: String, arguments: [String] = []) -> (output: String, exitCode: Int32) {
    // Create temporary file for output
    // Note: Using a temp file instead of Pipe because commands like "simctl list runtimes -j"
    // would hang when using Pipe. Writing to a file avoids this issue.
    let tempDir = FileManager.default.temporaryDirectory
    let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
    
    defer {
        // Clean up temp file in any case
        try? FileManager.default.removeItem(at: tempFile)
    }
    
    do {
        FileManager.default.createFile(atPath: tempFile.path, contents: nil, attributes: nil)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        
        // Redirect output to temp file instead of Pipe
        let fileHandle = try FileHandle(forWritingTo: tempFile)
        process.standardOutput = fileHandle
        process.standardError = fileHandle
        
        try process.run()
        process.waitUntilExit()
        
        // Close file handle before reading
        try fileHandle.close()
        
        let data = try Data(contentsOf: tempFile)
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return (output, process.terminationStatus)
    } catch {
        return ("", 1)
    }
}

// Get Xcode version
let (xcodeVersionOutput, _) = runCommand("/usr/bin/xcodebuild", arguments: ["-version", "-quiet"])
let versionLines = xcodeVersionOutput.components(separatedBy: .newlines)
guard let firstLine = versionLines.first else {
    print("Error: Failed to parse Xcode version")
    exit(1)
}

let versionComponents = firstLine.components(separatedBy: .whitespaces)
guard versionComponents.count >= 2 else {
    print("Error: Failed to parse Xcode version")
    exit(1)
}

let xcodeVersion = versionComponents[1]
print("Detected Xcode version: \(xcodeVersion)\n")

// Function to find available runtime
func findRuntime(for platform: String) -> String? {
    let (output, _) = runCommand("/usr/bin/xcrun", arguments: ["simctl", "list", "runtimes", "-j"])
    
    guard let jsonData = output.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
          let runtimes = json["runtimes"] as? [[String: Any]] else {
        return nil
    }
    
    // Find the latest runtime for the platform
    let matchingRuntimes = runtimes.filter { runtime in
        guard let name = runtime["name"] as? String else { return false }
        return name.contains(platform)
    }
    
    // Sort by version and get the latest
    let sorted = matchingRuntimes.sorted { (a, b) -> Bool in
        let versionA = a["version"] as? String ?? ""
        let versionB = b["version"] as? String ?? ""
        return versionA < versionB
    }
    
    return sorted.last?["identifier"] as? String
}

// Function to create simulator and return its UUID
func createSimulator(config: PlatformConfig) -> String? {
    guard let runtime = findRuntime(for: config.runtime) else {
        print("⚠️  Warning: Could not find runtime for \(config.runtime)")
        return nil
    }
    
    print("Creating simulator: \(config.simulatorName) (\(config.runtime))...")
    let (output, exitCode) = runCommand("/usr/bin/xcrun", arguments: [
        "simctl", "create", config.simulatorName,
        config.deviceType,
        runtime
    ])
    
    if exitCode == 0 {
        // Extract UUID from output (simctl create returns UUID)
        let uuid = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if !uuid.isEmpty {
            print("✅ Simulator created successfully (UUID: \(uuid))")
            return uuid
        } else {
            print("⚠️  Warning: Simulator creation succeeded but UUID is empty")
            return nil
        }
    } else {
        print("⚠️  Warning: Failed to create simulator: \(output)")
        return nil
    }
}

// Helper function to run xcodebuild command
func runXcodebuild(arguments: [String], workingDirectory: String? = nil) -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
    process.arguments = arguments
    
    // Set working directory if provided
    if let workingDir = workingDirectory {
        process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
    }
    
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    
    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    } catch {
        print("Error: Failed to run xcodebuild: \(error)")
        return 1
    }
}

// Function to find the most recent xcresult file in DerivedData
func findLatestXcresult(in derivedDataPath: String) -> String? {
    guard fileManager.fileExists(atPath: derivedDataPath) else {
        return nil
    }
    
    guard let enumerator = fileManager.enumerator(atPath: derivedDataPath) else {
        return nil
    }
    
    var xcresultFiles: [(path: String, modificationDate: Date)] = []
    
    // Recursively search for .xcresult files
    while let element = enumerator.nextObject() as? String {
        if element.hasSuffix(".xcresult") {
            let fullPath = "\(derivedDataPath)/\(element)"
            if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
               let modificationDate = attributes[.modificationDate] as? Date {
                xcresultFiles.append((path: fullPath, modificationDate: modificationDate))
            }
        }
    }
    
    // Sort by modification date (most recent first) and return the latest
    xcresultFiles.sort { $0.modificationDate > $1.modificationDate }
    return xcresultFiles.first?.path
}

// Function to run tests for SPM package
func runSPMTests(for platform: PlatformConfig, xcodeVersion: String) -> String? {
    print("\n" + String(repeating: "=", count: 60))
    print("Testing on \(platform.name)")
    print(String(repeating: "=", count: 60))
    
    // Get simulator UUID
    var simulatorUUID: String? = nil
    if platform.name != "macOS" {
        if let uuid = createSimulator(config: platform) {
            simulatorUUID = uuid
        } else {
            print("⚠️  Skipping \(platform.name) tests - simulator creation failed")
            return nil
        }
    }
    
    // Build destination string
    let destination: String
    if platform.name == "macOS" {
        destination = platform.destination
    } else if let uuid = simulatorUUID {
        destination = "platform=\(platform.name) Simulator,id=\(uuid)"
    } else {
        print("⚠️  Skipping \(platform.name) tests - no simulator UUID available")
        return nil
    }
    
    // Create output directory if it doesn't exist
    let outputDirectoryPath = "\(currentDirectory)/xcresults"
    if !fileManager.fileExists(atPath: outputDirectoryPath) {
        do {
            try fileManager.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true)
        } catch {
            print("⚠️  Warning: Failed to create output directory: \(error)")
        }
    }
    
    // Use temporary derivedDataPath to find the generated xcresult
    // Note: We use -derivedDataPath instead of -resultBundlePath because in Xcode 26.1.1,
    // when explicitly specifying -resultBundlePath, the generated xcresult file doesn't contain
    // code coverage data. This appears to be a bug in xcodebuild. As a workaround, we specify
    // -derivedDataPath and manually locate the generated xcresult file in the DerivedData directory.
    let tempDerivedDataPath = "\(spmDirectory)/DerivedData"

    // Wipe DerivedData so incremental builds don't suppress compiler diagnostics
    // (e.g. DeprecatedDeclaration / No-usage warnings disappear on incremental
    // rebuilds when source files haven't changed since the last cached build).
    if fileManager.fileExists(atPath: tempDerivedDataPath) {
        print("🧹 Cleaning DerivedData at \(tempDerivedDataPath)")
        try? fileManager.removeItem(atPath: tempDerivedDataPath)
    }

    // Run tests with a single test command
    // Using a single "test" command (instead of separating build-for-testing and test-without-building)
    // ensures that both build warnings from source code compilation and test warnings from test execution
    // are included in the generated xcresult bundle.
    print("\n🧪 Running tests...")
    let testExitCode = runXcodebuild(arguments: [
        "test",
        "-quiet",
        "-scheme", "Examples-Package",
        "-destination", destination,
        "-enableCodeCoverage", "YES",
        "-retry-tests-on-failure",
        "-test-iterations", "3",
        "-collect-test-diagnostics", "never",
        "-enablePerformanceTestsDiagnostics", "NO",
        "-derivedDataPath", tempDerivedDataPath
    ], workingDirectory: spmDirectory)
    
    // Find the generated xcresult file
    guard let generatedXcresultPath = findLatestXcresult(in: tempDerivedDataPath) else {
        print("⚠️  Warning: Could not find generated xcresult file")
        return nil
    }
    
    // Move to final location
    let finalResultBundlePath = "\(currentDirectory)/xcresults/SPM-\(xcodeVersion)-\(platform.name).xcresult"
    
    // Remove existing file if it exists
    if fileManager.fileExists(atPath: finalResultBundlePath) {
        try? fileManager.removeItem(atPath: finalResultBundlePath)
    }
    
    do {
        try fileManager.moveItem(atPath: generatedXcresultPath, toPath: finalResultBundlePath)
    } catch {
        print("⚠️  Warning: Failed to move xcresult file: \(error)")
        return nil
    }
    
    if testExitCode == 0 {
        print("\n✅ Success! Tests completed successfully")
        print("📦 xcresult file saved at: \(finalResultBundlePath)")
        return finalResultBundlePath
    } else {
        print("\n⚠️  Tests completed with exit code: \(testExitCode)")
        print("📦 xcresult file saved at: \(finalResultBundlePath)")
        return finalResultBundlePath
    }
}

// Function to run tests for xcworkspace
func runWorkspaceTests(for platform: PlatformConfig, xcodeVersion: String) -> String? {
    print("\n" + String(repeating: "=", count: 60))
    print("Testing xcworkspace on \(platform.name)")
    print(String(repeating: "=", count: 60))
    
    // Get simulator UUID
    var simulatorUUID: String? = nil
    if platform.name != "macOS" {
        if let uuid = createSimulator(config: platform) {
            simulatorUUID = uuid
        } else {
            print("⚠️  Skipping \(platform.name) tests - simulator creation failed")
            return nil
        }
    }
    
    // Build destination string
    let destination: String
    if platform.name == "macOS" {
        destination = platform.destination
    } else if let uuid = simulatorUUID {
        destination = "platform=\(platform.name) Simulator,id=\(uuid)"
    } else {
        print("⚠️  Skipping \(platform.name) tests - no simulator UUID available")
        return nil
    }
    
    // Create output directory if it doesn't exist
    let outputDirectoryPath = "\(currentDirectory)/xcresults"
    if !fileManager.fileExists(atPath: outputDirectoryPath) {
        do {
            try fileManager.createDirectory(atPath: outputDirectoryPath, withIntermediateDirectories: true)
        } catch {
            print("⚠️  Warning: Failed to create output directory: \(error)")
        }
    }
    
    // Use temporary derivedDataPath to find the generated xcresult
    // Note: We use -derivedDataPath instead of -resultBundlePath because in Xcode 26.1.1,
    // when explicitly specifying -resultBundlePath, the generated xcresult file doesn't contain
    // code coverage data. This appears to be a bug in xcodebuild. As a workaround, we specify
    // -derivedDataPath and manually locate the generated xcresult file in the DerivedData directory.
    let tempDerivedDataPath = "\(xcworkspaceDirectory)/DerivedData"

    // Wipe DerivedData so incremental builds don't suppress compiler diagnostics
    // (e.g. DeprecatedDeclaration / No-usage warnings disappear on incremental
    // rebuilds when source files haven't changed since the last cached build).
    if fileManager.fileExists(atPath: tempDerivedDataPath) {
        print("🧹 Cleaning DerivedData at \(tempDerivedDataPath)")
        try? fileManager.removeItem(atPath: tempDerivedDataPath)
    }

    // Run tests with a single test command
    // Using a single "test" command (instead of separating build-for-testing and test-without-building)
    // ensures that both build warnings from source code compilation and test warnings from test execution
    // are included in the generated xcresult bundle.
    // On macOS, disable app sandbox / hardened runtime for the host app.
    // Xcode 26.5 regression: with sandbox enabled, the llvm coverage runtime cannot
    // write profraw to the path xccov expects, so the result bundle ends up without
    // a coverage archive (xccov view fails with "Failed to load coverage archive").
    // Affects workspace + macOS app-host only; iOS/visionOS via simctl are fine.
    var sandboxOverrides: [String] = []
    if platform.name == "macOS" {
        sandboxOverrides = ["ENABLE_APP_SANDBOX=NO", "ENABLE_HARDENED_RUNTIME=NO"]
    }
    print("\n🧪 Running tests...")
    let testExitCode = runXcodebuild(arguments: [
        "test",
        "-quiet",
        "-workspace", xcworkspacePath,
        "-scheme", workspaceScheme,
        "-destination", destination,
        "-testPlan", workspaceTestPlan,
        "-enableCodeCoverage", "YES",
        "-retry-tests-on-failure",
        "-test-iterations", "3",
        "-collect-test-diagnostics", "never",
        "-enablePerformanceTestsDiagnostics", "NO",
        "-derivedDataPath", tempDerivedDataPath
    ] + sandboxOverrides, workingDirectory: xcworkspaceDirectory)
    
    // Find the generated xcresult file
    guard let generatedXcresultPath = findLatestXcresult(in: tempDerivedDataPath) else {
        print("⚠️  Warning: Could not find generated xcresult file")
        return nil
    }
    
    // Move to final location
    let finalResultBundlePath = "\(currentDirectory)/xcresults/Xcworkspace-\(xcodeVersion)-\(platform.name).xcresult"
    
    // Remove existing file if it exists
    if fileManager.fileExists(atPath: finalResultBundlePath) {
        try? fileManager.removeItem(atPath: finalResultBundlePath)
    }
    
    do {
        try fileManager.moveItem(atPath: generatedXcresultPath, toPath: finalResultBundlePath)
    } catch {
        print("⚠️  Warning: Failed to move xcresult file: \(error)")
        return nil
    }
    
    if testExitCode == 0 {
        print("\n✅ Success! Tests completed successfully")
        print("📦 xcresult file saved at: \(finalResultBundlePath)")
        return finalResultBundlePath
    } else {
        print("\n⚠️  Tests completed with exit code: \(testExitCode)")
        print("📦 xcresult file saved at: \(finalResultBundlePath)")
        return finalResultBundlePath
    }
}

// Run tests for all platforms
var xcresultPaths: [String] = []

print("\n" + String(repeating: "=", count: 60))
print("Running SPM Package Tests")
print(String(repeating: "=", count: 60))

for platform in platforms {
    if let xcresultPath = runSPMTests(for: platform, xcodeVersion: xcodeVersion) {
        xcresultPaths.append(xcresultPath)
    }
}

print("\n" + String(repeating: "=", count: 60))
print("Running Xcworkspace Tests")
print(String(repeating: "=", count: 60))

for platform in workspacePlatforms {
    if let xcresultPath = runWorkspaceTests(for: platform, xcodeVersion: xcodeVersion) {
        xcresultPaths.append(xcresultPath)
    }
}

// Summary
print("\n" + String(repeating: "=", count: 60))
print("Summary")
print(String(repeating: "=", count: 60))

if !xcresultPaths.isEmpty {
    print("Found xcresult files:")
    for xcresult in xcresultPaths {
        print("  - \(xcresult)")
    }
} else {
    print("⚠️  No xcresult files were generated")
}

exit(xcresultPaths.isEmpty ? 1 : 0)
