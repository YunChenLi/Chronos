import SwiftUI
import Foundation
import UserNotifications
internal import Combine

/// App 的核心數據中心 (Single Source of Truth)
class AppViewModel: ObservableObject {
    
    // MARK: - Published Properties (數據發佈)
    // 當這些屬性改變時，SwiftUI 會自動透過內部生成的 objectWillChange 通知介面更新
    
    @Published var appointments: [Appointment] = []
    @Published var members: [Member] = []
    @Published var expenses: [Expense] = []
    @Published var incomes: [Income] = []
    @Published var userProfile: UserProfile = UserProfile(name: "使用者", currency: "TWD")
    
    // MARK: - Storage Keys (儲存鍵值)
    
    private let kAppointments = "StoredAppointments"
    private let kMembers = "StoredMembers"
    private let kExpenses = "StoredExpenses"
    private let kIncomes = "StoredIncomes"
    private let kUserProfile = "StoredUserProfile"
    
    // MARK: - Initialization
    
    init() {
        loadAllData()
    }
    
    // MARK: - Data Management (資料管理)
    var isLoggedIn: Bool = false
    /// 從本地載入所有數據
    func loadAllData() {
        appointments = loadData(key: kAppointments, type: [Appointment].self) ?? []
        members = loadData(key: kMembers, type: [Member].self) ?? []
        expenses = loadData(key: kExpenses, type: [Expense].self) ?? []
        incomes = loadData(key: kIncomes, type: [Income].self) ?? []
        userProfile = loadData(key: kUserProfile, type: UserProfile.self) ?? UserProfile()
    }
    
    /// 將目前所有狀態存回本地
    func saveAllData() {
        saveData(data: appointments, key: kAppointments)
        saveData(data: members, key: kMembers)
        saveData(data: expenses, key: kExpenses)
        saveData(data: incomes, key: kIncomes)
        saveData(data: userProfile, key: kUserProfile)
    }
    
    // MARK: - Business Logic (業務邏輯)
    
    /// 刪除預約並移除相關通知
    func deleteAppointments(at offsets: IndexSet) {
        let sorted = appointments.sorted(by: { $0.date < $1.date })
        let itemsToDelete = offsets.map { sorted[$0] }
        
        for item in itemsToDelete {
            if let index = appointments.firstIndex(where: { $0.id == item.id }) {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
                appointments.remove(at: index)
            }
        }
        saveAllData()
    }
    
    /// 請求通知權限
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    // MARK: - Generic Persistence Helpers (泛型儲存工具)
    
    /// 讀取邏輯：讀取 Data 並解碼
    private func loadData<T: Decodable>(key: String, type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("❌ 解碼失敗 (\(key)): \(error)")
            return nil
        }
    }
    
    /// 儲存邏輯：編碼為 Data 並儲存
    private func saveData<T: Encodable>(data: T, key: String) {
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: key)
        } catch {
            print("❌ 編碼失敗 (\(key)): \(error)")
        }
    }
}
