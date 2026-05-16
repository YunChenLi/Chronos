//
//  AuthManager.swift
//  KinKeep
//

import Foundation
internal import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: AppUser? = nil
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // 新增：判斷當前使用者是否為訪客
    var isGuestUser: Bool {
        return currentUser?.id == "GUEST_USER_ID"
    }

    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            print("🔥 Auth state changed: \(firebaseUser?.uid ?? "nil")")
            
            // 如果我們正在訪客模式，不要因為 firebaseUser 是 nil 就登出
            if self?.isGuestUser == true {
                print("👤 Currently in Guest Mode, ignoring Firebase auth nil state.")
                return
            }

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

    // MARK: - 訪客登入 (Guest Mode)

    func signInAsGuest() {
        print("🚀 signInAsGuest called")
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        // 模擬短暫的載入時間
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // 建立一個訪客用的 AppUser
            let guestUser = AppUser(
                id: "GUEST_USER_ID", // 特殊的 ID 用來辨識訪客
                name: "訪客",
                email: "guest@kinkeep.app",
                phone: nil,
                role: .consumer, // 或者您可以為 UserRole 新增一個 .guest
                shopID: nil
            )
            
            self?.currentUser = guestUser
            self?.isLoggedIn = true
            self?.isLoading = false
            print("✅ Entered Guest Mode successfully")
        }
    }

    // MARK: - 註冊

    func signUp(name: String, email: String, password: String, phone: String) {
        print("🚀 signUp called: \(email)")
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            print("📬 createUser callback received")

            if let error = error {
                print("❌ createUser error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            guard let uid = result?.user.uid else {
                print("❌ No UID returned")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "無法取得用戶 ID，請重試"
                }
                return
            }

            print("✅ User created: \(uid)")
            let newUser = AppUser(id: uid, name: name, email: email, phone: phone)
            self?.saveUserToFirestore(newUser)
        }
    }

    // MARK: - 登入

    func signIn(email: String, password: String) {
        print("🚀 signIn called: \(email)")
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            print("📬 signIn callback received")
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    print("❌ signIn error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                } else {
                    print("✅ signIn success: \(result?.user.uid ?? "nil")")
                    // signIn 成功後，Firebase 的 listener 會觸發 fetchUserData 並設定 isLoading = false
                }
            }
        }
    }

    // MARK: - 登出

    func signOut() {
        print("🚀 signOut called")
        // 如果是訪客，直接清除本地狀態即可
        if isGuestUser {
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isLoggedIn = false
            }
            return
        }

        // 如果是正式用戶，呼叫 Firebase 登出
        try? Auth.auth().signOut()
    }

    // MARK: - 讀取用戶資料

    private func fetchUserData(uid: String) {
        print("📖 fetchUserData: \(uid)")
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            print("📬 fetchUserData callback received")
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("❌ fetchUserData error: \(error.localizedDescription)")
                    self?.errorMessage = "讀取用戶資料失敗"
                    return
                }

                if let data = snapshot?.data() {
                    print("✅ User data found: \(data)")
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
                    print("⚠️ No user data, creating new...")
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
        print("💾 saveUserToFirestore: \(user.id)")
        var data: [String: Any] = [
            "name": user.name,
            "email": user.email,
            "role": user.role.rawValue,
            "createdAt": Timestamp(date: user.createdAt)
        ]
        if let phone = user.phone, !phone.isEmpty { data["phone"] = phone }
        if let shopID = user.shopID { data["shopID"] = shopID }

        db.collection("users").document(user.id).setData(data) { [weak self] error in
            print("📬 saveUserToFirestore callback received")
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ saveUser error: \(error.localizedDescription)")
                    self?.errorMessage = "用戶資料儲存失敗：\(error.localizedDescription)"
                    self?.isLoading = false
                } else {
                    print("✅ User saved successfully, setting isLoggedIn = true")
                    self?.currentUser = user
                    self?.isLoggedIn = true
                    self?.isLoading = false
                }
            }
        }
    }
}
