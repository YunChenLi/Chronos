//
//  MemberManagementView.swift
//  Chronos
//

import SwiftUI

/// 成員管理視圖 (Tab 5)
struct MemberManagementView: View {
    @Binding var members: [Member]
    var saveAction: () -> Void

    @State private var newMemberName: String = ""
    @State private var selectedColorHex: String = Color.memberHexes.first!

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section("新增家庭成員") {
                        HStack {
                            TextField("輸入成員姓名", text: $newMemberName)
                                .textInputAutocapitalization(.words)
                            Button {
                                addMember()
                            } label: {
                                Image(systemName: "plus.circle.fill").foregroundColor(.indigo)
                            }
                            .disabled(newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }

                    Section("選擇成員代表色") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Color.memberHexes, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            hex == selectedColorHex
                                                ? Circle().stroke(Color.primary, lineWidth: 2)
                                                : nil
                                        )
                                        .onTapGesture { selectedColorHex = hex }
                                }
                            }
                        }
                    }

                    Section("現有家庭成員列表") {
                        if members.isEmpty {
                            Text("目前沒有成員。").foregroundColor(.secondary)
                        } else {
                            List {
                                ForEach(members) { member in
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: member.colorHex))
                                            .frame(width: 15, height: 15)
                                        Text(member.name)
                                        Spacer()
                                    }
                                }
                                .onDelete(perform: deleteMembers)
                            }
                        }
                    }
                }
            }
            .navigationTitle("成員管理")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !members.isEmpty { EditButton() }
                }
            }
        }
    }

    func addMember() {
        let trimmedName = newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newMember = Member(name: trimmedName, colorHex: selectedColorHex)
        members.append(newMember)
        members.sort { $0.name < $1.name }
        saveAction()
        newMemberName = ""

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func deleteMembers(at offsets: IndexSet) {
        members.remove(atOffsets: offsets)
        saveAction()
    }
}
