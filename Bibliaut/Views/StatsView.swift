import SwiftUI

/// The "stats" tab: level, streak, usage, and a monthly calendar of studied / missed days.
struct StatsView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let s = store.strings
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(s.tabStats)
                    .font(.heading(28))
                    .foregroundStyle(Color.text)
                    .padding(.bottom, 14)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    StatTile(icon: "book.fill", color: Color.brand,
                             title: s.statLevel, value: store.levelName, detail: "\(store.xp) XP")
                    StatTile(icon: "flame.fill", color: Color.gold,
                             title: s.statStreak, value: s.days(store.displayStreak), detail: nil)
                    StatTile(icon: "calendar", color: Color.iceInk,
                             title: s.statWeek, value: s.lessons(store.lessonsThisWeek), detail: nil)
                    StatTile(icon: "flag.checkered", color: Color.correct,
                             title: s.statStations, value: "\(store.totalStationsDone)/\(store.totalStations)",
                             detail: s.lessons(store.lessonsTotal))
                }

                MonthCalendar()
                    .padding(.top, 18)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color.bg)
    }
}

struct StatTile: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(color)
            Text(value)
                .font(.heading(20))
                .foregroundStyle(Color.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let detail {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.muted)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
    }
}

// MARK: - Calendar

/// One month of the streak history. Gold = studied, ice-blue = missed ("frozen"), ring = today.
struct MonthCalendar: View {
    @Environment(GameStore.self) private var store
    /// 0 = current month, -1 = previous month, ...
    @State private var monthOffset = 0

    private var calendar: Calendar { Calendar.current }

    private var monthStart: Date {
        let comps = calendar.dateComponents([.year, .month], from: Date())
        let thisMonth = calendar.date(from: comps) ?? Date()
        return calendar.date(byAdding: .month, value: monthOffset, to: thisMonth) ?? thisMonth
    }

    /// Days of the month, preceded by `nil` placeholders so the 1st lands on the right weekday.
    private var cells: [Date?] {
        let count = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let days: [Date?] = (0..<count).map { calendar.date(byAdding: .day, value: $0, to: monthStart) }
        return Array(repeating: nil, count: leading) + days
    }

    private var weekdaySymbols: [String] {
        var f = calendar
        f.locale = store.strings.locale
        let symbols = f.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = store.strings.locale
        f.setLocalizedDateFormatFromTemplate("yMMMM")
        return f.string(from: monthStart)
    }

    var body: some View {
        let s = store.strings
        let cells = self.cells
        let days = cells.compactMap { $0 }
        let studied = days.filter { store.studied(on: $0) }.count
        let missed = days.filter { store.missed($0) }.count

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(s.calendarTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.muted)
                Spacer()
                Button { monthOffset -= 1 } label: { navChevron("chevron.left") }
                Text(monthTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.text)
                    .frame(minWidth: 130)
                Button { monthOffset += 1 } label: { navChevron("chevron.right") }
                    .disabled(monthOffset >= 0)
                    .opacity(monthOffset >= 0 ? 0.35 : 1)
            }
            .buttonStyle(.plain)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdaySymbols.indices, id: \.self) { i in
                    Text(weekdaySymbols[i])
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.muted)
                }
                ForEach(cells.indices, id: \.self) { i in
                    if let day = cells[i] {
                        DayCell(date: day)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }

            HStack(spacing: 14) {
                legend(Color.gold, s.studiedDay)
                legend(Color.ice, s.missedDay)
                Spacer()
            }
            .padding(.top, 2)

            Text(s.monthSummary(studied, missed))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.text)
        }
        .padding(14)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.border, lineWidth: 1))
    }

    private func navChevron(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.brand)
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
    }

    private func legend(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.muted)
        }
    }
}

struct DayCell: View {
    @Environment(GameStore.self) private var store
    let date: Date

    var body: some View {
        let studied = store.studied(on: date)
        let missed = store.missed(date)
        let isToday = Calendar.current.isDateInToday(date)
        let dayNumber = Calendar.current.component(.day, from: date)

        ZStack {
            Circle()
                .fill(studied ? Color.gold : (missed ? Color.ice : Color.clear))
            if isToday {
                Circle().stroke(Color.brand, lineWidth: 2)
            }
            if missed {
                Image(systemName: "snowflake")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.iceInk)
                    .offset(y: 11)
            }
            Text("\(dayNumber)")
                .font(.system(size: 13, weight: studied ? .bold : .medium))
                .foregroundStyle(studied ? Color.brandInk : (missed ? Color.iceInk : Color.text))
                .offset(y: missed ? -3 : 0)
        }
        .frame(height: 34)
        .frame(maxWidth: .infinity)
    }
}
