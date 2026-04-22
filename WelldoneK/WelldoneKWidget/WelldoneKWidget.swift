import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct TodoEntry: TimelineEntry {
    let date: Date
    let todayTasks: [(String, String, Bool)] // (title, catRaw, done)
    let overdueCount: Int
    let doneCount: Int
    let totalCount: Int
}

// MARK: - Provider

struct TodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry { .sample }
    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) { completion(.sample) }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let defaults = UserDefaults.standard
        var todayTasks: [(String, String, Bool)] = []
        var overdueCount = 0, doneCount = 0, totalCount = 0

        if let data = defaults.data(forKey: "wdk_tasks"),
           let items = try? JSONDecoder().decode([TodoItem].self, from: data) {
            let cal = Calendar.current; let today = cal.startOfDay(for: Date())
            let todayItems = items.filter {
                guard let s = $0.scheduledDate else { return false }
                return cal.isDate(s, inSameDayAs: today) && $0.state != .overdue
            }
            todayTasks = todayItems.prefix(5).map { ($0.title, $0.category.rawValue, $0.state == .completed) }
            overdueCount = items.filter { $0.state == .overdue }.count
            doneCount = todayItems.filter { $0.state == .completed }.count
            totalCount = todayItems.count
        }

        let entry = TodoEntry(date: Date(), todayTasks: todayTasks,
                              overdueCount: overdueCount, doneCount: doneCount, totalCount: totalCount)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

extension TodoEntry {
    static var sample: TodoEntry {
        TodoEntry(date: Date(), todayTasks: [
            ("完成周报", "work", false), ("阅读 30 分钟", "study", false), ("跑步 5 公里", "life", false)
        ], overdueCount: 2, doneCount: 1, totalCount: 3)
    }
}

// MARK: - Widget Views

struct WelldoneKWidgetView: View {
    let entry: TodoEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("welldone-k").font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    Text(entry.date, format: .dateTime.month().day().weekday())
                        .font(.system(size: 13, weight: .semibold))
                }
                Spacer()
                // Progress ring
                ZStack {
                    Circle().stroke(.quaternary, lineWidth: 2.5)
                    Circle().trim(from: 0, to: entry.totalCount > 0 ? Double(entry.doneCount) / Double(entry.totalCount) : 0)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 20, height: 20)
            }

            if entry.overdueCount > 0 {
                HStack(spacing: 3) {
                    Text("⏳").font(.system(size: 8))
                    Text("overdue \(entry.overdueCount)")
                        .font(.system(size: 9, weight: .medium)).foregroundStyle(.red)
                }
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(Capsule().fill(.red.opacity(0.1)))
            }

            Divider().opacity(0.3)

            // Tasks
            ForEach(Array(entry.todayTasks.prefix(family == .systemSmall ? 3 : 5).enumerated()), id: \.offset) { _, t in
                HStack(spacing: 5) {
                    ZStack {
                        Circle().strokeBorder(t.2 ? catColor(t.1) : .secondary.opacity(0.3), lineWidth: 1.2)
                            .frame(width: 14, height: 14)
                        if t.2 {
                            Circle().fill(catColor(t.1)).frame(width: 14, height: 14)
                            Image(systemName: "checkmark").font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                    Circle().fill(catColor(t.1)).frame(width: 5, height: 5)
                    Text(t.0).font(.system(size: 11))
                        .foregroundStyle(t.2 ? .secondary : .primary)
                        .strikethrough(t.2).lineLimit(1)
                }
            }

            if entry.todayTasks.isEmpty {
                Spacer()
                HStack { Spacer(); Text("no tasks today").font(.caption).foregroundStyle(.tertiary); Spacer() }
                Spacer()
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(white: 0.97), Color(white: 0.95)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    func catColor(_ raw: String) -> Color {
        switch raw {
        case "work": .blue; case "study": .purple; case "life": .green; default: .gray
        }
    }
}

// MARK: - Widget Config

struct WelldoneKWidget: Widget {
    let kind = "WelldoneKWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoProvider()) { entry in
            WelldoneKWidgetView(entry: entry)
        }
        .configurationDisplayName("welldone-k")
        .description("Weekly todo at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct WelldoneKWidgetBundle: WidgetBundle {
    var body: some Widget { WelldoneKWidget() }
}
