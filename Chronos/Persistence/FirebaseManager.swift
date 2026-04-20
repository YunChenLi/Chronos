//
//  FirebaseManager.swift
//  KinKeep
//
//  負責從 Firebase Firestore 讀取合作店家資料
//

import Foundation
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    private let db = Firestore.firestore()

    @Published var shops: [Shop] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // MARK: - 從 Firestore 讀取所有店家

    func fetchShops() {
        isLoading = true
        errorMessage = nil

        db.collection("shops").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "讀取失敗：\(error.localizedDescription)"
                    self?.shops = ShopDatabase.shops
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    self?.shops = ShopDatabase.shops
                    return
                }

                self?.shops = documents.compactMap { doc in
                    Self.parseShop(from: doc)
                }
            }
        }
    }

    // MARK: - 解析 Firestore 文件為 Shop

    private static func parseShop(from doc: QueryDocumentSnapshot) -> Shop? {
        let data = doc.data()

        guard
            let name         = data["name"]            as? String,
            let categoryRaw  = data["category"]         as? String,
            let category     = ShopCategory(rawValue: categoryRaw),
            let address      = data["address"]          as? String,
            let latitude     = data["latitude"]         as? Double,
            let longitude    = data["longitude"]        as? Double,
            let rating       = data["rating"]           as? Double,
            let openingHours = data["openingHours"]     as? String,
            let icon         = data["imageSystemIcon"]  as? String
        else { return nil }

        // reviewCount 容許 int64 或 double 都能讀
        let reviewCount: Int
        if let rc = data["reviewCount"] as? Int {
            reviewCount = rc
        } else if let rc = data["reviewCount"] as? Double {
            reviewCount = Int(rc)
        } else {
            reviewCount = 0
        }

        // 解析服務項目
        let rawServices = data["services"] as? [[String: Any]] ?? []
        let services: [ShopService] = rawServices.compactMap { s in
            guard let sName = s["name"] as? String else { return nil }
            let duration: Int
            if let d = s["duration"] as? Int { duration = d }
            else if let d = s["duration"] as? Double { duration = Int(d) }
            else { duration = 60 }

            let price: Double
            if let p = s["price"] as? Double { price = p }
            else if let p = s["price"] as? Int { price = Double(p) }
            else { price = 0 }

            return ShopService(
                name: sName,
                duration: duration,
                price: price,
                description: s["description"] as? String
            )
        }

        return Shop(
            id: UUID(),
            name: name,
            category: category,
            address: address,
            phone: data["phone"] as? String,
            latitude: latitude,
            longitude: longitude,
            rating: rating,
            reviewCount: reviewCount,
            openingHours: openingHours,
            services: services,
            imageSystemIcon: icon,
            isPartner: data["isPartner"] as? Bool ?? true
        )
    }
}
