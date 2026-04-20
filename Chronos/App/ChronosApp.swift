//
//  ChronosApp.swift
//  KinKeep
//

internal import SwiftUI
import FirebaseCore

@main
struct AppointmentSystemApp: App {
    init() {
        // 初始化 Firebase（必須在 App 啟動時執行）
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

