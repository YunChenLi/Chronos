//
//  AuthManager.swift
//  KinKeep
//
//  處理 Firebase Authentication 登入、登出、註冊
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
internal import Combine

class AuthManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    static let shared = AuthManager()

    @Published var currentUser: AppUser? = nil
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        // 監聽登入狀態變化（延後到下一個 runloop，避免在初始化期間觸發發布）
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
                if let firebaseUser = firebaseUser {
                    self?.fetchUserData(uid: firebaseUser.uid)
                } else {
                    DispatchQueue.main.async {
                        self?.currentUser = nil
                        self?.isLoggedIn = false
                    }
                }
            }
        }
    }

    // MARK: - 電子郵件註冊

    func signUp(name: String, email: String, password: String, phone: String) {
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = self?.friendlyError(error) ?? error.localizedDescription
                }
                return
            }

            guard let uid = result?.user.uid else { return }

            // 建立用戶資料到 Firestore
            let newUser = AppUser(id: uid, name: name, email: email, phone: phone)
            self?.saveUserToFirestore(newUser)
        }
    }

    // MARK: - 電子郵件登入

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = self?.friendlyError(error) ?? error.localizedDescription
                }
            }
        }
    }

    // MARK: - 登出

    func signOut() {
        try? Auth.auth().signOut()
    }

    // MARK: - 取得用戶資料

    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let data = snapshot?.data() {
                    // 從 Firestore 解析用戶資料
                    let roleRaw = data["role"] as? String ?? "consumer"
                    let user = AppUser(
                        id: uid,
                        name: data["name"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        phone: data["phone"] as? String,
                        role: UserRole(rawValue: roleRaw) ?? .consumer,
                        shopID: data["shopID"] as? String
                    )
                    self?.currentUser = user
                    self?.isLoggedIn = true
                } else {
                    // 用戶資料不存在（第一次 Google 登入等情況）
                    if let firebaseUser = Auth.auth().currentUser {
                        let newUser = AppUser(
                            id: uid,
                            name: firebaseUser.displayName ?? "用戶",
                            email: firebaseUser.email ?? ""
                        )
                        self?.saveUserToFirestore(newUser)
                    }
                }
            }
        }
    }

    // MARK: - 儲存用戶至 Firestore

    private func saveUserToFirestore(_ user: AppUser) {
        var data: [String: Any] = [
            "name": user.name,
            "email": user.email,
            "role": user.role.rawValue,
            "createdAt": Timestamp(date: user.createdAt)
        ]
        if let phone = user.phone { data["phone"] = phone }
        if let shopID = user.shopID { data["shopID"] = shopID }

        db.collection("users").document(user.id).setData(data) { [weak self] error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.currentUser = user
                    self?.isLoggedIn = true
                } else {
                    self?.errorMessage = "用戶資料儲存失敗，請重試"
                }
            }
        }
    }

    // MARK: - 友善錯誤訊息（中文）

    private func friendlyError(_ error: Error) -> String {
        let code = AuthErrorCode(_bridgedNSError: error as NSError)
        switch code?.code {
        case .emailAlreadyInUse:    return "此電子郵件已被註冊"
        case .invalidEmail:         return "電子郵件格式不正確"
        case .weakPassword:         return "密碼至少需要 6 個字元"
        case .wrongPassword:        return "密碼錯誤，請重試"
        case .userNotFound:         return "找不到此帳號，請先註冊"
        case .networkError:         return "網路連線失敗，請檢查網路"
        default:                    return "發生錯誤，請重試"
        }
    }
}
