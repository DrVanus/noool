import SwiftUI

/// The order types for placing trades.
enum OrderType: String, CaseIterable {
    case market = "Market"
    case limit = "Limit"
    case stopLimit = "Stop-Limit"
    case trailingStop = "Trailing Stop"
}

struct TradeView: View {
    // MARK: - State
    @State private var selectedPair: String = "BTC-USD"
    @State private var isBuyOrder: Bool = true
    @State private var orderType: OrderType = .market

    // The chart data array, now using ChartPricePoint to avoid conflicts.
    @State private var tradeChartData: [ChartPricePoint] = []

    @State private var quantity: String = ""
    private let pairs = ["BTC-USD", "ETH-USD", "SOL-USD", "ADA-USD"]
    private let brandColor = Color.yellow

    // For animated glow on the buy/sell toggle
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            // MARK: - Background
            RadialGradient(
                gradient: Gradient(colors: [
                    .black,
                    brandColor.opacity(0.04),
                    .black
                ]),
                center: .center,
                startRadius: 10,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Neon ring behind the order card
            Circle()
                .stroke(brandColor.opacity(0.2), lineWidth: 6)
                .frame(width: 450, height: 450)
                .blur(radius: 20)
                .offset(y: 250)

            VStack(spacing: 24) {
                // MARK: - Live Chart Card
                chartCard
                    .rotation3DEffect(
                        .degrees(4), // subtle tilt
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .center
                    )

                // MARK: - Place an Order Card
                placeOrderCard
                    .padding(.top, -20) // slight overlap

                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Animate the glowing toggle
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse.toggle()
            }
            // Generate some sample chart data (replace with real API calls)
            generateChartData()
        }
    }

    // MARK: - Chart Card
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Chart")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            // Integrate the shared CryptoChartView
            CryptoChartView(
                priceData: tradeChartData,
                lineColor: brandColor
            )
            .frame(height: 220)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.25))
                .blur(radius: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(brandColor.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
    }

    // MARK: - Place an Order Card
    private var placeOrderCard: some View {
        let cardBackground = Color.black.opacity(0.25).blur(radius: 8)

        return VStack(alignment: .leading, spacing: 20) {
            Text("Place an Order")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            // Balance
            HStack {
                Text("Balance: $5,000.00")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }

            // Pair + Buy/Sell row
            pairBuySellRow

            // Order type row
            orderTypeRow

            // Quantity
            quantityField

            // Percentage row
            percentageRow

            // Confirm button
            Button(action: {
                // TODO: place order logic
            }) {
                Text("\(isBuyOrder ? "Buy" : "Sell") \(selectedPair)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(isBuyOrder ? brandColor.opacity(0.85) : Color.red.opacity(0.85))
                    .cornerRadius(12)
            }
            .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 2)
        }
        .padding(20)
        .background(cardBackground)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(brandColor.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: 5)
    }

    // MARK: - Pair + Buy/Sell
    private var pairBuySellRow: some View {
        HStack {
            Menu {
                ForEach(pairs, id: \.self) { pair in
                    Button(pair) {
                        selectedPair = pair
                    }
                }
            } label: {
                HStack {
                    Text(selectedPair)
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }

            Spacer()

            HStack(spacing: 0) {
                Button("Buy") {
                    isBuyOrder = true
                }
                .font(.headline)
                .foregroundColor(isBuyOrder ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(isBuyOrder ? brandColor.opacity(0.8) : Color.white.opacity(0.1))
                .shadow(
                    color: isBuyOrder ? brandColor.opacity(glowPulse ? 0.5 : 0.2) : .clear,
                    radius: glowPulse ? 12 : 0,
                    x: 0,
                    y: 0
                )

                Button("Sell") {
                    isBuyOrder = false
                }
                .font(.headline)
                .foregroundColor(!isBuyOrder ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(!isBuyOrder ? Color.red.opacity(0.8) : Color.white.opacity(0.1))
                .shadow(
                    color: !isBuyOrder ? Color.red.opacity(glowPulse ? 0.5 : 0.2) : .clear,
                    radius: glowPulse ? 12 : 0,
                    x: 0,
                    y: 0
                )
            }
            .cornerRadius(10)
        }
    }

    // MARK: - Order Type Row
    private var orderTypeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(OrderType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        orderType = type
                    }
                    .font(.footnote)
                    .foregroundColor(orderType == type ? .black : .white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(
                        orderType == type
                        ? brandColor.opacity(0.85)
                        : Color.white.opacity(0.1)
                    )
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Quantity Field
    private var quantityField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quantity")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            TextField("0.00", text: $quantity)
                .keyboardType(.decimalPad)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
        }
    }

    // MARK: - Percentage Row
    private var percentageRow: some View {
        HStack {
            ForEach([25, 50, 75, 100], id: \.self) { percent in
                Button("\(percent)%") {
                    // Example logic: quantity = some calculation
                    quantity = "\(percent)"
                }
                .font(.footnote)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            Spacer()
        }
    }

    // MARK: - Generate Chart Data
    private func generateChartData() {
        let now = Date()
        // Just a sample: 24 data points
        tradeChartData = (0..<24).map { i in
            ChartPricePoint(
                time: Calendar.current.date(byAdding: .hour, value: -i, to: now) ?? now,
                price: Double.random(in: 20000...25000)
            )
        }
        .sorted { $0.time < $1.time }
    }
}

struct TradeView_Previews: PreviewProvider {
    static var previews: some View {
        TradeView()
    }
}
