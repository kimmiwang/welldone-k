import SwiftUI

// MARK: - Models

enum TaskCategory: String, CaseIterable, Codable, Identifiable {
    case work, life, study, other
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .work: .blue; case .life: .green; case .study: .purple; case .other: .gray
        }
    }
    var icon: String {
        switch self {
        case .work: "🤘🏻"; case .life: "🛀🏻"; case .study: "📖"; case .other: "📦"
        }
    }
    var label: String {
        switch self {
        case .work: "Work"; case .life: "Life"; case .study: "Study"; case .other: "Other"
        }
    }
    static var sortOrder: [TaskCategory] { [.work, .life, .study, .other] }
}

enum TaskState: String, Codable {
    case pending, completed, overdue
}

struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var category: TaskCategory
    var state: TaskState
    var scheduledDate: Date?
    var dueDate: Date?
    var completionCount: Int
    var createdAt: Date

    init(id: UUID = UUID(), title: String, category: TaskCategory = .other,
         state: TaskState = .pending, scheduledDate: Date? = nil, dueDate: Date? = nil,
         completionCount: Int = 0, createdAt: Date = Date()) {
        self.id = id; self.title = title; self.category = category; self.state = state
        self.scheduledDate = scheduledDate; self.dueDate = dueDate
        self.completionCount = completionCount; self.createdAt = createdAt
    }
}

// MARK: - Store

@MainActor
final class TodoStore: ObservableObject {
    @Published var tasks: [TodoItem] = []
    @Published var countdown = CountdownData()

    private let tasksKey = "wdk_tasks"
    private let countdownKey = "wdk_countdown"
    private let defaults: UserDefaults

    struct CountdownData: Codable {
        var label = "Vacation"
        var targetDate = Calendar.current.date(byAdding: .day, value: 11, to: Date())!
        var emoji = "🏖️"
        var daysLeft: Int {
            max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()),
                                                     to: Calendar.current.startOfDay(for: targetDate)).day ?? 0)
        }
    }

    init() {
        defaults = UserDefaults.standard
        load()
        if tasks.isEmpty { tasks = Self.sampleData() }
    }

    // MARK: - Queries
    func tasks(for date: Date) -> [TodoItem] {
        let day = Calendar.current.startOfDay(for: date)
        return tasks.filter {
            guard let s = $0.scheduledDate else { return false }
            return Calendar.current.isDate(s, inSameDayAs: day) && $0.state != .overdue
        }.sorted { TaskCategory.sortOrder.firstIndex(of: $0.category)! < TaskCategory.sortOrder.firstIndex(of: $1.category)! }
    }

    var overdueTasks: [TodoItem] {
        tasks.filter { $0.state == .overdue }
            .sorted { TaskCategory.sortOrder.firstIndex(of: $0.category)! < TaskCategory.sortOrder.firstIndex(of: $1.category)! }
    }

    var inventoryTasks: [TodoItem] {
        tasks.sorted { $0.completionCount > $1.completionCount }
    }

    func weekTasks(for weekStart: Date) -> [TodoItem] {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 7, to: weekStart)!
        return tasks.filter {
            guard let s = $0.scheduledDate else { return false }
            return s >= weekStart && s < end && $0.state != .overdue
        }
    }

    // MARK: - Actions
    func toggleComplete(_ item: TodoItem) {
        guard let i = tasks.firstIndex(where: { $0.id == item.id }) else { return }
        if tasks[i].state == .completed {
            tasks[i].state = .pending
        } else {
            tasks[i].state = .completed
            tasks[i].completionCount += 1
        }
        save()
    }

    func add(_ item: TodoItem) { tasks.append(item); save() }

    func delete(_ item: TodoItem) { tasks.removeAll { $0.id == item.id }; save() }

    func reschedule(_ item: TodoItem, to date: Date) {
        guard let i = tasks.firstIndex(where: { $0.id == item.id }) else { return }
        tasks[i].scheduledDate = Calendar.current.startOfDay(for: date)
        if tasks[i].state == .overdue { tasks[i].state = .pending }
        save()
    }

    /// Duplicate from attic to a specific day (attic item stays, freq +1)
    func scheduleFromAttic(_ item: TodoItem, to date: Date) {
        // Increment frequency on the original attic item
        if let i = tasks.firstIndex(where: { $0.id == item.id }) {
            tasks[i].completionCount += 1
        }
        // Create a new copy scheduled to that day
        let copy = TodoItem(title: item.title, category: item.category,
                            scheduledDate: Calendar.current.startOfDay(for: date))
        tasks.append(copy)
        save()
    }

    func processOverdue() {
        let today = Calendar.current.startOfDay(for: Date())
        for i in tasks.indices {
            if let s = tasks[i].scheduledDate, s < today, tasks[i].state == .pending {
                tasks[i].state = .overdue
                tasks[i].dueDate = tasks[i].scheduledDate
            }
        }
        save()
    }

    // MARK: - Persistence
    func save() {
        if let d = try? JSONEncoder().encode(tasks) { defaults.set(d, forKey: tasksKey) }
        if let d = try? JSONEncoder().encode(countdown) { defaults.set(d, forKey: countdownKey) }
    }

    private func load() {
        if let d = defaults.data(forKey: tasksKey), let t = try? JSONDecoder().decode([TodoItem].self, from: d) { tasks = t }
        if let d = defaults.data(forKey: countdownKey), let c = try? JSONDecoder().decode(CountdownData.self, from: d) { countdown = c }
    }

    static func sampleData() -> [TodoItem] {
        let cal = Calendar.current; let today = cal.startOfDay(for: Date())
        let mon = cal.date(byAdding: .day, value: -(cal.component(.weekday, from: today) + 5) % 7, to: today)!
        func d(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: mon)! }
        return [
            TodoItem(title: "项目启动会", category: .work, state: .completed, scheduledDate: d(0), completionCount: 5),
            TodoItem(title: "阅读 30 分钟", category: .study, state: .completed, scheduledDate: d(0), completionCount: 24),
            TodoItem(title: "跑步 5 公里", category: .life, state: .completed, scheduledDate: d(1), completionCount: 18),
            TodoItem(title: "代码审查", category: .work, scheduledDate: d(1), completionCount: 10),
            TodoItem(title: "团队会议", category: .work, state: .completed, scheduledDate: d(2), completionCount: 20),
            TodoItem(title: "LeetCode 刷题", category: .study, state: .completed, scheduledDate: d(3), completionCount: 15),
            TodoItem(title: "买菜做饭", category: .life, scheduledDate: d(3), completionCount: 30),
            TodoItem(title: "完成周报", category: .work, scheduledDate: d(4), completionCount: 12),
            TodoItem(title: "阅读 30 分钟", category: .study, scheduledDate: d(4), completionCount: 24),
            TodoItem(title: "跑步 5 公里", category: .life, scheduledDate: d(4), completionCount: 18),
            TodoItem(title: "背单词", category: .study, scheduledDate: d(5), completionCount: 22),
            TodoItem(title: "提交方案", category: .work, state: .overdue, scheduledDate: d(-2), dueDate: d(-2), completionCount: 3),
            TodoItem(title: "预约体检", category: .life, state: .overdue, scheduledDate: d(-5), dueDate: d(-5), completionCount: 1),
            // Inventory-only
            TodoItem(title: "冥想 10 分钟", category: .life, completionCount: 16),
            TodoItem(title: "健身", category: .life, completionCount: 14),
        ]
    }
}

// MARK: - Week Helper

struct WeekDay: Identifiable {
    let id: String
    let date: Date
    let num: String
    let name: String
    let isToday: Bool
    let isPast: Bool
}

struct WeekHelper {
    static func week(offset: Int) -> [WeekDay] {
        let cal = Calendar.current; let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let mondayOffset = (weekday == 1 ? -6 : 2 - weekday)
        let monday = cal.date(byAdding: .day, value: mondayOffset + offset * 7, to: today)!
        let names = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        let fmt = DateFormatter(); fmt.dateFormat = "d"
        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i, to: monday)!
            return WeekDay(id: "\(offset)_\(i)", date: d, num: fmt.string(from: d),
                           name: names[i], isToday: cal.isDateInToday(d),
                           isPast: d < today && !cal.isDateInToday(d))
        }
    }

    static func rangeLabel(offset: Int) -> String {
        let days = week(offset: offset)
        let fmt = DateFormatter(); fmt.dateFormat = "M/d"
        return "\(fmt.string(from: days.first!.date)) - \(fmt.string(from: days.last!.date))"
    }
}
