//
//  AddAppointmentView.swift
//  KinKeep
//

internal import SwiftUI
import EventKit
import PhotosUI

/// 新增預約視圖（含真實照片、多重提醒、重複預約）
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
        case manual = "手動輸入"
        case member = "選擇成員"
        var id: String { self.rawValue }
    }

    // 基本資訊
    @State private var nameSource: NameSource = .manual
    @State private var name: String = ""
    @State private var selectedMember: Member?
    @State private var service: String = "💇 剪髮 (Haircut)"
    @State private var date: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var amountInput: String = ""
    @State private var extraServiceDetail: String = ""

    // 照片
    @State private var photoDescription: String = ""
    @State private var selectedUIImage: UIImage?
    @State private var isShowingCamera: Bool = false
    @State private var isShowingImagePicker: Bool = false
    @State private var imageSelection: PhotosPickerItem? = nil

    // 提醒
    @State private var selectedReminders: Set<ReminderOption> = [.thirtyMin]

    // 重複預約
    @State private var recurrence: RecurrenceOption = .none
    @State private var recurrenceCount: Int = 4

    // 日曆提示
    @State private var calendarStatusMessage: String?
    @State private var isShowingStatusAlert = false

    var finalName: String {
        nameSource == .manual ? name : (selectedMember?.name ?? members.first?.name ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: 預約者
                Section("預約者／家庭成員 (必填)") {
                    Picker("來源", selection: $nameSource) {
                        Text("手動輸入").tag(NameSource.manual)
                        if !members.isEmpty {
                            Text("選擇成員").tag(NameSource.member)
                        }
                    }
                    .pickerStyle(.segmented)

                    if nameSource == .manual {
                        TextField("預約者姓名", text: $name)
                            .textInputAutocapitalization(.words)
                    } else if !members.isEmpty {
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
                            if selectedMember == nil { selectedMember = members.first }
                        }
                    } else {
                        Text("⚠️ 請先在「成員管理」新增成員")
                            .foregroundColor(.orange)
                            .onAppear { nameSource = .manual }
                    }
                }

                // MARK: 服務資訊
                Section("預約服務資訊") {
                    Picker("服務項目", selection: $service) {
                        ForEach(availableServices, id: \.self) { Text($0) }
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

                // MARK: 聯絡資訊
                Section("客戶聯絡資訊 (選填)") {
                    TextField("郵件地址 (Email)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("電話號碼 (Phone)", text: $phone)
                        .keyboardType(.phonePad)
                }

                // MARK: 照片／備註
                Section("照片／備註 (選填)") {
                    if let uiImage = selectedUIImage {
                        VStack(alignment: .center, spacing: 8) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 150)
                                .cornerRadius(10)
                            Button("移除照片") {
                                selectedUIImage = nil
                                imageSelection = nil
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Menu {
                            Button {
                                isShowingCamera = true
                                isShowingImagePicker = true
                            } label: {
                                Label("使用相機拍照", systemImage: "camera")
                            }
                            PhotosPicker(selection: $imageSelection, matching: .images) {
                                Label("從相簿選擇", systemImage: "photo.stack")
                            }
                        } label: {
                            HStack {
                                Image(systemName: "photo.badge.plus").foregroundColor(.indigo)
                                Text("附加收據／照片").foregroundColor(.indigo)
                            }
                        }
                    }

                    TextEditor(text: $photoDescription)
                        .frame(height: 80)
                        .overlay(
                            Text(photoDescription.isEmpty ? "輸入文字備註..." : "")
                                .foregroundColor(.secondary)
                                .allowsHitTesting(false)
                                .padding(.top, 8).padding(.leading, 5),
                            alignment: .topLeading
                        )
                }

                // MARK: 提醒設定
                Section("提醒設定") {
                    ForEach(ReminderOption.allCases) { option in
                        HStack {
                            Image(systemName: option.icon).foregroundColor(.indigo).frame(width: 24)
                            Text(option.rawValue)
                            Spacer()
                            Image(systemName: selectedReminders.contains(option) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedReminders.contains(option) ? .indigo : .gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedReminders.contains(option) {
                                selectedReminders.remove(option)
                            } else {
                                selectedReminders.insert(option)
                            }
                        }
                    }
                }

                // MARK: 重複預約
                Section("重複預約") {
                    Picker("重複週期", selection: $recurrence) {
                        ForEach(RecurrenceOption.allCases) { option in
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.rawValue)
                            }
                            .tag(option)
                        }
                    }

                    if recurrence != .none {
                        Stepper("重複 \(recurrenceCount) 次", value: $recurrenceCount, in: 2...52)
                            .foregroundColor(.indigo)

                        let previewDates = recurrence.generateDates(from: date, count: min(3, recurrenceCount))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("預覽（前 \(min(3, recurrenceCount)) 筆）")
                                .font(.caption).foregroundColor(.secondary)
                            ForEach(previewDates, id: \.self) { d in
                                Text("• \(d.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundColor(.indigo)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: 儲存按鈕
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
                Button("確定") { dismiss() }
            } message: {
                Text(calendarStatusMessage ?? "發生未知錯誤。")
            }
            .onChange(of: imageSelection) { _, newSelection in
                guard let item = newSelection else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run { selectedUIImage = uiImage }
                    }
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(
                    selectedImage: $selectedUIImage,
                    sourceType: isShowingCamera ? .camera : .photoLibrary
                )
            }
        }
    }

    // MARK: - 儲存邏輯

    func saveAppointment() {
        let parsedAmount = Double(amountInput.trimmingCharacters(in: .whitespacesAndNewlines))
        let trimmedPhotoDesc = photoDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = service.contains("其他") ? extraServiceDetail.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let reminders = Array(selectedReminders)
        let count = recurrence == .none ? 1 : recurrenceCount
        let dates = recurrence.generateDates(from: date, count: count)
        let groupID = recurrence == .none ? nil : UUID()
        let photoData = selectedUIImage?.jpegData(compressionQuality: 0.8)

        for appointmentDate in dates {
            var newAppointment = Appointment(
                name: finalName,
                date: appointmentDate,
                service: service,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email,
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone,
                amount: parsedAmount,
                photoDescription: trimmedPhotoDesc.isEmpty ? nil : trimmedPhotoDesc,
                photoData: photoData,
                extraServiceDetail: detail.isEmpty ? nil : detail,
                reminderOptions: reminders
            )
            newAppointment.recurrence = recurrence
            newAppointment.recurrenceGroupID = groupID

            appointments.append(newAppointment)
            NotificationManager.scheduleReminders(for: newAppointment, options: reminders)
            addEventToCalendar(appointment: newAppointment)
        }
        saveAction()
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
                    var notes = "服務: \(appointment.service)\n預約者: \(appointment.name)"
                    if let detail = appointment.extraServiceDetail { notes += "\n額外服務: \(detail)" }
                    if let amount = appointment.amount { notes += "\n金額: $\(String(format: "%.0f", amount))" }
                    if let email = appointment.email { notes += "\n郵件: \(email)" }
                    if let phone = appointment.phone { notes += "\n電話: \(phone)" }
                    event.notes = notes
                    event.calendar = self.eventStore.defaultCalendarForNewEvents
                    do {
                        try self.eventStore.save(event, span: .thisEvent)
                        self.calendarStatusMessage = "✅ 預約已成功新增至日曆！"
                    } catch {
                        self.calendarStatusMessage = "❌ 日曆儲存失敗: \(error.localizedDescription)"
                    }
                    self.isShowingStatusAlert = true
                } else {
                    self.calendarStatusMessage = "⚠️ 預約已儲存，但日曆同步失敗。請在設定中開啟日曆權限。"
                    self.isShowingStatusAlert = true
                }
            }
        }
    }
}

