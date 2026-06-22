import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let benefits = [
        ("books.vertical.fill", "Full back-catalog of past lessons and a saved-favorites library"),
        ("bolt.fill", "Two bonus deep-dive lessons each day and topic playlists"),
        ("bell.badge.fill", "Daily learning reminder and progress insights"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()

                ScrollView {
                    VStack(spacing: 28) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.qmCard)
                                .frame(width: 80, height: 80)
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.qmAccent)
                        }
                        .padding(.top, 32)

                        // Heading
                        VStack(spacing: 8) {
                            Text("Coinsense Pro")
                                .font(.title.weight(.bold))
                            Text("$0.99 / month. Auto-renews until you cancel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Benefits
                        VStack(spacing: 0) {
                            ForEach(Array(benefits.enumerated()), id: \.offset) { _, benefit in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: benefit.0)
                                        .font(.body)
                                        .foregroundStyle(Color.qmAccent)
                                        .frame(width: 24)
                                        .padding(.top, 2)
                                    Text(benefit.1)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .padding(.vertical, 14)

                                if benefit.1 != benefits.last?.1 {
                                    Divider()
                                }
                            }
                        }
                        .qmCard()
                        .padding(.horizontal, 4)

                        // Unlock button
                        Button {
                            Haptics.tap()
                            Task { await store.purchase() }
                        } label: {
                            Group {
                                if store.purchaseInFlight {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Unlock for \(store.displayPrice)/mo")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .disabled(store.purchaseInFlight)
                        .prominentButton()
                        .padding(.horizontal, 4)

                        // Restore
                        Button("Restore Purchases") {
                            Haptics.tap()
                            Task { await store.restore() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        // Auto-renew disclosure
                        Text("Subscription automatically renews for \(store.displayPrice) per month unless cancelled at least 24 hours before the end of the current period. Cancel anytime in your Apple ID subscription settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)

                        // Terms & Privacy links
                        HStack(spacing: 20) {
                            Button("Terms of Use") {
                                openURL(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            }
                            Text("·")
                                .foregroundStyle(.secondary)
                            Button("Privacy Policy") {
                                openURL(URL(string: "https://shimondeitel.github.io/coinsense-site/privacy.html")!)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Color.qmAccent)

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
        .onChange(of: store.isPro) { _, newValue in
            if newValue { dismiss() }
        }
    }
}
