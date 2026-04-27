//
//  AuthView.swift
//  KinKeep
//
//  登入 / 註冊介面
//

import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isShowingSignUp = false

    var body: some View {
        if isShowingSignUp {
            SignUpView(isShowingSignUp: $isShowingSignUp)
        } else {
            SignInView(isShowingSignUp: $isShowingSignUp)
        }
    }
}

// MARK: - 登入頁面

struct SignInView: View {
    @StateObject private var authManager = AuthManager.shared
    @Binding var isShowingSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false

    var isDisabled: Bool {
        email.isEmpty || password.isEmpty || authManager.isLoading
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {

                    // MARK: Logo
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        Text("KinKeep")
                            .font(.largeTitle).fontWeight(.bold)
                        Text("你的家庭預約管家")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // MARK: 輸入欄位
                    VStack(spacing: 16) {
                        AuthTextField(
                            title: "電子郵件",
                            placeholder: "請輸入電子郵件",
                            icon: "envelope.fill",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        AuthSecureField(
                            title: "密碼",
                            placeholder: "請輸入密碼",
                            text: $password,
                            isVisible: $isPasswordVisible
                        )
                    }
                    .padding(.horizontal)

                    // MARK: 錯誤訊息
                    if let error = authManager.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error).font(.caption).foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }

                    // MARK: 登入按鈕
                    VStack(spacing: 12) {
                        Button {
                            authManager.signIn(email: email, password: password)
                        } label: {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("登入")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(isDisabled ? Color.gray : Color.indigo)
                            .cornerRadius(12)
                        }
                        .disabled(isDisabled)
                        .padding(.horizontal)

                        // 分隔線
                        HStack {
                            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                            Text("或").font(.caption).foregroundColor(.secondary)
                            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                        }
                        .padding(.horizontal)

                        // 前往註冊
                        Button {
                            authManager.errorMessage = nil
                            isShowingSignUp = true
                        } label: {
                            HStack {
                                Text("還沒有帳號？")
                                    .foregroundColor(.secondary)
                                Text("立即註冊")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.indigo)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - 註冊頁面

struct SignUpView: View {
    @StateObject private var authManager = AuthManager.shared
    @Binding var isShowingSignUp: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false

    var passwordMatch: Bool { password == confirmPassword }

    var isDisabled: Bool {
        name.isEmpty || email.isEmpty || password.isEmpty
            || confirmPassword.isEmpty || !passwordMatch
            || authManager.isLoading
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: 標題
                    VStack(spacing: 8) {
                        Text("建立帳號").font(.largeTitle).fontWeight(.bold)
                        Text("開始使用 KinKeep").foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // MARK: 輸入欄位
                    VStack(spacing: 14) {
                        AuthTextField(
                            title: "姓名",
                            placeholder: "請輸入你的姓名",
                            icon: "person.fill",
                            text: $name
                        )
                        AuthTextField(
                            title: "電子郵件",
                            placeholder: "請輸入電子郵件",
                            icon: "envelope.fill",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        AuthTextField(
                            title: "手機號碼（選填）",
                            placeholder: "09XX-XXX-XXX",
                            icon: "phone.fill",
                            text: $phone,
                            keyboardType: .phonePad
                        )
                        AuthSecureField(
                            title: "密碼（至少 6 碼）",
                            placeholder: "請輸入密碼",
                            text: $password,
                            isVisible: $isPasswordVisible
                        )
                        AuthSecureField(
                            title: "確認密碼",
                            placeholder: "請再次輸入密碼",
                            text: $confirmPassword,
                            isVisible: $isPasswordVisible
                        )

                        if !confirmPassword.isEmpty && !passwordMatch {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("兩次密碼不相符").font(.caption).foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // MARK: 錯誤訊息
                    if let error = authManager.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                            Text(error).font(.caption).foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }

                    // MARK: 按鈕
                    VStack(spacing: 12) {
                        Button {
                            authManager.signUp(name: name, email: email,
                                               password: password, phone: phone)
                        } label: {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("建立帳號")
                                        .fontWeight(.semibold).foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(14)
                            .background(isDisabled ? Color.gray : Color.indigo)
                            .cornerRadius(12)
                        }
                        .disabled(isDisabled)
                        .padding(.horizontal)

                        Button {
                            authManager.errorMessage = nil
                            isShowingSignUp = false
                        } label: {
                            HStack {
                                Text("已有帳號？").foregroundColor(.secondary)
                                Text("返回登入").fontWeight(.semibold).foregroundColor(.indigo)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - 可重用輸入元件

struct AuthTextField: View {
    let title: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).fontWeight(.medium).foregroundColor(.secondary)
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(.indigo).frame(width: 20)
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct AuthSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).fontWeight(.medium).foregroundColor(.secondary)
            HStack(spacing: 10) {
                Image(systemName: "lock.fill").foregroundColor(.indigo).frame(width: 20)
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
