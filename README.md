# Swift Tests Example

This repository contains comprehensive examples of all known test cases and frameworks for iOS, macOS, tvOS, watchOS, and other Apple platforms.

## Overview

This project demonstrates various testing scenarios using both XCTest and Swift Testing frameworks, showcasing different test outcomes and code coverage scenarios that appear in xcresult files.

- [Test Frameworks](#test-frameworks)
  - [XCTest](#xctest)
  - [Swift Testing](#swift-testing)
- [Supported Platforms](#supported-platforms)
- [Project Structure](#project-structure)
- [Available Test Types](#available-test-types)
- [Generating xcresult Files](#generating-xcresult-files)
  - [Usage](#usage)
  - [What It Does](#what-it-does)
  - [Output](#output)
- [Build Warnings in xcresult](#build-warnings-in-xcresult)

## Test Frameworks

This project demonstrates testing using both major Swift testing frameworks:

**XCTest** - The classic Apple testing framework that has been available since the early days of iOS and macOS development. It provides a comprehensive set of testing features including assertions, expectations, performance testing, and test attachments.

**Swift Testing** - The modern Swift testing framework introduced in Swift 5.9+. It offers a more Swift-native API with improved type safety, better async/await support, and features like parameterized tests and known issues handling.

Both frameworks are used in this project to test the same codebase, allowing comparison of how different testing approaches work with xcresult files. See the [Available Test Types](#available-test-types) table below for a comparison of supported test types in each framework.

## Supported Platforms

This project supports testing on all Apple platforms:

- **iOS** - iPhone and iPad
- **macOS** - Mac computers
- **tvOS** - Apple TV
- **watchOS** - Apple Watch
- **visionOS** - Apple Vision Pro

## Project Structure

This repository demonstrates how the same codebase produces different xcresult structures when built with different build systems. It contains two project configurations that share source files via symbolic links:

- **`SPM/`** - Multi-target Swift Package Manager project
- **`Xcworkspace/`** - Multi-module Xcode workspace with multiple Xcode projects

The key difference in generated xcresult files is that workspace projects organize results by module/project, while SPM projects present results at the file level without explicit target boundaries.

## Available Test Types

| Test Case | XCTest | Swift Testing |
|-----------|--------|---------------|
| Success | ✅ | ✅ |
| Failure | ✅ | ✅ |
| Skip/Disabled | ✅ | ✅ |
| Expected Failure | ✅ | ✅ |
| Flaky | ✅ | ✅ |
| Parameterized | ❌ | ✅ |
| Async | ✅ | ✅ |
| Throwing | ✅ | ✅ |
| Attachment | ✅ | ✅ |
| Performance | ✅ | ❌ |

**Note:** Missing test types (❌) indicate that the frameworks do not support these test types, at least as of today.

## Generating xcresult Files

The project includes a Swift script `generate-xcresult.swift` that automatically runs tests on all supported Apple platforms and generates xcresult files.

### Usage

```bash
swift generate-xcresult.swift
```

The script automatically saves all generated xcresult files to the `xcresults` directory in the project root.

### What It Does

1. **Detects Xcode version** automatically
2. **Runs tests for SPM Package:**
   - Tests all platforms: macOS, iOS, tvOS, watchOS, visionOS
   - Generates xcresult files with naming format: `SPM-<XcodeVersion>-<Platform>.xcresult`
3. **Runs tests for Xcode Workspace:**
   - Tests supported platforms: macOS, iOS, visionOS
   - Uses the test plan `XcodeprojExample.xctestplan`
   - Generates xcresult files with naming format: `Xcworkspace-<XcodeVersion>-<Platform>.xcresult`
4. **Checks for runtime availability** - if a runtime is not installed, shows a warning and skips xcresult generation for that platform. Note: Runtimes must be downloaded manually through Xcode if needed.
5. **Creates new simulators** - a new simulator is created for each platform on every script run
6. **Shows summary** with list of generated files

### Output

The script generates separate xcresult files for each project type and platform in the `xcresults` directory:

**SPM Package Results:**
- `xcresults/SPM-26.1.1-macOS.xcresult`
- `xcresults/SPM-26.1.1-iOS.xcresult`
- `xcresults/SPM-26.1.1-tvOS.xcresult`
- `xcresults/SPM-26.1.1-watchOS.xcresult`
- `xcresults/SPM-26.1.1-visionOS.xcresult`

**Xcode Workspace Results:**
- `xcresults/Xcworkspace-26.1.1-macOS.xcresult`
- `xcresults/Xcworkspace-26.1.1-iOS.xcresult`
- `xcresults/Xcworkspace-26.1.1-visionOS.xcresult`

## Build Warnings in xcresult

The generated xcresult files intentionally include both build warnings (from source code compilation) and test warnings (from test execution). These warnings are included by design and are part of the xcresult bundle structure.
