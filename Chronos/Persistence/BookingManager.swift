//
//  BookingManager.swift
//  KinKeep
//
//  處理預約資料的 Firebase 讀寫
//

import Foundation
import FirebaseFirestore

class BookingManager: ObservableObject {
    static let shared = BookingManager()

    private let db = Firestore.firestore()

    @Published var myBookings: [OnlineBooking] = []       // 消費者的預約
    @Published var shopBookings: [OnlineBooking] = []     // 店家收到的預約
    @Published var isLoading = false

    // MARK: - 消費者送出預約

    func createBooking(_ booking: OnlineBooking, completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "consumerID":       booking.consumerID,
            "consumerName":     booking.consumerName,
            "consumerPhone":    booking.consumerPhone ?? "",
            "shopID":           booking.shopID,
            "shopName":         booking.shopName,
            "serviceName":      booking.serviceName,
            "servicePrice":     booking.servicePrice,
            "serviceDuration":  booking.serviceDuration,
            "date":             Timestamp(date: booking.date),
            "status":           booking.status.rawValue,
            "note":             booking.note ?? "",
            "createdAt":        Timestamp(date: booking.createdAt)
        ]

        db.collection("bookings").document(booking.id).setData(data) { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }

    // MARK: - 消費者：讀取自己的預約

    func fetchMyBookings(consumerID: String) {
        isLoading = true
        db.collection("bookings")
            .whereField("consumerID", isEqualTo: consumerID)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.myBookings = snapshot?.documents.compactMap {
                        Self.parseBooking(from: $0)
                    } ?? []
                }
            }
    }

    // MARK: - 店家：讀取收到的預約（即時監聽）

    func fetchShopBookings(shopID: String) {
        isLoading = true
        db.collection("bookings")
            .whereField("shopID", isEqualTo: shopID)
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, _ in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.shopBookings = snapshot?.documents.compactMap {
                        Self.parseBooking(from: $0)
                    } ?? []
                }
            }
    }

    // MARK: - 店家：更新預約狀態

    func updateBookingStatus(_ bookingID: String, status: BookingStatus, completion: @escaping (Bool) -> Void) {
        db.collection("bookings").document(bookingID).updateData([
            "status": status.rawValue
        ]) { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }

    // MARK: - 解析 Firestore 文件

    private static func parseBooking(from doc: QueryDocumentSnapshot) -> OnlineBooking? {
        let data = doc.data()

        guard
            let consumerID      = data["consumerID"]      as? String,
            let consumerName    = data["consumerName"]     as? String,
            let shopID          = data["shopID"]           as? String,
            let shopName        = data["shopName"]         as? String,
            let serviceName     = data["serviceName"]      as? String,
            let servicePrice    = data["servicePrice"]     as? Double,
            let serviceDuration = data["serviceDuration"]  as? Int,
            let dateTimestamp   = data["date"]             as? Timestamp,
            let statusRaw       = data["status"]           as? String,
            let status          = BookingStatus(rawValue: statusRaw)
        else { return nil }

        var booking = OnlineBooking(
            consumerID: consumerID,
            consumerName: consumerName,
            consumerPhone: data["consumerPhone"] as? String,
            shopID: shopID,
            shopName: shopName,
            serviceName: serviceName,
            servicePrice: servicePrice,
            serviceDuration: serviceDuration,
            date: dateTimestamp.dateValue(),
            note: data["note"] as? String
        )
        booking.id = doc.documentID
        booking.status = status

        if let createdTimestamp = data["createdAt"] as? Timestamp {
            booking.createdAt = createdTimestamp.dateValue()
        }
        return booking
    }
}
