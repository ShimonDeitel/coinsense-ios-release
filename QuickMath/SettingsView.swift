import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                Form {
                    // Pro section
                    Section {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Coinsense Pro — Active")
                                    .font(.headline)
                            }
                            Button("Manage Subscription") {
                                openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                            }
                            .foregroundStyle(Color.qmAccent)
                        } else {
                            Button {
                                showPaywall = true
                                Haptics.tap()
                            } label: {
                                HStack {
                                    Image(systemName: "lock.open.fill")
                                        .foregroundStyle(Color.qmAccent)
                                    Text("Unlock Coinsense Pro")
                                        .font(.headline)
                                        .foregroundStyle(Color.qmAccent)
                                }
                            }
                            Button("Restore Purchases") {
                                Haptics.tap()
                                Task { await store.restore() }
                            }
                            .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Pro")
                    }

                    // Appearance section
                    Section {
                        Picker("Appearance", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.label).tag(theme.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Appearance")
                    }

                    // Links section
                    Section {
                        Button("Privacy Policy") {
                            openURL(URL(string: "https://shimondeitel.github.io/coinsense-site/privacy.html")!)
                        }
                        .foregroundStyle(Color.qmAccent)
                        Button("Terms of Use") {
                            openURL(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        }
                        .foregroundStyle(Color.qmAccent)
                    } header: {
                        Text("Legal")
                    }

                    // Data section
                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete All Data")
                        }
                    } header: {
                        Text("Data")
                    } footer: {
                        Text("This removes all lesson history and streaks. This action cannot be undone.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(store)
        }
        .alert("Delete All Data", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                appModel.deleteAllData()
                Haptics.warning()
            }
        } message: {
            Text("All lesson history, streaks, and saved lessons will be permanently deleted.")
        }
    }
}
