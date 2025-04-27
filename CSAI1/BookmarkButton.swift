//
//  BookmarkButton.swift
//  CSAI1
//
//  Created by DM on 4/26/25.
//


import SwiftUI

/// A reusable bookmark button for navigating to the BookmarksView.
struct BookmarkButton: View {
    @EnvironmentObject var viewModel: CryptoNewsFeedViewModel

    var body: some View {
        NavigationLink(destination: AllCryptoNewsView()
            .environmentObject(viewModel)) {
            Image(systemName: "bookmark")
        }
    }
}
