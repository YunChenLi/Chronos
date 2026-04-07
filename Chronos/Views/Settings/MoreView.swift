//
//  MoreView.swift
//  KinKeep
//
//  「更多」頁面：整合成員管理、預約歷史、設定
//

internal import SwiftUI

struct MoreView: View {
    @Binding var members: [Member]
    let appointments: [Appointment]
    var saveMembersAction: () -> Void

    var body: some View {
        NavigationView {
            List {
                // MARK: 成員管理
                Section {
                    NavigationLink(destination: MemberManagementView(
                        members: $members,
                        saveAction: saveMembersAction
                    )) {
                        MoreRow(
                            icon: "person.3.fill",
                            color: .indigo,
                            title: "成員管理",
                            subtitle: members.isEmpty ? "尚未新增成員" : "共 \(members.count) 位成員"
                        )
                    }
                }

                // MARK: 預約歷史
                Section {
                    NavigationLink(destination: HistoryView(appointments: appointments)) {
                        MoreRow(
                            icon: "clock.fill",
                            color: .teal,
                            title: "預約歷史",
                            subtitle: appointments.isEmpty ? "尚無記錄" : "共 \(appointments.count) 筆預約"
                        )
                    }
                }

                // MARK: 設定
                Section {
                    NavigationLink(destination: LifestyleSettingsView()) {
                        MoreRow(
                            icon: "person.crop.circle.badge.checkmark",
                            color: .purple,
                            title: "生活型態設定",
                            subtitle: "個人化支出類別"
                        )
                    }

                    NavigationLink(destination: CategorySettingsView()) {
                        MoreRow(
                            icon: "tag.fill",
                            color: .orange,
                            title: "自訂類別管理",
                            subtitle: "新增或刪除類別"
                        )
                    }
                } header: {
                    Text("設定")
                }

                // MARK: 關於
                Section("關於") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("更多")
        }
    }
}

// MARK: - 可重用列元件

struct MoreRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
