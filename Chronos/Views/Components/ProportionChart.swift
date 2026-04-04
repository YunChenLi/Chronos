//
//  ProportionChart.swift
//  Chronos
//

import SwiftUI

/// 橫向比例柱狀圖元件
struct ProportionChart: View {
    let data: [(label: String, value: Double)]
    let total: Double

    private let colors: [Color] = [.indigo, .orange, .green, .teal, .purple, .pink, .blue, .yellow]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(data.indices, id: \.self) { index in
                let item = data[index]
                let color = colors[index % colors.count]
                let percentage = total > 0 ? item.value / total * 100 : 0

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.label).font(.subheadline)
                        Spacer()
                        Text("$\(item.value, specifier: "%.0f") (\(percentage, specifier: "%.1f")%)")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color)
                                .frame(width: geometry.size.width * (total > 0 ? item.value / total : 0), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
