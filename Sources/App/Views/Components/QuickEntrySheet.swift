import SwiftUI

// MARK: - Quick Entry Toast (快速录入浮层)
struct QuickEntrySheet: View {
    @ObservedObject var store: TodoStore
    let targetDate: Date
    @Binding var isPresented: Bool

    @State private var title: String = ""
    @State private var category: TaskCategory = .other
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("新建任务")
                        .font(DesignTokens.Typography.headline)
                    Text(dateLabel)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(.secondary)
                }

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

            // Input Field
            HStack(spacing: DesignTokens.Spacing.md) {
                CategoryBadge(category: category)

                TextField("输入任务名称…", text: $title)
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
                                .fill(category == cat ? cat.color : Color.clear)
                        )
                        .background(
                            Capsule()
                                .fill(.quaternary)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Add Button
            Button(action: addTask) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加任务")
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

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: targetDate)
    }

    private func addTask() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let item = TodoItem(
            title: title.trimmingCharacters(in: .whitespaces),
            category: category,
            scheduledDate: Calendar.current.startOfDay(for: targetDate)
        )
        store.add(item)
        title = ""
        isPresented = false
    }
}
