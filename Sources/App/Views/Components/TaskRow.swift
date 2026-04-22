import SwiftUI

// MARK: - Task Row (单个任务条目)
struct TaskRow: View {
    let item: TodoItem
    let onToggle: () -> Void
    let compact: Bool

    init(item: TodoItem, compact: Bool = false, onToggle: @escaping () -> Void) {
        self.item = item
        self.compact = compact
        self.onToggle = onToggle
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            TaskCheckbox(state: item.state, category: item.category, action: onToggle)

            CategoryBadge(category: item.category)

            Text(item.title)
                .font(compact ? DesignTokens.Typography.footnote : DesignTokens.Typography.body)
                .foregroundStyle(item.state == .completed ? .secondary : .primary)
                .strikethrough(item.state == .completed, color: .secondary)
                .lineLimit(1)

            Spacer()

            if item.state == .overdue {
                OverdueTag()
            }
        }
        .padding(.vertical, compact ? DesignTokens.Spacing.xs : DesignTokens.Spacing.sm)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .contentShape(Rectangle())
        .opacity(item.state == .completed ? 0.6 : 1.0)
    }
}

// MARK: - Inventory Task Row (素材库条目，含频率)
struct InventoryTaskRow: View {
    let item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            TaskCheckbox(state: item.state, category: item.category, action: onToggle)

            CategoryBadge(category: item.category)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(item.state == .completed ? .secondary : .primary)
                    .strikethrough(item.state == .completed)
                    .lineLimit(1)

                if let date = item.scheduledDate {
                    Text(formatDate(date))
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            FrequencyBadge(count: item.completionCount)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .contentShape(Rectangle())
        .opacity(item.state == .completed ? 0.6 : 1.0)
    }

    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "今天" }
        if Calendar.current.isDateInTomorrow(date) { return "明天" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M/d EEE"
        return f.string(from: date)
    }
}
