import SwiftUI
import SwiftData

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var showLesson = false

    var body: some View {
        ZStack {
            QMBackground()
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header greeting
                        headerSection

                        // Today's lesson card
                        if let lesson = appModel.todayLesson {
                            todayCard(lesson: lesson)
                        }

                        // Streak metrics
                        streakRow

                        // Pro feature tile
                        proTile

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(Color.qmAccent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView().environmentObject(store).environmentObject(appModel) }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(store) }
        .sheet(isPresented: $showInsights) { InsightsView().environmentObject(appModel).environmentObject(store) }
        .sheet(isPresented: $showLesson) {
            if let lesson = appModel.todayLesson {
                LessonDetailView(lesson: lesson)
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
        }
        .onAppear { handleForceScreen() }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Your Money Lesson")
                    .font(.title2.weight(.bold))
            }
            Spacer()
            // Streak badge
            if let prog = appModel.progress, prog.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.qmAccent)
                    Text("\(prog.currentStreak)")
                        .font(.headline.weight(.bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.qmCard, in: Capsule())
            }
        }
        .padding(.top, 8)
    }

    private func todayCard(lesson: DailyLesson) -> some View {
        Button {
            showLesson = true
            Haptics.tap()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(lesson.topic.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.qmAccent)
                    Spacer()
                    if lesson.isPremium && !store.isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if appModel.todayReadLog != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.qmCorrect)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
                    }
                }
                Text(lesson.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(lesson.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(appModel.todayReadLog != nil ? "Read today" : "Tap to read")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(appModel.todayReadLog != nil ? Color.qmCorrect : Color.qmAccent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var streakRow: some View {
        HStack(spacing: 12) {
            MetricTile(
                value: "\(appModel.progress?.currentStreak ?? 0)",
                label: "day streak"
            )
            MetricTile(
                value: "\(appModel.progress?.longestStreak ?? 0)",
                label: "longest"
            )
            MetricTile(
                value: "\(appModel.readLogs.count)",
                label: "lessons read"
            )
        }
    }

    private var proTile: some View {
        Button {
            Haptics.tap()
            if store.isPro {
                showInsights = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: store.isPro ? "chart.bar.xaxis" : "lock.open.fill")
                    .font(.title3)
                    .foregroundStyle(Color.qmAccent)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.isPro ? "Your Insights" : "Unlock Coinsense Pro")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(store.isPro ? "Streaks, history & deep dives" : "Full catalog, streaks & daily reminders")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func handleForceScreen() {
        guard let screen = forceScreen else { return }
        switch screen {
        case "paywall": showPaywall = true
        case "insights": showInsights = true
        case "settings": showSettings = true
        case "lesson": showLesson = true
        default: break
        }
    }
}
