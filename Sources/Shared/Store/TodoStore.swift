import Foundation

// MARK: - Todo Store (Data Layer)
/// 负责任务的 CRUD 与持久化
/// 在生产环境中应使用 Core Data + CloudKit，这里使用 UserDefaults + JSON 作为轻量实现
@MainActor
final class TodoStore: ObservableObject {
    @Published var items: [TodoItem] = []

    private let storageKey = "com.systematic.todo.items"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// App Group identifier (Widget 与 App 共享)
    private let suiteName = "group.com.systematic.todo"

    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    init() {
        load()
        processOverdueTasks()
    }

    // MARK: - CRUD
    func add(_ item: TodoItem) {
        items.append(item)
        save()
    }

    func update(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        save()
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func deleteItems(at offsets: IndexSet, from source: [TodoItem]) {
        let idsToDelete = offsets.map { source[$0].id }
        items.removeAll { idsToDelete.contains($0.id) }
        save()
    }

    // MARK: - State Transitions
    func toggleComplete(_ item: TodoItem) {
        guard var mutable = items.first(where: { $0.id == item.id }) else { return }
        let action: TaskAction = mutable.state == .completed ? .uncomplete : .complete
        mutable.apply(action: action)
        update(mutable)
    }

    func reschedule(_ item: TodoItem, to date: Date) {
        guard var mutable = items.first(where: { $0.id == item.id }) else { return }
        mutable.scheduledDate = Calendar.current.startOfDay(for: date)
        if mutable.state == .overdue {
            mutable.apply(action: .reschedule)
        }
        mutable.updatedAt = Date()
        update(mutable)
    }

    func scheduleFromInventory(_ item: TodoItem, to date: Date) {
        // 创建一个副本安排到具体日期
        var scheduled = item
        scheduled.scheduledDate = Calendar.current.startOfDay(for: date)
        scheduled.state = .pending
        scheduled.updatedAt = Date()
        update(scheduled)
    }

    // MARK: - Overdue Processing (00:00 Cron)
    func processOverdueTasks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for index in items.indices {
            if let scheduled = items[index].scheduledDate,
               scheduled < today,
               items[index].state == .pending {
                items[index].apply(action: .markOverdue)
            }
        }
        save()
    }

    // MARK: - Queries
    /// 获取指定日期的任务
    func tasks(for date: Date) -> [TodoItem] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return items.filter { item in
            guard let scheduled = item.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: targetDay) &&
                   item.state != .overdue
        }
    }

    /// 获取所有逾期任务（Backlog）
    var overdueTasks: [TodoItem] {
        items.filter { $0.state == .overdue }
    }

    /// 素材库（所有任务定义，按完成频率降序）
    var inventoryTasks: [TodoItem] {
        items.sorted { $0.completionCount > $1.completionCount }
    }

    /// 按分类筛选素材库
    func inventoryTasks(category: TaskCategory?) -> [TodoItem] {
        let base = inventoryTasks
        guard let category = category else { return base }
        return base.filter { $0.category == category }
    }

    /// 本周所有已安排任务数
    var weeklyScheduledCount: Int {
        let week = WeekHelper.currentWeek()
        guard let start = week.first?.date, let end = week.last?.date else { return 0 }
        return items.filter { item in
            guard let date = item.scheduledDate else { return false }
            return date >= start && date <= Calendar.current.date(byAdding: .day, value: 1, to: end)!
        }.count
    }

    /// 本周已完成任务数
    var weeklyCompletedCount: Int {
        let week = WeekHelper.currentWeek()
        guard let start = week.first?.date, let end = week.last?.date else { return 0 }
        return items.filter { item in
            guard let date = item.scheduledDate else { return false }
            return date >= start &&
                   date <= Calendar.current.date(byAdding: .day, value: 1, to: end)! &&
                   item.state == .completed
        }.count
    }

    // MARK: - Persistence
    private func save() {
        guard let data = try? encoder.encode(items) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? decoder.decode([TodoItem].self, from: data) else {
            // 首次启动，生成示例数据
            items = Self.sampleData()
            save()
            return
        }
        items = decoded
    }

    // MARK: - Sample Data
    static func sampleData() -> [TodoItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return [
            TodoItem(title: "完成周报", category: .work, scheduledDate: today, completionCount: 12),
            TodoItem(title: "阅读 30 分钟", category: .study, scheduledDate: today, completionCount: 24),
            TodoItem(title: "跑步 5 公里", category: .life, scheduledDate: today, completionCount: 18),
            TodoItem(title: "整理邮件", category: .work,
                     scheduledDate: calendar.date(byAdding: .day, value: 1, to: today),
                     completionCount: 8),
            TodoItem(title: "LeetCode 刷题", category: .study,
                     scheduledDate: calendar.date(byAdding: .day, value: 1, to: today),
                     completionCount: 15),
            TodoItem(title: "团队会议", category: .work,
                     scheduledDate: calendar.date(byAdding: .day, value: 2, to: today),
                     completionCount: 20),
            TodoItem(title: "买菜做饭", category: .life,
                     scheduledDate: calendar.date(byAdding: .day, value: 2, to: today),
                     completionCount: 30),
            TodoItem(title: "代码审查", category: .work, completionCount: 10),
            TodoItem(title: "背单词", category: .study, completionCount: 22),
            TodoItem(title: "冥想 10 分钟", category: .life, completionCount: 16),
            TodoItem(title: "写技术博客", category: .study, completionCount: 5),
            TodoItem(title: "健身", category: .life, completionCount: 14),
            TodoItem(title: "复盘笔记", category: .other, completionCount: 7),
            // 逾期任务示例
            TodoItem(title: "提交方案", category: .work, state: .overdue,
                     scheduledDate: calendar.date(byAdding: .day, value: -1, to: today),
                     completionCount: 3),
            TodoItem(title: "预约体检", category: .life, state: .overdue,
                     scheduledDate: calendar.date(byAdding: .day, value: -2, to: today),
                     completionCount: 1),
        ]
    }
}
