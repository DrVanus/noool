//
//  ExtendedFearGreedViewModel.swift
//  CSAI1
//
//  Created by ChatGPT on 3/27/25
//

import Foundation
import Combine

// MARK: - Data Models

struct FearGreedData: Decodable {
    let value: String
    let valueClassification: String
    let timestamp: String?  // Optional if available

    enum CodingKeys: String, CodingKey {
        case value
        case valueClassification = "value_classification"
        case timestamp
    }
}

struct FearGreedResponse: Decodable {
    let data: [FearGreedData]
}

// MARK: - Extended ViewModel

class ExtendedFearGreedViewModel: ObservableObject {
    @Published var data: [FearGreedData] = []
    @Published var currentValue: Int = 0
    @Published var currentLabel: String = "Neutral"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lastMonthData: FearGreedData?

    private var cancellables = Set<AnyCancellable>()

    // Convenience accessors
    var yesterdayData: FearGreedData? { data.count > 1 ? data[1] : nil }
    var lastWeekData: FearGreedData? { data.count > 6 ? data[6] : nil }

    func fetchData() {
        // Fetch last‑month (30 days) separately
        let monthURL = URL(string: "https://api.alternative.me/fng/?limit=30")!
        URLSession.shared.dataTaskPublisher(for: monthURL)
            .map(\.data)
            .decode(type: FearGreedResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { monthResponse in
                // take the oldest entry in the 30‑day series
                if let monthEntry = monthResponse.data.last {
                    self.lastMonthData = monthEntry
                }
            }
            .store(in: &cancellables)

        guard let url = URL(string: "https://api.alternative.me/fng/?limit=7") else {
            DispatchQueue.main.async { self.errorMessage = "Invalid URL." }
            return
        }
        
        isLoading = true

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .handleEvents(receiveOutput: { rawData in
                if let jsonString = String(data: rawData, encoding: .utf8) {
                    print("Raw Fear & Greed JSON:\n\(jsonString)")
                }
            })
            .decode(type: FearGreedResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                if case let .failure(error) = completion {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            } receiveValue: { response in
                self.data = response.data
                if let latest = response.data.first, let intVal = Int(latest.value) {
                    self.currentValue = intVal
                    self.currentLabel = latest.valueClassification
                } else {
                    self.errorMessage = "Invalid data format received."
                }
                self.errorMessage = nil // Clear any previous error
            }
            .store(in: &cancellables)
    }
}
