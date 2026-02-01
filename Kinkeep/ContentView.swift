import SwiftUI
import Foundation
import EventKit
import UserNotifications
import PhotosUI
import UIKit
import CoreImage.CIFilterBuiltins
import Charts
internal import Combine

// MARK: - 0. 擴充與輔助工具 (Extensions & Helpers)

extension Optional where Wrapped == String {
    var isEmptyOrNil: Bool {
        self?.isEmpty ?? true
    }
}

// 新增：定義 App 主題背景顏色 (#e0f9f4)
extension Color {
    static let themeBackground = Color(red: 224/255, green: 249/255, blue: 244/255)
}

// 相機選擇器
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            print("⚠️ 裝置不支援相機，切換至相簿模式 (模擬器限制)")
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - 1. 生活型態管理 (Lifestyle Manager)

enum LifestyleTag: String, CaseIterable, Codable, Identifiable {
    case diningOut = "外食族"
    case beauty = "愛美族"
    case parent = "有小孩"
    case pet = "有寵物"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .diningOut: return "fork.knife"
        case .beauty: return "sparkles"
        case .parent: return "figure.and.child"
        case .pet: return "pawprint.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .diningOut: return .orange
        case .beauty: return .pink
        case .parent: return .blue
        case .pet: return .brown
        }
    }
}

class LifestyleManager: ObservableObject {
    @Published var selectedTags: Set<LifestyleTag> = [] {
        didSet { saveTags() }
    }
    
    private let kSelectedTags = "StoredLifestyleTags"
    
    init() { loadTags() }
    
    private func saveTags() {
        if let encoded = try? JSONEncoder().encode(Array(selectedTags)) {
            UserDefaults.standard.set(encoded, forKey: kSelectedTags)
        }
    }
    
    private func loadTags() {
        if let data = UserDefaults.standard.data(forKey: kSelectedTags),
           let decoded = try? JSONDecoder().decode([LifestyleTag].self, from: data) {
            selectedTags = Set(decoded)
        }
    }
    
    var mainCategories: [String] {
        var base = ["食", "衣", "住", "行", "育", "樂"]
        base.append("預約服務")
        
        if selectedTags.contains(.beauty) {
            if let index = base.firstIndex(of: "衣") { base.insert("購物", at: index + 1) }
            else { base.append("購物") }
        }
        if selectedTags.contains(.parent) { base.insert("育兒", at: base.count - 1) }
        if selectedTags.contains(.pet) { base.insert("寵物", at: base.count - 1) }
        base.append("其他")
        return base
    }
    
    func getSubCategories(for main: String) -> [String] {
        switch main {
        case "食": return selectedTags.contains(.diningOut) ? ["早餐", "午餐", "晚餐", "宵夜", "零食", "飲料", "保健"] : ["三餐", "零食", "飲料", "保健"]
        case "衣": return ["服裝", "鞋子", "配件", "洗衣"]
        case "購物": return selectedTags.contains(.beauty) ? ["化妝品", "保養品", "服飾", "飾品"] : ["一般購物"]
        case "住": return ["房租", "水電", "家具", "維修", "日用品"]
        case "行": return ["交通費", "油錢", "停車費", "保養"]
        case "育": return ["書籍", "課程", "學習用品"]
        case "樂": return ["娛樂", "旅遊", "運動", "電影"]
        case "育兒": return ["奶粉", "尿布", "玩具", "教育", "醫療"]
        case "寵物": return ["飼料", "零食", "醫療", "美容", "用品"]
        case "預約服務": return ["剪髮", "美甲", "按摩", "其他服務"]
        case "其他": return []
        default: return ["其他"]
        }
    }
}

// MARK: - 2. 資料模型 (Data Models)

enum MemberRole: String, CaseIterable, Codable, Identifiable {
    case father = "爸爸"
    case mother = "媽媽"
    case son = "兒子"
    case daughter = "女兒"
    case grandparent = "長輩"
    case pet = "寵物"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .father: return "👨🏻"
        case .mother: return "👩🏻"
        case .son: return "👦🏻"
        case .daughter: return "👧🏻"
        case .grandparent: return "👴🏻"
        case .pet: return "🐶"
        case .other: return "👤"
        }
    }
    
    var color: Color {
        switch self {
        case .father: return .blue
        case .mother: return .red
        case .son: return .cyan
        case .daughter: return .pink
        case .grandparent: return .gray
        case .pet: return .brown
        case .other: return .indigo
        }
    }
}

struct Member: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var role: MemberRole = .other
}

struct Appointment: Identifiable, Codable {
    var id = UUID()
    var name: String
    var date: Date
    var service: String
    var email: String?
    var phone: String?
    var amount: Double?
    var photoDescription: String?
    var photoData: Data?
    var extraServiceDetail: String?

    var isPhotoAttached: Bool { return photoData != nil }
}

struct Expense: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var amount: Double
    var mainCategory: String
    var subCategory: String
    var note: String
    var memberId: UUID?
}

struct Income: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var amount: Double
    var category: IncomeCategory
    var note: String
}

enum IncomeCategory: String, CaseIterable, Codable, Identifiable {
    case active = "工作收入"
    case passive = "理財收入"
    case other = "其他收入"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .active: return "薪水、佣金、獎金"
        case .passive: return "房租、股利、利息"
        case .other: return "創業、斜槓、其他"
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "briefcase.fill"
        case .passive: return "chart.line.uptrend.xyaxis"
        case .other: return "star.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .blue
        case .passive: return .green
        case .other: return .orange
        }
    }
}

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
    
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year ?? 0
    }
}


// MARK: - 3. 主內容視圖 (ContentView)

struct ContentView: View {
    @StateObject private var lifestyleManager = LifestyleManager()
    
    @State private var appointments: [Appointment] = []
    @State private var members: [Member] = []
    @State private var expenses: [Expense] = []
    @State private var incomes: [Income] = []
    @State private var userProfile: UserProfile = UserProfile()
    
    private let kAppointments = "StoredAppointments"
    private let kMembers = "StoredMembers"
    private let kExpenses = "StoredExpenses"
    private let kIncomes = "StoredIncomes"
    private let kUserProfile = "StoredUserProfile"

    init() {
        _appointments = State(initialValue: Self.loadData(key: "StoredAppointments", type: [Appointment].self) ?? [])
        _members = State(initialValue: Self.loadData(key: "StoredMembers", type: [Member].self) ?? [])
        _expenses = State(initialValue: Self.loadData(key: "StoredExpenses", type: [Expense].self) ?? [])
        _incomes = State(initialValue: Self.loadData(key: "StoredIncomes", type: [Income].self) ?? [])
        _userProfile = State(initialValue: Self.loadData(key: "StoredUserProfile", type: UserProfile.self) ?? UserProfile())
        
        // 設定全域 TabView 背景色 (可選)
        UITabBar.appearance().backgroundColor = UIColor.white
    }

    var body: some View {
        TabView {
            AppointmentListView(
                appointments: $appointments,
                expenses: $expenses,
                members: members,
                saveAction: saveData,
                deleteAction: deleteAppointments
            )
            .tabItem { Label("預約", systemImage: "list.bullet.clipboard") }

            CalendarExpenseView(
                expenses: $expenses,
                appointments: appointments,
                members: members,
                saveAction: saveData
            )
            .environmentObject(lifestyleManager)
            .tabItem { Label("記帳", systemImage: "calendar") }

            IncomeExpenseReportView(
                appointments: appointments,
                expenses: expenses,
                incomes: $incomes,
                members: members,
                saveAction: saveData
            )
            .tabItem { Label("收支表", systemImage: "chart.pie.fill") }

            MemberManagementView(members: $members, saveAction: saveData)
                .tabItem { Label("成員", systemImage: "person.3.fill") }
            
            SettingsView(userProfile: $userProfile, saveAction: saveData)
                .tabItem { Label("設定", systemImage: "gear") }
        }
        .tint(.indigo)
        .onAppear(perform: requestNotificationPermission)
    }

    func saveData() {
        Self.saveData(data: appointments, key: kAppointments)
        Self.saveData(data: members, key: kMembers)
        Self.saveData(data: expenses, key: kExpenses)
        Self.saveData(data: incomes, key: kIncomes)
        Self.saveData(data: userProfile, key: kUserProfile)
    }
    
    func deleteAppointments(at offsets: IndexSet) {
        let sorted = appointments.sorted(by: { $0.date < $1.date })
        let itemsToDelete = offsets.map { sorted[$0] }
        
        for item in itemsToDelete {
            if let index = appointments.firstIndex(where: { $0.id == item.id }) {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
                appointments.remove(at: index)
            }
        }
        saveData()
    }

    static func saveData<T: Encodable>(data: T, key: String) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    static func loadData<T: Decodable>(key: String, type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

// MARK: - 9. 設定頁面 (Settings View)

struct SettingsView: View {
    @Binding var userProfile: UserProfile
    var saveAction: () -> Void
    
    @State private var showLoginAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("一般設定")) {
                    Picker("語言 / Language", selection: $userProfile.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                    .onChange(of: userProfile.language) { _, _ in saveAction() }
                }
                
                Section(header: Text("帳號登入")) {
                    if userProfile.isLoggedIn {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(
                                        userProfile.loginProvider == "Gmail" ? Color.red.opacity(0.1) :
                                        (userProfile.loginProvider == "Hotmail" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    )
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: userProfile.loginProvider == "Gmail" ? "g.circle.fill" : "envelope.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(
                                        userProfile.loginProvider == "Gmail" ? .red :
                                        (userProfile.loginProvider == "Hotmail" ? .blue : .gray)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userProfile.name.isEmpty ? "使用者" : userProfile.name)
                                    .font(.headline)
                                Text(userProfile.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("已透過 \(userProfile.loginProvider) 登入")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Button(role: .destructive) {
                            logout()
                        } label: {
                            HStack {
                                Spacer()
                                Text("登出帳號")
                                Spacer()
                            }
                        }
                        
                    } else {
                        Text("請選擇登入方式以同步資料並啟用進階功能。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .listRowSeparator(.hidden)
                        
                        Button {
                            performSimulatedLogin(provider: "Gmail", email: "user@gmail.com")
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill").foregroundColor(.red)
                                Text("使用 Google 帳號登入")
                                Spacer()
                            }
                        }
                        
                        Button {
                            performSimulatedLogin(provider: "Hotmail", email: "user@hotmail.com")
                        } label: {
                            HStack {
                                Image(systemName: "envelope.circle.fill").foregroundColor(.blue)
                                Text("使用 Hotmail 帳號登入")
                                Spacer()
                            }
                        }
                        
                        Button {
                            performSimulatedLogin(provider: "Apple", email: "user@icloud.com")
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("使用 Apple ID 登入")
                                Spacer()
                            }
                        }
                    }
                }
                
                if userProfile.isLoggedIn {
                    Section(header: Text("個人資料")) {
                        HStack {
                            Text("暱稱")
                            Spacer()
                            TextField("請輸入暱稱", text: $userProfile.name)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: userProfile.name) { _, _ in saveAction() }
                        }
                        
                        DatePicker("生日", selection: $userProfile.birthday, displayedComponents: .date)
                            .onChange(of: userProfile.birthday) { _, _ in saveAction() }
                        
                        HStack {
                            Text("年齡")
                            Spacer()
                            Text("\(userProfile.age) 歲")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("關於 App")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.3.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("開發者")
                        Spacer()
                        Text("Chronos")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden) // 隱藏預設背景
            .background(Color.themeBackground) // 應用自訂背景色
            .navigationTitle("設定")
            .alert("登入成功", isPresented: $showLoginAlert) {
                Button("確定") { }
            } message: {
                Text("歡迎回來，\(userProfile.email)")
            }
        }
    }
    
    func performSimulatedLogin(provider: String, email: String) {
        userProfile.isLoggedIn = true
        userProfile.loginProvider = provider
        userProfile.email = email
        if userProfile.name.isEmpty {
            userProfile.name = "新使用者"
        }
        saveAction()
        showLoginAlert = true
    }
    
    func logout() {
        withAnimation {
            userProfile.isLoggedIn = false
            userProfile.loginProvider = ""
            userProfile.email = ""
            userProfile.name = ""
            saveAction()
        }
    }
}

// MARK: - 4. 預約列表 (Appointment List)
struct AppointmentListView: View {
    @Binding var appointments: [Appointment]
    @Binding var expenses: [Expense]
    let members: [Member]
    var saveAction: () -> Void
    var deleteAction: (IndexSet) -> Void

    @State private var isShowingAdd = false

    var body: some View {
        NavigationView {
            Group {
                if appointments.isEmpty {
                    ContentUnavailableView("目前沒有預約", systemImage: "calendar.badge.plus", description: Text("點擊右上角「+」新增預約"))
                        .background(Color.themeBackground)
                } else {
                    List {
                        ForEach(appointments.sorted(by: { $0.date < $1.date })) { appointment in
                            NavigationLink(destination: EditAppointmentView(
                                appointment: binding(for: appointment),
                                saveAction: saveAction
                            )) {
                                AppointmentRow(appointment: appointment)
                            }
                        }
                        .onDelete(perform: deleteAction)
                    }
                    .scrollContentBackground(.hidden) // 背景設定
                    .background(Color.themeBackground)
                }
            }
            .navigationTitle("預約列表")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { if !appointments.isEmpty { EditButton() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isShowingAdd = true } label: { Label("新增", systemImage: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $isShowingAdd) {
                AddAppointmentView(
                    appointments: $appointments,
                    expenses: $expenses,
                    members: members,
                    saveAction: saveAction
                )
            }
        }
    }
    
    private func binding(for appointment: Appointment) -> Binding<Appointment> {
        guard let index = appointments.firstIndex(where: { $0.id == appointment.id }) else {
            fatalError("Appointment not found")
        }
        return $appointments[index]
    }
}

struct AppointmentRow: View {
    let appointment: Appointment
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(appointment.name).font(.headline).foregroundColor(.primary)
                Spacer()
                Text(appointment.service).font(.caption).padding(5).background(Color.indigo.opacity(0.1)).foregroundColor(.indigo).cornerRadius(6)
            }
            HStack {
                Image(systemName: "clock")
                Text(appointment.date, style: .date)
                Text(appointment.date, style: .time)
            }
            .font(.caption).foregroundColor(.secondary)
            HStack {
                if let amount = appointment.amount {
                    Text("$\(Int(amount))").font(.subheadline).fontWeight(.bold).foregroundColor(.red)
                }
                Spacer()
                if appointment.isPhotoAttached {
                    Image(systemName: "photo.fill").foregroundColor(.orange).font(.caption)
                    Text("有照片").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 5. 新增/編輯 預約 (Appointment Views)

struct AddAppointmentView: View {
    @Binding var appointments: [Appointment]
    @Binding var expenses: [Expense]
    let members: [Member]
    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var nameSource: Int = 0
    @State private var manualName = ""
    @State private var selectedMember: Member?
    @State private var service = "💇 剪髮"
    @State private var date = Date()
    @State private var email = ""
    @State private var phone = ""
    @State private var amountInput = ""
    @State private var photoDescription = ""
    @State private var extraServiceDetail = ""
    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var photoItem: PhotosPickerItem?

    let eventStore = EKEventStore()
    
    var finalName: String { (nameSource == 1 && selectedMember != nil) ? selectedMember!.name : manualName }

    var body: some View {
        NavigationView {
            Form {
                Section("預約者") {
                    Picker("來源", selection: $nameSource) {
                        Text("手動輸入").tag(0)
                        if !members.isEmpty { Text("選擇成員").tag(1) }
                    }
                    .pickerStyle(.segmented)
                    if nameSource == 0 { TextField("姓名", text: $manualName) }
                    else if !members.isEmpty {
                        Picker("選擇成員", selection: $selectedMember) {
                            ForEach(members) { member in Text(member.name).tag(member as Member?) }
                        }.onAppear { if selectedMember == nil { selectedMember = members.first } }
                    }
                }
                Section("服務資訊") {
                    Picker("服務項目", selection: $service) {
                        Text("💇 剪髮").tag("💇 剪髮")
                        Text("💅 美甲").tag("💅 美甲")
                        Text("💆 按摩").tag("💆 按摩")
                        Text("❓ 其他").tag("❓ 其他")
                    }
                    if service.contains("其他") { TextField("詳細內容", text: $extraServiceDetail) }
                    DatePicker("日期", selection: $date)
                    TextField("金額", text: $amountInput).keyboardType(.decimalPad)
                }
                Section("照片記錄") {
                    if let image = selectedImage {
                        VStack {
                            Image(uiImage: image).resizable().scaledToFit().frame(height: 150).cornerRadius(8)
                            Button("移除", role: .destructive) { selectedImage = nil; photoItem = nil }
                        }
                    } else {
                        HStack(spacing: 20) {
                            Button { isShowingCamera = true } label: { Label("拍照", systemImage: "camera") }.buttonStyle(.borderless)
                            Spacer()
                            PhotosPicker(selection: $photoItem, matching: .images) { Label("相簿", systemImage: "photo.on.rectangle") }.buttonStyle(.borderless)
                        }.buttonStyle(.bordered)
                    }
                    TextField("備註", text: $photoDescription)
                }
                Section("聯絡") {
                    TextField("Email", text: $email).keyboardType(.emailAddress)
                    TextField("電話", text: $phone).keyboardType(.phonePad)
                }
                Button("儲存並同步至記帳") { saveAppointment() }.disabled(finalName.isEmpty)
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground) // 背景
            .navigationTitle("新增預約")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .onChange(of: photoItem) { _, newItem in
                Task { if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) { selectedImage = uiImage } }
            }
            .sheet(isPresented: $isShowingCamera) { CameraPicker(selectedImage: $selectedImage) }
        }
    }
    
    func saveAppointment() {
        let newAppt = Appointment(
            name: finalName, date: date, service: service,
            email: email.isEmpty ? nil : email, phone: phone.isEmpty ? nil : phone,
            amount: Double(amountInput), photoDescription: photoDescription,
            photoData: selectedImage?.jpegData(compressionQuality: 0.6),
            extraServiceDetail: extraServiceDetail.isEmpty ? nil : extraServiceDetail
        )
        appointments.append(newAppt)
        
        if let amt = Double(amountInput), amt > 0 {
            let memberId = (nameSource == 1) ? selectedMember?.id : nil
            let syncedExpense = Expense(
                date: date,
                amount: amt,
                mainCategory: "預約服務",
                subCategory: service.prefix(4).trimmingCharacters(in: .whitespaces),
                note: "來自預約: \(finalName) - \(service)",
                memberId: memberId
            )
            expenses.append(syncedExpense)
        }
        
        saveAction()
        scheduleLocalNotification(appointment: newAppt)
        addEventToCalendar(appointment: newAppt)
        dismiss()
    }
    
    func scheduleLocalNotification(appointment: Appointment) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ 預約提醒"; content.body = "\(appointment.name) 的 \(appointment.service) 即將開始"; content.sound = .default
        guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -30, to: appointment.date), triggerDate > Date() else { return }
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: appointment.id.uuidString, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
    }
    
    func addEventToCalendar(appointment: Appointment) {
        eventStore.requestFullAccessToEvents { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    let event = EKEvent(eventStore: eventStore)
                    event.title = "預約: \(appointment.service) - \(appointment.name)"
                    event.startDate = appointment.date; event.endDate = appointment.date.addingTimeInterval(3600)
                    event.calendar = eventStore.defaultCalendarForNewEvents
                    event.notes = "金額: \(appointment.amount ?? 0)\n備註: \(appointment.photoDescription ?? "")"
                    try? eventStore.save(event, span: .thisEvent)
                }
            }
        }
    }
}

struct EditAppointmentView: View {
    @Binding var appointment: Appointment
    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var amountInput = ""
    @State private var photoDescription = ""
    @State private var extraServiceDetail = ""
    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        Form {
            Section("資訊") {
                Text("姓名: \(appointment.name)"); Text("服務: \(appointment.service)"); Text("時間: \(appointment.date.formatted())")
            }
            Section("編輯") {
                TextField("金額", text: $amountInput).keyboardType(.decimalPad)
                if appointment.service.contains("其他") || !(appointment.extraServiceDetail?.isEmpty ?? true) {
                    TextField("詳情", text: $extraServiceDetail)
                }
            }
            Section("照片") {
                if let image = selectedImage {
                    VStack {
                        Image(uiImage: image).resizable().scaledToFit().frame(height: 200).cornerRadius(8)
                        Button("刪除", role: .destructive) { withAnimation { selectedImage = nil; photoItem = nil } }
                    }
                } else {
                    HStack {
                        Button("拍照") { isShowingCamera = true }.buttonStyle(.borderless)
                        Spacer()
                        PhotosPicker("相簿", selection: $photoItem, matching: .images).buttonStyle(.borderless)
                    }
                }
                TextField("備註", text: $photoDescription)
            }
            Button("儲存") {
                appointment.amount = Double(amountInput); appointment.photoDescription = photoDescription
                appointment.extraServiceDetail = extraServiceDetail; appointment.photoData = selectedImage?.jpegData(compressionQuality: 0.6)
                saveAction(); dismiss()
            }
        }
        .scrollContentBackground(.hidden).background(Color.themeBackground) // 背景
        .navigationTitle("編輯")
        .onAppear {
            if let amt = appointment.amount { amountInput = String(format: "%.0f", amt) }
            photoDescription = appointment.photoDescription ?? ""
            extraServiceDetail = appointment.extraServiceDetail ?? ""
            if let data = appointment.photoData { selectedImage = UIImage(data: data) }
        }
        .onChange(of: photoItem) { _, newItem in
            Task { if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) { selectedImage = uiImage } }
        }
        .sheet(isPresented: $isShowingCamera) { CameraPicker(selectedImage: $selectedImage) }
    }
}

// MARK: - 6. 月曆記帳 (Calendar Expense)

struct CalendarExpenseView: View {
    @Binding var expenses: [Expense]
    let appointments: [Appointment]
    let members: [Member]
    var saveAction: () -> Void
    @EnvironmentObject var lifestyleManager: LifestyleManager
    
    @State private var selectedDate = Date()
    @State private var isShowingAddExpense = false
    @State private var isShowingSettings = false
    @State private var isShowingInvoice = false
    
    var expensesForSelectedDate: [Expense] { expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) } }
    // appointmentsForSelectedDate 不再需要用於計算總金額或顯示列表，因為已同步至 expenses
    // var appointmentsForSelectedDate: [Appointment] { appointments.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) } }
    
    var totalAmount: Double {
        // 修正：只計算 expenses 即可，因為預約已同步轉為 Expense
        expensesForSelectedDate.reduce(0) { $0 + $1.amount }
    }
    
    func getMember(by id: UUID?) -> Member? {
        guard let id = id else { return nil }
        return members.first { $0.id == id }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if !lifestyleManager.selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(lifestyleManager.selectedTags), id: \.self) { tag in
                                Label(tag.rawValue, systemImage: tag.icon)
                                    .font(.caption).padding(6).background(tag.color.opacity(0.1))
                                    .foregroundColor(tag.color).cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }.padding(.top, 5)
                }
                
                DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical).padding()
                    .background(Color(UIColor.systemBackground)).cornerRadius(10).padding()
                
                Divider()
                
                List {
                    Section(header: HStack {
                        Text("\(selectedDate, style: .date) 支出"); Spacer(); Text("$\(Int(totalAmount))").foregroundStyle(.red)
                    }) {
                        if expensesForSelectedDate.isEmpty {
                            Text("無記錄").foregroundStyle(.secondary)
                        } else {
                            ForEach(expensesForSelectedDate) { expense in
                                HStack {
                                    if let member = getMember(by: expense.memberId) {
                                        Text(member.role.icon).font(.title2).frame(width: 30)
                                    } else {
                                        Image(systemName: "cart.circle").font(.title2).foregroundColor(.gray).frame(width: 30)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(expense.subCategory).font(.headline)
                                        HStack {
                                            Text(expense.mainCategory).font(.caption).padding(4).background(Color.indigo.opacity(0.1)).cornerRadius(4)
                                            if !expense.note.isEmpty { Text(expense.note).font(.caption).foregroundStyle(.secondary) }
                                        }
                                    }
                                    Spacer(); Text("$\(Int(expense.amount))")
                                }
                            }
                            .onDelete { indexSet in
                                let ids = indexSet.map { expensesForSelectedDate[$0].id }
                                expenses.removeAll { ids.contains($0.id) }
                                saveAction()
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden).background(Color.themeBackground) // 背景
                .listStyle(.insetGrouped)
            }
            .background(Color.themeBackground) // 背景
            .navigationTitle("月曆記帳")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { isShowingSettings = true } label: { Image(systemName: "gearshape.fill") } }
                ToolbarItem(placement: .topBarTrailing) { HStack(spacing: 15) { Button { isShowingInvoice = true } label: { Image(systemName: "qrcode.viewfinder").symbolRenderingMode(.hierarchical) }; Button { isShowingAddExpense = true } label: { Image(systemName: "plus.circle.fill") } } }
            }
            .sheet(isPresented: $isShowingAddExpense) {
                AddExpenseView(expenses: $expenses, members: members, selectedDate: selectedDate, saveAction: saveAction).environmentObject(lifestyleManager)
            }
            .sheet(isPresented: $isShowingSettings) {
                LifestyleSettingsView().environmentObject(lifestyleManager)
            }
            .sheet(isPresented: $isShowingInvoice) {
                CloudInvoiceView(expenses: $expenses, saveAction: saveAction)
            }
        }
    }
}

// MARK: - 6.2 雲端發票視圖
struct CloudInvoiceView: View {
    @Binding var expenses: [Expense]
    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss
    @AppStorage("MobileBarcode") private var mobileBarcode: String = ""
    @State private var isSyncing = false
    @State private var showSyncAlert = false
    @State private var syncedCount = 0
    
    func generateBarcode(from string: String) -> UIImage? {
        let context = CIContext(); let filter = CIFilter.code128BarcodeGenerator()
        filter.message = string.data(using: .ascii) ?? Data()
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) { return UIImage(cgImage: cgImage) }
        }
        return nil
    }
    
    func simulateSync() {
        guard !mobileBarcode.isEmpty else { return }
        isSyncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let locations = ["7-11", "全家", "全聯", "中油", "星巴克"]
            let randomCount = Int.random(in: 1...3)
            var newItems: [Expense] = []
            for _ in 0..<randomCount {
                let loc = locations.randomElement()!; let amt = Double(Int.random(in: 30...500))
                let cat = (loc.contains("中油")) ? "行" : "食"; let sub = (cat == "行") ? "油錢" : "零食"
                newItems.append(Expense(date: Date(), amount: amt, mainCategory: cat, subCategory: sub, note: "☁️ 發票: \(loc)", memberId: nil))
            }
            expenses.append(contentsOf: newItems)
            saveAction()
            syncedCount = newItems.count; isSyncing = false; showSyncAlert = true
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Text("手機條碼").font(.headline).foregroundColor(.secondary)
                    if mobileBarcode.isEmpty {
                        Image(systemName: "barcode.viewfinder").resizable().scaledToFit().frame(height: 100).foregroundColor(.gray.opacity(0.3))
                        Text("請輸入條碼").font(.caption).foregroundColor(.secondary)
                    } else if let barcodeImg = generateBarcode(from: mobileBarcode) {
                        Image(uiImage: barcodeImg).resizable().interpolation(.none).scaledToFit().frame(height: 120).padding().background(Color.white).cornerRadius(10)
                        Text(mobileBarcode).font(.system(.title2, design: .monospaced)).bold()
                    }
                }.padding().frame(maxWidth: .infinity).background(Color(UIColor.secondarySystemBackground)).cornerRadius(15).padding(.horizontal)
                
                Form {
                    Section("設定") { TextField("輸入手機條碼 (e.g. /AB1234)", text: $mobileBarcode).disableAutocorrection(true) }
                    Section {
                        Button { simulateSync() } label: { HStack { if isSyncing { ProgressView().padding(.trailing, 5); Text("同步中...") } else { Image(systemName: "arrow.triangle.2.circlepath"); Text("同步雲端發票") } } }
                        .disabled(mobileBarcode.isEmpty || isSyncing)
                    }
                }
                .scrollContentBackground(.hidden).background(Color.themeBackground)
            }
            .background(Color.themeBackground)
            .navigationTitle("雲端發票")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("關閉") { dismiss() } } }
            .alert("同步完成", isPresented: $showSyncAlert) { Button("好") {} } message: { Text("匯入 \(syncedCount) 筆資料。") }
        }
    }
}

// 6.1 設定頁面 (LifestyleSettingsView) - 保持不變，略

struct LifestyleSettingsView: View {
    @EnvironmentObject var lifestyleManager: LifestyleManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("選擇您的生活型態")) {
                    ForEach(LifestyleTag.allCases) { tag in
                        Toggle(isOn: binding(for: tag)) {
                            HStack {
                                Image(systemName: tag.icon).foregroundColor(tag.color).frame(width: 30)
                                VStack(alignment: .leading) { Text(tag.rawValue).font(.headline); Text(description(for: tag)).font(.caption).foregroundStyle(.secondary) }
                            }
                        }.toggleStyle(SwitchToggleStyle(tint: tag.color))
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("設定").toolbar { ToolbarItem(placement: .cancellationAction) { Button("完成") { dismiss() } } }
        }
    }
    private func binding(for tag: LifestyleTag) -> Binding<Bool> {
        Binding(get: { lifestyleManager.selectedTags.contains(tag) }, set: { if $0 { lifestyleManager.selectedTags.insert(tag) } else { lifestyleManager.selectedTags.remove(tag) } })
    }
    private func description(for tag: LifestyleTag) -> String {
        switch tag { case .diningOut: return "細分餐別"; case .beauty: return "新增化妝品等"; case .parent: return "新增育兒"; case .pet: return "新增寵物"; }
    }
}

// 6.3 新增支出視圖 (AddExpenseView)

struct AddExpenseView: View {
    @Binding var expenses: [Expense]
    let members: [Member] // 接收成員列表
    var selectedDate: Date
    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lifestyleManager: LifestyleManager
    
    @State private var amount = ""
    @State private var mainCategory = "食"
    @State private var subCategory = ""
    @State private var customSubCategory = ""
    @State private var note = ""
    
    // 成員選擇
    @State private var selectedMemberId: UUID?
    
    @State private var isRecurring = false
    @State private var recurrenceFrequency = "每月固定日期"
    let recurrenceOptions = ["每天", "每兩個禮拜", "每月固定日期"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("金額") { TextField("輸入金額", text: $amount).keyboardType(.decimalPad) }
                
                // 新增：消費成員選擇
                Section("消費成員") {
                    Picker("選擇成員", selection: $selectedMemberId) {
                        Text("未指定").tag(UUID?.none)
                        ForEach(members) { member in
                            Text("\(member.role.icon) \(member.name)").tag(Optional(member.id))
                        }
                    }
                }
                
                Section("分類") {
                    Picker("主分類", selection: $mainCategory) {
                        ForEach(lifestyleManager.mainCategories, id: \.self) { Text($0).tag($0) }
                    }
                    .onChange(of: mainCategory) { _, newVal in
                        if let first = lifestyleManager.getSubCategories(for: newVal).first { subCategory = first } else { subCategory = "" }
                    }
                    if mainCategory == "其他" { TextField("類別名稱", text: $customSubCategory) }
                    else {
                        let subs = lifestyleManager.getSubCategories(for: mainCategory)
                        if !subs.isEmpty { Picker("子分類", selection: $subCategory) { ForEach(subs, id: \.self) { Text($0).tag($0) } } }
                    }
                }
                
                Section("固定/重複支出") {
                    Toggle("設為重複", isOn: $isRecurring)
                    if isRecurring {
                        Picker("頻率", selection: $recurrenceFrequency) { ForEach(recurrenceOptions, id: \.self) { Text($0) } }
                        Text("自動建立未來一年紀錄").font(.caption).foregroundStyle(.secondary)
                    }
                }
                
                Section("備註") { TextField("備註 (如：貸款、房租...)", text: $note) }
                
                Button("儲存") {
                    if let amt = Double(amount) {
                        let finalSub = (mainCategory == "其他") ? (customSubCategory.isEmpty ? "雜項" : customSubCategory) : subCategory
                        var expensesToAdd: [Expense] = []
                        let calendar = Calendar.current
                        
                        if isRecurring {
                            let count = recurrenceFrequency == "每天" ? 365 : (recurrenceFrequency == "每兩個禮拜" ? 26 : 12)
                            for i in 0..<count {
                                var dateComponent = DateComponents()
                                if recurrenceFrequency == "每天" { dateComponent.day = i }
                                else if recurrenceFrequency == "每兩個禮拜" { dateComponent.day = i * 14 }
                                else { dateComponent.month = i }
                                
                                if let nextDate = calendar.date(byAdding: dateComponent, to: selectedDate) {
                                    expensesToAdd.append(Expense(date: nextDate, amount: amt, mainCategory: mainCategory, subCategory: finalSub, note: note, memberId: selectedMemberId))
                                }
                            }
                        } else {
                            expensesToAdd.append(Expense(date: selectedDate, amount: amt, mainCategory: mainCategory, subCategory: finalSub, note: note, memberId: selectedMemberId))
                        }
                        expenses.append(contentsOf: expensesToAdd); saveAction(); dismiss()
                    }
                }.disabled(amount.isEmpty)
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("新增支出")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .onAppear {
                if subCategory.isEmpty, let first = lifestyleManager.getSubCategories(for: mainCategory).first { subCategory = first }
                // 預設選第一個成員
                if selectedMemberId == nil, let firstMember = members.first {
                    selectedMemberId = firstMember.id
                }
            }
        }
    }
}

// MARK: - 7. 收入支出表 (New: Income Expense Report View)

struct IncomeExpenseReportView: View {
    let appointments: [Appointment]
    let expenses: [Expense]
    @Binding var incomes: [Income]
    let members: [Member] // 接收成員
    var saveAction: () -> Void
    
    @State private var isShowingAddIncome = false
    @State private var selectedMonth = Date()
    @State private var selectedMemberForAnalysis: Member? // 新增：用於個別成員分析
    
    var filteredIncomes: [Income] { incomes.filter { Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) } }
    var filteredAppointments: [Appointment] { appointments.filter { Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) } }
    var filteredExpenses: [Expense] { expenses.filter { Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) } }
    
    var totalIncome: Double { filteredIncomes.reduce(0) { $0 + $1.amount } }
    var totalApptExpense: Double { filteredAppointments.reduce(0) { $0 + ($1.amount ?? 0) } }
    
    // 修正: totalDailyExpense 排除 "預約服務" 類別，避免重複計算
    var totalDailyExpense: Double {
        filteredExpenses.filter { $0.mainCategory != "預約服務" }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double { totalApptExpense + totalDailyExpense }
    var netBalance: Double { totalIncome - totalExpense }
    
    // 計算成員支出資料 (家庭佔比 Pie Chart)
    struct MemberExpenseData: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
        let role: MemberRole
    }
    
    var memberExpenseChartData: [MemberExpenseData] {
        var dict: [UUID: Double] = [:]
        var unassignedTotal: Double = 0
        
        // 1. 累加 expenses
        for exp in filteredExpenses {
            if let mid = exp.memberId {
                dict[mid, default: 0] += exp.amount
            } else {
                unassignedTotal += exp.amount
            }
        }
        
        // 2. 轉換為陣列
        var data: [MemberExpenseData] = []
        for (mid, amt) in dict {
            if let member = members.first(where: { $0.id == mid }) {
                data.append(MemberExpenseData(name: member.name, amount: amt, role: member.role))
            }
        }
        
        if unassignedTotal > 0 {
            data.append(MemberExpenseData(name: "未指定/共用", amount: unassignedTotal, role: .other))
        }
        
        return data.sorted { $0.amount > $1.amount }
    }
    
    // 計算個別成員類別支出 (Individual Member Category Pie Chart)
    struct CategoryExpenseData: Identifiable {
        let id = UUID()
        let category: String
        let amount: Double
    }
    
    var individualMemberCategoryData: [CategoryExpenseData] {
        guard let member = selectedMemberForAnalysis else { return [] }
        
        let memberExpenses = filteredExpenses.filter { $0.memberId == member.id }
        let grouped = Dictionary(grouping: memberExpenses, by: { $0.mainCategory })
        
        return grouped.map { key, value in
            CategoryExpenseData(category: key, amount: value.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 月份選擇
                HStack {
                    Text("選擇月份").font(.headline)
                    Spacer()
                    HStack(spacing: 15) {
                        Button { withAnimation { selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth } } label: { Image(systemName: "chevron.left").font(.headline).foregroundColor(.indigo) }
                        Text(selectedMonth, format: .dateTime.year().month()).font(.system(.body, design: .rounded)).bold().frame(minWidth: 80)
                        Button { withAnimation { selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth } } label: { Image(systemName: "chevron.right").font(.headline).foregroundColor(.indigo) }
                    }.padding(.vertical, 6).padding(.horizontal, 10).background(Color(UIColor.systemBackground)).cornerRadius(8)
                }.padding().background(Color(UIColor.secondarySystemBackground))
                
                List {
                    // 1. 總覽 (順序調整：總表 -> 收入 -> 支出 -> 圖表)
                    Section {
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading) { Text("本月收入").font(.caption).foregroundColor(.secondary); Text("$\(Int(totalIncome))").font(.title2).bold().foregroundColor(.blue) }
                                Spacer()
                                VStack(alignment: .trailing) { Text("本月支出").font(.caption).foregroundColor(.secondary); Text("$\(Int(totalExpense))").font(.title2).bold().foregroundColor(.red) }
                            }
                            Divider()
                            HStack { Text("本月結餘").font(.headline); Spacer(); Text("$\(Int(netBalance))").font(.title).bold().foregroundColor(netBalance >= 0 ? .green : .red) }
                        }.padding(.vertical, 5)
                    } header: { Text("月收支總覽") }
                    
                    // 2. 收入
                    Section(header: HStack { Text("收入明細"); Spacer(); Button("新增") { isShowingAddIncome = true }.font(.caption).buttonStyle(.borderedProminent) }) {
                        if filteredIncomes.isEmpty { Text("無記錄").font(.caption).foregroundColor(.secondary) }
                        else {
                            ForEach(IncomeCategory.allCases) { category in
                                let catIncomes = filteredIncomes.filter { $0.category == category }
                                if !catIncomes.isEmpty {
                                    DisclosureGroup {
                                        ForEach(catIncomes) { income in
                                            HStack { Text(income.date, style: .date).font(.caption).foregroundColor(.secondary); Text(income.note.isEmpty ? category.rawValue : income.note); Spacer(); Text("$\(Int(income.amount))") }
                                        }
                                    } label: {
                                        HStack { Image(systemName: category.icon).foregroundColor(category.color); Text(category.rawValue); Spacer(); Text("$\(Int(catIncomes.reduce(0){$0+$1.amount}))").bold() }
                                    }
                                }
                            }
                        }
                    }
                    
                    // 3. 支出分佈 (順序調整)
                    Section(header: Text("支出分類詳情")) {
                        NavigationLink(destination: AppointmentExpenseDetailView(appointments: filteredAppointments)) {
                            HStack { Image(systemName: "scissors").foregroundColor(.purple); Text("預約服務支出"); Spacer(); Text("$\(Int(totalApptExpense))").foregroundColor(.secondary) }
                        }
                        NavigationLink(destination: DailyExpenseDetailView(expenses: filteredExpenses)) {
                            HStack { Image(systemName: "cart").foregroundColor(.orange); Text("日常雜項支出"); Spacer(); Text("$\(Int(totalDailyExpense))").foregroundColor(.secondary) }
                        }
                    }
                    
                    // 4. 圖表區 (家庭成員佔比 + 個別成員分析)
                    Section(header: Text("圖表分析")) {
                        // 4.1 家庭成員花費佔比
                        VStack(alignment: .leading) {
                            Text("家庭成員花費佔比").font(.headline).padding(.bottom, 5)
                            if totalExpense > 0 && !memberExpenseChartData.isEmpty {
                                Chart(memberExpenseChartData) { item in
                                    SectorMark(
                                        angle: .value("Amount", item.amount),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1.5
                                    )
                                    .cornerRadius(5)
                                    .foregroundStyle(item.role.color)
                                    .annotation(position: .overlay) {
                                        if item.amount / totalExpense > 0.05 {
                                            VStack(spacing: 0) {
                                                Text(item.role.icon).font(.caption)
                                                Text("\(Int(item.amount/totalExpense*100))%").font(.caption2).bold().foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 200)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                                    ForEach(memberExpenseChartData) { item in
                                        HStack(spacing: 4) { Circle().fill(item.role.color).frame(width: 8, height: 8); Text(item.name).font(.caption).lineLimit(1) }
                                    }
                                }
                            } else {
                                Text("本月尚無支出數據").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center).padding()
                            }
                        }
                        .padding(.vertical)
                        
                        Divider()
                        
                        // 4.2 個別成員花費分析 (New)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("個別成員分析").font(.headline)
                                Spacer()
                                Picker("選擇成員", selection: $selectedMemberForAnalysis) {
                                    Text("請選擇").tag(Member?.none)
                                    ForEach(members) { member in
                                        Text(member.name).tag(Optional(member))
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            
                            if let _ = selectedMemberForAnalysis {
                                if !individualMemberCategoryData.isEmpty {
                                    let totalMemberExpense = individualMemberCategoryData.reduce(0) { $0 + $1.amount }
                                    Chart(individualMemberCategoryData) { item in
                                        SectorMark(
                                            angle: .value("Amount", item.amount),
                                            innerRadius: .ratio(0.5),
                                            angularInset: 1.5
                                        )
                                        .foregroundStyle(by: .value("Category", item.category))
                                        .annotation(position: .overlay) {
                                            if item.amount / totalMemberExpense > 0.05 {
                                                Text("\(Int(item.amount/totalMemberExpense*100))%")
                                                    .font(.caption2).bold().foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .frame(height: 200)
                                    .padding(.top)
                                    
                                    // 簡單列表顯示金額
                                    ForEach(individualMemberCategoryData) { item in
                                        HStack {
                                            Text(item.category).font(.caption)
                                            Spacer()
                                            Text("$\(Int(item.amount))").font(.caption).bold()
                                        }
                                    }
                                    .padding(.top, 5)
                                    
                                } else {
                                    Text("該成員本月無支出紀錄").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center).padding()
                                }
                            } else {
                                Text("請選擇成員以查看詳情").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center).padding()
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .scrollContentBackground(.hidden).background(Color.themeBackground)
            }
            .background(Color.themeBackground) // Added this
            .navigationTitle("收支分析")
            .sheet(isPresented: $isShowingAddIncome) { AddIncomeView(incomes: $incomes, saveAction: saveAction) }
        }
    }
}

// 7.1 詳細頁面 - 預約支出 (改為 Pie Chart)
struct AppointmentExpenseDetailView: View {
    let appointments: [Appointment]
    var groupedData: [(service: String, total: Double)] { Dictionary(grouping: appointments.filter { $0.amount != nil }, by: { $0.service }).map { (key, value) in (key, value.reduce(0) { $0 + ($1.amount ?? 0) }) }.sorted { $0.1 > $1.1 } }
    var total: Double { appointments.reduce(0) { $0 + ($1.amount ?? 0) } }
    var body: some View {
        List {
            Section("服務分佈圓餅圖") {
                if groupedData.isEmpty { Text("無資料").foregroundColor(.secondary) }
                else {
                    Chart(groupedData, id: \.service) { item in
                        SectorMark(
                            angle: .value("Amount", item.total),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Service", item.service))
                        .annotation(position: .overlay) {
                            if item.total / total > 0.05 {
                                Text("\(Int(item.total/total*100))%").font(.caption2).bold().foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 250)
                    .padding(.vertical)
                }
            }
            
            Section("詳細列表") {
                ForEach(groupedData, id: \.service) { item in
                    HStack {
                        Text(item.service)
                        Spacer()
                        Text("$\(Int(item.total))")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden).background(Color.themeBackground)
        .navigationTitle("預約支出詳情")
    }
}

// 7.2 詳細頁面 - 日常支出 (改為 Pie Chart)
struct DailyExpenseDetailView: View {
    let expenses: [Expense]
    
    // 修正: 排除 "預約服務" 類別，顯示純日常支出
    var dailyOnlyExpenses: [Expense] { expenses.filter { $0.mainCategory != "預約服務" } }
    
    var groupedData: [(category: String, total: Double)] { Dictionary(grouping: dailyOnlyExpenses, by: { $0.mainCategory }).map { (key, value) in (key, value.reduce(0) { $0 + $1.amount }) }.sorted { $0.1 > $1.1 } }
    var total: Double { dailyOnlyExpenses.reduce(0) { $0 + $1.amount } }
    
    var body: some View {
        List {
            Section("主分類分佈圓餅圖") {
                if groupedData.isEmpty { Text("無資料").foregroundColor(.secondary) }
                else {
                    Chart(groupedData, id: \.category) { item in
                        SectorMark(
                            angle: .value("Amount", item.total),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", item.category))
                        .annotation(position: .overlay) {
                            if item.total / total > 0.05 {
                                Text("\(Int(item.total/total*100))%").font(.caption2).bold().foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 250)
                    .padding(.vertical)
                }
            }
            
            Section("詳細列表") {
                ForEach(groupedData, id: \.category) { item in
                    HStack {
                        Text(item.category)
                        Spacer()
                        Text("$\(Int(item.total))")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden).background(Color.themeBackground)
        .navigationTitle("日常支出詳情")
    }
}

struct AddIncomeView: View {
    @Binding var incomes: [Income]
    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var amount = ""; @State private var category: IncomeCategory = .active; @State private var date = Date(); @State private var note = ""
    var body: some View {
        NavigationView {
            Form {
                Section("金額") { TextField("金額", text: $amount).keyboardType(.decimalPad) }
                Section("分類") { Picker("類型", selection: $category) { ForEach(IncomeCategory.allCases) { cat in HStack { Image(systemName: cat.icon); Text(cat.rawValue) }.tag(cat) } }; Text(category.description).font(.caption).foregroundColor(.secondary) }
                Section("資訊") { DatePicker("日期", selection: $date, displayedComponents: .date); TextField("備註", text: $note) }
                Button("儲存") { if let val = Double(amount) { incomes.append(Income(date: date, amount: val, category: category, note: note)); saveAction(); dismiss() } }.disabled(amount.isEmpty)
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("新增收入").toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
        }
    }
}

// MARK: - 8. 成員管理 (Member Management)

struct MemberManagementView: View {
    @Binding var members: [Member]
    var saveAction: () -> Void
    @State private var newName = ""
    @State private var selectedRole: MemberRole = .other
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("新增成員")) {
                    TextField("輸入姓名", text: $newName)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MemberRole.allCases) { role in
                                Button { selectedRole = role } label: {
                                    VStack(spacing: 4) { Text(role.icon).font(.largeTitle); Text(role.rawValue).font(.caption2).fontWeight(.bold) }
                                    .padding(8).background(selectedRole == role ? role.color.opacity(0.15) : Color.gray.opacity(0.05))
                                    .cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10).stroke(selectedRole == role ? role.color : Color.clear, lineWidth: 2))
                                }.foregroundColor(.primary)
                            }
                        }.padding(.vertical, 5)
                    }
                    Button { if !newName.isEmpty { members.append(Member(name: newName, role: selectedRole)); members.sort { $0.name < $1.name }; saveAction(); newName = ""; selectedRole = .other } } label: { HStack { Spacer(); Text("新增成員").fontWeight(.bold); Spacer() } }.buttonStyle(.borderedProminent).disabled(newName.isEmpty).padding(.top, 5)
                }
                Section(header: Text("家庭成員列表")) {
                    ForEach(members) { member in
                        HStack(spacing: 15) { ZStack { Circle().fill(member.role.color.opacity(0.2)).frame(width: 40, height: 40); Text(member.role.icon).font(.title2) }; VStack(alignment: .leading) { Text(member.name).font(.headline); Text(member.role.rawValue).font(.caption).foregroundColor(.secondary) } }.padding(.vertical, 4)
                    }.onDelete { idx in members.remove(atOffsets: idx); saveAction() }
                }
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("成員管理")
        }
    }
}

@main
struct AppointmentAndExpenseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
