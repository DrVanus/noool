//
//  EnhancedChartPricePoint.swift
//  CSAI1
//
//  Created by DM on 3/21/25.
//


//
//  EnhancedChartPricePoint.swift
//  CSAI1
//
//  Shared data model for chart points used by multiple views.
//

import Foundation

/// Data model for chart points.
/// Conforms to Identifiable so we can use it in ForEach,
/// and Equatable so that SwiftUI can animate changes in arrays of these points.
struct EnhancedChartPricePoint: Identifiable, Equatable {
    let id = UUID()
    let time: Date
    let price: Double

    static func == (lhs: EnhancedChartPricePoint, rhs: EnhancedChartPricePoint) -> Bool {
        lhs.time == rhs.time && lhs.price == rhs.price
    }
}