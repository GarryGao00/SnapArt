//
//  quicktest.swift
//  SnapArt
//
//  Created by Garry Mackinaw on 1/24/25.
//

//
//  quicktest.swift
//  SnapArt
//
//  Created by Garry Mackinaw on 1/24/25.
//

import Foundation

// Simple test to verify config reading
func testConfigReading() {
    do {
        // Print current directory for debugging
        print("Current directory: \(FileManager.default.currentDirectoryPath)")
        
        // Try to read config file directly first
        let configPath = "./SnapArt/Config.xcconfig"
        guard FileManager.default.fileExists(atPath: configPath) else {
            print("❌ Config file not found at path: \(configPath)")
            return
        }
        
        print("✅ Found config file at: \(configPath)")
        
        // Test Configuration class directly
        if let stabilityKey = try? Configuration.value(for: "STABILITY_KEY") as String {
            print("✅ Found Stability API Key: length=\(stabilityKey.count)")
        } else {
            print("❌ Could not read Stability API Key")
        }
        
        if let openAIKey = try? Configuration.value(for: "OPENAI_API_KEY") as String {
            print("✅ Found OpenAI API Key: length=\(openAIKey.count)")
        } else {
            print("❌ Could not read OpenAI API Key")
        }
        
        // Test APIKeys enum
        let stabilityKeyFromEnum = APIKeys.stabilityKey
        let openAIKeyFromEnum = APIKeys.openAIKey
        
        print("\nTesting via APIKeys enum:")
        print("Stability Key length: \(stabilityKeyFromEnum.count)")
        print("OpenAI Key length: \(openAIKeyFromEnum.count)")
        
    } catch {
        print("❌ Error: \(error)")
    }
}

// Copy Configuration enum implementation
enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue, configFileNotFound
    }
    
    private static func readConfigFile() throws -> [String: String] {
        let configPath = "./SnapArt/Config.xcconfig"
        
        do {
            let contents = try String(contentsOfFile: configPath, encoding: .utf8)
            print("✅ Successfully read config file contents")
            var config: [String: String] = [:]
            
            contents.components(separatedBy: .newlines).forEach { line in
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    config[key] = value
                    print("Found config entry: \(key)")
                }
            }
            return config
        } catch {
            print("❌ Error reading config file: \(error.localizedDescription)")
            throw Error.configFileNotFound
        }
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        let config = try readConfigFile()
        
        guard let value = config[key] else {
            print("Missing configuration key: \(key)")
            throw Error.missingKey
        }

        print("Found value for \(key): \(value)")

        switch T.self {
        case is String.Type:
            return value as! T
        default:
            guard let convertedValue = T(value) else {
                print("Could not convert value to required type: \(value)")
                throw Error.invalidValue
            }
            return convertedValue
        }
    }
}

enum APIKeys {
    static var stabilityKey: String {
        let key = (try? Configuration.value(for: "STABILITY_KEY")) ?? ""
        print("Stability API Key length: \(key.count)")
        return key
    }
    
    static var openAIKey: String {
        let key = (try? Configuration.value(for: "OPENAI_API_KEY")) ?? ""
        print("OpenAI API Key length: \(key.count)")
        return key
    }
}

// Execute the test
testConfigReading()