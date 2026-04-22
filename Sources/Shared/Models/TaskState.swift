import Foundation

// MARK: - Task State Machine
/// 任务状态有限状态机 (XState-like pattern)
/// State transitions: Pending -> Completed | Pending -> Overdue -> Pending (reschedule)
enum TaskState: String, Codable {
    case pending    = "pending"
    case completed  = "completed"
    case overdue    = "overdue"
}

// MARK: - State Machine Actions
enum TaskAction {
    case complete           // 用户勾选完成
    case uncomplete         // 用户取消勾选
    case markOverdue        // 系统在 00:00 触发
    case reschedule         // 用户从 Backlog 拖回日期
}

// MARK: - Reducer (Pure Function)
/// XState 风格的 Reducer：给定当前状态和动作，返回新状态
struct TaskStateMachine {
    static func reduce(state: TaskState, action: TaskAction) -> TaskState {
        switch (state, action) {
        // Pending → Completed
        case (.pending, .complete):
            return .completed

        // Completed → Pending (undo)
        case (.completed, .uncomplete):
            return .pending

        // Pending → Overdue (00:00 cron)
        case (.pending, .markOverdue):
            return .overdue

        // Overdue → Pending (user reschedules)
        case (.overdue, .reschedule):
            return .pending

        // Overdue → Completed (直接在 backlog 完成)
        case (.overdue, .complete):
            return .completed

        // 其他非法转换，保持原状态
        default:
            return state
        }
    }
}
