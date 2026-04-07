//
//  ShopDetailView.swift
//  KinKeep
//
//  店家詳細頁面 + 預約入口
//

internal import SwiftUI
import MapKit

struct ShopDetailView: View {
    let shop: Shop
    @Binding var appointments: [Appointment]
    let members: [Member]
    var saveAction: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var selectedService: ShopService? = nil
    @State private var isShowingBooking = false
    @State private var mapPosition: MapCameraPosition = .automatic

    init(shop: Shop, appointments: Binding<[Appointment]>, members: [Member], saveAction: @escaping () -> Void) {
        self.shop = shop
        self._appointments = appointments
        self.members = members
        self.saveAction = saveAction
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: 頂部封面
                    shopHeader

                    // MARK: 基本資訊
                    shopInfo

                    Divider().padding(.horizontal)

                    // MARK: 服務項目
                    servicesSection

                    Divider().padding(.horizontal)

                    // MARK: 地圖位置
                    locationSection

                    // MARK: 底部預約按鈕間距
                    Spacer().frame(height: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(shop.name).fontWeight(.semibold)
                }
            }
            .overlay(alignment: .bottom) { bookingBar }
            .sheet(isPresented: $isShowingBooking) {
                if let service = selectedService {
                    ShopBookingView(
                        shop: shop,
                        service: service,
                        appointments: $appointments,
                        members: members,
                        saveAction: saveAction
                    )
                }
            }
        }
    }

    // MARK: - 頂部封面

    private var shopHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: shop.category.color).opacity(0.6),
                                 Color(hex: shop.category.color).opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(height: 180)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if shop.isPartner {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("認證合作店家")
                        }
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.indigo)
                        .cornerRadius(10)
                    }
                    Spacer()
                    Image(systemName: shop.imageSystemIcon)
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.trailing, 20)
                }

                Text(shop.name)
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text(shop.category.rawValue)
                    .font(.subheadline).foregroundColor(.white.opacity(0.85))
            }
            .padding(16)
        }
    }

    // MARK: - 基本資訊

    private var shopInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 評分
            HStack(spacing: 6) {
                ForEach(0..<5) { i in
                    Image(systemName: Double(i) < shop.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                Text(String(format: "%.1f", shop.rating)).fontWeight(.semibold)
                Text("(\(shop.reviewCount) 則評價)").foregroundColor(.secondary)
            }

            // 資訊列
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "mappin.circle.fill", color: .red, text: shop.address)
                InfoRow(icon: "clock.fill", color: .orange, text: "營業時間：\(shop.openingHours)")
                if let phone = shop.phone {
                    Button {
                        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        InfoRow(icon: "phone.fill", color: .green, text: phone)
                    }
                }
            }
        }
        .padding(16)
    }

    // MARK: - 服務項目

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("服務項目")
                .font(.headline).fontWeight(.bold)
                .padding(.horizontal, 16).padding(.top, 16)

            ForEach(shop.services) { service in
                ServiceRow(
                    service: service,
                    isSelected: selectedService?.id == service.id,
                    categoryColor: Color(hex: shop.category.color)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        selectedService = selectedService?.id == service.id ? nil : service
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - 地圖位置

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("店家位置")
                .font(.headline).fontWeight(.bold)
                .padding(.horizontal, 16).padding(.top, 16)

            Map(position: $mapPosition) {
                Marker(shop.name, systemImage: shop.category.icon, coordinate: shop.coordinate)
                    .tint(Color(hex: shop.category.color))
            }
            .frame(height: 160)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .onAppear {
                mapPosition = .region(MKCoordinateRegion(
                    center: shop.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))
            }

            // 導航按鈕
            Button {
                let url = URL(string: "maps://?q=\(shop.name)&ll=\(shop.latitude),\(shop.longitude)")!
                UIApplication.shared.open(url)
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    Text("在地圖中開啟導航")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .foregroundColor(.indigo)
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
    }

    // MARK: - 底部預約欄

    private var bookingBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                if let service = selectedService {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("已選：\(service.name)").font(.subheadline).fontWeight(.semibold)
                        Text("$\(Int(service.price)) · \(service.duration) 分鐘")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    Text("請選擇服務項目").foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    if selectedService != nil { isShowingBooking = true }
                } label: {
                    Text(selectedService == nil ? "選擇服務" : "立即預約")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(selectedService == nil ? Color.gray : Color.indigo)
                        .cornerRadius(12)
                }
                .disabled(selectedService == nil)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - 服務項目列

struct ServiceRow: View {
    let service: ShopService
    let isSelected: Bool
    let categoryColor: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name).font(.subheadline).fontWeight(.semibold)
                if let desc = service.description {
                    Text(desc).font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Label("\(service.duration) 分鐘", systemImage: "clock")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(service.price))")
                    .fontWeight(.bold).foregroundColor(categoryColor)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? categoryColor : .secondary)
            }
        }
        .padding(12)
        .background(isSelected ? categoryColor.opacity(0.08) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? categoryColor : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - 資訊列元件

struct InfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundColor(color).frame(width: 20)
            Text(text).font(.subheadline).foregroundColor(.primary)
        }
    }
}

