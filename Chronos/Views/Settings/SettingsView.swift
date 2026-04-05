//
//  SettingsView.swift
//  KinKeep
//
//  整合所有設定的入口頁面
//

internal import SwiftUI

struct SettingsView: View {
    @StateObject private var lifestyleManager = LifestyleManager.shared

    var body: some View {
        NavigationView {
            List {
                // MARK: 生活型態
                Section("個人化") {
                    NavigationLink(destination: LifestyleSettingsView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.indigo.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .foregroundColor(.indigo)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("生活型態設定")
                                    .fontWeight(.medium)
                                // 顯示已選標籤
                                if lifestyleManager.selectedTags.isEmpty {
                                    Text("尚未選擇").font(.caption).foregroundColor(.secondary)
                                } else {
                                    Text(lifestyleManager.selectedTags.map { $0.rawValue }.joined(separator: "・"))
                                        .font(.caption).foregroundColor(.indigo)
                                }
                            }
                        }
                    }

                    NavigationLink(destination: CategorySettingsView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.orange)
                            }
                            Text("自訂類別管理")
                                .fontWeight(.medium)
                        }
                    }
                }

                // MARK: 版本資訊
                Section("關於") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("開發者")
                        Spacer()
                        Text("KinKeep Team").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}
