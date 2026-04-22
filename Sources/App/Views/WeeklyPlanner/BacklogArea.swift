import SwiftUI

// MARK: - Backlog Area (逾期任务区域)
struct BacklogArea: View {
    @ObservedObject var store: TodoStore
    let weekDays: [WeekDay]
    @State private var isExpanded: Bool = true

    var overdueTasks: [TodoItem] {
        store.overdueTasks
    }

    var body: some View {
        if !overdueTasks.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                // Header
                Button {
                    withAnimation(DesignTokens.Motion.quick) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.red)

                        Text("逾期任务")
                            .font(DesignTokens.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)

                        Text("\(overdueTasks.count)")
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.red))

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(overdueTasks) { item in
                            TaskRow(item: item, compact: true) {
                                store.toggleComplete(item)
                            }
                            .contextMenu {
                                ForEach(weekDays) { day in
                                    Button {
                                        store.reschedule(item, to: day.date)
                                    } label: {
                                        Label(
                                            "移至 \(day.dayOfWeek) \(day.dayNumber)日",
                                            systemImage: "calendar.badge.plus"
                                        )
                                    }
                                }
                            }

                            if item.id != overdueTasks.last?.id {
                                Divider().padding(.leading, 36)
                            }
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .fill(.red.opacity(0.04))
                    )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }
}
