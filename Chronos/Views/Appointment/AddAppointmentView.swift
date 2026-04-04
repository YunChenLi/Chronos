//
//  AddAppointmentView.swift
//  Chronos
//

import SwiftUI
import EventKit
import UserNotifications

/// 新增預約視圖
struct AddAppointmentView: View {
    @Binding var appointments: [Appointment]
    let members: [Member]
    var saveAction: () -> Void

    @Environment(\.dismiss) var dismiss

    let eventStore = EKEventStore()

    private let availableServices = [
        "💇 剪髮 (Haircut)",
        "💆 按摩 (Massage)",
        "💬 諮詢 (Consultation)",
        "💅 美甲 (Manicure)",
        "❓ 其他 (Other)"
    ]

    enum NameSource: String, CaseIterable, Identifiable {
        case member = "家庭成員"
        case manual = "新增非成員姓名"
        var id: String { self.rawValue }
    }

    @State private var calendarStatusMessage: String?
    @State private var isShowingStatusAlert = false

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
            return selectedMember?.name ?? (members.first?.name ?? "")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: 預約者資訊
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
                                HStack {
                                    Circle()
                                        .fill(Color(hex: member.colorHex))
                                        .frame(width: 10, height: 10)
                                    Text(member.name)
                                }
                                .tag(Optional(member))
                            }
                        }
                        .onAppear {
                            if selectedMember == nil, let first = members.first {
                                selectedMember = first
                            }
                        }
                    } else if nameSource == .member && members.isEmpty {
                        Text("⚠️ 請先在「成員管理」頁面新增家庭成員")
                            .foregroundColor(.orange)
                            .onAppear {
                                nameSource = .manual
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
                        Text("$").foregroundColor(.secondary)
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
                    Button("取消") { dismiss() }
                }
            }
            .alert("預約同步狀態", isPresented: $isShowingStatusAlert) {
                Button("確定") { self.dismiss() }
            } message: {
                Text(calendarStatusMessage ?? "發生未知錯誤。")
            }
        }
    }

    // MARK: - 儲存邏輯

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

    // MARK: - 本地通知

    func scheduleLocalNotification(appointment: Appointment) {
        let center = UNUserNotificationCenter.current()
        guard let reminderDate = Calendar.current.date(byAdding: .minute, value: -30, to: appointment.date) else { return }
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ 預約提醒：服務將於 30 分鐘後開始"
        content.body = "客戶：\(appointment.name)；服務：\(appointment.service)。請準時準備。"
        content.sound = UNNotificationSound.default

        let triggerDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: appointment.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 日曆同步

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
                    if let amount = appointment.amount { notes += "\n消費金額: $\(String(format: "%.0f", amount))" }
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
