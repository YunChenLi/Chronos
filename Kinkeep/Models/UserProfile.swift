import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case chinese = "中文"
    case english = "English"
    case japanese = "日本語"
    
    var id: String { rawValue }
}

struct UserProfile: Codable {
    var isLoggedIn: Bool = false
    var loginProvider: String = ""
    var email: String = ""
    var name: String = ""
    var birthday: Date = Date()
    var language: AppLanguage = .chinese
    var currency: String
    
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year ?? 0
    }
}
