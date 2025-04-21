//
//  GlobalSummaryView.swift
//  CSAI1
//
//  Single-row “chips” design with full labels and auto-scaling to avoid truncation.
//

import SwiftUI

struct GlobalSummaryView: View {
    @EnvironmentObject var vm: MarketViewModel
    
    var body: some View {
        if let global = vm.globalData {
            rowOfChips(global)
        } else {
            Text("Loading global market data...")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Single Row of “Chips”
    @ViewBuilder
    private func rowOfChips(_ global: GlobalMarketData) -> some View {
        HStack(spacing: 0) {
            statChip(
                label: "Market Cap",
                value: global.total_market_cap?["usd"],
                icon: "dollarsign.circle"
            )
            divider()
            statChip(
                label: "24h Volume",
                value: global.total_volume?["usd"],
                icon: "chart.bar.fill"
            )
            divider()
            statChip(
                label: "BTC Dominance",
                value: global.market_cap_percentage?["btc"],
                suffix: "%",
                icon: "bitcoinsign.circle"
            )
            divider()
            // For "24h Change" we now use a dynamic arrow based on value
            statChip(
                label: "24h Change",
                value: global.market_cap_change_percentage_24h_usd,
                suffix: "%",
                isPercent: true,
                icon: "clock.fill"  // placeholder; see below for dynamic icon logic
            )
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
    
    // MARK: - Stat “Chip”
    @ViewBuilder
    private func statChip(label: String,
                          value: Double?,
                          suffix: String = "",
                          isPercent: Bool = false,
                          icon: String = "") -> some View {
        
        let isNil = (value == nil)
        let raw = value ?? 0
        let displayText = isNil
            ? "--"
            : isPercent
                ? String(format: "%.2f", raw) + suffix
                : raw.formattedWithAbbreviations() + suffix
        
        // For percent-based stats, use green/red; otherwise, use primary color.
        let color: Color = {
            guard isPercent, !isNil else { return .primary }
            return raw >= 0 ? .green : .red
        }()
        
        VStack(spacing: 2) {
            // Label row with fixed icon size and dynamic icon for "24h Change"
            HStack(spacing: 2) {
                if !icon.isEmpty {
                    // For 24h Change, replace the provided icon with an arrow reflecting the sign.
                    let chosenIcon: String = (label == "24h Change")
                        ? (raw >= 0 ? "arrow.up.right" : "arrow.down.right")
                        : icon
                    Image(systemName: chosenIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(.gray)
                }
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
            }
            // Value text centered in the chip
            Text(displayText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
        }
        // Each chip expands equally and has a fixed minimum height for uniformity.
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44, alignment: .center)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Vertical Divider
    private func divider() -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(width: 0.5, height: 24)
    }
}
