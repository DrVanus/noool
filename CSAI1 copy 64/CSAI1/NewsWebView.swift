// NewsWebView.swift
// CSAI1
//
// Created by ChatGPT on 4/18/25.
// Native SwiftUI crypto‑news feed (no WKWebView).

import SwiftUI
import SafariServices

// MARK: -- Error View

struct CryptoNewsErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            Button(action: onRetry) {
                Text("Retry")
                    .font(.caption2)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(6)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.8))
        .cornerRadius(8)
    }
}

// MARK: -- Data Model

struct CryptoNewsArticle: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String?
    let url: URL
    let urlToImage: URL?
    let publishedAt: Date
    let source: Source

    struct Source: Codable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case title, description, url, urlToImage, publishedAt, source
    }
}

// MARK: -- Networking via RSS

enum CryptoNewsAPIError: Error {
    case invalidURL
    case network(Error)
    case invalidResponse
    case parsing
}

actor CryptoNewsService {
    func fetchLatestNews() async throws -> [CryptoNewsArticle] {
        guard let feedURL = URL(string: "https://www.coindesk.com/arc/outboundfeeds/rss/") else {
            throw CryptoNewsAPIError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: feedURL)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw CryptoNewsAPIError.network(URLError(.badServerResponse))
        }
        let parser = RSSParser(data: data)
        let items = parser.parse()
        return items.map { item in
            CryptoNewsArticle(
                title: item.title,
                description: item.description,
                url: item.link,
                urlToImage: item.imageURL,
                publishedAt: item.pubDate,
                source: .init(name: "CoinDesk")
            )
        }
    }
}

private struct RSSItem {
    let title: String
    let link: URL
    let description: String
    let pubDate: Date
    let imageURL: URL?
}

private class RSSParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private var items: [RSSItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentImageURL: String?
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return df
    }()

    init(data: Data) {
        parser = XMLParser(data: data)
        super.init()
        parser.delegate = self
    }

    func parse() -> [RSSItem] {
        parser.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
            currentImageURL = nil
        }
        if elementName == "enclosure", let urlStr = attributeDict["url"] {
            currentImageURL = urlStr
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "description": currentDescription += string
        case "pubDate": currentPubDate += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            guard let linkURL = URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)),
                  let date = dateFormatter.date(from: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
            else { return }
            let imageURL = currentImageURL.flatMap { URL(string: $0) }
            items.append(RSSItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: linkURL,
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: date,
                imageURL: imageURL
            ))
        }
    }
}

// MARK: -- ViewModel

@MainActor
class CryptoNewsFeedViewModel: ObservableObject {
    @Published var articles: [CryptoNewsArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = CryptoNewsService()

    func loadNews() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetched = try await service.fetchLatestNews()
                articles = fetched
            } catch {
                errorMessage = "Failed to load: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

// MARK: -- Row

struct CryptoNewsRow: View {
    let article: CryptoNewsArticle

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let imageURL = article.urlToImage {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: 100, height: 60)
                            .clipped()
                    case .failure:
                        Color.gray.frame(width: 100, height: 60)
                    default:
                        Color.gray.opacity(0.3).frame(width: 100, height: 60)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                Text("\(article.source.name) • " +
                     article.publishedAt.formatted(.dateTime.month().day().year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: -- Main View

struct CryptoNewsView: View {
    @StateObject private var viewModel = CryptoNewsFeedViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading…")
            } else if let error = viewModel.errorMessage {
                CryptoNewsErrorView(message: error) {
                    viewModel.loadNews()
                }
            } else {
                List(viewModel.articles) { article in
                    Button {
                        openSafari(article.url)
                    } label: {
                        CryptoNewsRow(article: article)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            viewModel.loadNews()
        }
    }

    private func openSafari(_ url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return
        }
        let safari = SFSafariViewController(url: url)
        root.present(safari, animated: true)
    }
}

// MARK: -- Preview

struct CryptoNewsView_Previews: PreviewProvider {
    static var previews: some View {
        CryptoNewsView()
    }
}
