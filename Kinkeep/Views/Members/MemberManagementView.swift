//
//  MemberManagementView.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//
import SwiftUI
internal import Combine
import Foundation
import UserNotifications
import EventKit
import PhotosUI
import UIKit
import CoreImage.CIFilterBuiltins
import Charts

struct MemberManagementView: View {
    @Binding var members: [Member]
    var saveAction: () -> Void
    @State private var newName = ""
    @State private var selectedRole: MemberRole = .other
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("新增成員")) {
                    TextField("輸入姓名", text: $newName)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MemberRole.allCases) { role in
                                Button { selectedRole = role } label: {
                                    VStack(spacing: 4) { Text(role.icon).font(.largeTitle); Text(role.rawValue).font(.caption2).fontWeight(.bold) }
                                    .padding(8).background(selectedRole == role ? role.color.opacity(0.15) : Color.gray.opacity(0.05))
                                    .cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10).stroke(selectedRole == role ? role.color : Color.clear, lineWidth: 2))
                                }.foregroundColor(.primary)
                            }
                        }.padding(.vertical, 5)
                    }
                    Button { if !newName.isEmpty { members.append(Member(name: newName, role: selectedRole)); members.sort { $0.name < $1.name }; saveAction(); newName = ""; selectedRole = .other } } label: { HStack { Spacer(); Text("新增成員").fontWeight(.bold); Spacer() } }.buttonStyle(.borderedProminent).disabled(newName.isEmpty).padding(.top, 5)
                }
                Section(header: Text("家庭成員列表")) {
                    ForEach(members) { member in
                        HStack(spacing: 15) { ZStack { Circle().fill(member.role.color.opacity(0.2)).frame(width: 40, height: 40); Text(member.role.icon).font(.title2) }; VStack(alignment: .leading) { Text(member.name).font(.headline); Text(member.role.rawValue).font(.caption).foregroundColor(.secondary) } }.padding(.vertical, 4)
                    }.onDelete { idx in members.remove(atOffsets: idx); saveAction() }
                }
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("成員管理")
        }
    }
}

