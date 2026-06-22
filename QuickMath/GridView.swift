import SwiftUI
import SwiftData

// MARK: - LessonDetailView (the primary lesson reading screen)

struct LessonDetailView: View {
    let lesson: DailyLesson

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false

    private var isLocked: Bool { lesson.isPremium && !store.isPro }
    private var isReadToday: Bool { appModel.todayReadLog != nil && appModel.todayLesson?.id == lesson.id }
    private var isSaved: Bool { appModel.savedLessons.contains(where: { $0.id == lesson.id }) }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Topic chip
                        Text(lesson.topic.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.qmAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.qmCard, in: Capsule())

                        // Title
                        Text(lesson.title)
                            .font(.title.weight(.bold))
                            .foregroundStyle(.primary)

                        if isLocked {
                            lockedBody
                        } else {
                            // Body
                            Text(lesson.body)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineSpacing(6)

                            Divider()

                            // Action row
                            actionRow
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
                if !isLocked {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            appModel.toggleSaved(lessonID: lesson.id)
                            Haptics.tap()
                        } label: {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(Color.qmAccent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(store)
        }
    }

    private var lockedBody: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.qmAccent)

            Text("This is a Pro lesson")
                .font(.headline)

            Text("Unlock the full back-catalog, bonus deep-dives, and daily reminders with Coinsense Pro.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Unlock Pro") {
                showPaywall = true
                Haptics.tap()
            }
            .prominentButton()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    private var actionRow: some View {
        VStack(spacing: 12) {
            if appModel.todayLesson?.id == lesson.id && !isReadToday {
                Button {
                    appModel.markTodayRead()
                    Haptics.success()
                } label: {
                    Label("Mark as Read", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .prominentButton()
            } else if isReadToday {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.qmCorrect)
                    Text("Completed today")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
            }
        }
    }
}

// MARK: - CatalogView (browse all lessons)

struct CatalogView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @State private var selectedLesson: DailyLesson?
    @State private var showPaywall = false

    private let topics = ["All", "Saving", "Spending", "Investing", "Debt", "Budgeting", "Mindset", "Habits", "Credit"]
    @State private var selectedTopic = "All"

    private var filteredLessons: [DailyLesson] {
        if selectedTopic == "All" { return appModel.allLessons }
        return appModel.allLessons.filter { $0.topic == selectedTopic }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 0) {
                    // Topic filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(topics, id: \.self) { topic in
                                Button(topic) {
                                    selectedTopic = topic
                                    Haptics.tap()
                                }
                                .font(.caption.weight(.medium))
                                .foregroundStyle(selectedTopic == topic ? .white : Color.qmAccent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selectedTopic == topic ? Color.qmAccent : Color.qmCard,
                                    in: Capsule()
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }

                    Divider()

                    List {
                        ForEach(filteredLessons) { lesson in
                            Button {
                                if lesson.isPremium && !store.isPro {
                                    showPaywall = true
                                } else {
                                    selectedLesson = lesson
                                }
                                Haptics.tap()
                            } label: {
                                lessonRow(lesson: lesson)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("All Lessons")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedLesson) { lesson in
            LessonDetailView(lesson: lesson)
                .environmentObject(appModel)
                .environmentObject(store)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(store)
        }
    }

    private func lessonRow(lesson: DailyLesson) -> some View {
        let isRead = appModel.readLogs.contains(where: { $0.lessonID == lesson.id })
        let isSaved = appModel.savedLessons.contains(where: { $0.id == lesson.id })

        return HStack(spacing: 14) {
            // Status indicator
            Circle()
                .fill(isRead ? Color.qmCorrect : Color.qmCard2)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(lesson.topic.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.qmAccent)
                    Spacer()
                    if lesson.isPremium && !store.isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if isSaved {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.qmAccent)
                    }
                }
                Text(lesson.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(lesson.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 10)
    }
}
