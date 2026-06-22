import SwiftUI
import SwiftData

// MARK: - SwiftData Models

@Model
final class DailyLesson {
    var id: String
    var dayIndex: Int
    var title: String
    var body: String
    var topic: String
    var isPremium: Bool

    init(id: String, dayIndex: Int, title: String, body: String, topic: String, isPremium: Bool) {
        self.id = id
        self.dayIndex = dayIndex
        self.title = title
        self.body = body
        self.topic = topic
        self.isPremium = isPremium
    }
}

@Model
final class ReadLog {
    var id: String
    var lessonID: String
    var readDate: Date
    var savedToLibrary: Bool

    init(id: String, lessonID: String, readDate: Date, savedToLibrary: Bool = false) {
        self.id = id
        self.lessonID = lessonID
        self.readDate = readDate
        self.savedToLibrary = savedToLibrary
    }
}

@Model
final class LearningProgress {
    var id: String
    var currentStreak: Int
    var longestStreak: Int
    var lastReadDate: Date?

    init(id: String = "main", currentStreak: Int = 0, longestStreak: Int = 0, lastReadDate: Date? = nil) {
        self.id = id
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastReadDate = lastReadDate
    }
}

// MARK: - Lesson catalog

private let lessonCatalog: [(dayIndex: Int, title: String, body: String, topic: String, isPremium: Bool)] = [
    (0, "Pay Yourself First", "Before paying any bill, transfer a fixed amount — even $5 — to savings. Automate it so it happens the moment your paycheck lands. What remains is your real spending budget.", "Saving", false),
    (1, "The Latte Myth, Reframed", "Skipping coffee won't make you rich, but the habit behind it matters. Identifying one small automatic expense and redirecting it builds the muscle of intentional spending.", "Mindset", false),
    (2, "Track Every Dollar for One Week", "You can't improve what you don't measure. Spend one week writing down every purchase — no judgment. Patterns you never noticed will surface instantly.", "Habits", false),
    (3, "The 50/30/20 Rule", "Split take-home pay: 50 % needs, 30 % wants, 20 % savings and debt. It's a starting guide, not a law — adjust the ratios once you have real numbers.", "Budgeting", false),
    (4, "Emergency Fund: Why $1,000 First", "A $1,000 starter emergency fund stops most unexpected expenses from becoming debt. It's not 'three months of expenses' yet — just get to $1,000 first.", "Saving", false),
    (5, "Compound Interest Is Time × Money", "A dollar saved at 25 is worth far more than a dollar saved at 45. The math isn't complicated — start early, leave it alone, and time does the heavy lifting.", "Investing", true),
    (6, "Understanding Net Worth", "Net worth = assets minus liabilities. Knowing this number — even if it's negative — is the starting line. You can't run toward a goal you haven't located.", "Mindset", true),
    (7, "High-Interest Debt Is a Guaranteed Loss", "A 20 % APR credit card means every unpaid dollar costs you 20 cents per year. Paying it off is a guaranteed 20 % return — better than almost any investment.", "Debt", false),
    (8, "The Avalanche vs Snowball Methods", "Avalanche: pay the highest-interest debt first (saves the most money). Snowball: pay the smallest balance first (wins motivational momentum). Both work — pick the one you'll stick to.", "Debt", true),
    (9, "Automate Everything You Can", "Automation removes willpower from the equation. Auto-pay bills on time, auto-invest a fixed amount, auto-save to an emergency fund. Humans fail; schedules don't.", "Habits", false),
    (10, "What a Budget Actually Is", "A budget isn't a restriction — it's a spending plan you write before the month starts. It gives every dollar a job so money stops disappearing without a trace.", "Budgeting", false),
    (11, "Opportunity Cost", "Every dollar spent is a dollar that cannot be invested, saved, or used differently. This isn't guilt — it's the core of intentional spending. Ask: 'Is this the best use of this dollar right now?'", "Mindset", true),
    (12, "The Subscription Audit", "Open your bank statement and highlight every recurring charge. Most people find $50–$150/month in subscriptions they barely use. Cancel the ones that pass a simple test: 'Would I buy this again today?'", "Spending", false),
    (13, "Index Funds in Plain English", "An index fund buys a tiny piece of hundreds of companies at once. You own the whole market, not a bet on one stock. Low fees, automatic diversification, historically strong long-run returns.", "Investing", true),
    (14, "Credit Score Basics", "Your credit score tracks five things: payment history (35 %), amounts owed (30 %), length of history (15 %), new credit (10 %), credit mix (10 %). Pay on time and keep balances low — two rules cover 65 %.", "Credit", false),
    (15, "The Real Cost of a Car", "Sticker price is just the beginning. Add insurance, registration, maintenance, fuel, depreciation, and interest if financed. Total cost of ownership is often 2–3× the purchase price over five years.", "Spending", true),
    (16, "Roth vs Traditional IRA", "Roth: pay tax now, withdraw tax-free later. Traditional: defer tax now, pay later. If you expect to earn more in retirement than now, Roth wins. Uncertainty? Split contributions.", "Investing", true),
    (17, "The 24-Hour Rule", "Before any non-essential purchase over $50, wait 24 hours. Most impulse buys feel much less urgent after a night's sleep. The pause is the point.", "Spending", false),
    (18, "Inflation Erodes Cash", "Cash sitting in a checking account loses roughly 2–4 % of purchasing power per year to inflation. A high-yield savings account or short-term Treasury bill is a simple, low-risk antidote.", "Saving", true),
    (19, "The Magic of Employer Match", "If your employer matches 401(k) contributions, not contributing up to the match is turning down free money. It's an immediate 50–100 % return — always capture it first.", "Investing", false),
]

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var todayLesson: DailyLesson?
    @Published private(set) var todayReadLog: ReadLog?
    @Published private(set) var allLessons: [DailyLesson] = []
    @Published private(set) var readLogs: [ReadLog] = []
    @Published private(set) var savedLessons: [DailyLesson] = []
    @Published private(set) var progress: LearningProgress?

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([DailyLesson.self, ReadLog.self, LearningProgress.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    func reload() {
        let ctx = container.mainContext
        seedLessonsIfNeeded(ctx: ctx)
        fetchAll(ctx: ctx)
    }

    func refresh() { reload() }

    // MARK: - Seeding

    private func seedLessonsIfNeeded(ctx: ModelContext) {
        let existing = (try? ctx.fetch(FetchDescriptor<DailyLesson>())) ?? []
        guard existing.isEmpty else { return }
        for item in lessonCatalog {
            let lesson = DailyLesson(
                id: "lesson_\(item.dayIndex)",
                dayIndex: item.dayIndex,
                title: item.title,
                body: item.body,
                topic: item.topic,
                isPremium: item.isPremium
            )
            ctx.insert(lesson)
        }
        let prog = LearningProgress(id: "main")
        ctx.insert(prog)
        try? ctx.save()
    }

    private func fetchAll(ctx: ModelContext) {
        let lessons = (try? ctx.fetch(FetchDescriptor<DailyLesson>(sortBy: [SortDescriptor(\.dayIndex)]))) ?? []
        allLessons = lessons

        let logs = (try? ctx.fetch(FetchDescriptor<ReadLog>(sortBy: [SortDescriptor(\.readDate, order: .reverse)]))) ?? []
        readLogs = logs

        // Today's lesson = cycled by calendar day-of-year
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % max(1, lessons.count)
        todayLesson = lessons[safe: index]

        // Determine if today's lesson has been read
        let today = Calendar.current.startOfDay(for: Date())
        todayReadLog = logs.first {
            $0.lessonID == todayLesson?.id &&
            Calendar.current.isDate($0.readDate, inSameDayAs: today)
        }

        // Saved lessons
        let savedIDs = Set(logs.filter { $0.savedToLibrary }.map { $0.lessonID })
        savedLessons = lessons.filter { savedIDs.contains($0.id) }

        // Progress
        let allProgress = (try? ctx.fetch(FetchDescriptor<LearningProgress>())) ?? []
        progress = allProgress.first
    }

    // MARK: - Actions

    func markTodayRead() {
        guard let lesson = todayLesson else { return }
        let ctx = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())

        // Check if already logged today
        if todayReadLog != nil { return }

        let log = ReadLog(
            id: UUID().uuidString,
            lessonID: lesson.id,
            readDate: Date()
        )
        ctx.insert(log)

        // Update streak
        updateStreak(ctx: ctx, today: today)

        try? ctx.save()
        reload()
    }

    func toggleSaved(lessonID: String) {
        let ctx = container.mainContext
        let logs = (try? ctx.fetch(FetchDescriptor<ReadLog>())) ?? []
        // Find most recent log for this lesson
        if let log = logs.filter({ $0.lessonID == lessonID }).sorted(by: { $0.readDate > $1.readDate }).first {
            log.savedToLibrary.toggle()
            try? ctx.save()
            reload()
        }
    }

    private func updateStreak(ctx: ModelContext, today: Date) {
        let allProgress = (try? ctx.fetch(FetchDescriptor<LearningProgress>())) ?? []
        guard let prog = allProgress.first else { return }

        let cal = Calendar.current
        if let last = prog.lastReadDate {
            let lastDay = cal.startOfDay(for: last)
            if cal.isDate(lastDay, inSameDayAs: today) {
                // Already counted today — no-op
            } else if let diff = cal.dateComponents([.day], from: lastDay, to: today).day, diff == 1 {
                // Consecutive day
                prog.currentStreak += 1
            } else {
                // Streak broken
                prog.currentStreak = 1
            }
        } else {
            prog.currentStreak = 1
        }
        if prog.currentStreak > prog.longestStreak {
            prog.longestStreak = prog.currentStreak
        }
        prog.lastReadDate = today
    }

    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: DailyLesson.self)
        try? ctx.delete(model: ReadLog.self)
        try? ctx.delete(model: LearningProgress.self)
        try? ctx.save()
        reload()
    }
}

// MARK: - Collection safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
