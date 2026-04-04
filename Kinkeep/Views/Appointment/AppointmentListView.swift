//
//  AppointmentListView.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//
//AppointmentListView.swift: 預約清單主頁面

// MARK: - 預約列表 (Appointment List)
import SwiftUI

struct AppointmentListView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var isShowingAdd = false

    var body: some View {
        NavigationView {
            Group {
                if vm.appointments.isEmpty {
                    ContentUnavailableView("目前沒有預約",
                        systemImage: "calendar.badge.plus",
                        description: Text("點擊右上角「+」新增預約"))
                        .background(Color.themeBackground)
                } else {
                    List {
                        // 注意：資料現在來自 vm.appointments
                        ForEach(vm.appointments.sorted(by: { $0.date < $1.date })) { appointment in
                            NavigationLink(destination: EditAppointmentView(appointment: appointment)) {
                                AppointmentRow(appointment: appointment)
                            }
                        }
                        .onDelete(perform: vm.deleteAppointments)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.themeBackground)
                }
            }
            .navigationTitle("預約列表")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !vm.appointments.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isShowingAdd = true } label: {
                        Label("新增", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $isShowingAdd) {
                AddAppointmentView() // 也不需要傳遞一堆 Binding 了
            }
        }
    }
}
