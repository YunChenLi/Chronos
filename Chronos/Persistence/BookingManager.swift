//
//  BookingManager.swift
//  KinKeep
//

import Foundation
internal import Combine
import FirebaseFirestore

class BookingManager: ObservableObject {
    static let shared = BookingManager()

    private let db = Firestore.firestore()

    @Published var myBookings: [OnlineBooking] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // MARK: - 消費者送出預約

    func createBooking(_ booking: OnlineBooking, completion: @escaping (Bool, String?) -> Void) {
        let data: [String: Any] = [
            "consumerID":       booking.consumerID,
            "consumerName":     booking.consumerName,
            "consumerPhone":    booking.consumerPhone ?? "",
            "shopID":           booking.shopID,
            "shopName":         booking.shopName,
            "shopAddress":      booking.shopAddress,
            "serviceName":      booking.serviceName,
            "servicePrice":     booking.servicePrice,
            "serviceDuration":  booking.serviceDuration,
            "date":             Timestamp(date: booking.date),
            "status":           BookingStatus.pending.rawValue,
            "note":             booking.note ?? "",
            "depositPaid":      booking.depositPaid,
            "depositAmount":    booking.depositAmount,
            "createdAt":        Timestamp(date: booking.createdAt)
        ]

        db.collection("bookings").document(booking.id).setData(data) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    // MARK: - 即時監聽消費者預約

    func listenMyBookings(consumerID: String) {
        isLoading = true
        db.collection("bookings")
            .whereField("consumerID", isEqualTo: consumerID)
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    let bookings = snapshot?.documents.compactMap {
                        Self.parseBooking(from: $0)
                    } ?? []
                    self?.myBookings = bookings
                    // 自動檢查放鳥
                    self?.checkNoShows(bookings: bookings, consumerID: consumerID)
                }
            }
    }

    // MARK: - 取消預約

    func cancelBooking(_ booking: OnlineBooking, reason: String,
                       completion: @escaping (Bool, String?) -> Void) {
        // 再次確認可否取消
        guard booking.canCancel else {
            completion(false, "預約需提前 24 小時取消，如需取消請直接聯絡店家。")
            return
        }

        let data: [String: Any] = [
            "status": BookingStatus.cancelled.rawValue,
            "cancelledAt": Timestamp(date: Date()),
            "cancelReason": reason
        ]

        db.collection("bookings").document(booking.id).updateData(data) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    // MARK: - 放鳥偵測（自動）

    private func checkNoShows(bookings: [OnlineBooking], consumerID: String) {
        let now = Date()
        // 找出已過時間但狀態仍是 confirmed 的預約
        let noShows = bookings.filter { booking in
            (booking.status == .confirmed || booking.status == .pending)
            && booking.date < now
            && now.timeIntervalSince(booking.date) > 3600 // 過了 1 小時還沒完成
        }

        for booking in noShows {
            markAsNoShow(bookingID: booking.id, consumerID: consumerID)
        }
    }

    private func markAsNoShow(bookingID: String, consumerID: String) {
        // 更新預約狀態為放鳥
        db.collection("bookings").document(bookingID).updateData([
            "status": BookingStatus.noShow.rawValue
        ])

        // 增加用戶放鳥次數
        let userRef = db.collection("users").document(consumerID)
        userRef.getDocument { snapshot, _ in
            let currentCount = snapshot?.data()?["noShowCount"] as? Int ?? 0
            let newCount = currentCount + 1
            var updateData: [String: Any] = ["noShowCount": newCount]

            // 放鳥 2 次以上需要訂金
            if newCount >= 2 {
                updateData["requiresDeposit"] = true
            }
            userRef.updateData(updateData)
        }
    }

    // MARK: - 查詢是否需要訂金

    func checkDepositRequired(consumerID: String,
                              completion: @escaping (Bool, Double) -> Void) {
        db.collection("users").document(consumerID).getDocument { snapshot, _ in
            let requiresDeposit = snapshot?.data()?["requiresDeposit"] as? Bool ?? false
            // 訂金為服務費的 30%（由呼叫端傳入服務金額計算）
            completion(requiresDeposit, 0)
        }
    }

    // MARK: - 解析 Firestore 文件

    static func parseBooking(from doc: QueryDocumentSnapshot) -> OnlineBooking? {
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
            shopAddress: data["shopAddress"] as? String ?? "",
            serviceName: serviceName,
            servicePrice: servicePrice,
            serviceDuration: serviceDuration,
            date: dateTimestamp.dateValue(),
            note: data["note"] as? String
        )
        booking.id = doc.documentID
        booking.status = status
        booking.depositPaid = data["depositPaid"] as? Bool ?? false
        booking.depositAmount = data["depositAmount"] as? Double ?? 0
        if let cancelledAt = data["cancelledAt"] as? Timestamp {
            booking.cancelledAt = cancelledAt.dateValue()
        }
        booking.cancelReason = data["cancelReason"] as? String
        if let createdTimestamp = data["createdAt"] as? Timestamp {
            booking.createdAt = createdTimestamp.dateValue()
        }
        return booking
    }
}

