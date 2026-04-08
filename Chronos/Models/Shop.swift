//
//  Shop.swift
//  KinKeep
//
//  合作店家資料模型
//

import Foundation
import CoreLocation

/// 合作店家
struct Shop: Identifiable, Codable {
    var id = UUID()
    var name: String
    var category: ShopCategory
    var address: String
    var phone: String?
    var latitude: Double
    var longitude: Double
    var rating: Double          // 1.0 - 5.0
    var reviewCount: Int
    var openingHours: String    // 如 "10:00 - 21:00"
    var services: [ShopService]
    var imageSystemIcon: String // 暫用 SF Symbol，之後換真實圖片
    var isPartner: Bool = true  // 是否為認證合作店家

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// 店家類別
enum ShopCategory: String, Codable, CaseIterable, Identifiable {
    case hairSalon   = "💇 美髮"
    case spa         = "💆 SPA"
    case nail        = "💅 美甲"
    case clinic      = "🏥 診所"
    case fitness     = "💪 健身"
    case restaurant  = "🍽 餐廳"
    case other       = "📋 其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hairSalon:  return "scissors"
        case .spa:        return "wind"
        case .nail:       return "hand.raised.fill"
        case .clinic:     return "cross.case.fill"
        case .fitness:    return "figure.run"
        case .restaurant: return "fork.knife"
        case .other:      return "ellipsis.circle"
        }
    }

    var color: String {
        switch self {
        case .hairSalon:  return "#5C5CFF"
        case .spa:        return "#AF52DE"
        case .nail:       return "#FF2D55"
        case .clinic:     return "#34C759"
        case .fitness:    return "#FF9500"
        case .restaurant: return "#FF6B35"
        case .other:      return "#8E8E93"
        }
    }
}

/// 店家服務項目（含價格）
struct ShopService: Identifiable, Codable {
    var id = UUID()
    var name: String
    var duration: Int    // 分鐘
    var price: Double
    var description: String?
}

// MARK: - 內建合作店家資料庫

struct ShopDatabase {
    static let shops: [Shop] = [
        Shop(
            name: "質感美髮工作室",
            category: .hairSalon,
            address: "台北市大安區忠孝東路四段 123 號",
            phone: "02-2777-8888",
            latitude: 25.0418, longitude: 121.5646,
            rating: 4.8, reviewCount: 234,
            openingHours: "10:00 - 21:00",
            services: [
                ShopService(name: "💇 剪髮", duration: 60, price: 800, description: "含洗髮、吹整"),
                ShopService(name: "🎨 染髮", duration: 120, price: 2500, description: "全頭染，含護髮"),
                ShopService(name: "✨ 燙髮", duration: 180, price: 3000, description: "數位燙或離子燙"),
            ],
            imageSystemIcon: "scissors"
        ),
        Shop(
            name: "悠活 SPA 會館",
            category: .spa,
            address: "台北市信義區松仁路 58 號",
            phone: "02-8101-2345",
            latitude: 25.0330, longitude: 121.5654,
            rating: 4.9, reviewCount: 187,
            openingHours: "11:00 - 22:00",
            services: [
                ShopService(name: "💆 全身按摩", duration: 60, price: 1800),
                ShopService(name: "🌿 精油護理", duration: 90, price: 2500),
                ShopService(name: "💎 臉部護理", duration: 75, price: 2000),
            ],
            imageSystemIcon: "wind"
        ),
        Shop(
            name: "nail+ 美甲沙龍",
            category: .nail,
            address: "台北市中山區南京西路 45 號",
            phone: "02-2567-9900",
            latitude: 25.0525, longitude: 121.5229,
            rating: 4.7, reviewCount: 312,
            openingHours: "10:30 - 21:30",
            services: [
                ShopService(name: "💅 基礎美甲", duration: 60, price: 600),
                ShopService(name: "✨ 光療延甲", duration: 90, price: 1200),
                ShopService(name: "🎨 手繪彩甲", duration: 120, price: 1800),
            ],
            imageSystemIcon: "hand.raised.fill"
        ),
        Shop(
            name: "A&M 美甲沙龍",
            category: .nail,
            address: "桃園市中壢區高鐵站前西路二段99號",
            phone: "03-2873939",
            latitude: 25.00726, longitude: 121.22051,
            rating: 5, reviewCount: 136,
            openingHours: "10:00 - 22:00",
            services: [
                ShopService(name: "💅 基礎美甲", duration: 60, price: 600),
                ShopService(name: "✨ 光療延甲", duration: 90, price: 1200),
                ShopService(name: "🎨 手繪彩甲", duration: 120, price: 1800),
            ],
            imageSystemIcon: "hand.raised.fill"
        ),
        Shop(
            name: "康健家庭診所",
            category: .clinic,
            address: "台北市松山區八德路三段 200 號",
            phone: "02-2762-1234",
            latitude: 25.0491, longitude: 121.5601,
            rating: 4.6, reviewCount: 98,
            openingHours: "09:00 - 18:00",
            services: [
                ShopService(name: "🩺 一般門診", duration: 30, price: 300),
                ShopService(name: "💉 疫苗接種", duration: 20, price: 500),
                ShopService(name: "🔬 健康檢查", duration: 60, price: 2000),
            ],
            imageSystemIcon: "cross.case.fill"
        ),
        Shop(
            name: "FitLife 健身中心",
            category: .fitness,
            address: "台北市內湖區瑞光路 513 號",
            phone: "02-8791-5566",
            latitude: 25.0797, longitude: 121.5780,
            rating: 4.5, reviewCount: 156,
            openingHours: "06:00 - 23:00",
            services: [
                ShopService(name: "💪 私人教練課", duration: 60, price: 1500),
                ShopService(name: "🧘 瑜珈課程", duration: 60, price: 500),
                ShopService(name: "🏊 游泳課", duration: 45, price: 600),
            ],
            imageSystemIcon: "figure.run"
        ),
        Shop(
            name: "原燒日式燒肉",
            category: .restaurant,
            address: "台北市大安區復興南路一段 107 號",
            phone: "02-2771-0099",
            latitude: 25.0409, longitude: 121.5435,
            rating: 4.7, reviewCount: 521,
            openingHours: "11:30 - 22:00",
            services: [
                ShopService(name: "🍖 雙人套餐", duration: 90, price: 1600),
                ShopService(name: "🥩 四人套餐", duration: 90, price: 2800),
                ShopService(name: "🎉 包廂預約", duration: 120, price: 5000),
            ],
            imageSystemIcon: "fork.knife"
        ),
    ]
}
