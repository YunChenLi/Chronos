//
//  AddAppointmentView.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//  AddAppointmentView.swift: 新增預約的彈窗邏輯

// MARK: - 新增/編輯 預約 (Appointment Views)
import SwiftUI
internal import Combine
import Foundation
import UserNotifications
import EventKit
import PhotosUI
import UIKit
import CoreImage.CIFilterBuiltins
import Charts

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
}
