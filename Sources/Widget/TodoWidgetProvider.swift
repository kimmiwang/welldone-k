import SwiftUI
import WidgetKit

// MARK: - Widget Timeline Provider
struct TodoWidgetProvider: TimelineProvider {
    typealias Entry = TodoWidgetEntry

    func placeholder(in context: Context) -> TodoWidgetEntry {
        TodoWidgetEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoWidgetEntry) -> Void) {
        completion(TodoWidgetEntry.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoWidgetEntry>) -> Void) {
        let store = WidgetDataProvider.shared
        let entry = TodoWidgetEntry(
            date: Date(),
            weekDays: WeekHelper.currentWeek(),
            todayTasks: store.todayTasks,
            overdueTasks: store.overdueTasks,
            topInventory: store.topInventoryTasks(limit: 5),
            completedToday: store.completedTodayCount,
            totalToday: store.totalTodayCount
        )

        // 每 30 分钟刷新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry
struct TodoWidgetEntry: TimelineEntry {
    let date: Date
    let weekDays: [WeekDay]
    let todayTasks: [TodoItem]
    let overdueTasks: [TodoItem]
    let topInventory: [TodoItem]
    let completedToday: Int
    let totalToday: Int

    static var placeholder: TodoWidgetEntry {
        TodoWidgetEntry(
            date: Date(),
            weekDays: WeekHelper.currentWeek(),
            todayTasks: [
                TodoItem(title: "完成周报", category: .work, completionCount: 12),
                TodoItem(title: "阅读 30 分钟", category: .study, completionCount: 24),
                TodoItem(title: "跑步 5 公里", category: .life, completionCount: 18),
            ],
            overdueTasks: [
                TodoItem(title: "提交方案", category: .work, state: .overdue, completionCount: 3),
            ],
            topInventory: [
                TodoItem(title: "买菜做饭", category: .life, completionCount: 30),
                TodoItem(title: "阅读 30 分钟", category: .study, completionCount: 24),
                TodoItem(title: "背单词", category: .study, completionCount: 22),
            ],
            completedToday: 1,
            totalToday: 3
        )
    }
}

// MARK: - Widget Data Provider (Shared Container)
class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    private let storageKey = "com.systematic.todo.items"
    private let suiteName = "group.com.systematic.todo"
    private let decoder = JSONDecoder()

    private var items: [TodoItem] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: storageKey),
              let decoded = try? decoder.decode([TodoItem].self, from: data) else {
            return TodoStore.sampleData()
        }
        return decoded
    }

    var todayTasks: [TodoItem] {
        items.filter { item in
            guard let date = item.scheduledDate else { return false }
            return Calendar.current.isDateInToday(date) && item.state != .overdue
        }
    }

    var overdueTasks: [TodoItem] {
        items.filter { $0.state == .overdue }
    }

    func topInventoryTasks(limit: Int) -> [TodoItem] {
        Array(items.sorted { $0.completionCount > $1.completionCount }.prefix(limit))
    }

    var completedTodayCount: Int {
        todayTasks.filter { $0.state == .completed }.count
    }

    var totalTodayCount: Int {
        todayTasks.count
    }
}
