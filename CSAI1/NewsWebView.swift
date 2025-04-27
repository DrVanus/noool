// NewsWebView.swift
// CSAI1
//
// Created by ChatGPT on 4/18/25.
// Native SwiftUI crypto‑news feed (no WKWebView).

import SwiftUI
import SafariServices
import UIKit
import Combine


// MARK: - Custom Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.5),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 300)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Applies a shimmer animation to placeholder content.
    func shimmeringEffect() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: -- Thumbnail Caching

actor ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSURL, UIImage>()
    func loadImage(from url: URL?) async -> UIImage? {
        guard let url = url else { return nil }
        let key = url as NSURL
        if let img = cache.object(forKey: key) {
            return img
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                cache.setObject(img, forKey: key)
                return img
            }
        } catch { }
        return nil
    }
}

struct CachingAsyncImage: View {
    let url: URL?
    var body: some View {
        CachingAsyncImageContent(url: url)
    }
}

private struct CachingAsyncImageContent: View {
    let url: URL?
    @State private var uiImage: UIImage?
    var body: some View {
        Group {
            if let img = uiImage {
                Image(uiImage: img).resizable()
            } else {
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.7))
                }
                .shimmeringEffect()
            }
        }
        .onAppear {
            Task {
                if let loaded = await ThumbnailCache.shared.loadImage(from: url) {
                    uiImage = loaded
                }
            }
        }
    }
}

// Formatter for absolute dates
private let fullDateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM d yyyy, h:mm a"
    return df
}()

/// Skeleton row view for loading state
struct SkeletonNewsRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 60)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 14)
            }
        }
        .redacted(reason: .placeholder)
        .shimmeringEffect()
        .padding(.vertical, 2)
    }
}

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
    // Preview sources: two fastest feeds for immediate display
    private let previewFeedInfo: [(url: String, sourceName: String)] = [
        ("https://www.coindesk.com/arc/outboundfeeds/rss/", "CoinDesk"),
        ("https://cryptoslate.com/feed/", "CryptoSlate")
    ]

    func fetchLatestNews() async -> [CryptoNewsArticle] {
        let feedInfo: [(url: String, sourceName: String)] = [
            ("https://www.coindesk.com/arc/outboundfeeds/rss/", "CoinDesk"),
            ("https://cryptoslate.com/feed/", "CryptoSlate"),
            ("https://cointelegraph.com/rss", "CoinTelegraph"),
            ("https://www.theblock.co/rss", "The Block"),
            ("https://bitcoinmagazine.com/.rss/full/", "Bitcoin Magazine"),
            ("https://coinjournal.net/feed/", "CoinJournal")
        ]
        // Concurrently fetch each feed
        let allItems: [(item: RSSItem, sourceName: String)] = await withTaskGroup(of: [(RSSItem, String)].self) { group in
            for (feedURLString, sourceName) in feedInfo {
                group.addTask {
                    guard let url = URL(string: feedURLString),
                          let (data, response) = try? await URLSession.shared.data(from: url),
                          let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                        return []
                    }
                    let parser = RSSParser(data: data)
                    let parsed = parser.parse()
                    return parsed.map { (item: $0, sourceName: sourceName) }
                }
            }
            var collected: [(RSSItem, String)] = []
            for await result in group {
                collected += result
            }
            return collected
        }
        guard !allItems.isEmpty else { return [] }
        // Sort by newest first
        let sorted = allItems.sorted { $0.item.pubDate > $1.item.pubDate }
        let mapped = sorted.map { (item, srcName) in
            CryptoNewsArticle(
                title: item.title,
                description: item.description,
                url: item.link,
                urlToImage: item.imageURL,
                publishedAt: item.pubDate,
                source: .init(name: srcName)
            )
        }
        // limit total items for pagination
        let maxItems = 100
        return Array(mapped.prefix(maxItems))
    }

    func fetchPreviewNews() async -> [CryptoNewsArticle] {
        await withTaskGroup(of: [CryptoNewsArticle].self) { group in
            for (feedURLString, sourceName) in previewFeedInfo {
                group.addTask {
                    guard let url = URL(string: feedURLString),
                          let (data, response) = try? await URLSession.shared.data(from: url),
                          let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                        return []
                    }
                    let parser = RSSParser(data: data)
                    let items = parser.parse().sorted { $0.pubDate > $1.pubDate }
                    return items.prefix(5).map {
                        CryptoNewsArticle(
                            title: $0.title,
                            description: $0.description,
                            url: $0.link,
                            urlToImage: $0.imageURL,
                            publishedAt: $0.pubDate,
                            source: .init(name: sourceName)
                        )
                    }
                }
            }
            var collected = [CryptoNewsArticle]()
            for await result in group {
                collected += result
            }
            return collected.sorted { $0.publishedAt > $1.publishedAt }
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
        if ["enclosure", "media:content", "media:thumbnail"].contains(elementName),
           let urlStr = attributeDict["url"] {
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
            // Fallback: If no enclosure or media image, try to extract <img src="..."> from description
            if currentImageURL == nil {
                if let match = currentDescription.range(of: "<img[^>]+src=[\"']([^\"']+)[\"']", options: .regularExpression) {
                    let imgTag = String(currentDescription[match])
                    if let urlMatch = imgTag.range(of: "src=[\"']([^\"']+)[\"']", options: .regularExpression) {
                        let srcString = String(imgTag[urlMatch])
                        let srcValue = srcString
                            .replacingOccurrences(of: "src=\"", with: "")
                            .replacingOccurrences(of: "src='", with: "")
                            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                        currentImageURL = srcValue
                    }
                }
            }
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
    /// Articles currently displayed (preview → full)
    @Published var displayedArticles: [CryptoNewsArticle] = []
    @Published var errorMessage: String?
    @Published var bookmarks: [CryptoNewsArticle] = []
    @Published var readArticles: Set<UUID> = []

    @Published var isLoadingFull = false
    @Published var currentPage = 1
    let pageSize = 20

    @Published var fullArticlesCache: [CryptoNewsArticle] = []

    private let service = CryptoNewsService()

    /// Fetch only preview articles for quick display
    func loadPreview() {
        errorMessage = nil
        displayedArticles = []
        Task {
            let previews = await service.fetchPreviewNews()
            await MainActor.run {
                displayedArticles = previews
            }
        }
    }

    /// Fetch all articles and cache, then show first page
    func loadFullArticles() {
        errorMessage = nil
        Task {
            isLoadingFull = true
            let all = await service.fetchLatestNews()
            await MainActor.run {
                fullArticlesCache = all
                displayedArticles = Array(all.prefix(pageSize))
                currentPage = 1
                isLoadingFull = false
            }
        }
    }

    func loadNextPage() async {
        guard !isLoadingFull else { return }
        isLoadingFull = true
        let start = currentPage * pageSize
        let nextSlice = Array(fullArticlesCache.dropFirst(start).prefix(pageSize))
        await MainActor.run {
            displayedArticles += nextSlice
            if !nextSlice.isEmpty {
                currentPage += 1
            }
            isLoadingFull = false
        }
    }

    func toggleBookmark(_ article: CryptoNewsArticle) {
        if let idx = bookmarks.firstIndex(where: { $0.id == article.id }) {
            bookmarks.remove(at: idx)
        } else {
            bookmarks.append(article)
        }
    }
    func isBookmarked(_ article: CryptoNewsArticle) -> Bool {
        bookmarks.contains(where: { $0.id == article.id })
    }
    func toggleRead(_ article: CryptoNewsArticle) {
        if readArticles.contains(article.id) {
            readArticles.remove(article.id)
        } else {
            readArticles.insert(article.id)
        }
    }
    func isRead(_ article: CryptoNewsArticle) -> Bool {
        readArticles.contains(article.id)
    }
}

// MARK: -- Row

struct CryptoNewsRow: View {
    @EnvironmentObject var viewModel: CryptoNewsFeedViewModel
    let article: CryptoNewsArticle

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CachingAsyncImage(url: article.urlToImage)
                .frame(width: 100, height: 60)
                .cornerRadius(6)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                Text("\(article.source.name) • \(article.publishedAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title), source: \(article.source.name), published: \(fullDateFormatter.string(from: article.publishedAt))")
        .swipeActions(edge: .leading) {
            Button {
                viewModel.toggleRead(article)
            } label: {
                Label(viewModel.isRead(article) ? "Mark Unread" : "Mark Read",
                      systemImage: viewModel.isRead(article) ? "envelope.open" : "envelope.badge")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                viewModel.toggleBookmark(article)
            } label: {
                Image(systemName: viewModel.isBookmarked(article) ? "bookmark.fill" : "bookmark")
                    .font(.title2)
                    .accessibilityLabel(viewModel.isBookmarked(article) ? "Remove Bookmark" : "Bookmark")
            }
            .tint(.orange)
            
            Button {
                UIPasteboard.general.url = article.url
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.title2)
                    .accessibilityLabel("Copy Link")
            }
            .tint(.gray)
            
            Button {
                UIApplication.shared.open(article.url)
            } label: {
                Image(systemName: "safari")
                    .font(.title2)
                    .accessibilityLabel("Open in Safari")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button { UIApplication.shared.open(article.url) }
                label: { Label("Open in Safari", systemImage: "safari") }
            Button { UIPasteboard.general.url = article.url }
                label: { Label("Copy Link", systemImage: "doc.on.doc") }
            ShareLink(item: article.url) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .padding(.vertical, 8)
    }
}


