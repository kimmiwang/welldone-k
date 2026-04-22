import SwiftUI

@main
struct WelldoneKApp: App {
    @StateObject private var store = TodoStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .onAppear { store.processOverdue() }
        }
        #if os(macOS)
        .defaultSize(width: 800, height: 600)
        #endif
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodoPage()
                .tabItem { Label("todo", systemImage: "calendar") }
                .tag(0)
            OrganizePage()
                .tabItem { Label("organize", systemImage: "tray.2") }
                .tag(1)
        }
    }
}

// MARK: - Todo Page

struct TodoPage: View {
    @EnvironmentObject var store: TodoStore
    @State private var weekOffset = 0
    @State private var showAddSheet = false
    @State private var addDate = Date()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if !store.overdueTasks.isEmpty {
                overdueSection
                Divider()
            }
            weekNav
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(WeekHelper.week(offset: weekOffset)) { day in
                        DaySlotView(day: day, addDate: $addDate, showAddSheet: $showAddSheet)
                        if day.id != WeekHelper.week(offset: weekOffset).last?.id {
                            Divider().padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTaskSheet(date: addDate)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("weekly todo").font(.headline)
                HStack(spacing: 6) {
                    Text(WeekHelper.rangeLabel(offset: weekOffset))
                        .font(.caption).foregroundStyle(.secondary)
                    weekProgress
                }
            }
            Spacer()
            CountdownButton()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var weekProgress: some View {
        let wt = store.weekTasks(for: WeekHelper.week(offset: weekOffset).first!.date)
        let total = wt.count
        let done = wt.filter { $0.state == .completed }.count
        let progress = total > 0 ? Double(done) / Double(total) : 0
        return HStack(spacing: 4) {
            ZStack {
                Circle().stroke(Color.gray.opacity(0.15), lineWidth: 2.5)
                Circle().trim(from: 0, to: progress)
                    .stroke(done >= total && total > 0 ? .green : .blue,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 16, height: 16)
            Text("\(done)/\(total)").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
        }
    }

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("⏳").font(.caption)
                Text("overdue").font(.subheadline.bold()).foregroundStyle(.red)
                Text("\(store.overdueTasks.count)")
                    .font(.caption2.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(.red))
            }
            ForEach(store.overdueTasks) { item in
                TaskRowView(item: item, isOverdue: true)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(.red.opacity(0.03))
    }

    private var weekNav: some View {
        HStack {
            Button("← prev") { weekOffset -= 1 }
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button("today") { weekOffset = 0 }
                .font(.caption.bold()).foregroundStyle(.blue)
                .opacity(weekOffset == 0 ? 0.3 : 1)
                .disabled(weekOffset == 0)
            Spacer()
            Button("next →") { weekOffset += 1 }
                .font(.caption).foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16).padding(.vertical, 6)
    }
}

// MARK: - Countdown Button (editable)

struct CountdownButton: View {
    @EnvironmentObject var store: TodoStore
    @State private var showEdit = false

    var body: some View {
        Button { showEdit = true } label: {
            HStack(spacing: 4) {
                Text(store.countdown.emoji)
                Text("\(store.countdown.label) in ").font(.caption).foregroundStyle(.secondary)
                + Text("\(store.countdown.daysLeft)d").font(.caption.bold()).foregroundStyle(.blue)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEdit) {
            CountdownEditSheet()
        }
    }
}

struct CountdownEditSheet: View {
    @EnvironmentObject var store: TodoStore
    @Environment(\.dismiss) var dismiss
    @State private var label = ""
    @State private var targetDate = Date()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Text("edit countdown").font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            TextField("e.g. Vacation, Birthday…", text: $label)
                .textFieldStyle(.roundedBorder)
            
            DatePicker("target date", selection: $targetDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()

            Button("save") {
                if !label.trimmingCharacters(in: .whitespaces).isEmpty {
                    store.countdown.label = label.trimmingCharacters(in: .whitespaces)
                }
                store.countdown.targetDate = targetDate
                store.save()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .onAppear {
            label = store.countdown.label
            targetDate = store.countdown.targetDate
        }
        #if os(macOS)
        .frame(width: 340)
        #else
        .presentationDetents([.height(500)])
        #endif
    }
}

// MARK: - Day Slot (with drop support)

struct DaySlotView: View {
    @EnvironmentObject var store: TodoStore
    let day: WeekDay
    @Binding var addDate: Date
    @Binding var showAddSheet: Bool

    var dayTasks: [TodoItem] { store.tasks(for: day.date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(day.num)
                    .font(.subheadline.bold())
                    .foregroundStyle(day.isToday ? .white : (day.isPast ? Color.gray.opacity(0.5) : .primary))
                    .frame(width: 26, height: 26)
                    .background(day.isToday ? Circle().fill(.blue) : nil)
                Text(day.name).font(.caption).foregroundStyle(day.isToday ? .blue : .secondary)
                if !dayTasks.isEmpty {
                    let done = dayTasks.filter { $0.state == .completed }.count
                    Text("\(done)/\(dayTasks.count)").font(.system(size: 10)).foregroundStyle(Color.gray.opacity(0.5))
                }
                Spacer()
                Button {
                    addDate = day.date
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus").font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.gray.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)

            ForEach(dayTasks) { item in
                TaskRowView(item: item, isOverdue: false)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(day.isToday ? .blue.opacity(0.04) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(day.isToday ? .blue.opacity(0.2) : .clear)
        )
        // Drop support: accept dragged items from attic (duplicate, not move)
        .dropDestination(for: String.self) { items, _ in
            for idString in items {
                if let uuid = UUID(uuidString: idString),
                   let item = store.tasks.first(where: { $0.id == uuid }) {
                    if item.scheduledDate == nil {
                        // From attic: duplicate to this day, freq +1
                        store.scheduleFromAttic(item, to: day.date)
                    } else {
                        // From another day: move
                        store.reschedule(item, to: day.date)
                    }
                }
            }
            return !items.isEmpty
        }
    }
}

// MARK: - Task Row

struct TaskRowView: View {
    @EnvironmentObject var store: TodoStore
    let item: TodoItem
    let isOverdue: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button { store.toggleComplete(item) } label: {
                ZStack {
                    Circle()
                        .strokeBorder(item.state == .completed ? item.category.color :
                                        (isOverdue ? .red.opacity(0.6) : .secondary.opacity(0.4)), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if item.state == .completed {
                        Circle().fill(item.category.color).frame(width: 18, height: 18)
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            Circle().fill(item.category.color).frame(width: 7, height: 7)

            Text(item.title)
                .font(.system(size: 12))
                .foregroundStyle(item.state == .completed ? .secondary : .primary)
                .strikethrough(item.state == .completed)
                .lineLimit(1)

            Spacer()

            if isOverdue, let due = item.dueDate {
                let days = max(1, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: due),
                                                                    to: Calendar.current.startOfDay(for: Date())).day ?? 1)
                Text("\(days)d late")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(.red.opacity(0.1)))
            }
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .contentShape(Rectangle())
        .opacity(item.state == .completed ? 0.5 : 1)
        .contextMenu {
            Button(role: .destructive) { store.delete(item) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Task Sheet (with close button, category first)

struct AddTaskSheet: View {
    @EnvironmentObject var store: TodoStore
    @Environment(\.dismiss) var dismiss
    let date: Date
    @State private var title = ""
    @State private var category: TaskCategory = .work
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header with close
            HStack {
                Spacer()
                Text("new task").font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text(date, format: .dateTime.month().day().weekday()).font(.caption).foregroundStyle(.secondary)

            // Category first (single row)
            HStack(spacing: 6) {
                ForEach(TaskCategory.allCases) { cat in
                    Button { category = cat } label: {
                        HStack(spacing: 3) {
                            Text(cat.icon).font(.system(size: 12))
                            Text(cat.label).font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(category == cat ? .white : .primary)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Capsule().fill(category == cat ? cat.color : Color.gray.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            // Input field
            HStack {
                Circle().fill(category.color).frame(width: 8, height: 8)
                TextField("task name…", text: $title).focused($focused).onSubmit { add() }
            }
            .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.15)))

            Button("add task") { add() }
                .buttonStyle(.borderedProminent).disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(24)
        .onAppear { focused = true }
        #if os(macOS)
        .frame(width: 340)
        #else
        .presentationDetents([.height(280)])
        #endif
    }

    private func add() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        store.add(TodoItem(title: title.trimmingCharacters(in: .whitespaces),
                           category: category, scheduledDate: Calendar.current.startOfDay(for: date)))
        dismiss()
    }
}

// MARK: - Organize Page

struct OrganizePage: View {
    var body: some View {
        HSplitOrStack {
            TodoPage()
            AtticPanel()
        }
    }
}

struct HSplitOrStack<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        #if os(macOS)
        HSplitView { content() }
        #else
        NavigationSplitView { content() } detail: { EmptyView() }
        #endif
    }
}

// MARK: - Attic Panel

struct AtticPanel: View {
    @EnvironmentObject var store: TodoStore
    @State private var filter: TaskCategory? = nil
    @State private var showAdd = false

    var filtered: [TodoItem] {
        let base = store.inventoryTasks
        guard let f = filter else { return base }
        return base.filter { $0.category == f }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("attic").font(.headline)
                    Text("sorted by frequency · drag to left").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    chipButton(label: "🪐 All", cat: nil)
                    ForEach(TaskCategory.allCases) { cat in
                        chipButton(label: "\(cat.icon) \(cat.label)", cat: cat)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
            }
            Divider()

            List {
                ForEach(filtered) { item in
                    HStack(spacing: 8) {
                        Circle().fill(item.category.color).frame(width: 7, height: 7)
                        Text(item.title).lineLimit(1)
                        Spacer()
                        Text("\(item.completionCount)")
                            .font(.caption2.bold()).foregroundStyle(.secondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.gray.opacity(0.15)))
                    }
                    .contextMenu {
                        Button(role: .destructive) { store.delete(item) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .draggable(item.id.uuidString)
                }
            }
            .listStyle(.plain)
        }
        .sheet(isPresented: $showAdd) {
            AddToAtticSheet()
        }
    }

    private func chipButton(label: String, cat: TaskCategory?) -> some View {
        Button { filter = cat } label: {
            Text(label)
                .font(.caption).fontWeight(.medium)
                .foregroundStyle(filter == cat ? .white : .primary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(filter == cat ? (cat?.color ?? .blue) : Color.gray.opacity(0.15)))
                .fixedSize()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add To Attic Sheet (with close button, category first)

struct AddToAtticSheet: View {
    @EnvironmentObject var store: TodoStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var category: TaskCategory = .other
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Text("add to attic").font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Category first (single row)
            HStack(spacing: 6) {
                ForEach(TaskCategory.allCases) { cat in
                    Button { category = cat } label: {
                        HStack(spacing: 3) {
                            Text(cat.icon).font(.system(size: 12))
                            Text(cat.label).font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(category == cat ? .white : .primary)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Capsule().fill(category == cat ? cat.color : Color.gray.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            HStack {
                Circle().fill(category.color).frame(width: 8, height: 8)
                TextField("task name…", text: $title).focused($focused).onSubmit { add() }
            }
            .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.15)))

            Button("add to attic") { add() }
                .buttonStyle(.borderedProminent).disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(24)
        .onAppear { focused = true }
        #if os(macOS)
        .frame(width: 340)
        #else
        .presentationDetents([.height(260)])
        #endif
    }

    private func add() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        store.add(TodoItem(title: title.trimmingCharacters(in: .whitespaces), category: category))
        dismiss()
    }
}
