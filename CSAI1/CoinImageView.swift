//
//  CoinImageView.swift
//  CSAI1
//
//  Created by ChatGPT on 4/1/25
//  A dedicated view for loading a coin’s icon with robust fallback logic and debug logging.
//

import SwiftUI

// MARK: - Logo Dictionaries

private let cryptoCompareLogos: [String: String] = [
    "BTC":   "https://www.cryptocompare.com/media/19633/btc.png",
    "ETH":   "https://www.cryptocompare.com/media/20646/eth.png",
    "USDT":  "https://www.cryptocompare.com/media/356512/usdt.png",
    "BNB":   "https://www.cryptocompare.com/media/1383963/bnb.png",
    "DOGE":  "https://www.cryptocompare.com/media/19684/doge.png",
    "ADA":   "https://www.cryptocompare.com/media/12318177/ada.png",
    "SOL":   "https://www.cryptocompare.com/media/356512/sol.png",
    "XRP":   "https://www.cryptocompare.com/media/34477776/xrp.png",
    "TRX":   "https://www.cryptocompare.com/media/34477776/trx.png",
    "USDC":  "https://www.cryptocompare.com/media/356512/usdc.png",
    "MATIC": "https://www.cryptocompare.com/media/37746240/matic.png",
    "LTC":   "https://www.cryptocompare.com/media/35309662/ltc.png",
    "DOT":   "https://www.cryptocompare.com/media/356512/dot.png",
    "AVAX":  "https://www.cryptocompare.com/media/37746241/avax.png",
    "UNI":   "https://www.cryptocompare.com/media/37746239/uni.png",
    "SHIB":  "https://www.cryptocompare.com/media/37746242/shib.png",
    "LINK":  "https://www.cryptocompare.com/media/12318183/link.png",
    "XLM":   "https://www.cryptocompare.com/media/19633/xlm.png",
    "ATOM":  "https://www.cryptocompare.com/media/20646/atom.png",
    "ETC":   "https://www.cryptocompare.com/media/19633/etc.png",
    "BCH":   "https://www.cryptocompare.com/media/19633/bch.png"
]

private let coinMarketCapLogos: [String: String] = [
    "BTC": "https://s2.coinmarketcap.com/static/img/coins/64x64/1.png",
    "ETH": "https://s2.coinmarketcap.com/static/img/coins/64x64/1027.png",
    "BNB": "https://s2.coinmarketcap.com/static/img/coins/64x64/1839.png",
    "SOL": "https://s2.coinmarketcap.com/static/img/coins/64x64/5426.png",
    "XRP": "https://s2.coinmarketcap.com/static/img/coins/64x64/52.png",
    "USDT": "https://s2.coinmarketcap.com/static/img/coins/64x64/825.png",
    "USDC": "https://s2.coinmarketcap.com/static/img/coins/64x64/3408.png",
    "ADA":  "https://s2.coinmarketcap.com/static/img/coins/64x64/2010.png",
    "DOGE": "https://s2.coinmarketcap.com/static/img/coins/64x64/74.png",
    "MATIC": "https://s2.coinmarketcap.com/static/img/coins/64x64/3890.png",
    "DOT":  "https://s2.coinmarketcap.com/static/img/coins/64x64/6636.png",
    "LTC":  "https://s2.coinmarketcap.com/static/img/coins/64x64/2.png",
    "SHIB": "https://s2.coinmarketcap.com/static/img/coins/64x64/5994.png",
    "TRX":  "https://s2.coinmarketcap.com/static/img/coins/64x64/1958.png",
    "AVAX": "https://s2.coinmarketcap.com/static/img/coins/64x64/5805.png",
    "LINK": "https://s2.coinmarketcap.com/static/img/coins/64x64/1975.png"
]

struct CoinImageView: View {
    let symbol: String
    let urlStr: String?
    
    var body: some View {
        let upperSymbol = symbol.uppercased()
        Group {
            if let ccURLStr = cryptoCompareLogos[upperSymbol],
               let ccURL = URL(string: ccURLStr) {
                AsyncImage(url: ccURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                             .scaledToFit()
                             .frame(width: 32, height: 32)
                             .clipShape(Circle())
                             .onAppear {
                                print("Loaded \(upperSymbol) image from CryptoCompare")
                             }
                    case .failure(let error):
                        fallbackImage(for: upperSymbol)
                            .onAppear {
                                print("CryptoCompare failed for \(upperSymbol): \(error.localizedDescription)")
                            }
                    case .empty:
                        ProgressView().frame(width: 32, height: 32)
                    @unknown default:
                        fallbackImage(for: upperSymbol)
                    }
                }
            } else {
                fallbackImage(for: upperSymbol)
                    .onAppear {
                        print("CryptoCompare URL not found for \(upperSymbol)")
                    }
            }
        }
    }
    
    private func fallbackImage(for symbol: String) -> some View {
        if let cmcURLStr = coinMarketCapLogos[symbol],
           let cmcURL = URL(string: cmcURLStr) {
            return AnyView(
                AsyncImage(url: cmcURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                             .scaledToFit()
                             .frame(width: 32, height: 32)
                             .clipShape(Circle())
                             .onAppear {
                                print("Loaded \(symbol) image from CoinMarketCap")
                             }
                    case .failure(let error):
                        localOrDefault(for: symbol)
                            .onAppear {
                                print("CoinMarketCap failed for \(symbol): \(error.localizedDescription)")
                            }
                    case .empty:
                        ProgressView().frame(width: 32, height: 32)
                    @unknown default:
                        localOrDefault(for: symbol)
                    }
                }
            )
        } else {
            return AnyView(
                localOrDefault(for: symbol)
                    .onAppear {
                        print("CoinMarketCap URL not found for \(symbol)")
                    }
            )
        }
    }
    
    private func localOrDefault(for symbol: String) -> some View {
        if UIImage(named: symbol.lowercased()) != nil {
            return AnyView(
                Image(symbol.lowercased())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .onAppear {
                        print("Loaded local image for \(symbol)")
                    }
            )
        } else {
            return AnyView(
                Image(systemName: "bitcoinsign.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray)
                    .onAppear {
                        print("No local image for \(symbol), using SF Symbol")
                    }
            )
        }
    }
}

struct CoinImageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CoinImageView(symbol: "BTC", urlStr: nil)
            CoinImageView(symbol: "DOGE", urlStr: nil)
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.black)
    }
}
