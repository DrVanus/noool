import SwiftUI
import SafariServices

// MARK: - List View (unchanged)
private struct CryptoNewsListView: View {
    @ObservedObject var viewModel: CryptoNewsFeedViewModel
    @Binding var showingSafari: Bool
    @Binding var selectedArticleURL: URL?
    @Binding var searchText: String

    var body: some View {
        List {
            if filteredArticles.isEmpty {
                ProgressView("Loading news…")
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(groupedArticles, id: \.key) { section in
                    Section(header: Text(section.key)) {
                        ForEach(section.value, id: \.url) { article in
                            ArticleRowView(
                                article: article,
                                showingSafari: $showingSafari,
                                selectedArticleURL: $selectedArticleURL
                            )
                            .environmentObject(viewModel)
                            .onAppear {
                                if article.url == viewModel.displayedArticles.last?.url {
                                    Task { await viewModel.loadNextPage() }
                                }
                            }
                        }
                    }
                }
                if viewModel.isLoadingFull {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(PlainListStyle())
        .padding(.top, 0)
        .background(Color(.systemBackground))
        .accentColor(.primary)
        .refreshable {
            await viewModel.loadFullArticles()
            await viewModel.loadNextPage()
        }
        .sheet(isPresented: $showingSafari) {
            if let url = selectedArticleURL {
                SafariView(url: url)
            }
        }
    }

    private var filteredArticles: [CryptoNewsArticle] {
        guard !searchText.isEmpty else { return viewModel.displayedArticles }
        return viewModel.displayedArticles.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.source.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedArticles: [(key: String, value: [CryptoNewsArticle])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filteredArticles) { article -> String in
            if cal.isDateInToday(article.publishedAt) { return "Today" }
            if cal.isDateInYesterday(article.publishedAt) { return "Yesterday" }
            return "Earlier"
        }
        return ["Today","Yesterday","Earlier"].compactMap { key in
            dict[key].map { (key: key, value: $0) }
        }
    }
}

// MARK: - Hosting View with Native UISearchController
struct AllCryptoNewsView: View {
    @StateObject private var viewModel = CryptoNewsFeedViewModel()
    @State private var showingSafari = false
    @State private var selectedArticleURL: URL?
    @State private var searchText = ""

    var body: some View {
        // Use the parent navigation stack’s bar
        CryptoNewsListView(
            viewModel: viewModel,
            showingSafari: $showingSafari,
            selectedArticleURL: $selectedArticleURL,
            searchText: $searchText
        )
        .navigationTitle("All Crypto News")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            NavigationLink(destination: BookmarksView()
                .environmentObject(viewModel)
            ) {
                Image(systemName: "bookmark")
            }
        )
        .background(
            NavSearchConfigurator(text: $searchText,
                                 placeholder: "Search articles")
        )
        .task {
            // Preview first, then full list and pagination
            await viewModel.loadPreview()
            await viewModel.loadFullArticles()
            await viewModel.loadNextPage()
        }
    }
}

// Inject UISearchController into the navigation bar
fileprivate struct NavSearchConfigurator: UIViewControllerRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let search = UISearchController(searchResultsController: nil)
        search.searchBar.placeholder = placeholder
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.delegate = context.coordinator
        vc.navigationItem.searchController = search
        vc.view.backgroundColor = .clear
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        uiViewController.navigationItem.searchController?.searchBar.text = text
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        init(text: Binding<String>) { _text = text }
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }
}

// MARK: - Article Row (unchanged)
private struct ArticleRowView: View {
    let article: CryptoNewsArticle
    @EnvironmentObject var viewModel: CryptoNewsFeedViewModel
    @Binding var showingSafari: Bool
    @Binding var selectedArticleURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let imgURL = article.urlToImage {
                AsyncImage(url: imgURL) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 75, height: 75)
                .cornerRadius(8)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 75, height: 75)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let desc = article.description {
                    let plain = desc
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !plain.isEmpty {
                        Text(plain)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }

                HStack(spacing: 6) {
                    if let host = URL(string: article.url.absoluteString)?.host,
                       let iconURL = URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico") {
                        AsyncImage(url: iconURL) { phase in
                            if let img = phase.image {
                                img.resizable().scaledToFit()
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        }
                        .frame(width: 16, height: 16)
                        .cornerRadius(2)
                    }

                    Text(article.source.name)
                    Text("•")
                    Text(article.publishedAt, style: .relative)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedArticleURL = article.url
            showingSafari = true
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button {
                selectedArticleURL = article.url
                showingSafari = true
            } label: {
                Label("Open in Safari", systemImage: "safari")
            }
            Button {
                viewModel.toggleBookmark(article)
            } label: {
                Label(
                    viewModel.bookmarks.contains(where: { $0.url == article.url }) ?
                        "Remove Bookmark" : "Bookmark",
                    systemImage: viewModel.bookmarks.contains(where: { $0.url == article.url }) ?
                        "bookmark.slash" : "bookmark"
                )
            }
            ShareLink(item: article.url) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                viewModel.toggleBookmark(article)
            } label: {
                Label("Bookmark", systemImage: "bookmark")
            }
            .tint(.blue)

            Button {
                selectedArticleURL = article.url
                showingSafari = true
            } label: {
                Label("Open", systemImage: "safari")
            }
            .tint(.green)
        }
    }
}

// MARK: - Bookmark Row (no swipe actions)
private struct BookmarkRowView: View {
    let article: CryptoNewsArticle
    @EnvironmentObject var viewModel: CryptoNewsFeedViewModel
    @Binding var showingSafari: Bool
    @Binding var selectedArticleURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // thumbnail
            if let imgURL = article.urlToImage {
                AsyncImage(url: imgURL) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 75, height: 75)
                .cornerRadius(8)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 75, height: 75)
                    .cornerRadius(8)
            }

            // title & metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                if let desc = article.description {
                    let plain = desc
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !plain.isEmpty {
                        Text(plain)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                HStack(spacing: 6) {
                    Text(article.source.name)
                    Text("•")
                    Text(article.publishedAt, style: .relative)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedArticleURL = article.url
            showingSafari = true
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Safari & Bookmarks (unchanged)
private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct BookmarksView: View {
    @EnvironmentObject var viewModel: CryptoNewsFeedViewModel
    @State private var showingSafari = false
    @State private var selectedArticleURL: URL?

    var body: some View {
        List {
            ForEach(viewModel.bookmarks, id: \.url) { article in
                BookmarkRowView(
                    article: article,
                    showingSafari: $showingSafari,
                    selectedArticleURL: $selectedArticleURL
                )
                .environmentObject(viewModel)
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Bookmarks")
        .sheet(isPresented: $showingSafari) {
            if let url = selectedArticleURL {
                SafariView(url: url)
            }
        }
    }
}
