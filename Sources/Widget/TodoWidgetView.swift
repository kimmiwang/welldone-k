import SwiftUI
import WidgetKit

// MARK: - Widget View (Large Size - 双栏布局)
struct TodoWidgetView: View {
    let entry: TodoWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemLarge:
            largeWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Large Widget (双栏)
    private var largeWidget: some View {
        HStack(spacing: 0) {
            // Left: Today Focus
            leftColumn
                .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(.separator)
                .frame(width: 0.5)

            // Right: Top Inventory
            rightColumn
                .frame(maxWidth: .infinity)
        }
        .containerBackground(for: .widget) {
            backgroundGradient
        }
    }

    // MARK: - Medium Widget
    private var mediumWidget: some View {
        HStack(spacing: 12) {
            // Today tasks
            VStack(alignment: .leading, spacing: 6) {
                headerRow
                ForEach(entry.todayTasks.prefix(3)) { item in
                    widgetTaskRow(item)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Mini week strip
            VStack(spacing: 3) {
                ForEach(entry.weekDays) { day in
                    miniDayDot(day)
                }
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            backgroundGradient
        }
    }

    // MARK: - Small Widget
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            ForEach(entry.todayTasks.prefix(3)) { item in
                widgetTaskRow(item)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            backgroundGradient
        }
    }

    // MARK: - Left Column (Today)
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今日待办")
                        .font(.system(size: 13, weight: .semibold))
                    Text(todayLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Progress
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 2.5)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.completedToday)")
                        .font(.system(size: 9, weight: .bold))
                }
                .frame(width: 24, height: 24)
            }

            // Overdue
            if !entry.overdueTasks.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 8))
                    Text("逾期 \(entry.overdueTasks.count) 项")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(.red)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(.red.opacity(0.1)))
            }

            Divider().opacity(0.3)

            // Task list
            ForEach(entry.todayTasks.prefix(5)) { item in
                widgetTaskRow(item)
            }

            if entry.todayTasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(.green.opacity(0.5))
                        Text("今日无待办")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(.top, 8)
            }

            Spacer(minLength: 0)

            // Week dots
            HStack(spacing: 4) {
                ForEach(entry.weekDays) { day in
                    miniDayDot(day)
                }
            }
        }
        .padding(12)
    }

    // MARK: - Right Column (Inventory)
    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("高频任务")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
            }

            Divider().opacity(0.3)

            ForEach(entry.topInventory.prefix(5)) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(item.category.color)
                        .frame(width: 6, height: 6)

                    Text(item.title)
                        .font(.system(size: 11))
                        .lineLimit(1)

                    Spacer()

                    Text("×\(item.completionCount)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    // MARK: - Shared Components
    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Systematic")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(todayLabel)
                    .font(.system(size: 13, weight: .semibold))
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 2)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 20, height: 20)
        }
    }

    private func widgetTaskRow(_ item: TodoItem) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(item.state == .completed ? item.category.color : .secondary.opacity(0.3), lineWidth: 1.2)
                    .frame(width: 14, height: 14)
                if item.state == .completed {
                    Circle()
                        .fill(item.category.color)
                        .frame(width: 14, height: 14)
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            Circle()
                .fill(item.category.color)
                .frame(width: 5, height: 5)

            Text(item.title)
                .font(.system(size: 11))
                .foregroundStyle(item.state == .completed ? .secondary : .primary)
                .strikethrough(item.state == .completed)
                .lineLimit(1)
        }
    }

    private func miniDayDot(_ day: WeekDay) -> some View {
        VStack(spacing: 1) {
            Text(String(day.dayOfWeek.prefix(1)))
                .font(.system(size: 7))
                .foregroundStyle(.tertiary)
            Circle()
                .fill(day.isToday ? .blue : (day.isPast ? .secondary.opacity(0.2) : .secondary.opacity(0.1)))
                .frame(width: 6, height: 6)
        }
    }

    private var progress: Double {
        guard entry.totalToday > 0 else { return 0 }
        return Double(entry.completedToday) / Double(entry.totalToday)
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: entry.date)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.97, blue: 0.99),
                Color(red: 0.94, green: 0.95, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Widget Configuration
struct SystematicTodoWidget: Widget {
    let kind: String = "SystematicTodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoWidgetProvider()) { entry in
            TodoWidgetView(entry: entry)
        }
        .configurationDisplayName("周期待办")
        .description("一目了然的周视图规划与高频任务管理")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle
@main
struct SystematicTodoWidgetBundle: WidgetBundle {
    var body: some Widget {
        SystematicTodoWidget()
    }
}

// MARK: - Preview
#Preview("Large", as: .systemLarge) {
    SystematicTodoWidget()
} timeline: {
    TodoWidgetEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    SystematicTodoWidget()
} timeline: {
    TodoWidgetEntry.placeholder
}
