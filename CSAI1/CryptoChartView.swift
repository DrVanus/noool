import SwiftUI
import Charts

/// A renamed data model to avoid conflict with 'PricePoint' in CoinDetailView.
struct ChartPricePoint: Identifiable {
    let id = UUID()
    let time: Date
    let price: Double
}

/// A reusable Swift Charts view. Pass in your own [ChartPricePoint] data.
struct CryptoChartView: View {
    let priceData: [ChartPricePoint]
    let lineColor: Color  // e.g. .yellow

    var body: some View {
        Chart {
            ForEach(priceData) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic)
        }
        .chartYAxis {
            AxisMarks()
        }
    }
}

struct CryptoChartView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview
        let now = Date()
        let sampleData = (0..<24).map { i in
            ChartPricePoint(
                time: Calendar.current.date(byAdding: .hour, value: -i, to: now) ?? now,
                price: Double.random(in: 20000...25000)
            )
        }
        .sorted { $0.time < $1.time }

        return CryptoChartView(priceData: sampleData, lineColor: .yellow)
            .frame(height: 220)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
