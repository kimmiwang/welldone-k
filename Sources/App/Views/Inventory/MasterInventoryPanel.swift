import SwiftUI

// MARK: - Master Inventory Panel (右侧任务素材库)
struct MasterInventoryPanel: View {
    @ObservedObject var store: TodoStore
    @State private var selectedCategory: TaskCategory? = nil
    @State private var showAddSheet = false
    @State private var searchText = ""

    var filteredTasks: [TodoItem] {
        var tasks = store.inventoryTasks(category: selectedCategory)
        if !searchText.isEmpty {
            tasks = tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return tasks
    }

    var body: some View {
        VStack(spacing: 0) {
            // Panel Header
            panelHeader

            Divider().opacity(0.5)

            // Category Filter
            categoryFilter

            // Search Bar
            searchBar

            Divider().opacity(0.3)

            // Task List
            if filteredTasks.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTasks) { item in
                            InventoryTaskRow(item: item) {
                                withAnimation(DesignTokens.Motion.quick) {
                                    store.toggleComplete(item)
                                }
                            }
                            .onDrag {
                                NSItemProvider(object: item.id.uuidString as NSString)
                            }

                            if item.id != filteredTasks.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // Bottom Bar
            bottomBar
        }
        .sheet(isPresented: $showAddSheet) {
            InventoryAddSheet(store: store, isPresented: $showAddSheet)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews
    private var panelHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("任务素材库")
                    .font(DesignTokens.Typography.headline)

                Text("按完成频率排序")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(store.items.count) 项")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.lg)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md) {
                filterChip(label: "全部", icon: "square.grid.2x2", category: nil)
                ForEach(TaskCategory.allCases) { cat in
                    filterChip(label: cat.rawValue, icon: cat.iconName, category: cat)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
    }

    private func filterChip(label: String, icon: String, category: TaskCategory?) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            withAnimation(DesignTokens.Motion.quick) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(DesignTokens.Typography.caption)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? (category?.color ?? .blue) : .clear)
            )
            .background(
                Capsule()
                    .fill(.quaternary)
            )
        }
        .buttonStyle(.plain)
    }

    private var searchBar: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            TextField("搜索任务…", text: $searchText)
                .font(DesignTokens.Typography.footnote)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(.quaternary.opacity(0.5))
        )
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.bottom, DesignTokens.Spacing.md)
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.quaternary)
            Text("暂无任务")
                .font(DesignTokens.Typography.footnote)
                .foregroundStyle(.tertiary)
            Text("点击右下角 + 添加任务到素材库")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(.quaternary)
            Spacer()
        }
    }

    private var bottomBar: some View {
        HStack {
            // Stats
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                Text("高频: \(topFrequencyLabel)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // FAB
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.lg)
        .background(.ultraThinMaterial)
    }

    private var topFrequencyLabel: String {
        guard let top = store.inventoryTasks.first else { return "无" }
        return "\(top.title) ×\(top.completionCount)"
    }
}

// MARK: - Inventory Add Sheet
struct InventoryAddSheet: View {
    @ObservedObject var store: TodoStore
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var category: TaskCategory = .other
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            HStack {
                Text("添加到素材库")
                    .font(DesignTokens.Typography.headline)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Input
            HStack(spacing: DesignTokens.Spacing.md) {
                CategoryBadge(category: category)
                TextField("任务名称…", text: $title)
                    .font(DesignTokens.Typography.body)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit { addTask() }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(.quaternary)
            )

            // Category Picker
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(TaskCategory.allCases) { cat in
                    Button {
                        withAnimation(DesignTokens.Motion.quick) {
                            category = cat
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 12))
                            Text(cat.rawValue)
                                .font(DesignTokens.Typography.footnote)
                        }
                        .foregroundStyle(category == cat ? .white : .primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(category == cat ? cat.color : .clear)
                        )
                        .background(
                            Capsule()
                                .fill(.quaternary)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("添加到素材库的任务可拖拽到周计划中使用")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(.tertiary)

            Button(action: addTask) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加")
                }
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(title.isEmpty ? .gray : category.color)
                )
            }
            .buttonStyle(.plain)
            .disabled(title.isEmpty)
        }
        .padding(DesignTokens.Spacing.xxl)
        .onAppear { isFocused = true }
    }

    private func addTask() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let item = TodoItem(
            title: title.trimmingCharacters(in: .whitespaces),
            category: category
        )
        store.add(item)
        title = ""
        isPresented = false
    }
}
