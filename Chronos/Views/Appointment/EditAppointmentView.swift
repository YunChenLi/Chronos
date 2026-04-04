//
//  EditAppointmentView.swift
//  Chronos
//

import SwiftUI

/// 編輯預約視圖
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
            // MARK: 預約摘要
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
                    Text(appointment.date, style: .date)
                    Text("@")
                    Text(appointment.date, style: .time)
                }

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
                    Text("$").foregroundColor(.secondary)
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
        appointment.amount = Double(trimmedAmount)

        let trimmedPhotoDesc = photoDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.photoDescription = trimmedPhotoDesc.isEmpty ? nil : trimmedPhotoDesc

        let trimmedExtraDetail = extraServiceDetail.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.extraServiceDetail = trimmedExtraDetail.isEmpty ? nil : trimmedExtraDetail

        appointment.isPhotoAttached = isPhotoAttached
        saveAction()
        dismiss()
    }
}
