//
//  EditAppointmentView.swift
//  KinKeep
//

import SwiftUI
import PhotosUI

/// 編輯預約視圖（含真實照片功能）
struct EditAppointmentView: View {
    @Binding var appointment: Appointment
    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var amountInput: String
    @State private var photoDescription: String
    @State private var extraServiceDetail: String

    // 真實照片
    @State private var selectedUIImage: UIImage?
    @State private var isShowingImagePicker: Bool = false
    @State private var isShowingCamera: Bool = false
    @State private var imageSelection: PhotosPickerItem? = nil

    init(appointment: Binding<Appointment>, saveAction: @escaping () -> Void) {
        self._appointment = appointment
        self.saveAction = saveAction
        _amountInput = State(initialValue: appointment.wrappedValue.amount.map { String(format: "%.0f", $0) } ?? "")
        _photoDescription = State(initialValue: appointment.wrappedValue.photoDescription ?? "")
        _extraServiceDetail = State(initialValue: appointment.wrappedValue.extraServiceDetail ?? "")
        if let data = appointment.wrappedValue.photoData {
            _selectedUIImage = State(initialValue: UIImage(data: data))
        }
    }

    var body: some View {
        Form {
            // MARK: 預約摘要
            Section("預約者與服務資訊") {
                HStack {
                    Image(systemName: "person.circle.fill").foregroundColor(.indigo)
                    Text("客戶: \(appointment.name)")
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
                        Text("額外服務內容").font(.caption).foregroundColor(.secondary)
                        TextField("請描述額外服務內容", text: $extraServiceDetail, axis: .vertical)
                            .lineLimit(2...5)
                    }
                }
            }

            // MARK: 消費金額
            Section("修改消費金額") {
                HStack {
                    Text("$").foregroundColor(.secondary)
                    TextField("金額", text: $amountInput)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            // MARK: 照片記錄（真實相機/相簿）
            Section("照片記錄與管理") {
                if let uiImage = selectedUIImage {
                    VStack(alignment: .center, spacing: 10) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(10)

                        Button("移除照片") {
                            selectedUIImage = nil
                            imageSelection = nil
                        }
                        .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // 選擇照片來源
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

                // 文字備註
                TextEditor(text: $photoDescription)
                    .frame(height: 100)
                    .overlay(
                        Text(photoDescription.isEmpty ? "輸入照片備註或說明..." : "")
                            .foregroundColor(.secondary)
                            .allowsHitTesting(false)
                            .padding(.top, 8).padding(.leading, 5),
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
        // PhotosPicker 選擇後載入圖片
        .onChange(of: imageSelection) { _, newSelection in
            guard let item = newSelection else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run { selectedUIImage = uiImage }
                }
            }
        }
        // 相機 sheet
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(
                selectedImage: $selectedUIImage,
                sourceType: isShowingCamera ? .camera : .photoLibrary
            )
        }
    }

    func saveChanges() {
        appointment.amount = Double(amountInput.trimmingCharacters(in: .whitespacesAndNewlines))
        appointment.photoData = selectedUIImage?.jpegData(compressionQuality: 0.8)
        let trimmedDesc = photoDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.photoDescription = trimmedDesc.isEmpty ? nil : trimmedDesc
        let trimmedDetail = extraServiceDetail.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.extraServiceDetail = trimmedDetail.isEmpty ? nil : trimmedDetail
        saveAction()
        dismiss()
    }
}

