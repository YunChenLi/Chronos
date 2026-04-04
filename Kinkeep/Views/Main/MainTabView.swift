//
//  MainTabView.swift
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

   

//@main
//struct AppointmentAndExpenseApp: App {
 //   var body: some Scene {
 //       WindowGroup {
  //          ContentView()
  //          ContentView()
  //      }
 //   }
//}


import SwiftUI

struct MainTabView: View {
    // 透過 EnvironmentObject 取得全域資料
    @EnvironmentObject var vm: AppViewModel
    @EnvironmentObject var lifestyleManager: LifestyleManager

    var body: some View {
        TabView {
            AppointmentListView()
                .tabItem { Label("預約", systemImage: "list.bullet.clipboard") }

            CalendarExpenseView()
                .tabItem { Label("記帳", systemImage: "calendar") }

            IncomeExpenseReportView()
                .tabItem { Label("收支表", systemImage: "chart.pie.fill") }

            MemberManagementView()
                .tabItem { Label("成員", systemImage: "person.3.fill") }
            
            SettingsView()
                .tabItem { Label("設定", systemImage: "gear") }
        }
        .tint(.indigo)
        // 當 App 出現時，請求權限（原本在 ContentView 的邏輯）
        .onAppear(perform: vm.requestNotificationPermission)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppViewModel())
        .environmentObject(LifestyleManager())
}


@main
struct AppointmentAndExpenseApp: App {
    // 1. 初始化 ViewModel
    @StateObject private var vm = AppViewModel()
    @StateObject private var lifestyle = LifestyleManager()

    var body: some Scene {
        WindowGroup {
            // 2. 傳遞給第一個 View
            MainTabView()
                .environmentObject(vm)
                .environmentObject(lifestyle)
        }
    }
}
