import Foundation

// MARK: - Week Day Model
/// 周视图中的每一天
struct WeekDay: Identifiable, Hashable {
    let id: String
    let date: Date
    let dayOfWeek: String       // 周几
    let dayNumber: String       // 日期数字
    let isToday: Bool
    let isPast: Bool

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.id = ISO8601DateFormatter().string(from: self.date)

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        formatter.dateFormat = "EEE"
        self.dayOfWeek = formatter.string(from: date)

        formatter.dateFormat = "d"
        self.dayNumber = formatter.string(from: date)

        self.isToday = calendar.isDateInToday(date)
        self.isPast = self.date < calendar.startOfDay(for: Date()) && !self.isToday
    }
}

// MARK: - Week Helper
struct WeekHelper {
    /// 获取本周的 7 天
    static func currentWeek() -> [WeekDay] {
        let calendar = Calendar.current
        let today = Date()

        // 获取本周周一
        var startOfWeek = today
        var interval: TimeInterval = 0
        _ = calendar.dateInterval(of: .weekOfYear, start: &startOfWeek, interval: &interval, for: today)

        // 确保从周一开始（中国习惯）
        let weekday = calendar.component(.weekday, from: startOfWeek)
        if weekday == 1 { // 如果是周日，退回到上一个周一
            startOfWeek = calendar.date(byAdding: .day, value: -6, to: startOfWeek)!
        }

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else {
                return nil
            }
            return WeekDay(date: date)
        }
    }

    /// 判断两个日期是否为同一天
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
}
