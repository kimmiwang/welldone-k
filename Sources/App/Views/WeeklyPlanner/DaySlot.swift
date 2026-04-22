import SwiftUI

// MARK: - Day Slot (单日格子)
struct DaySlot: View {
    let day: WeekDay
    let tasks: [TodoItem]
    @ObservedObject var store: TodoStore
    @Binding var selectedDate: Date?
    @Binding var showQuickEntry: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day Header
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Day Number
                ZStack {
                    if day.isToday {
                        Circle()
                            .fill(.blue)
                            .frame(width: 24, height: 24)
                    }
                    Text(day.dayNumber)
                        .font(DesignTokens.Typography.subheadline)
                        .fontWeight(day.isToday ? .bold : .medium)
                        .foregroundStyle(day.isToday ? .white : (day.isPast ? .tertiary : .primary))
                }

                Text(day.dayOfWeek)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(day.isToday ? .blue : .secondary)

                Spacer()

                if !tasks.isEmpty {
                    Text("\(completedCount)/\(tasks.count)")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Add Button
                Button {
                    selectedDate = day.date
                    showQuickEntry = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(.quaternary))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)

            // Task List
            if tasks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(tasks) { item in
                        TaskRow(item: item, compact: true) {
                            withAnimation(DesignTokens.Motion.quick) {
                                store.toggleComplete(item)
                            }
                        }

                        if item.id != tasks.last?.id {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(day.isToday ? .blue.opacity(0.04) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(
                    day.isToday ? .blue.opacity(0.3) : .clear,
                    lineWidth: 1
                )
        )
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    private var completedCount: Int {
        tasks.filter { $0.state == .completed }.count
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            Text(day.isPast ? "无任务" : "点击 + 添加")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(.quaternary)
            Spacer()
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadObject(ofClass: NSString.self) { reading, _ in
                guard let idString = reading as? String,
                      let uuid = UUID(uuidString: idString) else { return }
                Task { @MainActor in
                    if let item = store.items.first(where: { $0.id == uuid }) {
                        store.scheduleFromInventory(item, to: day.date)
                    }
                }
            }
        }
        return true
    }
}
