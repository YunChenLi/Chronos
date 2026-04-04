//
//  AppointmentListView.swift
//  Chronos
//

import SwiftUI

/// 預約列表的單元格視圖
struct AppointmentRow: View {
    let appointment: Appointment
    let members: [Member]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                let memberColor = members.first(where: { $0.name == appointment.name })?.colorHex ?? "#000000"
                Circle()
                    .fill(Color(hex: memberColor))
                    .frame(width: 10, height: 10)
                    .padding(.trailing, 4)

                Text(appointment.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                Text(appointment.service)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.15))
                    .foregroundColor(.indigo)
                    .cornerRadius(8)
            }

            if let detail = appointment.extraServiceDetail, !detail.isEmpty {
                Text("附註: \(detail)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text(appointment.date, style: .date)
                Text("@")
                Text(appointment.date, style: .time)
            }
            .font(.footnote)
            .foregroundColor(.secondary)

            if let amount = appointment.amount {
                Text("金額: $\(amount, specifier: "%.0f") (預約支出)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            if let desc = appointment.photoDescription, !desc.isEmpty || appointment.isPhotoAttached {
                HStack(spacing: 4) {
                    Image(systemName: appointment.isPhotoAttached ? "photo.fill" : "camera.fill")
                        .foregroundColor(.orange)
                    Text(appointment.isPhotoAttached ? "已附加照片" : "已記錄文字備註")
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

/// 預約列表視圖 (Tab 1)
struct AppointmentListView: View {
    @Binding var appointments: [Appointment]
    let members: [Member]
    var saveAction: () -> Void
    var deleteAction: (IndexSet) -> Void

    @State private var isShowingAddAppointment = false

    private func binding(for appointment: Appointment) -> Binding<Appointment>? {
        guard let index = appointments.firstIndex(where: { $0.id == appointment.id }) else {
            return nil
        }
        return Binding(
            get: { self.appointments[index] },
            set: { self.appointments[index] = $0 }
        )
    }

    var body: some View {
        NavigationView {
            VStack {
                if appointments.isEmpty {
                    Spacer()
                    ContentUnavailableView {
                        Label("目前沒有預約", systemImage: "calendar.badge.plus")
                    } description: {
                        Text("點擊右上角的「+」新增一個預約。")
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(appointments.sorted(by: { $0.date < $1.date })) { appointment in
                            if let appointmentBinding = binding(for: appointment) {
                                NavigationLink(destination: EditAppointmentView(
                                    appointment: appointmentBinding,
                                    saveAction: saveAction
                                )) {
                                    AppointmentRow(appointment: appointment, members: members)
                                }
                            }
                        }
                        .onDelete(perform: deleteAction)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("預約列表")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !appointments.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddAppointment = true
                    } label: {
                        Label("新增預約", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddAppointment) {
                AddAppointmentView(
                    appointments: $appointments,
                    members: members,
                    saveAction: saveAction
                )
            }
        }
    }
}
