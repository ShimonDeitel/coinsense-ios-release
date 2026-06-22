import SwiftUI
import SwiftData

struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 0) {
                    // Tab picker
                    Picker("Section", selection: $selectedTab) {
                        Text("Progress").tag(0)
                        Text("Library").tag(1)
                        Text("Catalog").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Divider()

                    switch selectedTab {
                    case 0: progressTab
                    case 1: libraryTab
                    default: catalogTabView
                    }
                }
            }
            .navigationTitle("Your Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }

    // MARK: - Progress Tab

    private var progressTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Streak cards
                HStack(spacing: 12) {
                    MetricTile(
                        value: "\(appModel.progress?.currentStreak ?? 0)",
                        label: "current streak"
                    )
                    MetricTile(
                        value: "\(appModel.progress?.longestStreak ?? 0)",
                        label: "longest streak"
                    )
                }

                HStack(spacing: 12) {
                    MetricTile(
                        value: "\(appModel.readLogs.count)",
                        label: "lessons read"
                    )
                    MetricTile(
                        value: "\(appModel.savedLessons.count)",
                        label: "saved"
                    )
                }

                // Last read date
                if let lastDate = appModel.progress?.lastReadDate {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LAST LESSON")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(lastDate.formatted(date: .long, time: .omitted))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .qmCard()
                }

                // Topic breakdown
                topicBreakdown

                // Recent history
                recentHistory

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private var topicBreakdown: some View {
        let topicCounts = Dictionary(grouping: appModel.readLogs) { log in
            appModel.allLessons.first(where: { $0.id == log.lessonID })?.topic ?? "Other"
        }.mapValues { $0.count }

        let sorted = topicCounts.sorted { $0.value > $1.value }

        return VStack(alignment: .leading, spacing: 12) {
            Text("TOPICS COVERED")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if sorted.isEmpty {
                Text("Read your first lesson to see topic progress.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sorted, id: \.key) { topic, count in
                    HStack {
                        Text(topic)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count) lesson\(count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .qmCard()
    }

    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT HISTORY")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            let recent = appModel.readLogs.prefix(10)
            if recent.isEmpty {
                Text("No lessons read yet. Start today!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(recent), id: \.id) { log in
                    let lessonTitle = appModel.allLessons.first(where: { $0.id == log.lessonID })?.title ?? log.lessonID
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.qmCorrect)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lessonTitle)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(log.readDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if log.savedToLibrary {
                            Image(systemName: "bookmark.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.qmAccent)
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .qmCard()
    }

    // MARK: - Library Tab

    private var libraryTab: some View {
        Group {
            if appModel.savedLessons.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "bookmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No saved lessons yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Tap the bookmark icon while reading a lesson to save it here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                List {
                    ForEach(appModel.savedLessons) { lesson in
                        savedLessonRow(lesson: lesson)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @State private var selectedLesson: DailyLesson?

    private func savedLessonRow(lesson: DailyLesson) -> some View {
        Button {
            selectedLesson = lesson
            Haptics.tap()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(Color.qmAccent)
                    .font(.subheadline)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.topic.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.qmAccent)
                    Text(lesson.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(lesson.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .sheet(item: $selectedLesson) { l in
            LessonDetailView(lesson: l)
                .environmentObject(appModel)
                .environmentObject(store)
        }
    }

    // MARK: - Catalog Tab (bonus deep-dive lessons)

    private var catalogTabView: some View {
        CatalogView()
            .environmentObject(appModel)
            .environmentObject(store)
    }
}
