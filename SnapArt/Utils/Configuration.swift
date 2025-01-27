import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue, configFileNotFound
    }
    
    private static func readConfigFile() throws -> [String: String] {
        // First try to find the config file in the app bundle
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "xcconfig") else {
            print("❌ Config file not found in bundle")
            throw Error.configFileNotFound
        }
        
        print("📁 Found config file at: \(configPath)")
        
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
                    print("📝 Found config entry: \(key)")
                }
            }
            return config
        } catch {
            print("❌ Error reading config file: \(error.localizedDescription)")
            throw Error.configFileNotFound
        }
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        // Read from Config.xcconfig file
        let config = try readConfigFile()
        
        guard let value = config[key] else {
            print("❌ Missing configuration key: \(key)")
            throw Error.missingKey
        }

        print("✅ Found value for \(key)")

        // Convert the value to the required type
        switch T.self {
        case is String.Type:
            return value as! T
        default:
            guard let convertedValue = T(value) else {
                print("❌ Could not convert value to required type: \(value)")
                throw Error.invalidValue
            }
            return convertedValue
        }
    }
}

enum APIKeys {
    static var stabilityKey: String {
        let key = (try? Configuration.value(for: "STABILITY_KEY")) ?? ""
        print("🔑 Stability API Key length: \(key.count)")
        return key
    }
    
    static var openAIKey: String {
        let key = (try? Configuration.value(for: "OPENAI_API_KEY")) ?? ""
        print("🔑 OpenAI API Key length: \(key.count)")
        return key
    }
} 