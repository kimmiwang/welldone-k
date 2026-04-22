import SwiftUI

// MARK: - Glass Morphism Card
/// 毛玻璃材质卡片，遵循 Apple Materials 设计规范
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(.ultraThinMaterial)
                    .shadow(color: DesignTokens.Shadow.sm, radius: 8, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let category: TaskCategory

    var body: some View {
        Circle()
            .fill(category.color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Completion Frequency Badge
struct FrequencyBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(DesignTokens.Typography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(.quaternary)
            )
    }
}

// MARK: - Custom Checkbox
struct TaskCheckbox: View {
    let state: TaskState
    let category: TaskCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(borderColor, lineWidth: 1.5)
                    .frame(width: 20, height: 20)

                if state == .completed {
                    Circle()
                        .fill(category.color)
                        .frame(width: 20, height: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }

    private var borderColor: Color {
        switch state {
        case .completed: return category.color
        case .overdue: return .red.opacity(0.6)
        case .pending: return .secondary.opacity(0.4)
        }
    }
}

// MARK: - Overdue Tag
struct OverdueTag: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 8))
            Text("延期")
                .font(DesignTokens.Typography.caption2)
        }
        .foregroundStyle(.red)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(.red.opacity(0.1))
        )
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat

    init(progress: Double, lineWidth: CGFloat = 3, size: CGFloat = 28) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress >= 1.0 ? Color.green : Color.blue,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DesignTokens.Motion.standard, value: progress)
        }
        .frame(width: size, height: size)
    }
}
