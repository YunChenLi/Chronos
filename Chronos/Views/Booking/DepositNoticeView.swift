//
//  DepositNoticeView.swift
//  KinKeep
//
//  放鳥兩次後，預約前顯示訂金說明
//

internal import SwiftUI

struct DepositNoticeView: View {
    let servicePrice: Double
    let onProceed: () -> Void
    let onCancel: () -> Void

    var depositAmount: Double { servicePrice * 0.3 }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // 圖示
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)
                }

                // 說明
                VStack(spacing: 12) {
                    Text("需要支付預約訂金")
                        .font(.title2).fontWeight(.bold)

                    Text("由於你曾有 2 次預約未出現記錄，\n本次預約需先支付 30% 訂金。")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    // 金額
                    VStack(spacing: 8) {
                        HStack {
                            Text("服務費用")
                            Spacer()
                            Text("$\(Int(servicePrice))")
                        }
                        HStack {
                            Text("預約訂金（30%）")
                                .fontWeight(.semibold).foregroundColor(.orange)
                            Spacer()
                            Text("$\(Int(depositAmount))")
                                .fontWeight(.bold).foregroundColor(.orange)
                        }
                        Divider()
                        HStack {
                            Text("現場付款").foregroundColor(.secondary).font(.caption)
                            Spacer()
                            Text("$\(Int(servicePrice - depositAmount))")
                                .foregroundColor(.secondary).font(.caption)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Text("訂金將於成功完成服務後自動抵扣服務費用。")
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // 按鈕
                VStack(spacing: 12) {
                    Button {
                        onProceed()
                    } label: {
                        Label("使用 Apple Pay 支付訂金", systemImage: "apple.logo")
                            .frame(maxWidth: .infinity).padding(14)
                            .background(Color.black).foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Button("取消預約") { onCancel() }
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("訂金說明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onCancel() }
                }
            }
        }
    }
}
