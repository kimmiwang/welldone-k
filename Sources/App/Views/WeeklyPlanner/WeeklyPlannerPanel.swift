import SwiftUI

// MARK: - Weekly Planner Panel (左侧周计划面板)
struct WeeklyPlannerPanel: View {
    @ObservedObject var store: TodoStore
    @State private var selectedDate: Date?
    @State private var showQuickEntry = false

    private let weekDays = WeekHelper.currentWeek()

    var body: some View {
        VStack(spacing: 0) {
            // Panel Header
            panelHeader

            Divider().opacity(0.5)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Backlog Area
                    BacklogArea(store: store, weekDays: weekDays)

                    if !store.overdueTasks.isEmpty {
                        Divider()
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                    }

                    // 7-Day Grid
                    LazyVStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(weekDays) { day in
                            DaySlot(
                                day: day,
                                tasks: store.tasks(for: day.date),
                                store: store,
                                selectedDate: $selectedDate,
                                showQuickEntry: $showQuickEntry
                            )

                            if day.id != weekDays.last?.id {
                                Divider()
                                    .padding(.horizontal, DesignTokens.Spacing.lg)
                                    .opacity(0.4)
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                }
            }
        }
        .sheet(isPresented: $showQuickEntry) {
            if let date = selectedDate {
                QuickEntrySheet(store: store, targetDate: date, isPresented: $showQuickEntry)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var panelHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("本周计划")
                    .font(DesignTokens.Typography.headline)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text(weekRangeLabel)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(.secondary)

                    if store.weeklyScheduledCount > 0 {
                        ProgressRing(
                            progress: Double(store.weeklyCompletedCount) / Double(store.weeklyScheduledCount),
                            lineWidth: 2,
                            size: 14
                        )
                        Text("\(store.weeklyCompletedCount)/\(store.weeklyScheduledCount)")
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button {
                store.processOverdueTasks()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.lg)
    }

    private var weekRangeLabel: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return "\(formatter.string(from: first.date)) - \(formatter.string(from: last.date))"
    }
}
