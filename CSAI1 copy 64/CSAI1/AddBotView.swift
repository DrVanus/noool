import SwiftUI

// Define a unique model for this file to avoid duplicate declarations
struct LocalBot: Identifiable, Codable {
    let id: Int
    let name: String
    let exchange: String
    let strategy: String
    let status: String
    let basePair: String
    let totalProfit: Double
    let dailyProfitPercent: Double
    let runningTimeDays: Int
}

struct AddBotView: View {
    // Local state for the new bot’s properties.
    @State private var name: String = ""
    @State private var exchange: String = ""
    @State private var type: String = ""
    @State private var basePair: String = ""
    
    // onSave passes a LocalBot instance back to the caller.
    let onSave: (LocalBot) -> Void
    
    // Environment dismiss variable to close the view.
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bot Info")) {
                    TextField("Bot Name", text: $name)
                    TextField("Exchange", text: $exchange)
                    TextField("Type (e.g., DCA, Grid)", text: $type)
                    TextField("Base Pair (e.g., BTC_USDT)", text: $basePair)
                }
            }
            .navigationTitle("Add Bot")
            .toolbar {
                // Cancel Button.
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                // Save Button.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newBot = LocalBot(
                            id: Int.random(in: 1000...9999), // Example random ID.
                            name: name,
                            exchange: exchange,
                            strategy: type, // Using "type" as the strategy.
                            status: "Active",
                            basePair: basePair,
                            totalProfit: 0.0,
                            dailyProfitPercent: 0.0,
                            runningTimeDays: 0
                        )
                        onSave(newBot)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddBotView_Previews: PreviewProvider {
    static var previews: some View {
        AddBotView { bot in
            print("Added bot: \(bot.name)")
        }
    }
}
