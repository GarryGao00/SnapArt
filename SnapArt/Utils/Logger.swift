import Foundation

enum Logger {
    static func log(_ action: String, file: String = #file) {
        let timestamp = getCurrentTimestamp()
        let fileName = (file as NSString).lastPathComponent
        print("📝 [\(timestamp)] [\(fileName)] \(action)")
    }
    
    private static func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy-MM-dd:HH:mm:ss"
        return formatter.string(from: Date())
    }
} 