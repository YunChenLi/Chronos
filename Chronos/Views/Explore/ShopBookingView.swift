//
//  ShopBookingView.swift
//  KinKeep
//

internal import SwiftUI
import EventKit

struct ShopBookingView: View {
    let shop: Shop
    let service: ShopService
    @Binding var appointments: [Appointment]
    let members: [Member]
    var saveAction: () -> Void

    @Environment(\.dismiss) var dismiss

    // 預約資料
    @State private var selectedDate: Date = nextHalfHour()
    @State private var selectedMemberID: UUID?
    @State private var note: String = ""
    @State private var selectedReminders: Set<ReminderOption> = [.oneHour, .thirtyMin]

    // 日曆相關
    private let eventStore = EKEventStore()
    @State private var isBookingConfirmed = false
    @State private var calendarStatusMessage = ""
    @State private var isShowingStatusAlert = false

    init(shop: Shop, service: ShopService, appointments: Binding<[Appointment]>,
         members: [Member], saveAction: @escaping () -> Void) {
        self.shop = shop
        self.service = service
        self._appointments = appointments
        self.members = members
        self.saveAction = saveAction
        self._selectedMemberID = State(initialValue: members.first?.id)
    }

    var selectedMember: Member? {
        members.first(where: { $0.id == selectedMemberID })
    }

    var isSaveDisabled: Bool { selectedMember == nil }

    // 預計結束時間
    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: service.duration, to: selectedDate) ?? selectedDate
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: 預約摘要
                Section("預約服務") {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: shop.category.color).opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: shop.imageSystemIcon)
                                .foregroundColor(Color(hex: shop.category.color))
                                .font(.title3)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shop.name).font(.headline).fontWeight(.bold)
                            Text(service.name).font(.subheadline).foregroundColor(.secondary)
                            HStack(spacing: 12) {
                                Label("$\(Int(service.price))", systemImage: "dollarsign.circle")
                                    .font(.caption).foregroundColor(.indigo)
                                Label("\(service.duration) 分鐘", systemImage: "clock")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: 預約人
                Section("預約人") {
                    if members.isEmpty {
                        Text("⚠️ 請先在「成員管理」新增成員").foregroundColor(.orange)
                    } else {
                        Picker("選擇成員", selection: $selectedMemberID) {
                            ForEach(members) { member in
                                HStack {
                                    Circle().fill(Color(hex: member.colorHex)).frame(width: 10, height: 10)
                                    Text(member.name)
                                }
                                .tag(member.id as UUID?)
                            }
                        }
                    }
                }

                // MARK: 預約時間
                Section("選擇時間") {
                    DatePicker(
                        "預約日期與時間",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)

                    HStack {
                        Image(systemName: "clock.fill").foregroundColor(.indigo)
                        Text(selectedDate.formatted(date: .long, time: .shortened))
                            .font(.subheadline).foregroundColor(.indigo)
                    }
                    HStack {
                        Image(systemName: "clock.badge.checkmark").foregroundColor(.secondary)
                        Text("預計結束：\(endTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                // MARK: 提醒設定
                Section("提醒設定") {
                    ForEach(ReminderOption.allCases) { option in
                        HStack {
                            Image(systemName: option.icon).foregroundColor(.indigo).frame(width: 24)
                            Text(option.rawValue)
                            Spacer()
                            Image(systemName: selectedReminders.contains(option)
                                  ? "checkmark.circle.fill" : "circle")
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

                // MARK: 備註
                Section("備註（選填）") {
                    TextEditor(text: $note)
                        .frame(height: 80)
                        .overlay(
                            Text(note.isEmpty ? "輸入給店家的備註..." : "")
                                .foregroundColor(.secondary).allowsHitTesting(false)
                                .padding(.top, 8).padding(.leading, 5),
                            alignment: .topLeading
                        )
                }

                // MARK: 確認預約按鈕
                Button {
                    confirmBooking()
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("確認預約並加入日曆")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaveDisabled)
            }
            .navigationTitle("線上預約")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            // 日曆同步結果 Alert（包含成功/失敗訊息）
            .alert(isBookingConfirmed ? "預約成功 🎉" : "預約已儲存",
                   isPresented: $isShowingStatusAlert) {
                Button("完成") { dismiss() }
            } message: {
                Text(calendarStatusMessage)
            }
        }
    }

    // MARK: - 確認預約 + 日曆同步

    func confirmBooking() {
        guard let member = selectedMember else { return }
        let reminders = Array(selectedReminders)

        var newAppointment = Appointment(
            name: member.name,
            date: selectedDate,
            service: service.name,
            phone: shop.phone,
            amount: service.price,
            photoDescription: note.isEmpty ? nil : note,
            extraServiceDetail: "📍 \(shop.name)・\(shop.address)",
            reminderOptions: reminders
        )
        newAppointment.recurrence = .none

        // 1. 存入 App 預約列表
        appointments.append(newAppointment)
        saveAction()

        // 2. 設定本地通知
        NotificationManager.scheduleReminders(for: newAppointment, options: reminders)

        // 3. 同步到 Apple Calendar
        addToAppleCalendar(appointment: newAppointment)
    }

    // MARK: - Apple Calendar 同步邏輯

    func addToAppleCalendar(appointment: Appointment) {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if granted && error == nil {
                    let event = EKEvent(eventStore: self.eventStore)

                    // 標題
                    event.title = "\(self.service.name) @ \(self.shop.name)"

                    // 開始 / 結束時間
                    event.startDate = self.selectedDate
                    event.endDate   = self.endTime

                    // 地點
                    event.location = self.shop.address

                    // 備註內容
                    var notes = "🏪 店家：\(self.shop.name)"
                    notes += "\n💆 服務：\(self.service.name)"
                    notes += "\n⏱ 時長：\(self.service.duration) 分鐘"
                    notes += "\n💰 費用：$\(Int(self.service.price))"
                    if let phone = self.shop.phone { notes += "\n📞 電話：\(phone)" }
                    notes += "\n📍 地址：\(self.shop.address)"
                    if !self.note.isEmpty { notes += "\n📝 備註：\(self.note)" }
                    event.notes = notes

                    // 加入日曆提醒（與 App 通知同步）
                    for option in self.selectedReminders {
                        let alarm = EKAlarm(relativeOffset: TimeInterval(-option.minutesBefore * 60))
                        event.addAlarm(alarm)
                    }

                    event.calendar = self.eventStore.defaultCalendarForNewEvents

                    do {
                        try self.eventStore.save(event, span: .thisEvent)
                        self.calendarStatusMessage =
                            "已將「\(self.service.name)」加入預約列表與 Apple 日曆 📅\n\n店家：\(self.shop.name)\n時間：\(self.selectedDate.formatted(date: .long, time: .shortened))"
                        self.isBookingConfirmed = true
                    } catch {
                        self.calendarStatusMessage =
                            "預約已儲存至 App ✅\n但日曆同步失敗：\(error.localizedDescription)"
                        self.isBookingConfirmed = false
                    }
                } else {
                    // 無日曆權限，仍完成預約
                    self.calendarStatusMessage =
                        "預約已儲存至 App ✅\n\n若要同步至 Apple 日曆，請至「設定 → 隱私權 → 行事曆」開啟存取權限。"
                    self.isBookingConfirmed = true
                }
                self.isShowingStatusAlert = true
            }
        }
    }

    // MARK: - 工具

    static func nextHalfHour() -> Date {
        let cal = Calendar.current
        let now = Date()
        let minutes = cal.component(.minute, from: now)
        let addMinutes = minutes < 30 ? 30 - minutes : 60 - minutes
        return cal.date(byAdding: .minute, value: addMinutes, to: now) ?? now
    }
}

