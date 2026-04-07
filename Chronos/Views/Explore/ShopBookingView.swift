//
//  ShopBookingView.swift
//  KinKeep
//
//  線上預約表單：從店家選好服務後，填寫預約資料
//

internal import SwiftUI
internal import Combine

struct ShopBookingView: View {
    let shop: Shop
    let service: ShopService
    @Binding var appointments: [Appointment]
    let members: [Member]
    var saveAction: () -> Void

    @Environment(\.dismiss) var dismiss
    @StateObject private var notificationManager = BookingNotificationHelper()

    // 預約資料
    @State private var selectedDate: Date = nextHalfHour()
    @State private var selectedMemberID: UUID?
    @State private var note: String = ""
    @State private var selectedReminders: Set<ReminderOption> = [.oneHour, .thirtyMin]
    @State private var isBookingConfirmed = false

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

    var isSaveDisabled: Bool {
        selectedMember == nil
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: 預約摘要
                Section {
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
                } header: {
                    Text("預約服務")
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

                    // 預約時間摘要
                    HStack {
                        Image(systemName: "clock.fill").foregroundColor(.indigo)
                        Text(selectedDate.formatted(date: .long, time: .shortened))
                            .font(.subheadline).foregroundColor(.indigo)
                    }

                    // 預計結束時間
                    HStack {
                        Image(systemName: "clock.badge.checkmark").foregroundColor(.secondary)
                        let endTime = Calendar.current.date(byAdding: .minute, value: service.duration, to: selectedDate) ?? selectedDate
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
                        Text("確認預約")
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
            // 預約成功 Alert
            .alert("預約成功 🎉", isPresented: $isBookingConfirmed) {
                Button("完成") { dismiss() }
            } message: {
                Text("已將「\(service.name)」預約加入您的預約列表，並設定提醒通知。")
            }
        }
    }

    // MARK: - 確認預約邏輯

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
            extraServiceDetail: "📍 \(shop.name) · \(shop.address)",
            reminderOptions: reminders
        )
        newAppointment.recurrence = .none

        appointments.append(newAppointment)
        NotificationManager.scheduleReminders(for: newAppointment, options: reminders)
        saveAction()

        isBookingConfirmed = true
    }

    // 取最近的整點或半點
    static func nextHalfHour() -> Date {
        let cal = Calendar.current
        let now = Date()
        let minutes = cal.component(.minute, from: now)
        let addMinutes = minutes < 30 ? 30 - minutes : 60 - minutes
        return cal.date(byAdding: .minute, value: addMinutes, to: now) ?? now
    }
}

class BookingNotificationHelper: ObservableObject {
    // Add any published properties in the future if needed
    init() {}
}
