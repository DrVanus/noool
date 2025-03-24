import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("darkMode") var darkMode = false
    @AppStorage("baseCurrency") var baseCurrency = "USD"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Dark Mode", isOn: $darkMode)
                    
                    Picker("Base Currency", selection: $baseCurrency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        Text("BTC").tag("BTC")
                    }
                }
                
                Section(header: Text("Profile")) {
                    NavigationLink("Account Info", destination: AccountInfoView())
                    NavigationLink("Security", destination: SecuritySettingsView())
                }
                
                Section {
                    Button("Sign Out") {
                        // handle sign-out
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct AccountInfoView: View {
    var body: some View {
        Text("User account info goes here...")
            .navigationTitle("Account Info")
    }
}

struct SecuritySettingsView: View {
    var body: some View {
        Text("Security settings (PIN, FaceID, 2FA) go here...")
            .navigationTitle("Security")
    }
}
