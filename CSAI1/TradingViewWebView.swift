import SwiftUI
import WebKit

struct TradingViewWebView: UIViewRepresentable {
    let symbol: String
    let timeframe: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        // Set transparent backgrounds so our dark theme shows.
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // HTML string embedding the TradingView widget.
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Trading Chart</title>
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
        TradingViewWebView(symbol: "BINANCE:BTCUSDT", timeframe: "60")
            .frame(height: 300)
            .previewLayout(.sizeThatFits)
    }
}
