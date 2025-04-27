import SwiftUI
import Combine

// MARK: - DataUnavailableView

struct DataUnavailableView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                Text("Retry")
                    .font(.caption2)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.yellow)
                    .cornerRadius(6)
                    .foregroundColor(.black)
            }
        }
    }
}

// MARK: - MarketSentimentView

struct MarketSentimentView: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var vm = ExtendedFearGreedViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "gauge")
                    .foregroundColor(.yellow)
                Text("Market Sentiment")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }

            // Subtitle
            Text("Real‑time Fear & Greed updates")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.vertical, 2)

            Divider()
                .background(Color.white.opacity(0.12))

            // Main content
            if vm.isLoading {
                ProgressView()
                    .tint(.yellow)
                    .frame(maxWidth: .infinity)
            } else if let err = vm.errorMessage {
                DataUnavailableView(message: err, onRetry: vm.fetchData)
            } else if vm.data.isEmpty {
                DataUnavailableView(message: "No data available.", onRetry: vm.fetchData)
            } else {
                HStack(alignment: .top) {
                    ImprovedHalfCircleGauge(
                        value: Double(vm.currentValue),
                        classification: vm.data.first?.valueClassification ?? ""
                    )
                    .frame(width: 250, height: 140)
                    Spacer()
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach([("Now", vm.data.first),
                                 ("Yesterday", vm.yesterdayData),
                                 ("Last Week", vm.lastWeekData),
                                 ("Last Month", vm.lastMonthData)], id: \.0) { label, data in
                            timeframeRow(label, data)
                            if label != "Last Month" {
                                Divider()
                                    .background(Color.white.opacity(0.12))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            // AI Observations
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Observations")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
                Text(aiInsight(for: vm.data.first?.valueClassification ?? ""))
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.05)
                      : Color.black.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .frame(maxWidth: .infinity)
        .onAppear { vm.fetchData() }
        .onReceive(Timer.publish(every: 120, on: .main, in: .common).autoconnect()) {
            _ in vm.fetchData()
        }
    }

    private func timeframeRow(_ label: String, _ d: FearGreedData?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            HStack {
                if let d = d {
                    Text(d.valueClassification.capitalized)
                        .font(.caption2).bold()
                        .foregroundColor(color(for: d.valueClassification))
                    Spacer()
                    let badgeSize: CGFloat = 24
                    ZStack {
                        Circle()
                            .stroke(color(for: d.valueClassification).opacity(0.6), lineWidth: 2)
                            .frame(width: badgeSize, height: badgeSize)
                        Circle()
                            .fill(RadialGradient(
                                gradient: Gradient(colors: [
                                    color(for: d.valueClassification).opacity(0.9),
                                    color(for: d.valueClassification).opacity(0.5)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: badgeSize / 2
                            ))
                            .overlay(
                                Circle()
                                    .stroke(color(for: d.valueClassification).opacity(0.8), lineWidth: 1.5)
                            )
                        Text("\(d.value)")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.7), radius: 2)
                    }
                    .frame(width: badgeSize, height: badgeSize)
                } else {
                    Text("—")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
    }

    private func color(for cls: String) -> Color {
        switch cls.lowercased() {
        case "extreme fear":  return .red
        case "fear":          return .orange
        case "neutral":       return .yellow
        case "greed":         return .green
        case "extreme greed": return .mint
        default:              return .gray
        }
    }

    private func aiInsight(for classification: String) -> String {
        switch classification.lowercased() {
        case "extreme fear":  return "Extreme Fear—market is fragile."
        case "fear":          return "Fear—selective buying might be possible."
        case "neutral":       return "Neutral—monitor momentum."
        case "greed":         return "Greed—potential profit‑taking."
        case "extreme greed": return "Extreme Greed—market exuberant, consider profit‑taking."
        default:              return ""
        }
    }
}

// MARK: - ImprovedHalfCircleGauge

struct ImprovedHalfCircleGauge: View {
    var value: Double
    var classification: String
    var lineWidth: CGFloat = 10
 
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var rotateRing = false
    @State private var tipPulse   = false
    @State private var shimmer    = false
    @State private var previousValue: Double = 0
    @State private var refreshBounce = false

    static let segments: [(ClosedRange<Double>, Color)] = [
        (0...25,   .red),
        (25...50,  .orange),
        (50...75,  .yellow),
        (75...100, .green)
    ]

    private var currentColor: Color {
        switch classification.lowercased() {
        case "extreme fear":  return .red
        case "fear":          return .orange
        case "neutral":       return .yellow
        case "greed":         return .green
        case "extreme greed": return .mint
        default:              return .white
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w      = geo.size.width
            let h      = geo.size.height
            let radius = (min(w, h * 2) / 2 - lineWidth / 2) * 0.92
            let needleLength = radius * 0.9
            let center = CGPoint(x: w/2, y: h)
            let endDeg = 180 + (value/100) * 180

            // Badge positioning
            let liveBadgeSize: CGFloat = 24
            let badgeOffset    = lineWidth * 3.2
            let badgeRadius = radius + badgeOffset
            let badgeX = center.x + cos(endDeg.radians) * badgeRadius
            let badgeY = center.y + sin(endDeg.radians) * badgeRadius

            let baseOffset = lineWidth * 1.2
            let baseLeft = CGPoint(x: center.x + cos(endDeg.radians + .pi/2) * baseOffset,
                                   y: center.y + sin(endDeg.radians + .pi/2) * baseOffset)
            let baseRight = CGPoint(x: center.x + cos(endDeg.radians - .pi/2) * baseOffset,
                                    y: center.y + sin(endDeg.radians - .pi/2) * baseOffset)
            let tip = CGPoint(x: center.x + cos(endDeg.radians) * needleLength,
                              y: center.y + sin(endDeg.radians) * needleLength)

            ZStack {
                // 1) Background arc
                Path { p in
                    p.addArc(center: center,
                             radius: radius,
                             startAngle: .degrees(180),
                             endAngle: .degrees(360),
                             clockwise: false)
                }
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops:
                            Self.segments.map {
                                .init(color: $0.1.opacity(0.2),
                                      location: $0.0.lowerBound/100)
                            } + [.init(color: Self.segments.last!.1.opacity(0.2),
                                       location: 1)]
                        ),
                        center: .center,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth * 0.8, lineCap: .round)
                )
                

                // 2a) Full‐gauge gradient
                Path { p in
                    p.addArc(center: center,
                             radius: radius,
                             startAngle: .degrees(180),
                             endAngle: .degrees(360),
                             clockwise: false)
                }
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Self.segments[0].1, location: 0.0),
                            .init(color: Self.segments[1].1, location: 0.25),
                            .init(color: Self.segments[2].1, location: 0.5),
                            .init(color: Self.segments[3].1, location: 0.75),
                            .init(color: Self.segments[3].1, location: 1.0),
                        ]),
                        center: .center,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth * 0.8, lineCap: .round)
                )


                // Numeric labels at key ticks
                ForEach([25.0, 50.0, 75.0], id: \.self) { mark in
                    TickLabelView(mark: mark, center: center, radius: radius, lineWidth: lineWidth)
                }

                // 4) Motion‑blur wedge
                Path { p in
                    let blurStart = Angle(degrees: endDeg - 5)
                    let blurEnd   = Angle(degrees: endDeg)
                    p.addArc(center: center,
                             radius: radius,
                             startAngle: blurStart,
                             endAngle: blurEnd,
                             clockwise: false)
                }
                .stroke(currentColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round))
                .blur(radius: 4)

                // 5) Glowing needle
                Path { p in
                    let left  = CGPoint(x: baseLeft.x - lineWidth * 0.2, y: baseLeft.y)
                    let right = CGPoint(x: baseRight.x + lineWidth * 0.2, y: baseRight.y)
                    p.move(to: left)
                    p.addLine(to: tip)
                    p.addLine(to: right)
                    p.addQuadCurve(to: left, control: center)
                    p.closeSubpath()
                }
                .fill(LinearGradient(gradient: Gradient(colors: [
                    currentColor.opacity(0.9),
                    currentColor.opacity(0.6)
                ]), startPoint: .top, endPoint: .bottom))
                .overlay(
                    Path { p in
                        let left  = CGPoint(x: baseLeft.x - lineWidth * 0.2, y: baseLeft.y)
                        let right = CGPoint(x: baseRight.x + lineWidth * 0.2, y: baseRight.y)
                        p.move(to: left)
                        p.addLine(to: tip)
                        p.addLine(to: right)
                        p.addQuadCurve(to: left, control: center)
                        p.closeSubpath()
                    }
                    .stroke(currentColor.opacity(0.9), lineWidth: 2)
                )
                .shadow(color: currentColor.opacity(0.6), radius: 6, x: 0, y: 0)
                
                // 3) Focused shimmer on the glowing wedge
                Path { p in
                    let shimmerStart = Angle(degrees: endDeg - 8)
                    let shimmerEnd   = Angle(degrees: endDeg)
                    p.addArc(center: center,
                             radius: radius,
                             startAngle: shimmerStart,
                             endAngle: shimmerEnd,
                             clockwise: false)
                }
                .stroke(currentColor.opacity(0.4),
                        style: StrokeStyle(lineWidth: lineWidth * 0.3,
                                           lineCap: .round,
                                           dash: [radius * 0.05, radius * 0.25],
                                           dashPhase: shimmer ? 0 : radius * 0.3))
                .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: shimmer)
                
                // 2c) Subtle tip glow for lighting effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                currentColor.opacity(0.6),
                                currentColor.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: lineWidth * 3
                        )
                    )
                    .frame(width: lineWidth * 6, height: lineWidth * 6)
                    .blur(radius: lineWidth)
                    .position(tip)
                    .opacity(refreshBounce || tipPulse ? 0.4 : 0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: tipPulse)
                
                // 5a) Refined needle base glow (subtle)
                Circle()
                    .fill(currentColor.opacity(0.4))
                    .frame(width: lineWidth, height: lineWidth)
                    .position(center)
                    .blur(radius: 3)
                
                // 5b) Needle base backlight (softest)
                Circle()
                    .fill(currentColor.opacity(0.15))
                    .frame(width: lineWidth * 2, height: lineWidth * 2)
                    .position(center)
                    .blur(radius: 4)
                
                // 6) Precision hub assembly
                let outerBezel: CGFloat = lineWidth * 2
                let innerHub: CGFloat   = lineWidth * 1.2
                
                // Outer metallic bezel
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.black.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: outerBezel, height: outerBezel)
                    .position(center)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 1, y: 1)
                
                // Inner domed hub
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: currentColor.opacity(0.8), location: 0),
                                .init(color: currentColor.opacity(0.5), location: 0.6),
                                .init(color: Color.black.opacity(0.4),    location: 1)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: innerHub
                        )
                    )
                    .frame(width: innerHub * 2, height: innerHub * 2)
                    .position(center)
                    .overlay(
                        // Tiny specular highlight slice
                        Circle()
                            .trim(from: 0, to: 0.2)
                            .stroke(Color.white.opacity(0.5), lineWidth: innerHub * 0.08)
                            .rotationEffect(.degrees(50))
                            .frame(width: innerHub * 1.4, height: innerHub * 1.4)
                            .position(center)
                    )

                LiveBadgeView(
                    value: Int(value),
                    position: CGPoint(x: badgeX, y: badgeY),
                    currentColor: currentColor,
                    tipPulse: tipPulse,
                    refreshBounce: refreshBounce,
                    rotateRing: rotateRing
                )


                // 7) Pivot & lens
                Circle()
                    .stroke(currentColor.opacity(0.8), lineWidth: 3)
                    .frame(width: lineWidth * 1.4, height: lineWidth * 1.4)
                    .position(center)

                // End-state labels
                Text("Extreme Fear")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.red)
                    .position(x: center.x - radius + lineWidth + 4,
                              y: center.y + lineWidth + 12)

                Text("Extreme Greed")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.green)
                    .position(x: center.x + radius - lineWidth - 4,
                              y: center.y + lineWidth + 12)

                // Arc cover‐glass overlay
                Path { p in
                    p.addArc(center: center,
                             radius: radius,
                             startAngle: .degrees(180),
                             endAngle: .degrees(360),
                             clockwise: false)
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.08), location: 0),
                            .init(color: Color.white.opacity(0), location: 0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.overlay)

                // Inner curved‑glass highlight (subtle double‑edge)
                Path { p in
                    p.addArc(center: center,
                             radius: radius - 2,
                             startAngle: .degrees(180),
                             endAngle: .degrees(360),
                             clockwise: false)
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.04), location: 0),
                            .init(color: Color.white.opacity(0), location: 0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.overlay)
            }
        }
        .frame(width: 250, height: 140)
        .scaleEffect(horizontalSizeClass == .compact ? 0.9 :
                     horizontalSizeClass == .regular ? 1.1 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Market sentiment is \(Int(value))%")
        .accessibilityHint("Current sentiment value in percent")
        .onAppear {
            shimmer = true
            tipPulse = true
            rotateRing = true
            previousValue = value
        }
        .onChange(of: value) { newValue in
            if (previousValue < 50 && newValue >= 50) ||
               (previousValue >= 50 && newValue < 50) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            // trigger quick bounce
            refreshBounce = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    refreshBounce = false
                }
            }
            previousValue = newValue
        }
    }
}
// MARK: - LiveBadgeView
struct LiveBadgeView: View {
    let value: Int
    let position: CGPoint
    let currentColor: Color
    let tipPulse: Bool
    let refreshBounce: Bool
    let rotateRing: Bool

    var body: some View {
        let size: CGFloat = 24
        ZStack {
            // 1) Rotating halo ring behind badge
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            currentColor.opacity(0.4),
                            currentColor.opacity(0.1),
                            currentColor.opacity(0.4)
                        ]),
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: size + 12, height: size + 12) // increased from +12
                .rotationEffect(.degrees(rotateRing ? 360 : 0))
                .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: rotateRing)
                .accessibilityHidden(true)
 
            // 2) Badge outline
            Circle()
                .stroke(currentColor.opacity(0.6), lineWidth: 2)
                .frame(width: size, height: size)
 
            // 3) Badge fill
            Circle()
                .fill(
                    RadialGradient(gradient: Gradient(colors: [
                        currentColor.opacity(0.9),
                        currentColor.opacity(0.5)
                    ]), center: .center, startRadius: 0, endRadius: size / 2)
                )
                .frame(width: size, height: size)
                .overlay(Circle().stroke(currentColor.opacity(0.8), lineWidth: 1.5))
 
            // 4) Value text
            Text("\(value)")
                .font(.caption2).bold()
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 2)
        }
        .scaleEffect(refreshBounce ? 1.3 : (tipPulse ? 1.1 : 1.0))
        .frame(width: size + 12, height: size + 12) // match halo container size
        .position(position)
    }
}

// MARK: - Double Extension

private extension Double {
    var radians: CGFloat { CGFloat(self) * .pi / 180 }
}

// MARK: - TickLineView

struct TickLineView: View {
    let mark: Double, center: CGPoint, radius: CGFloat, lineWidth: CGFloat

    private var rad: CGFloat {
        CGFloat(Angle(degrees: 180 + (mark / 100) * 180).radians)
    }
    private var inner: CGPoint {
        CGPoint(
            x: center.x + cos(rad) * (radius - lineWidth/2 - 4),
            y: center.y + sin(rad) * (radius - lineWidth/2 - 4)
        )
    }
    private var outer: CGPoint {
        let extra: CGFloat = (mark == 50) ? 6 : 2
        return CGPoint(
            x: center.x + cos(rad) * (radius + lineWidth/2 + extra),
            y: center.y + sin(rad) * (radius + lineWidth/2 + extra)
        )
    }

    var body: some View {
        Path { p in
            p.move(to: inner)
            p.addLine(to: outer)
        }
        .stroke(Color.white.opacity(mark == 50 ? 0.5 : 1),
                style: StrokeStyle(lineWidth: 2, lineCap: .butt))
    }
}

// MARK: - TickLabelView

struct TickLabelView: View {
    let mark: Double, center: CGPoint, radius: CGFloat, lineWidth: CGFloat

    private var rad: CGFloat {
        CGFloat(Angle(degrees: 180 + (mark / 100) * 180).radians)
    }
    private var labelRadius: CGFloat {
        switch mark {
        case 50:  return radius - lineWidth * 1.4
        default:  return radius - lineWidth * 0.8 - 4
        }
    }
    private var pos: CGPoint {
        CGPoint(
            x: center.x + cos(rad) * labelRadius,
            y: center.y + sin(rad) * labelRadius
        )
    }

    var body: some View {
        Text("\(Int(mark))")
            .font(.system(size: 9, weight: .bold))
            .opacity(0.5)
            .foregroundColor(.white)
            .position(x: pos.x, y: pos.y)
    }
}
