import SwiftUI
import Foundation
import EventKit
import UserNotifications

// MARK: - 資料模型 (Data Model)

/// 家庭成員資料結構
struct Member: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
}

/// 預約資料的結構
struct Appointment: Identifiable, Codable {
    var id = UUID()
    var name: String // 預約者姓名/家庭成員名稱
    var date: Date
    var service: String // 服務項目，含 Emoji
    var email: String?
    var phone: String?
    var amount: Double? // 消費金額 (可選)
    var photoDescription: String? // 圖片描述/備註
    var isPhotoAttached: Bool = false
    var extraServiceDetail: String? // 如果服務是「其他」，記錄額外詳情
    
    var displayAmount: Double {
        return amount ?? 0.0
    }
}

// MARK: - 主內容視圖 (Main Tab View Wrapper)
struct ContentView: View {
    @State private var appointments: [Appointment] = []
    @State private var members: [Member] = [] // 新增：家庭成員列表
    
    private let appointmentKey = "StoredAppointments"
    private let memberKey = "StoredMembers" // 家庭成員儲存鍵
    
    init() {
        _appointments = State(initialValue: loadAppointments())
        _members = State(initialValue: loadMembers()) // 載入成員
        requestNotificationPermission()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission denied.")
            }
        }
    }

    var body: some View {
        TabView {
            // MARK: Tab 1: 預約列表
            AppointmentListView(
                appointments: $appointments,
                members: members, // 傳遞成員列表
                saveAction: saveAppointments,
                deleteAction: deleteAppointments
            )
            .tabItem {
                Label("預約列表", systemImage: "list.bullet.clipboard")
            }
            
            // MARK: Tab 2: 預約歷史
            HistoryView(appointments: appointments)
            .tabItem {
                Label("預約歷史", systemImage: "clock.fill")
            }
            
            // MARK: Tab 3: 支出報告
            ReportView(appointments: appointments)
            .tabItem {
                Label("支出報告", systemImage: "chart.bar.fill")
            }
            
            // MARK: Tab 4: 成員管理
            MemberManagementView(members: $members, saveAction: saveMembers)
            .tabItem {
                Label("成員管理", systemImage: "person.3.fill")
            }
        }
        .tint(.indigo)
    }
    
    // MARK: - 資料持久化邏輯
    
    func loadAppointments() -> [Appointment] {
        if let savedData = UserDefaults.standard.data(forKey: appointmentKey) {
            if let decodedAppointments = try? JSONDecoder().decode([Appointment].self, from: savedData) {
                return decodedAppointments
            }
        }
        return []
    }
    
    func saveAppointments() {
        if let encoded = try? JSONEncoder().encode(appointments) {
            UserDefaults.standard.set(encoded, forKey: appointmentKey)
        }
    }
    
    func deleteAppointments(at offsets: IndexSet) {
        let sortedAppointments = appointments.sorted(by: { $0.date < $1.date })
        let appointmentsToDelete = offsets.map { sortedAppointments[$0] }
        
        for appointment in appointmentsToDelete {
            if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [appointment.id.uuidString])
                appointments.remove(at: index)
            }
        }
        saveAppointments()
    }
    
    // MARK: - 成員資料邏輯
    
    func loadMembers() -> [Member] {
        if let savedData = UserDefaults.standard.data(forKey: memberKey) {
            if let decodedMembers = try? JSONDecoder().decode([Member].self, from: savedData) {
                return decodedMembers.sorted { $0.name < $1.name }
            }
        }
        return []
    }

    func saveMembers() {
        if let encoded = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(encoded, forKey: memberKey)
        }
    }
}


// MARK: - 3. 預約列表視圖 (Appointment List View - Tab 1)
struct AppointmentListView: View {
    @Binding var appointments: [Appointment]
    let members: [Member] // 接收成員列表
    var saveAction: () -> Void
    var deleteAction: (IndexSet) -> Void
    
    @State private var isShowingAddAppointment = false
    
    var body: some View {
        NavigationView {
            VStack {
                if appointments.isEmpty {
                    Spacer()
                    ContentUnavailableView {
                        Label("目前沒有預約", systemImage: "calendar.badge.plus")
                    } description: {
                        Text("點擊右上角的「+」新增一個預約。")
                    }
                    Spacer()
                } else {
                    List {
                        // 依據日期排序預約
                        ForEach(appointments.sorted(by: { $0.date < $1.date })) { appointment in
                            
                            // 點擊後進入編輯頁面
                            NavigationLink(destination: EditAppointmentView(
                                appointment: $appointments[appointments.firstIndex(where: { $0.id == appointment.id })!],
                                saveAction: saveAction
                            )) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(appointment.name)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text(appointment.service)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.indigo.opacity(0.15))
                                            .foregroundColor(.indigo)
                                            .cornerRadius(8)
                                    }
                                    
                                    // 顯示額外服務描述
                                    if let detail = appointment.extraServiceDetail, !detail.isEmpty {
                                        Text("附註: \(detail)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // 日期與時間
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                        Text(appointment.date, style: .date); `Text`(" @ "); `Text`(appointment.date, style: .time)
                                    }
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    
                                    // 消費金額
                                    if let amount = appointment.amount {
                                        Text("金額: $\(amount, specifier: "%.0f")")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                    }
                                    
                                    // 照片備註提示
                                    if let desc = appointment.photoDescription, !desc.isEmpty || appointment.isPhotoAttached {
                                        HStack(spacing: 4) {
                                            Image(systemName: appointment.isPhotoAttached ? "photo.fill" : "camera.fill").foregroundColor(.orange)
                                            Text(appointment.isPhotoAttached ? "已附加照片" : "已記錄文字備註")
                                        }
                                        .font(.caption)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteAction)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("預約列表")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !appointments.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddAppointment = true
                    } label: {
                        Label("新增預約", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddAppointment) {
                // 將成員列表傳遞給新增視圖
                AddAppointmentView(appointments: $appointments, members: members, saveAction: saveAction)
            }
        }
    }
}


// MARK: - 4. 預約歷史記錄視圖 (History View - Tab 2)
struct HistoryView: View {
    let appointments: [Appointment]

    var groupedAppointments: [String: [Appointment]] {
        Dictionary(grouping: appointments.sorted(by: { $0.date > $1.date })) { appointment in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年 MM月"
            return formatter.string(from: appointment.date)
        }
    }
    
    var sortedKeys: [String] {
        groupedAppointments.keys.sorted(by: >)
    }

    var body: some View {
        NavigationView {
            List {
                if appointments.isEmpty {
                    ContentUnavailableView {
                        Label("無歷史記錄", systemImage: "clock.badge.xmark")
                    } description: {
                        Text("新增預約後，記錄將在此處按月份分類顯示。")
                    }
                } else {
                    ForEach(sortedKeys, id: \.self) { month in
                        Section(header: Text(month).font(.headline).foregroundColor(.indigo)) {
                            ForEach(groupedAppointments[month]!) { appointment in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(appointment.name)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text(appointment.service)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 8)
                                            .background(Color.indigo.opacity(0.1))
                                            .cornerRadius(5)
                                    }
                                    
                                    if let detail = appointment.extraServiceDetail, !detail.isEmpty {
                                        Text("附註: \(detail)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text(appointment.date, style: .time)
                                            .font(.subheadline)
                                        
                                        if let amount = appointment.amount {
                                            Text("|")
                                                .foregroundColor(.secondary)
                                            Text("收入: $\(amount, specifier: "%.0f")")
                                                .foregroundColor(.red)
                                                .fontWeight(.medium)
                                        }
                                        
                                        if appointment.isPhotoAttached {
                                            Text("|")
                                                .foregroundColor(.secondary)
                                            Image(systemName: "photo.fill")
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("預約歷史記錄")
        }
    }
}

// MARK: - 5. 營收報告視圖 (Report View - Tab 3)

struct ProportionChart: View {
    let data: [(label: String, value: Double)]
    let total: Double
    
    private let colors: [Color] = [.indigo, .orange, .green, .teal, .purple, .pink, .blue, .yellow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(data.indices, id: \.self) { index in
                let item = data[index]
                let color = colors[index % colors.count]
                let percentage = item.value / total
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.label)
                            .font(.subheadline)
                        Spacer()
                        Text("$\(item.value, specifier: "%.0f") (\(percentage, specifier: "%.1f")%)")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    // 柱狀圖 (Bar Chart)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color)
                                .frame(width: geometry.size.width * percentage, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ReportView: View {
    let appointments: [Appointment]
    
    enum ReportCategory: String, CaseIterable, Identifiable {
        case service = "服務類別總計"
        case member = "成員支出總結" // 新增分類
        case month = "月份總計"
        var id: String { self.rawValue }
    }
    
    @State private var selectedCategory: ReportCategory = .service
    
    var overallTotal: Double {
        appointments.reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    // 依服務分類的總計 (Service Totals)
    var serviceTotals: [(service: String, total: Double)] {
        let grouped = Dictionary(grouping: appointments.compactMap { $0.amount != nil ? ($0.service, $0.amount!) : nil }) { $0.0 }
        return grouped.map { (service, items) in
            let total = items.reduce(0) { $0 + $1.1 }
            return (service, total)
        }.sorted { $0.total > $1.total }
    }
    
    // 依成員分類的總計 (Member Totals)
    var memberTotals: [(member: String, total: Double)] {
        let grouped = Dictionary(grouping: appointments.compactMap { $0.amount != nil ? ($0.name, $0.amount!) : nil }) { $0.0 }
        return grouped.map { (name, items) in
            let total = items.reduce(0) { $0 + $1.1 }
            return (name, total)
        }.sorted { $0.total > $1.total }
    }
    
    // 依月份分類的總計 (Month Totals)
    var monthTotals: [(month: String, total: Double)] {
        let grouped = Dictionary(grouping: appointments.compactMap { $0.amount != nil ? ($0.date, $0.amount!) : nil }) { item in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年 MM月"
            return formatter.string(from: item.0)
        }
        return grouped.map { (month, items) in
            let total = items.reduce(0) { $0 + $1.1 }
            return (month, total)
        }.sorted { $0.month > $1.month }
    }
    // 定義一個計算屬性，專門處理資料邏輯
private var currentChartData: [(label: String, value: Double)] {
    switch selectedCategory {
    case .service:
        return serviceTotals.map { (label: $0.service, value: $0.total) }
    // 如果還有其他 case，繼續寫...
    default: // 假設需要 default
        return []
    }
}
    var body: some View {
        NavigationView {
            VStack {
                if appointments.isEmpty || overallTotal == 0 {
                    ContentUnavailableView {
                        Label("無營收或支出資料", systemImage: "chart.bar.xaxis.ascending")
                    } description: {
                        Text("請新增預約並填寫金額後，報告和圖表將在此處顯示。")
                    }
                } else {
                    List {
                        // 總覽
                        Section("總支出 (Total Expenditure)") {
                            HStack {
                                Text("累積總計")
                                Spacer()
                                Text("$\(overallTotal, specifier: "%.0f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        

                        
                        // 報告詳細列表
                        switch selectedCategory {
                        case .service:
                            Section(ReportCategory.service.rawValue) {
                                ForEach(serviceTotals, id: \.service) { item in
                                    HStack {
                                        Image(systemName: "tag.fill").foregroundColor(.indigo)
                                        Text(item.service)
                                        Spacer()
                                        Text("$\(item.total, specifier: "%.0f")")
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        case .member:
                            Section(ReportCategory.member.rawValue) {
                                ForEach(memberTotals, id: \.member) { item in
                                    HStack {
                                        Image(systemName: "person.fill").foregroundColor(.purple)
                                        Text(item.member)
                                        Spacer()
                                        Text("$\(item.total, specifier: "%.0f")")
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        case .month:
                            Section(ReportCategory.month.rawValue) {
                                ForEach(monthTotals, id: \.month) { item in
                                    HStack {
                                        Image(systemName: "calendar").foregroundColor(.green)
                                        Text(item.month)
                                        Spacer()
                                        Text("$\(item.total, specifier: "%.0f")")
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("支出報告")
        }
    }
}

// MARK: - 6. 編輯預約視圖 (Edit Appointment View)
struct EditAppointmentView: View {
    @Binding var appointment: Appointment
    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var amountInput: String
    @State private var photoDescription: String
    @State private var isPhotoAttached: Bool
    @State private var extraServiceDetail: String
    
    init(appointment: Binding<Appointment>, saveAction: @escaping () -> Void) {
        self._appointment = appointment
        self.saveAction = saveAction
        
        _amountInput = State(initialValue: appointment.wrappedValue.amount.map { String(format: "%.0f", $0) } ?? "")
        _photoDescription = State(initialValue: appointment.wrappedValue.photoDescription ?? "")
        _isPhotoAttached = State(initialValue: appointment.wrappedValue.isPhotoAttached)
        _extraServiceDetail = State(initialValue: appointment.wrappedValue.extraServiceDetail ?? "")
    }

    var body: some View {
        Form {
            // MARK: 預約摘要 (不可修改欄位)
            Section("預約者與服務資訊") {
                HStack {
                    Image(systemName: "person.circle.fill").foregroundColor(.indigo)
                    Text("客戶/成員: \(appointment.name)")
                }
                HStack {
                    Image(systemName: "tag.square.fill").foregroundColor(.indigo)
                    Text("服務: \(appointment.service)")
                }
                HStack {
                    Image(systemName: "calendar.badge.clock.fill").foregroundColor(.indigo)
                    Text("時間: \(appointment.date, style: .date) \(appointment.date, style: .time)")
                }
                
                // 額外服務內容編輯
                if appointment.service.contains("其他") || !(appointment.extraServiceDetail ?? "").isEmpty {
                    VStack(alignment: .leading) {
                        Text("額外服務內容")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("請描述額外服務內容", text: $extraServiceDetail, axis: .vertical)
                            .lineLimit(2...5)
                    }
                }
            }
            
            // MARK: 消費金額修改
            Section("修改消費金額") {
                HStack {
                    Text("$")
                        .foregroundColor(.secondary)
                    TextField("金額", text: $amountInput)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // MARK: 照片記錄與管理
            Section("照片記錄與管理") {
                VStack(alignment: .leading, spacing: 10) {
                    if isPhotoAttached {
                        VStack(alignment: .center, spacing: 10) {
                            Text("⚠️ 圖片功能模擬 (Canvas 限制)")
                                .font(.caption).foregroundColor(.red)
                            
                            Image(systemName: "photo.on.rectangle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .foregroundColor(.gray.opacity(0.7))
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.vertical, 5)

                            Button("移除附加照片") {
                                isPhotoAttached = false
                            }
                            .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity)

                    } else {
                        Button {
                            isPhotoAttached = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.on.rectangle.fill")
                                Text("拍照記錄 (模擬)")
                            }
                        }
                        
                        Button {
                            isPhotoAttached = true
                        } label: {
                            HStack {
                                Image(systemName: "photo.stack.fill")
                                Text("從相簿選擇檔案 (模擬)")
                            }
                        }
                    }
                }
                
                // 備註文本區域
                TextEditor(text: $photoDescription)
                    .frame(height: 100)
                    .overlay(
                        Text(photoDescription.isEmpty ? "新增照片相關文字描述或備註..." : "")
                            .foregroundColor(.secondary)
                            .allowsHitTesting(false)
                            .padding(.top, 8)
                            .padding(.leading, 5),
                        alignment: .topLeading
                    )
            }
            
            // 儲存按鈕
            Button("儲存修改並更新記錄") {
                saveChanges()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .navigationTitle("編輯歷史記錄")
        .navigationBarTitleDisplayMode(.inline)
    }

    func saveChanges() {
        let trimmedAmount = amountInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedAmount = Double(trimmedAmount)
        
        appointment.amount = parsedAmount
        
        let trimmedPhotoDesc = photoDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.photoDescription = trimmedPhotoDesc.isEmpty ? nil : trimmedPhotoDesc
        
        let trimmedExtraDetail = extraServiceDetail.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.extraServiceDetail = trimmedExtraDetail.isEmpty ? nil : trimmedExtraDetail
        
        appointment.isPhotoAttached = isPhotoAttached
        
        saveAction()
        dismiss()
    }
}


// MARK: - 7. 新增預約視圖 (Add Appointment View)
struct AddAppointmentView: View {
    @Binding var appointments: [Appointment]
    let members: [Member] // 接收成員列表
    var saveAction: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    let eventStore = EKEventStore()
    
    // 服務項目新增 Emoji/圖標
    private let availableServices = [
        "💇 剪髮 (Haircut)",
        "💆 按摩 (Massage)",
        "💬 諮詢 (Consultation)",
        "💅 美甲 (Manicure)",
        "❓ 其他 (Other)"
    ]
    
    // 預約者名稱選項，包含家庭成員和一個「手動輸入」選項
    enum NameSource: String, CaseIterable, Identifiable {
        case member = "家庭成員"
        case manual = "新增非成員姓名"
        var id: String { self.rawValue }
    }
    
    @State private var calendarStatusMessage: String?
    @State private var isShowingStatusAlert = false
    
    // 預約者資訊
    @State private var nameSource: NameSource = .manual
    @State private var name: String = ""
    @State private var selectedMember: Member?
    @State private var service: String = "💇 剪髮 (Haircut)"
    @State private var date: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var amountInput: String = ""
    @State private var photoDescription: String = ""
    @State private var extraServiceDetail: String = ""
    
    var finalName: String {
        if nameSource == .manual {
            return name
        } else {
            return selectedMember?.name ?? "未知成員"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: 預約者資訊 (新增成員選擇邏輯)
                Section("預約者/家庭成員 (必填)") {
                    Picker("預約者來源", selection: $nameSource) {
                        Text("新增非成員姓名").tag(NameSource.manual)
                        if !members.isEmpty {
                            Text("選擇家庭成員").tag(NameSource.member)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if nameSource == .manual {
                        TextField("預約者姓名", text: $name)
                            .textInputAutocapitalization(.words)
                    } else if nameSource == .member && !members.isEmpty {
                        Picker("選擇成員", selection: $selectedMember) {
                            ForEach(members, id: \.self) { member in
                                Text(member.name).tag(Optional(member))
                            }
                        }
                        .onAppear {
                            if selectedMember == nil {
                                selectedMember = members.first
                            }
                        }
                    }
                }
                
                // MARK: 預約服務資訊
                Section("預約服務資訊") {
                    Picker("服務項目", selection: $service) {
                        ForEach(availableServices, id: \.self) { serviceOption in
                            Text(serviceOption)
                        }
                    }
                    
                    // 根據服務項目顯示額外輸入欄位
                    if service.contains("其他") {
                        TextField("請描述額外服務內容", text: $extraServiceDetail, axis: .vertical)
                            .lineLimit(2...5)
                    }
                    
                    DatePicker("日期與時間", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
                
                // MARK: 消費金額
                Section("消費金額 (必填)") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("金額", text: $amountInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // MARK: 客戶聯絡資訊
                Section("客戶聯絡資訊 (選填)") {
                    TextField("郵件地址 (Email)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    TextField("電話號碼 (Phone)", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                // MARK: 照片/記錄備註
                Section("照片/記錄備註 (選填)") {
                    TextEditor(text: $photoDescription)
                        .frame(height: 100)
                }
                
                // 提交按鈕
                Button("儲存預約，並設定本地提醒") {
                    saveAppointment()
                }
                .disabled(finalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amountInput.isEmpty)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("新增預約")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("預約同步狀態", isPresented: $isShowingStatusAlert) {
                Button("確定") {
                    self.dismiss()
                }
            } message: {
                Text(calendarStatusMessage ?? "發生未知錯誤。")
            }
        }
    }
    
    /// 將新預約添加到列表、日曆並設定通知
    func saveAppointment() {
        let parsedAmount = Double(amountInput.trimmingCharacters(in: .whitespacesAndNewlines))
        let trimmedPhotoDesc = photoDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let detail = service.contains("其他") ? extraServiceDetail.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let trimmedDetail = detail.isEmpty ? nil : detail
        
        let newAppointment = Appointment(
            name: finalName,
            date: date,
            service: service,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email,
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone,
            amount: parsedAmount,
            photoDescription: trimmedPhotoDesc.isEmpty ? nil : trimmedPhotoDesc,
            isPhotoAttached: false,
            extraServiceDetail: trimmedDetail
        )
        
        appointments.append(newAppointment)
        saveAction()
        
        scheduleLocalNotification(appointment: newAppointment)
        addEventToCalendar(appointment: newAppointment)
    }
    
    // MARK: - 本地通知邏輯
    func scheduleLocalNotification(appointment: Appointment) {
        let center = UNUserNotificationCenter.current()
        guard let reminderDate = Calendar.current.date(byAdding: .minute, value: -30, to: appointment.date) else { return }
        guard reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ 預約提醒：服務將於 30 分鐘後開始"
        content.body = "客戶：\(appointment.name)；服務：\(appointment.service)。請準時準備。"
        content.sound = UNNotificationSound.default
        
        let triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: appointment.id.uuidString, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error { print("Error scheduling notification: \(error.localizedDescription)") }
        }
    }
    
    // MARK: - 日曆同步邏輯
    func addEventToCalendar(appointment: Appointment) {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if granted && error == nil {
                    let event = EKEvent(eventStore: self.eventStore)
                    event.title = "預約: \(appointment.service) (\(appointment.name))"
                    event.startDate = appointment.date
                    event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: appointment.date)!
                    
                    var notes = "服務項目: \(appointment.service)\n預約者: \(appointment.name)"
                    if let detail = appointment.extraServiceDetail { notes += "\n額外服務: \(detail)" }
                    if let amount = appointment.amount { notes += "\n消費金額: $\(amount, default: "%.0f")" }
                    if let photoDesc = appointment.photoDescription { notes += "\n照片備註: \(photoDesc)" }
                    if let email = appointment.email { notes += "\n郵件: \(email)" }
                    if let phone = appointment.phone { notes += "\n電話: \(phone)" }
                    if appointment.isPhotoAttached { notes += "\n [已附加服務照片記錄] " }

                    event.notes = notes
                    event.calendar = self.eventStore.defaultCalendarForNewEvents
                    
                    do {
                        try self.eventStore.save(event, span: .thisEvent)
                        self.calendarStatusMessage = "✅ 預約已成功新增至日曆與本地通知！"
                        self.isShowingStatusAlert = true
                    } catch {
                        self.calendarStatusMessage = "❌ 日曆儲存失敗: \(error.localizedDescription)"
                        self.isShowingStatusAlert = true
                    }
                } else {
                    let errorMessage = error?.localizedDescription ?? "日曆權限被拒。請在設定中開啟。"
                    self.calendarStatusMessage = "⚠️ 預約已儲存，但日曆同步失敗。\n原因: \(errorMessage)"
                    self.isShowingStatusAlert = true
                }
            }
        }
    }
}

// MARK: - 9. 成員管理視圖 (Member Management View - Tab 4)
struct MemberManagementView: View {
    @Binding var members: [Member]
    var saveAction: () -> Void
    
    @State private var newMemberName: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section("新增家庭成員") {
                        HStack {
                            TextField("輸入成員姓名 (e.g., 爸爸, 妹妹)", text: $newMemberName)
                            
                            Button {
                                addMember()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.indigo)
                            }
                            .disabled(newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    Section("現有家庭成員列表") {
                        if members.isEmpty {
                            Text("目前沒有成員。")
                                .foregroundColor(.secondary)
                        } else {
                            List {
                                ForEach(members) { member in
                                    HStack {
                                        Image(systemName: "person.fill").foregroundColor(.indigo)
                                        Text(member.name)
                                    }
                                }
                                .onDelete(perform: deleteMembers)
                            }
                        }
                    }
                }
            }
            .navigationTitle("成員管理")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !members.isEmpty {
                        EditButton()
                    }
                }
            }
        }
    }
    
    func addMember() {
        let trimmedName = newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newMember = Member(name: trimmedName)
        members.append(newMember)
        members.sort { $0.name < $1.name } // 排序
        saveAction()
        
        newMemberName = ""
        // 觸覺回饋
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func deleteMembers(at offsets: IndexSet) {
        members.remove(atOffsets: offsets)
        saveAction()
    }
}


// MARK: - 8. App 結構 (App Structure)
@main
struct AppointmentSystemApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

