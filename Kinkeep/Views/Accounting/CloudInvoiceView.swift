//
//  CloudInvoiceView.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//
import SwiftUI
import Foundation
import EventKit
import UserNotifications
import PhotosUI
import UIKit
import CoreImage.CIFilterBuiltins
import Charts
internal import Combine
// MARK: - 雲端發票視圖
struct CloudInvoiceView: View {
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var lifestyleManager: LifestyleManager

    var saveAction: () -> Void
    @Environment(\.dismiss) var dismiss
    @AppStorage("MobileBarcode") private var mobileBarcode: String = ""
    @State private var isSyncing = false
    @State private var showSyncAlert = false
    @State private var syncedCount = 0
    
    func generateBarcode(from string: String) -> UIImage? {
        let context = CIContext(); let filter = CIFilter.code128BarcodeGenerator()
        filter.message = string.data(using: .ascii) ?? Data()
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) { return UIImage(cgImage: cgImage) }
        }
        return nil
    }
    
    func simulateSync() {
        guard !mobileBarcode.isEmpty else { return }
        isSyncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let locations = ["7-11", "全家", "全聯", "中油", "星巴克"]
            let randomCount = Int.random(in: 1...3)
            var newItems: [Expense] = []
            for _ in 0..<randomCount {
                let loc = locations.randomElement()!; let amt = Double(Int.random(in: 30...500))
                let cat = (loc.contains("中油")) ? "行" : "食"; let sub = (cat == "行") ? "油錢" : "零食"
                newItems.append(Expense(date: Date(), amount: amt, mainCategory: cat, subCategory: sub, note: "☁️ 發票: \(loc)", memberId: nil))
            }
            expenses.append(contentsOf: newItems)
            saveAction()
            syncedCount = newItems.count; isSyncing = false; showSyncAlert = true
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Text("手機條碼").font(.headline).foregroundColor(.secondary)
                    if mobileBarcode.isEmpty {
                        Image(systemName: "barcode.viewfinder").resizable().scaledToFit().frame(height: 100).foregroundColor(.gray.opacity(0.3))
                        Text("請輸入條碼").font(.caption).foregroundColor(.secondary)
                    } else if let barcodeImg = generateBarcode(from: mobileBarcode) {
                        Image(uiImage: barcodeImg).resizable().interpolation(.none).scaledToFit().frame(height: 120).padding().background(Color.white).cornerRadius(10)
                        Text(mobileBarcode).font(.system(.title2, design: .monospaced)).bold()
                    }
                }.padding().frame(maxWidth: .infinity).background(Color(UIColor.secondarySystemBackground)).cornerRadius(15).padding(.horizontal)
                
                Form {
                    Section("設定") { TextField("輸入手機條碼 (e.g. /AB1234)", text: $mobileBarcode).disableAutocorrection(true) }
                    Section {
                        Button { simulateSync() } label: { HStack { if isSyncing { ProgressView().padding(.trailing, 5); Text("同步中...") } else { Image(systemName: "arrow.triangle.2.circlepath"); Text("同步雲端發票") } } }
                        .disabled(mobileBarcode.isEmpty || isSyncing)
                    }
                }
                .scrollContentBackground(.hidden).background(Color.themeBackground)
            }
            .background(Color.themeBackground)
            .navigationTitle("雲端發票")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("關閉") { dismiss() } } }
            .alert("同步完成", isPresented: $showSyncAlert) { Button("好") {} } message: { Text("匯入 \(syncedCount) 筆資料。") }
        }
    }
}

