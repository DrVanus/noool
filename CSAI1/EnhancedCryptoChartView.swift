//
//  EnhancedCryptoChartView.swift
//  CSAI1
//

import SwiftUI
import Charts

// 1) Remove the local EnhancedChartPricePoint
// 2) Optionally import if separate module, or just rely on it being in the same target.

struct EnhancedCryptoChartView: View {
    let priceData: [EnhancedChartPricePoint]
    let lineColor: Color
    
    @State private var selectedPoint: EnhancedChartPricePoint? = nil
    @State private var showCrosshair: Bool = true
    @State private var crosshairLocation: CGPoint? = nil

    var body: some View {
        ZStack {
            Chart {
                // area fill
                ForEach(priceData) { point in
                    AreaMark(
                        x: .value("Time", point.time),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [lineColor.opacity(0.4), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // main line
                ForEach(priceData) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(lineColor)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                }

                // highlight selected point
                if let selectedPoint {
                    RuleMark(x: .value("Selected Time", selectedPoint.time))
                        .foregroundStyle(Color.white.opacity(0.4))

                    PointMark(
                        x: .value("Time", selectedPoint.time),
                        y: .value("Price", selectedPoint.price)
                    )
                    .annotation(position: .top) {
                        Text("\(selectedPoint.price, format: .number.precision(.fractionLength(2)))")
                            .font(.caption)
                            .padding(6)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2)))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let locationX = drag.location.x - origin.x
                                    crosshairLocation = drag.location

                                    if let date: Date = proxy.value(atX: locationX) {
                                        let closest = priceData.min {
                                            abs($0.time.timeIntervalSince(date)) < abs($1.time.timeIntervalSince(date))
                                        }
                                        selectedPoint = closest
                                    }
                                }
                                .onEnded { _ in
                                    // selectedPoint = nil
                                }
                        )
                }
            }

            if showCrosshair, let loc = crosshairLocation {
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    if loc.x >= 0 && loc.y >= 0 && loc.x <= width && loc.y <= height {
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 1, height: height)
                                .position(x: loc.x, y: height / 2)

                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: width, height: 1)
                                .position(x: width / 2, y: loc.y)
                        }
                    }
                }
                .allowsHitTesting(false)
            }

            // Toggle for crosshair
            VStack {
                HStack {
                    Spacer()
                    Toggle("Crosshair", isOn: $showCrosshair)
                        .padding(6)
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(8)
                        .padding([.top, .trailing], 8)
                }
                Spacer()
            }
        }
    }
}

struct EnhancedCryptoChartView_Previews: PreviewProvider {
    static var previews: some View {
        let now = Date()
        let sampleData = (0..<24).map { i in
            EnhancedChartPricePoint(
                time: Calendar.current.date(byAdding: .hour, value: -i, to: now) ?? now,
                price: Double.random(in: 20000...25000)
            )
        }
        .sorted { $0.time < $1.time }

        return EnhancedCryptoChartView(
            priceData: sampleData,
            lineColor: .yellow
        )
        .frame(height: 300)
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
}
