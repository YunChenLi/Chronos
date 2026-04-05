//
//  InvoiceView.swift
//  KinKeep
//
//  雲端發票載具記錄 + 發票掃描
//

internal import SwiftUI
import PhotosUI
internal import Combine

/// 發票記錄區塊（內嵌在表單中使用）
struct InvoiceSection: View {
    @Binding var carrierCode: String      // 載具號碼
    @Binding var invoiceImageData: Data?  // 發票照片
    @StateObject private var scanner = InvoiceScannerHelper()

    @State private var isShowingCamera = false
    @State private var isShowingImagePicker = false
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage?

    var body: some View {
        Section("雲端發票載具") {

            // MARK: 載具號碼
            HStack {
                Image(systemName: "creditcard.and.123").foregroundColor(.indigo)
                TextField("載具號碼（如 /ABC-DEF）", text: $carrierCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                if !carrierCode.isEmpty {
                    Button {
                        carrierCode = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
            }

            // 格式提示
            if !carrierCode.isEmpty && !isValidCarrier(carrierCode) {
                Text("⚠️ 格式建議：/ABC-DEF（斜線開頭，7碼英數）")
                    .font(.caption).foregroundColor(.orange)
            }

            // MARK: 發票掃描照片
            if let data = invoiceImageData, let uiImage = UIImage(data: data) {
                VStack(alignment: .center, spacing: 8) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 180).cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.indigo.opacity(0.3), lineWidth: 1)
                        )
                    Button("移除發票照片") {
                        invoiceImageData = nil
                        selectedUIImage = nil
                    }
                    .foregroundColor(.red).font(.caption)
                }
                .frame(maxWidth: .infinity)
            } else {
                // 掃描 / 選擇發票
                Menu {
                    Button {
                        isShowingCamera = true
                        isShowingImagePicker = true
                    } label: {
                        Label("掃描發票（相機）", systemImage: "camera.viewfinder")
                    }

                    PhotosPicker(selection: $imageSelection, matching: .images) {
                        Label("從相簿選擇", systemImage: "photo.stack")
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.text.viewfinder").foregroundColor(.indigo)
                        Text("掃描／附加發票").foregroundColor(.indigo)
                    }
                }
            }
        }
        .onChange(of: imageSelection) { _, newSelection in
            guard let item = newSelection else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        selectedUIImage = uiImage
                        invoiceImageData = uiImage.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(
                selectedImage: $selectedUIImage,
                sourceType: isShowingCamera ? .camera : .photoLibrary
            )
            .onDisappear {
                if let uiImage = selectedUIImage {
                    invoiceImageData = uiImage.jpegData(compressionQuality: 0.8)
                }
            }
        }
    }

    private func isValidCarrier(_ code: String) -> Bool {
        // 台灣手機載具格式：/XXXXXXX（斜線 + 7碼英數）
        let pattern = #"^\/[A-Z0-9+\-.]{7}$"#
        return code.range(of: pattern, options: .regularExpression) != nil
    }
}

/// 掃描輔助（未來可整合 Vision OCR）
class InvoiceScannerHelper: ObservableObject {
    // 預留：未來可用 Vision framework 自動辨識載具條碼
    // 使用 ObservableObject 預設的 objectWillChange，無需自行宣告
    init() {}
}
