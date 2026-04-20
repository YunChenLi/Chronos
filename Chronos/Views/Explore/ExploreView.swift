//
//  ExploreView.swift
//  KinKeep
//

internal import SwiftUI
import MapKit
import CoreLocation
internal import Combine


struct ExploreView: View {
    @Binding var appointments: [Appointment]
    let members: [Member]
    var saveAction: () -> Void

    @StateObject private var locationManager = LocationManager()
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: ShopCategory? = nil
    @State private var viewMode: ViewMode = .list
    @State private var selectedShop: Shop? = nil
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.0480, longitude: 121.5468),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    enum ViewMode { case list, map }

    var filteredShops: [Shop] {
        firebaseManager.shops.filter { shop in
            let matchCategory = selectedCategory == nil || shop.category == selectedCategory
            let matchSearch = searchText.isEmpty
                || shop.name.localizedCaseInsensitiveContains(searchText)
                || shop.address.localizedCaseInsensitiveContains(searchText)
            return matchCategory && matchSearch
        }
    }

    var sortedShops: [Shop] {
        guard let userLocation = locationManager.userLocation else { return filteredShops }
        return filteredShops.sorted {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: userLocation)
            < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: userLocation)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                categoryFilter
                viewModePicker

                if viewMode == .list {
                    shopListView
                } else {
                    shopMapView
                }
            }
            .navigationTitle("探索合作店家")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedShop) { shop in
                ShopDetailView(
                    shop: shop,
                    appointments: $appointments,
                    members: members,
                    saveAction: saveAction
                )
            }
            .onAppear { firebaseManager.fetchShops() }
            .overlay {
                if firebaseManager.isLoading {
                    ZStack {
                        Color.black.opacity(0.1).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("載入店家資料中...").font(.caption).foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - 搜尋欄

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("搜尋店家名稱或地址", text: $searchText).textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - 類別篩選

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryFilterChip(title: "全部", isSelected: selectedCategory == nil, color: .indigo)
                    .onTapGesture { selectedCategory = nil }
                ForEach(ShopCategory.allCases) { cat in
                    CategoryFilterChip(
                        title: cat.rawValue,
                        isSelected: selectedCategory == cat,
                        color: Color(hex: cat.color)
                    )
                    .onTapGesture {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
    }

    // MARK: - 切換器

    private var viewModePicker: some View {
        Picker("顯示方式", selection: $viewMode) {
            Label("列表", systemImage: "list.bullet").tag(ViewMode.list)
            Label("地圖", systemImage: "map").tag(ViewMode.map)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal).padding(.bottom, 8)
    }

    // MARK: - 列表

    private var shopListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if firebaseManager.isLoading {
                    ProgressView("載入中...").padding(.top, 60)
                } else if sortedShops.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.slash").font(.largeTitle).foregroundColor(.secondary)
                        Text("找不到符合條件的店家").foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 60)
                } else {
                    ForEach(sortedShops) { shop in
                        ShopCard(shop: shop, userLocation: locationManager.userLocation)
                            .onTapGesture { selectedShop = shop }
                    }
                }
            }
            .padding(.horizontal).padding(.bottom, 20)
        }
    }

    // MARK: - 地圖（iOS 17+ 新版 API）

    private var shopMapView: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                UserAnnotation()
                ForEach(sortedShops) { shop in
                    Annotation(shop.name, coordinate: shop.coordinate) {
                        ShopMapPin(shop: shop, isSelected: selectedShop?.id == shop.id)
                            .onTapGesture {
                                selectedShop = shop
                                withAnimation {
                                    mapPosition = .region(MKCoordinateRegion(
                                        center: shop.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    ))
                                }
                            }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            if !sortedShops.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sortedShops) { shop in
                            ShopMiniCard(shop: shop)
                                .onTapGesture {
                                    selectedShop = shop
                                    withAnimation {
                                        mapPosition = .region(MKCoordinateRegion(
                                            center: shop.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        ))
                                    }
                                }
                        }
                    }
                    .padding(.horizontal).padding(.vertical, 12)
                }
                .background(.ultraThinMaterial)
                .cornerRadius(20, corners: [.topLeft, .topRight])
            }
        }
    }
}

// MARK: - 地圖大頭針

struct ShopMapPin: View {
    let shop: Shop
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: shop.category.color) : Color.white)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(radius: 4)
                Image(systemName: shop.category.icon)
                    .foregroundColor(isSelected ? .white : Color(hex: shop.category.color))
                    .font(.system(size: isSelected ? 18 : 14))
            }
            Triangle()
                .fill(isSelected ? Color(hex: shop.category.color) : Color.white)
                .frame(width: 10, height: 6)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 店家卡片

struct ShopCard: View {
    let shop: Shop
    let userLocation: CLLocation?

    var distanceText: String? {
        guard let userLoc = userLocation else { return nil }
        let dist = CLLocation(latitude: shop.latitude, longitude: shop.longitude).distance(from: userLoc)
        return dist < 1000
            ? String(format: "%.0f m", dist)
            : String(format: "%.1f km", dist / 1000)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color(hex: shop.category.color).opacity(0.15))
                    .frame(height: 80)
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: shop.category.color).opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: shop.imageSystemIcon)
                            .font(.title2)
                            .foregroundColor(Color(hex: shop.category.color))
                    }
                    .padding(.leading, 16).padding(.bottom, 12)
                    Spacer()
                    if shop.isPartner {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.indigo)
                            Text("合作店家").font(.caption).foregroundColor(.indigo)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.indigo.opacity(0.1)).cornerRadius(12)
                        .padding(.trailing, 12).padding(.bottom, 12)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(shop.name).font(.headline).fontWeight(.bold)
                    Spacer()
                    Text(shop.category.rawValue)
                        .font(.caption).foregroundColor(Color(hex: shop.category.color))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(hex: shop.category.color).opacity(0.1)).cornerRadius(8)
                }
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < Int(shop.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow).font(.caption2)
                    }
                    Text(String(format: "%.1f", shop.rating)).font(.caption).foregroundColor(.secondary)
                    Text("(\(shop.reviewCount))").font(.caption).foregroundColor(.secondary)
                    if let dist = distanceText {
                        Spacer()
                        Image(systemName: "location.fill").foregroundColor(.indigo).font(.caption2)
                        Text(dist).font(.caption).foregroundColor(.indigo)
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: "mappin").foregroundColor(.secondary).font(.caption)
                    Text(shop.address).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
                HStack(spacing: 4) {
                    Image(systemName: "clock").foregroundColor(.secondary).font(.caption)
                    Text(shop.openingHours).font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("立即預約 →").font(.caption).fontWeight(.semibold).foregroundColor(.indigo)
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 迷你卡片

struct ShopMiniCard: View {
    let shop: Shop
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: shop.category.color).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: shop.category.icon)
                    .foregroundColor(Color(hex: shop.category.color))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(shop.name).font(.subheadline).fontWeight(.semibold).lineLimit(1)
                HStack(spacing: 2) {
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2)
                    Text(String(format: "%.1f", shop.rating)).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color(.systemBackground)).cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4)
        .frame(width: 160)
    }
}

// MARK: - 類別篩選 Chip

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    var body: some View {
        Text(title)
            .font(.caption).fontWeight(.medium)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? color : Color.clear, lineWidth: 1.5))
    }
}

// MARK: - 圓角輔助

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}

// MARK: - 定位管理器

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
}

