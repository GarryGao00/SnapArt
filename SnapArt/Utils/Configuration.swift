import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue, configFileNotFound
    }
    
    private static var cachedConfig: [String: String]?
    
    private static func readConfigFile() throws -> [String: String] {
        // Return cached config if available
        if let cached = cachedConfig {
            return cached
        }
        
        // First try to find the config file in the app bundle
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "xcconfig") else {
            Logger.log("Config file not found in bundle")
            throw Error.configFileNotFound
        }
        
        Logger.log("Reading config file for the first time")
        
        do {
            let contents = try String(contentsOfFile: configPath, encoding: .utf8)
            var config: [String: String] = [:]
            
            contents.components(separatedBy: .newlines).forEach { line in
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    config[key] = value
                }
            }
            
            // Cache the config
            cachedConfig = config
            Logger.log("Config file cached successfully")
            
            return config
        } catch {
            Logger.log("Error reading config file: \(error.localizedDescription)")
            throw Error.configFileNotFound
        }
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        let config = try readConfigFile()
        
        guard let value = config[key] else {
            throw Error.missingKey
        }

        switch T.self {
        case is String.Type:
            return value as! T
        default:
            guard let convertedValue = T(value) else {
                throw Error.invalidValue
            }
            return convertedValue
        }
    }
}

enum APIKeys {
    private static var cachedStabilityKey: String?
    private static var cachedOpenAIKey: String?
    
    static var stabilityKey: String {
        if let cached = cachedStabilityKey {
            return cached
        }
        let key = (try? Configuration.value(for: "STABILITY_KEY")) ?? ""
        cachedStabilityKey = key
        Logger.log("Stability API Key cached (length: \(key.count))")
        return key
    }
    
    static var openAIKey: String {
        if let cached = cachedOpenAIKey {
            return cached
        }
        let key = (try? Configuration.value(for: "OPENAI_API_KEY")) ?? ""
        cachedOpenAIKey = key
        Logger.log("OpenAI API Key cached (length: \(key.count))")
        return key
    }
} 