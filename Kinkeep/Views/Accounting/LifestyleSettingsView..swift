//
//  LifestyleSettingsView..swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//
import SwiftUI
import Foundation
import EventKit
import UserNotifications
import PhotosUI
import UIKit
import CoreImage.CIFilterBuiltins
import Charts
internal import Combine

// 設定頁面 (LifestyleSettingsView) - 保持不變，略
import Charts
struct LifestyleSettingsView: View {
    @EnvironmentObject var vm: AppViewModel

    @EnvironmentObject var lifestyleManager: LifestyleManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("選擇您的生活型態")) {
                    ForEach(LifestyleTag.allCases) { tag in
                        Toggle(isOn: binding(for: tag)) {
                            HStack {
                                Image(systemName: tag.icon).foregroundColor(tag.color).frame(width: 30)
                                VStack(alignment: .leading) { Text(tag.rawValue).font(.headline); Text(description(for: tag)).font(.caption).foregroundStyle(.secondary) }
                            }
                        }.toggleStyle(SwitchToggleStyle(tint: tag.color))
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("設定").toolbar { ToolbarItem(placement: .cancellationAction) { Button("完成") { dismiss() } } }
        }
    }
    private func binding(for tag: LifestyleTag) -> Binding<Bool> {
        Binding(get: { lifestyleManager.selectedTags.contains(tag) }, set: { if $0 { lifestyleManager.selectedTags.insert(tag) } else { lifestyleManager.selectedTags.remove(tag) } })
    }
    private func description(for tag: LifestyleTag) -> String {
        switch tag { case .diningOut: return "細分餐別"; case .beauty: return "新增化妝品等"; case .parent: return "新增育兒"; case .pet: return "新增寵物"; }
    }
}
