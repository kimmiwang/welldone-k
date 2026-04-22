import Foundation

// MARK: - Core Data Model (Plain Swift Mirror)
/// 任务数据模型
struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var category: TaskCategory
    var state: TaskState
    var scheduledDate: Date?          // 被安排到哪一天（nil = 仅在素材库中）
    var completionCount: Int           // 历史完成次数（频率权重）
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory = .other,
        state: TaskState = .pending,
        scheduledDate: Date? = nil,
        completionCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.state = state
        self.scheduledDate = scheduledDate
        self.completionCount = completionCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - State Transition Helper
    mutating func apply(action: TaskAction) {
        let newState = TaskStateMachine.reduce(state: state, action: action)
        if newState == .completed && state != .completed {
            completionCount += 1
        }
        state = newState
        updatedAt = Date()
    }
}

// MARK: - Convenience Extensions
extension TodoItem {
    /// 是否已安排到具体日期
    var isScheduled: Bool { scheduledDate != nil }

    /// 是否为今天的任务
    var isToday: Bool {
        guard let date = scheduledDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    /// 格式化的日期描述
    var dateLabel: String {
        guard let date = scheduledDate else { return "未安排" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }
}
