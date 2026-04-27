//
//  MyBookingsView.swift
//  KinKeep
//
//  消費者查看自己的線上預約記錄
//

import SwiftUI

struct MyBookingsView: View {
    @StateObject private var bookingManager = BookingManager.shared
    @StateObject private var authManager = AuthManager.shared

    var pendingBookings: [OnlineBooking] {
        bookingManager.myBookings.filter { $0.status == .pending || $0.status == .confirmed }
    }

    var pastBookings: [OnlineBooking] {
        bookingManager.myBookings.filter { $0.status == .completed || $0.status == .cancelled }
    }

    var body: some View {
        NavigationView {
            Group {
                if bookingManager.isLoading {
                    ProgressView("載入預約記錄...")
                } else if bookingManager.myBookings.isEmpty {
                    ContentUnavailableView {
                        Label("尚無線上預約", systemImage: "calendar.badge.clock")
                    } description: {
                        Text("去「探索」頁面找合作店家預約吧！")
                    }
                } else {
                    List {
                        if !pendingBookings.isEmpty {
                            Section("即將到來") {
                                ForEach(pendingBookings) { booking in
                                    BookingCard(booking: booking)
                                }
                            }
                        }
                        if !pastBookings.isEmpty {
                            Section("歷史記錄") {
                                ForEach(pastBookings) { booking in
                                    BookingCard(booking: booking)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("我的預約")
            .onAppear {
                if let userID = authManager.currentUser?.id {
                    bookingManager.fetchMyBookings(consumerID: userID)
                }
            }
        }
    }
}

// MARK: - 預約卡片

struct BookingCard: View {
    let booking: OnlineBooking

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.shopName)
                        .font(.headline).fontWeight(.bold)
                    Text(booking.serviceName)
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                // 狀態標籤
                HStack(spacing: 4) {
                    Image(systemName: booking.status.icon)
                    Text(booking.status.displayText)
                }
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(Color(hex: booking.status.color))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color(hex: booking.status.color).opacity(0.12))
                .cornerRadius(8)
            }

            HStack(spacing: 16) {
                Label(booking.date.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "clock.fill")
                    .font(.caption).foregroundColor(.secondary)

                Label("$\(Int(booking.servicePrice))",
                      systemImage: "dollarsign.circle.fill")
                    .font(.caption).foregroundColor(.indigo)
            }

            if let note = booking.note, !note.isEmpty {
                Text("備註：\(note)")
                    .font(.caption).foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
