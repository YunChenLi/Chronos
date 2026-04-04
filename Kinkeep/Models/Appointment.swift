//
//  Appointment.swift
//  KinKeep
//
//  Created by 李芸禎 on 2026/2/1.
//


import Foundation

struct Appointment: Identifiable, Codable {
    var id = UUID()
    var name: String
    var date: Date
    var service: String
    var email: String
    var phone: String
    var amount: Double
    var photoDescription: String
    var photoData: Data
    var extraServiceDetail: String

    var isPhotoAttached: Bool { return photoData != nil }
}
