//
//  AppointmentRow.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//
//AppointmentRow.swift: 單個預約卡片 UI
import SwiftUI
internal import Combine
import Foundation
import UserNotifications
import EventKit
import PhotosUI
import UIKit
import CoreImage.CIFilterBuiltins
import Charts

struct AppointmentRow: View {
    let appointment: Appointment
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(appointment.name).font(.headline).foregroundColor(.primary)
                Spacer()
                Text(appointment.service).font(.caption).padding(5)
                    .background(Color.indigo.opacity(0.1)).foregroundColor(.indigo).cornerRadius(6)
            }
            HStack {
                Image(systemName: "clock")
                Text(appointment.date, style: .date)
                Text(appointment.date, style: .time)
            }
            .font(.caption).foregroundColor(.secondary)
            HStack {
                if let amount = appointment.amount {
                    Text("$\(Int(amount))").font(.subheadline).fontWeight(.bold).foregroundColor(.red)
                }
                Spacer()
                if appointment.isPhotoAttached {
                    Image(systemName: "photo.fill").foregroundColor(.orange).font(.caption)
                    Text("有照片").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
