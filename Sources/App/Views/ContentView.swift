import SwiftUI

// MARK: - Main Content View (双栏布局)
struct ContentView: View {
    @StateObject private var store = TodoStore()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 600

            if isCompact {
                // 窄屏：Tab 切换模式
                compactLayout
            } else {
                // 宽屏：双栏并排
                wideLayout(width: geometry.size.width)
            }
        }
        .background(backgroundGradient)
    }

    // MARK: - Wide Layout (双栏)
    private func wideLayout(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Left: Weekly Planner
            WeeklyPlannerPanel(store: store)
                .frame(width: width * 0.55)
                .background(.ultraThinMaterial)

            Divider()

            // Right: Master Inventory
            MasterInventoryPanel(store: store)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial.opacity(0.8))
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))
        .shadow(color: DesignTokens.Shadow.md, radius: 20, y: 8)
        .padding(DesignTokens.Spacing.xl)
    }

    // MARK: - Compact Layout (Tab)
    @State private var selectedTab: Int = 0

    private var compactLayout: some View {
        TabView(selection: $selectedTab) {
            WeeklyPlannerPanel(store: store)
                .tabItem {
                    Label("周计划", systemImage: "calendar")
                }
                .tag(0)

            MasterInventoryPanel(store: store)
                .tabItem {
                    Label("素材库", systemImage: "tray.2.fill")
                }
                .tag(1)
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.96, blue: 0.98),
                Color(red: 0.92, green: 0.93, blue: 0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .frame(minWidth: 800, minHeight: 600)
}
