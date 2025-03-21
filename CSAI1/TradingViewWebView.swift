import SwiftUI
import WebKit

/// A UIViewRepresentable that displays a TradingView chart in a WKWebView.
/// Provide the symbol (e.g. "BINANCE:BTCUSDT") and timeframe (e.g. "60" for 1H).
struct TradingViewWebView: UIViewRepresentable {
    let symbol: String
    let timeframe: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        // Set transparent backgrounds so it fits a dark theme if desired.
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // This HTML string embeds the TradingView widget for the given symbol/timeframe.
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>TradingView Chart</title>
        </head>
        <body style="margin:0; padding:0; background-color:#000;">
            <div class="tradingview-widget-container" style="width:100%; height:300px;">
              <div id="tradingview_widget"></div>
              <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
              <script type="text/javascript">
              new TradingView.widget({
                "width": "100%",
                "height": "100%",
                "symbol": "\(symbol)",
                "interval": "\(timeframe)",
                "timezone": "Etc/UTC",
                "theme": "dark",
                "style": "1",
                "locale": "en",
                "toolbar_bg": "#f1f3f6",
                "enable_publishing": false,
                "allow_symbol_change": true,
                "container_id": "tradingview_widget"
              });
              </script>
            </div>
        </body>
        </html>
        """
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}

struct TradingViewWebView_Previews: PreviewProvider {
    static var previews: some View {
        // Example usage: 1-hour timeframe on BTC/USDT
        TradingViewWebView(symbol: "BINANCE:BTCUSDT", timeframe: "60")
            .frame(height: 300)
            .previewLayout(.sizeThatFits)
    }
}
