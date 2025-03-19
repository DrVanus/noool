//
//  TradingViewWebView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  TradingViewWebView.swift
//  CRYPTOSAI
//
//  Embeds a TradingView chart widget via WKWebView.
//

import SwiftUI
import WebKit

struct TradingViewWebView: UIViewRepresentable {
    let symbol: String
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Example TradingView widget URL
        let urlString = "https://s.tradingview.com/widgetembed/?symbol=\(symbol)&interval=60"
        guard let url = URL(string: urlString) else { return }
        uiView.load(URLRequest(url: url))
    }
}
