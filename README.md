# Systematic Todo Widget

> 智能桌面周期待办组件 — 基于 Apple 生态的原生桌面小组件

## 🏗 项目架构

```
SystematicTodo/
├── Sources/
│   ├── Shared/                          # 共享模块 (App + Widget)
│   │   ├── Models/
│   │   │   ├── TaskCategory.swift       # 分类枚举 + HIG 色彩令牌
│   │   │   ├── TaskState.swift          # 状态机 (Enum + Reducer)
│   │   │   ├── TodoItem.swift           # 核心数据模型
│   │   │   └── WeekDay.swift            # 周视图辅助模型
│   │   ├── Store/
│   │   │   └── TodoStore.swift          # 数据存储 + CRUD + 状态转换
│   │   └── Design/
│   │       ├── DesignTokens.swift       # 设计系统常量
│   │       └── Components.swift         # 共享 UI 组件
│   │
│   ├── App/                             # 主 App
│   │   ├── SystematicTodoApp.swift      # App 入口
│   │   ├── Views/
│   │   │   ├── ContentView.swift        # 双栏布局主视图
│   │   │   ├── Components/
│   │   │   │   ├── TaskRow.swift        # 任务行组件
│   │   │   │   └── QuickEntrySheet.swift # 快速录入浮层
│   │   │   ├── WeeklyPlanner/
│   │   │   │   ├── WeeklyPlannerPanel.swift  # 左栏：周计划面板
│   │   │   │   ├── DaySlot.swift            # 单日格子
│   │   │   │   └── BacklogArea.swift        # 逾期任务区
│   │   │   └── Inventory/
│   │   │       └── MasterInventoryPanel.swift # 右栏：任务素材库
│   │   └── Intents/
│   │       └── TodoIntents.swift        # App Intents (原地交互)
│   │
│   └── Widget/                          # Widget Extension
│       ├── TodoWidgetProvider.swift      # Timeline Provider
│       └── TodoWidgetView.swift         # 小/中/大号 Widget 视图
│
└── SystematicTodo.xcodeproj/
```

## 📐 设计规范

| 设计维度 | 规范 |
|---------|------|
| 设计系统 | Apple Human Interface Guidelines (HIG) |
| 字体 | SF Pro (系统默认) |
| 图标 | SF Symbols |
| 材质 | Ultra Thin Material (毛玻璃) |
| 动画 | Spring (0.4s, 0.8 damping) |

### 色彩令牌 (Design Tokens)
- **工作 (Work):** `.systemBlue` — 蓝色
- **学习 (Study):** `.systemPurple` — 紫色
- **生活 (Life):** `.systemGreen` — 绿色
- **其他 (Other):** `.systemGray` — 灰色

## 🔄 状态机 (XState Pattern)

```
┌─────────┐  complete   ┌───────────┐
│ Pending │────────────►│ Completed │
│         │◄────────────│           │
└────┬────┘  uncomplete └───────────┘
     │                       ▲
     │ markOverdue           │ complete
     ▼                       │
┌─────────┐                  │
│ Overdue │──────────────────┘
│         │  reschedule  ┌─────────┐
│         │─────────────►│ Pending │
└─────────┘              └─────────┘
```

## 🧩 核心模块说明

### 1. TaskStateMachine (Reducer 模式)
纯函数式状态转换，给定 `(currentState, action) → newState`

### 2. TodoStore (响应式数据层)
- `@Published` 驱动的 SwiftUI 数据流
- App Group 共享 UserDefaults (App ↔ Widget)
- 自动逾期处理 (00:00 cron)
- 完成计数频率排序

### 3. Widget (三种尺寸)
- **Small:** 今日待办概览 + 进度环
- **Medium:** 今日任务 + 周点阵
- **Large:** 左右双栏 (今日 + 高频任务库)

### 4. App Intents
- `ToggleTaskIntent` — 小组件内切换完成状态
- `AddQuickTaskIntent` — Siri / Shortcuts 快速添加
- `RescheduleTaskIntent` — 重新安排逾期任务

## 🚀 开发指南

### 环境要求
- Xcode 15.0+
- macOS Sonoma 14.0+ / iOS 17.0+
- Apple Developer 账号 (CloudKit 同步需要)

### 构建步骤
1. 在 Xcode 中打开 `SystematicTodo.xcodeproj`
2. 配置 App Group: `group.com.systematic.todo`
3. 配置 CloudKit Container (如需跨设备同步)
4. 选择目标设备运行

### 生产化清单
- [ ] 替换 UserDefaults 为 `NSPersistentCloudKitContainer`
- [ ] 配置 App Group entitlements
- [ ] 添加 Widget Extension target
- [ ] 实现 BackgroundTask 定时刷新逾期任务
- [ ] 添加 Haptic Feedback
- [ ] 适配 Dynamic Type
- [ ] 适配 VoiceOver 无障碍
