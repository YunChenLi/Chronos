//
//  ShopBookingView.swift
//  KinKeep
//
//  更新：預約確認後同時寫入 Firebase bookings 集合
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
    @StateObject private var authManager = AuthManager.shared

    @State private var selectedDate: Date = nextHalfHour()
    @State private var selectedMemberID: UUID?
    @State private var note: String = ""
    @State private var selectedReminders: Set<ReminderOption> = [.oneHour, .thirtyMin]

    private let eventStore = EKEventStore()
    @State private var isBookingConfirmed = false
    @State private var calendarStatusMessage = ""
    @State private var isShowingStatusAlert = false
    @State private var isSaving = false

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

    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: service.duration, to: selectedDate) ?? selectedDate
    }

    var isSaveDisabled: Bool { selectedMember == nil || isSaving }

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
                    DatePicker("預約日期與時間", selection: $selectedDate,
                               in: Date()..., displayedComponents: [.date, .hourAndMinute])
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
                    TextEditor(text: $note).frame(height: 80)
                        .overlay(
                            Text(note.isEmpty ? "輸入給店家的備註..." : "")
                                .foregroundColor(.secondary).allowsHitTesting(false)
                                .padding(.top, 8).padding(.leading, 5),
                            alignment: .topLeading
                        )
                }

                // MARK: 確認按鈕
                Button {
                    confirmBooking()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "calendar.badge.plus")
                            Text("確認預約並加入日曆")
                        }
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
            .alert(isBookingConfirmed ? "預約成功 🎉" : "預約已儲存",
                   isPresented: $isShowingStatusAlert) {
                Button("完成") { dismiss() }
            } message: {
                Text(calendarStatusMessage)
            }
        }
    }

    // MARK: - 確認預約

    func confirmBooking() {
        guard let member = selectedMember else { return }
        isSaving = true
        let reminders = Array(selectedReminders)

        // 1. 存入本地 App
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
        appointments.append(newAppointment)
        saveAction()
        NotificationManager.scheduleReminders(for: newAppointment, options: reminders)

        // 2. 寫入 Firebase bookings
        if let currentUser = authManager.currentUser {
            let onlineBooking = OnlineBooking(
                consumerID: currentUser.id,
                consumerName: member.name,
                consumerPhone: currentUser.phone,
                shopID: shop.id.uuidString,
                shopName: shop.name,
                serviceName: service.name,
                servicePrice: service.price,
                serviceDuration: service.duration,
                date: selectedDate,
                note: note.isEmpty ? nil : note
            )
            BookingManager.shared.createBooking(onlineBooking) { success, error  in
                print(success ? "✅ 預約已同步至 Firebase" : "⚠️ Firebase 同步失敗")
            }
        }

        // 3. 同步 Apple Calendar
        addToAppleCalendar(appointment: newAppointment)
    }

    func addToAppleCalendar(appointment: Appointment) {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                self.isSaving = false
                if granted && error == nil {
                    let event = EKEvent(eventStore: self.eventStore)
                    event.title = "\(self.service.name) @ \(self.shop.name)"
                    event.startDate = self.selectedDate
                    event.endDate = self.endTime
                    event.location = self.shop.address
                    var notes = "🏪 \(self.shop.name)\n💆 \(self.service.name)\n💰 $\(Int(self.service.price))"
                    if !self.note.isEmpty { notes += "\n📝 \(self.note)" }
                    event.notes = notes
                    for option in self.selectedReminders {
                        event.addAlarm(EKAlarm(relativeOffset: TimeInterval(-option.minutesBefore * 60)))
                    }
                    event.calendar = self.eventStore.defaultCalendarForNewEvents
                    try? self.eventStore.save(event, span: .thisEvent)
                    self.calendarStatusMessage = "已同步至 App、Firebase 與 Apple 日曆 📅"
                } else {
                    self.calendarStatusMessage = "預約已儲存 ✅\n（日曆同步需在設定中開啟權限）"
                }
                self.isBookingConfirmed = true
                self.isShowingStatusAlert = true
            }
        }
    }

    static func nextHalfHour() -> Date {
        let cal = Calendar.current
        let now = Date()
        let minutes = cal.component(.minute, from: now)
        let add = minutes < 30 ? 30 - minutes : 60 - minutes
        return cal.date(byAdding: .minute, value: add, to: now) ?? now
    }
}
