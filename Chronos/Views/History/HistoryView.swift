//
//  HistoryView.swift
//  Chronos
//

internal import SwiftUI

/// 預約歷史記錄視圖 (Tab 2)
struct HistoryView: View {
    let appointments: [Appointment]

    var groupedAppointments: [String: [Appointment]] {
        Dictionary(grouping: appointments.sorted(by: { $0.date > $1.date })) { appointment in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年 MM月"
            return formatter.string(from: appointment.date)
        }
    }

    var sortedKeys: [String] {
        groupedAppointments.keys.sorted(by: >)
    }

    var body: some View {
        NavigationView {
            List {
                if appointments.isEmpty {
                    ContentUnavailableView {
                        Label("無歷史記錄", systemImage: "clock.badge.xmark")
                    } description: {
                        Text("新增預約後，記錄將在此處按月份分類顯示。")
                    }
                } else {
                    ForEach(sortedKeys, id: \.self) { month in
                        Section(header: Text(month).font(.headline).foregroundColor(.indigo)) {
                            ForEach(groupedAppointments[month]!) { appointment in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(appointment.name).fontWeight(.semibold)
                                        Spacer()
                                        Text(appointment.service)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 8)
                                            .background(Color.indigo.opacity(0.1))
                                            .cornerRadius(5)
                                    }

                                    if let detail = appointment.extraServiceDetail, !detail.isEmpty {
                                        Text("附註: \(detail)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    HStack {
                                        Text(appointment.date, style: .time).font(.subheadline)

                                        if let amount = appointment.amount {
                                            Text("|").foregroundColor(.secondary)
                                            Text("預約支出: $\(amount, specifier: "%.0f")")
                                                .foregroundColor(.red)
                                                .fontWeight(.medium)
                                        }

                                        if appointment.isPhotoAttached {
                                            Text("|").foregroundColor(.secondary)
                                            Image(systemName: "photo.fill").foregroundColor(.orange)
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("預約歷史記錄")
        }
    }
}
