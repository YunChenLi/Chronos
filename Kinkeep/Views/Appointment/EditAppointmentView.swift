//
//  EditAppointmentView.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//  EditAppointmentView.swift: 編輯預約頁面
import SwiftUI
internal import Combine
import Foundation
import UserNotifications
import EventKit
import PhotosUI
import UIKit
import CoreImage.CIFilterBuiltins
import Charts

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

