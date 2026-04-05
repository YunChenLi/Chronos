//
//  LifestyleSettingsView.swift
//  KinKeep
//

internal import SwiftUI

struct LifestyleSettingsView: View {
    @StateObject private var lifestyleManager = LifestyleManager.shared

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("根據你的生活型態，自動調整支出類別與子類別。")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("例如：勾選「外食族」後，「食」類別會細分為早餐、午餐、晚餐等。")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("選擇你的生活型態（可複選）") {
                ForEach(LifestyleTag.allCases) { tag in
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(tag.color.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: tag.icon)
                                .foregroundColor(tag.color)
                                .font(.title3)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tag.rawValue).fontWeight(.medium)
                            Text(tagDescription(tag)).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: lifestyleManager.selectedTags.contains(tag)
                              ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(lifestyleManager.selectedTags.contains(tag) ? tag.color : .gray)
                            .font(.title3)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if lifestyleManager.selectedTags.contains(tag) {
                            lifestyleManager.selectedTags.remove(tag)
                        } else {
                            lifestyleManager.selectedTags.insert(tag)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("目前支出主類別預覽") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(lifestyleManager.mainCategories, id: \.self) { cat in
                            Text(cat)
                                .font(.caption).fontWeight(.medium)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.indigo.opacity(0.1))
                                .foregroundColor(.indigo).cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }
        }
        .navigationTitle("生活型態設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tagDescription(_ tag: LifestyleTag) -> String {
        switch tag {
        case .diningOut: return "細分早、午、晚餐等飲食類別"
        case .beauty:    return "新增化妝品、保養品等購物類別"
        case .parent:    return "新增奶粉、尿布、玩具等育兒類別"
        case .pet:       return "新增飼料、寵物醫療等寵物類別"
        }
    }
}
