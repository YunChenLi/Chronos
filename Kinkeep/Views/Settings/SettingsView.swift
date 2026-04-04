//
//  SettingsView.swift
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

// MARK: - 設定頁面 (Settings View)

struct SettingsView: View {
    @Binding var userProfile: UserProfile
    var saveAction: () -> Void
    
    @State private var showLoginAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("一般設定")) {
                    Picker("語言 / Language", selection: $userProfile.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                    .onChange(of: userProfile.language) { _, _ in saveAction() }
                }
                
                Section(header: Text("帳號登入")) {
                    if userProfile.isLoggedIn {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(
                                        userProfile.loginProvider == "Gmail" ? Color.red.opacity(0.1) :
                                        (userProfile.loginProvider == "Hotmail" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    )
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: userProfile.loginProvider == "Gmail" ? "g.circle.fill" : "envelope.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(
                                        userProfile.loginProvider == "Gmail" ? .red :
                                        (userProfile.loginProvider == "Hotmail" ? .blue : .gray)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userProfile.name.isEmpty ? "使用者" : userProfile.name)
                                    .font(.headline)
                                Text(userProfile.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("已透過 \(userProfile.loginProvider) 登入")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Button(role: .destructive) {
                            logout()
                        } label: {
                            HStack {
                                Spacer()
                                Text("登出帳號")
                                Spacer()
                            }
                        }
                        
                    } else {
                        Text("請選擇登入方式以同步資料並啟用進階功能。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .listRowSeparator(.hidden)
                        
                        Button {
                            performSimulatedLogin(provider: "Gmail", email: "user@gmail.com")
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill").foregroundColor(.red)
                                Text("使用 Google 帳號登入")
                                Spacer()
                            }
                        }
                        
                        Button {
                            performSimulatedLogin(provider: "Hotmail", email: "user@hotmail.com")
                        } label: {
                            HStack {
                                Image(systemName: "envelope.circle.fill").foregroundColor(.blue)
                                Text("使用 Hotmail 帳號登入")
                                Spacer()
                            }
                        }
                        
                        Button {
                            performSimulatedLogin(provider: "Apple", email: "user@icloud.com")
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("使用 Apple ID 登入")
                                Spacer()
                            }
                        }
                    }
                }
                
                if userProfile.isLoggedIn {
                    Section(header: Text("個人資料")) {
                        HStack {
                            Text("暱稱")
                            Spacer()
                            TextField("請輸入暱稱", text: $userProfile.name)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: userProfile.name) { _, _ in saveAction() }
                        }
                        
                        DatePicker("生日", selection: $userProfile.birthday, displayedComponents: .date)
                            .onChange(of: userProfile.birthday) { _, _ in saveAction() }
                        
                        HStack {
                            Text("年齡")
                            Spacer()
                            Text("\(userProfile.age) 歲")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("關於 App")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.3.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("開發者")
                        Spacer()
                        Text("Chronos")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden) // 隱藏預設背景
            .background(Color.themeBackground) // 應用自訂背景色
            .navigationTitle("設定")
            .alert("登入成功", isPresented: $showLoginAlert) {
                Button("確定") { }
            } message: {
                Text("歡迎回來，\(userProfile.email)")
            }
        }
    }
    
    func performSimulatedLogin(provider: String, email: String) {
        userProfile.isLoggedIn = true
        userProfile.loginProvider = provider
        userProfile.email = email
        if userProfile.name.isEmpty {
            userProfile.name = "新使用者"
        }
        saveAction()
        showLoginAlert = true
    }
    
    func logout() {
        withAnimation {
            userProfile.isLoggedIn = false
            userProfile.loginProvider = ""
            userProfile.email = ""
            userProfile.name = ""
            saveAction()
        }
    }
}


