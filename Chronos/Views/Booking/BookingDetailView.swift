//
//  BookingDetailView.swift
//  KinKeep
//
//  預約詳情 + 取消操作
//

internal import SwiftUI

struct BookingDetailView: View {
    let booking: OnlineBooking
    @StateObject private var bookingManager = BookingManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var isShowingCancelSheet = false
    @State private var isShowingCancelAlert = false
    @State private var cancelReason = ""
    @State private var isCancelling = false
    @State private var cancelError: String? = nil
    @State private var cancelSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: 頂部狀態卡
                statusHeader

                // MARK: 預約資訊
                VStack(spacing: 12) {
                    InfoCard {
                        InfoRow2(icon: "building.2.fill", color: .indigo,
                                title: "店家", value: booking.shopName)
                        Divider()
                        InfoRow2(icon: "tag.fill", color: .indigo,
                                title: "服務", value: booking.serviceName)
                        Divider()
                        InfoRow2(icon: "clock.fill", color: .orange,
                                title: "時間",
                                value: booking.date.formatted(date: .long, time: .shortened))
                        Divider()
                        InfoRow2(icon: "timer", color: .teal,
                                title: "時長", value: "\(booking.serviceDuration) 分鐘")
                        Divider()
                        InfoRow2(icon: "dollarsign.circle.fill", color: .green,
                                title: "費用", value: "$\(Int(booking.servicePrice))")

                        if !booking.shopAddress.isEmpty {
                            Divider()
                            InfoRow2(icon: "mappin.circle.fill", color: .red,
                                    title: "地址", value: booking.shopAddress)
                        }
                    }

                    // 備註
                    if let note = booking.note, !note.isEmpty {
                        InfoCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("備註", systemImage: "text.bubble.fill")
                                    .font(.caption).foregroundColor(.secondary)
                                Text(note).font(.subheadline)
                            }
                        }
                    }

                    // 訂金資訊
                    if booking.depositPaid && booking.depositAmount > 0 {
                        InfoCard {
                            HStack {
                                Label("已支付訂金", systemImage: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("$\(Int(booking.depositAmount))")
                                    .fontWeight(.bold).foregroundColor(.green)
                            }
                        }
                    }

                    // 取消原因
                    if let reason = booking.cancelReason, !reason.isEmpty {
                        InfoCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("取消原因", systemImage: "xmark.circle.fill")
                                    .font(.caption).foregroundColor(.red)
                                Text(reason).font(.subheadline)
                            }
                        }
                    }
                }
                .padding()

                // MARK: 取消按鈕
                if booking.canCancel {
                    cancelSection
                } else if (booking.status == .pending || booking.status == .confirmed)
                            && !booking.canCancel {
                    // 不足 24 小時，不可取消
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("距離預約不足 24 小時，如需取消請直接聯絡店家")
                            .font(.caption).foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // 撥打電話按鈕
                    if let phone = booking.consumerPhone {
                        Button {
                            if let url = URL(string: "tel://\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("聯絡店家", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity).padding(14)
                                .background(Color(.systemGray6)).cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer().frame(height: 40)
            }
        }
        .navigationTitle("預約詳情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingCancelSheet) {
            CancelBookingSheet(
                booking: booking,
                cancelReason: $cancelReason,
                isCancelling: $isCancelling,
                onConfirm: { performCancel() },
                onDismiss: { isShowingCancelSheet = false }
            )
        }
        .alert("取消成功", isPresented: $cancelSuccess) {
            Button("確定") { dismiss() }
        } message: {
            Text("你的預約已取消，店家將會收到通知。")
        }
        .alert("取消失敗", isPresented: Binding(
            get: { cancelError != nil },
            set: { if !$0 { cancelError = nil } }
        )) {
            Button("確定") {}
        } message: {
            Text(cancelError ?? "")
        }
    }

    // MARK: - 頂部狀態

    private var statusHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: booking.status.color).opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: booking.status.icon)
                    .font(.system(size: 30))
                    .foregroundColor(Color(hex: booking.status.color))
            }
            Text(booking.status.displayText)
                .font(.title2).fontWeight(.bold)
                .foregroundColor(Color(hex: booking.status.color))

            if booking.status == .noShow {
                Text("此次預約記錄為未出現\n累計 2 次將需要支付訂金")
                    .font(.caption).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(hex: booking.status.color).opacity(0.05))
    }

    // MARK: - 取消區塊

    private var cancelSection: some View {
        VStack(spacing: 8) {
            Button {
                isShowingCancelSheet = true
            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("取消預約")
                }
                .frame(maxWidth: .infinity).padding(14)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red).cornerRadius(12)
            }

            Text("提前 24 小時可免費取消")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - 執行取消

    func performCancel() {
        isCancelling = true
        bookingManager.cancelBooking(booking, reason: cancelReason) { success, error in
            isCancelling = false
            isShowingCancelSheet = false
            if success {
                cancelSuccess = true
            } else {
                cancelError = error ?? "取消失敗，請重試"
            }
        }
    }
}

// MARK: - 取消預約 Sheet

struct CancelBookingSheet: View {
    let booking: OnlineBooking
    @Binding var cancelReason: String
    @Binding var isCancelling: Bool
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    let reasons = ["臨時有事", "行程異動", "找到其他店家", "健康因素", "其他原因"]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("取消後無法復原", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange).fontWeight(.semibold)
                        Text("取消「\(booking.shopName)」的「\(booking.serviceName)」預約")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text(booking.date.formatted(date: .long, time: .shortened))
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("取消原因（選填）") {
                    ForEach(reasons, id: \.self) { reason in
                        HStack {
                            Text(reason)
                            Spacer()
                            if cancelReason == reason {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.indigo)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { cancelReason = reason }
                    }

                    TextField("或輸入其他原因", text: $cancelReason, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button {
                        onConfirm()
                    } label: {
                        HStack {
                            if isCancelling {
                                ProgressView().tint(.white)
                            } else {
                                Text("確認取消預約")
                                    .fontWeight(.semibold).foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity).padding(4)
                    }
                    .listRowBackground(Color.red)
                    .disabled(isCancelling)
                }
            }
            .navigationTitle("取消預約")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("返回") { onDismiss() }
                }
            }
        }
    }
}

// MARK: - 共用元件

struct InfoCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct InfoRow2: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color).frame(width: 24)
            Text(title).foregroundColor(.secondary).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}
