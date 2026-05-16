//
//  MyBookingsView.swift
//  KinKeep
//
//  整合預約列表 + 訂單 + 歷史記錄
//

internal import SwiftUI

struct MyBookingsView: View {
    @StateObject private var bookingManager = BookingManager.shared
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedTab: BookingTab = .upcoming

    enum BookingTab: String, CaseIterable {
        case upcoming = "即將到來"
        case history  = "歷史記錄"
        case cancelled = "已取消"
    }

    var upcomingBookings: [OnlineBooking] {
        bookingManager.myBookings.filter {
            $0.status == .pending || $0.status == .confirmed
        }
        .sorted { $0.date < $1.date }
    }

    var historyBookings: [OnlineBooking] {
        bookingManager.myBookings.filter {
            $0.status == .completed || $0.status == .noShow
        }
        .sorted { $0.date > $1.date }
    }

    var cancelledBookings: [OnlineBooking] {
        bookingManager.myBookings.filter { $0.status == .cancelled }
            .sorted { $0.date > $1.date }
    }

    // 放鳥警告
    var noShowCount: Int {
        bookingManager.myBookings.filter { $0.status == .noShow }.count
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // 放鳥警告橫幅
                if noShowCount >= 1 {
                    NoShowWarningBanner(count: noShowCount)
                }

                // 分頁切換
                Picker("", selection: $selectedTab) {
                    ForEach(BookingTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // 內容
                Group {
                    switch selectedTab {
                    case .upcoming:
                        BookingListSection(
                            bookings: upcomingBookings,
                            emptyIcon: "calendar.badge.plus",
                            emptyTitle: "沒有即將到來的預約",
                            emptyDesc: "去「探索」頁面找合作店家預約吧！",
                            showCancelButton: true
                        )
                    case .history:
                        BookingListSection(
                            bookings: historyBookings,
                            emptyIcon: "clock.badge.checkmark",
                            emptyTitle: "尚無歷史記錄",
                            emptyDesc: "完成的預約會顯示在這裡",
                            showCancelButton: false
                        )
                    case .cancelled:
                        BookingListSection(
                            bookings: cancelledBookings,
                            emptyIcon: "xmark.circle",
                            emptyTitle: "沒有取消的預約",
                            emptyDesc: "",
                            showCancelButton: false
                        )
                    }
                }
            }
            .navigationTitle("我的預約")
            .onAppear {
                if let userID = authManager.currentUser?.id {
                    bookingManager.listenMyBookings(consumerID: userID)
                }
            }
        }
    }
}

// MARK: - 放鳥警告橫幅

struct NoShowWarningBanner: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(count >= 2 ? "⚠️ 下次預約需支付訂金" : "注意：你有 \(count) 次未出現記錄")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                Text(count >= 2
                     ? "因累計 2 次未出現，預約時需先支付 30% 訂金"
                     : "再一次未出現，下次預約將需要支付訂金")
                    .font(.caption).foregroundColor(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(12)
        .background(count >= 2 ? Color.red : Color.orange)
    }
}

// MARK: - 預約列表區塊

struct BookingListSection: View {
    let bookings: [OnlineBooking]
    let emptyIcon: String
    let emptyTitle: String
    let emptyDesc: String
    let showCancelButton: Bool

    var body: some View {
        if bookings.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: emptyIcon)
                    .font(.system(size: 48)).foregroundColor(.secondary)
                Text(emptyTitle).font(.headline).foregroundColor(.secondary)
                if !emptyDesc.isEmpty {
                    Text(emptyDesc).font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            List {
                ForEach(bookings) { booking in
                    NavigationLink(destination: BookingDetailView(booking: booking)) {
                        BookingRowView(booking: booking)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - 預約列表行

struct BookingRowView: View {
    let booking: OnlineBooking

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.shopName)
                        .font(.headline).fontWeight(.bold)
                    Text(booking.serviceName)
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                StatusBadge(status: booking.status)
            }

            HStack(spacing: 12) {
                Label(
                    booking.date.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "clock"
                )
                .font(.caption).foregroundColor(.secondary)

                if booking.status == .confirmed || booking.status == .pending {
                    Text(booking.timeUntilText)
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(booking.canCancel ? .secondary : .orange)
                }
            }

            if booking.depositPaid && booking.depositAmount > 0 {
                Label("已支付訂金 $\(Int(booking.depositAmount))",
                      systemImage: "checkmark.seal.fill")
                    .font(.caption).foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 狀態標籤

struct StatusBadge: View {
    let status: BookingStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.displayText)
        }
        .font(.caption).fontWeight(.semibold)
        .foregroundColor(Color(hex: status.color))
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color(hex: status.color).opacity(0.12))
        .cornerRadius(8)
    }
}
