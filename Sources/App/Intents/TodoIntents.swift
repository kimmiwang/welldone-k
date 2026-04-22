import AppIntents
import WidgetKit

// MARK: - Toggle Task Intent
/// App Intent: 在小组件内直接切换任务完成状态（无需跳转 App）
struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "切换任务状态"
    static var description: IntentDescription = "在小组件中直接完成或取消完成一个任务"

    @Parameter(title: "任务 ID")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        let store = WidgetDataProvider.shared
        // 在实际实现中，这里会通过 App Group 共享 UserDefaults 来更新数据
        // 并触发 WidgetCenter.shared.reloadTimelines(ofKind: "SystematicTodoWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "SystematicTodoWidget")
        return .result()
    }
}

// MARK: - Add Quick Task Intent
/// App Intent: 快速添加任务
struct AddQuickTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "快速添加任务"
    static var description: IntentDescription = "快速向今天添加一个新任务"

    @Parameter(title: "任务标题")
    var title: String

    @Parameter(title: "分类")
    var categoryRaw: String?

    init() {}

    init(title: String, category: TaskCategory = .other) {
        self.title = title
        self.categoryRaw = category.rawValue
    }

    func perform() async throws -> some IntentResult {
        let category = TaskCategory(rawValue: categoryRaw ?? "其他") ?? .other
        let item = TodoItem(
            title: title,
            category: category,
            scheduledDate: Calendar.current.startOfDay(for: Date())
        )
        // 持久化到共享存储
        // 在完整实现中使用 Core Data + CloudKit
        WidgetCenter.shared.reloadTimelines(ofKind: "SystematicTodoWidget")
        return .result()
    }
}

// MARK: - Reschedule Task Intent
/// App Intent: 将逾期任务重新安排到指定日期
struct RescheduleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "重新安排任务"
    static var description: IntentDescription = "将逾期任务移动到新的日期"

    @Parameter(title: "任务 ID")
    var taskID: String

    @Parameter(title: "目标日期")
    var targetDate: Date

    init() {}

    init(taskID: String, targetDate: Date) {
        self.taskID = taskID
        self.targetDate = targetDate
    }

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "SystematicTodoWidget")
        return .result()
    }
}

// MARK: - App Shortcuts Provider
struct TodoShortcutsProvider: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddQuickTaskIntent(),
            phrases: [
                "添加待办到 \(.applicationName)",
                "在 \(.applicationName) 中新建任务"
            ],
            shortTitle: "快速添加任务",
            systemImageName: "plus.circle.fill"
        )
    }
}
