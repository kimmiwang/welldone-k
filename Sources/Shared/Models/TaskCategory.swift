import SwiftUI

// MARK: - Task Category Design Tokens
/// 任务分类枚举，遵循 HIG 色彩系统
enum TaskCategory: String, CaseIterable, Codable, Identifiable {
    case work   = "工作"
    case study  = "学习"
    case life   = "生活"
    case other  = "其他"

    var id: String { rawValue }

    /// 系统级设计令牌色彩
    var color: Color {
        switch self {
        case .work:  return .blue       // .systemBlue
        case .study: return .purple     // .systemPurple
        case .life:  return .green      // .systemGreen
        case .other: return .gray       // .systemGray
        }
    }

    /// SF Symbol 图标名
    var iconName: String {
        switch self {
        case .work:  return "briefcase.fill"
        case .study: return "book.fill"
        case .life:  return "leaf.fill"
        case .other: return "tray.fill"
        }
    }

    /// 英文标识
    var label: String {
        switch self {
        case .work:  return "Work"
        case .study: return "Study"
        case .life:  return "Life"
        case .other: return "Other"
        }
    }
}
