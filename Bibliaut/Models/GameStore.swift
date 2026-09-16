import SwiftUI
import Observation
import UIKit

enum Screen: Equatable {
    case home
    case lesson
    case result(LessonResult)
    /// A treasure chest was just opened; payload is the talents it contained.
    case chest(Int)
}

/// Pages reachable from the bottom bar (only shown while `screen == .home`).
/// Named `HomeTab` to avoid clashing with SwiftUI's `Tab` (iOS 18).
enum HomeTab: Equatable {
    case home, collection, stats
}

struct LessonResult: Equatable {
    let success: Bool
    let xpGain: Int
    let streak: Int
    let unitJustCompleted: Bool
    let hasNext: Bool
}

/// State of the station currently being played.
struct LessonState {
    let unitIndex: Int
    let stationIndex: Int
    let qs: [Question]
    var idx = 0
    var hearts: Int
    var correct = 0
    var failed = false
    /// Shuffled original option indices for the current question.
    var optionOrder: [Int] = []
    /// Original index of the option the player chose, nil until answered.
    var answered: Int? = nil

    var current: Question { qs[idx] }
    var isLast: Bool { idx == qs.count - 1 }

    mutating func prepareQuestion() {
        optionOrder = Array(0..<current.optionCount).shuffled()
        answered = nil
    }
}

/// Game rules + persistence. Keys mirror the web version's localStorage keys,
/// values live in UserDefaults.
@Observable
final class GameStore {
    static let xpPerCorrect = 10
    static let completionBonus = 5
    static let heartsMax = 5
    static let heartRegen: TimeInterval = 5 * 60
    /// Station indices after which a treasure chest sits on the path.
    static let chestAfter: Set<Int> = [4, 9]
    /// Talents (collectible coins) found in one chest, and the price of a gift card.
    /// 12 chests × 20 = 240 talents = exactly the 8 cards × 30.
    static let talentsPerChest = 20
    static let cardPrice = 30

    private static let defaults = UserDefaults.standard

    let content = Content.shared

    var lang: Lang { didSet { Self.defaults.set(lang.rawValue, forKey: "bq-lang") } }
    var playerName: String { didSet { Self.defaults.set(playerName, forKey: "bq-name") } }
    var screen: Screen = .home
    var tab: HomeTab = .home
    var lesson: LessonState?
    /// Ticks once a second while hearts are regenerating, drives the countdowns.
    var now = Date()

    private(set) var xp: Int { didSet { Self.defaults.set(xp, forKey: "bq-xp") } }
    private(set) var talents: Int { didSet { Self.defaults.set(talents, forKey: "bq-talents") } }
    private(set) var progress: [String: [Int]] { didSet { Self.defaults.set(progress, forKey: "bq-progress") } }
    private(set) var heartLosses: [TimeInterval] { didSet { Self.defaults.set(heartLosses, forKey: "bq-heart-losses") } }
    private(set) var streak: Int { didSet { Self.defaults.set(streak, forKey: "bq-streak") } }
    private(set) var lastStudy: String? { didSet { Self.defaults.set(lastStudy, forKey: "bq-laststudy") } }
    private(set) var chests: [String: Bool] { didSet { Self.defaults.set(chests, forKey: "bq-chests") } }
    /// Emojis of the gift cards the player owns (the web version's gift log, deduplicated).
    private(set) var ownedCards: [String] { didSet { Self.defaults.set(ownedCards, forKey: "bq-gift-log") } }
    /// Stations played per day, keyed by `dayKey` – feeds the statistics page.
    private(set) var dailyStations: [String: Int] { didSet { Self.defaults.set(dailyStations, forKey: "bq-daily") } }
    /// Timestamp of the very first lesson; days before it don't count as missed.
    private(set) var firstStudy: TimeInterval? { didSet { Self.defaults.set(firstStudy, forKey: "bq-first-study") } }

    @ObservationIgnored private var timer: Timer?

    init() {
        let d = Self.defaults
        lang = Lang(rawValue: d.string(forKey: "bq-lang") ?? "") ?? .hu
        playerName = d.string(forKey: "bq-name") ?? ""
        xp = d.integer(forKey: "bq-xp")
        talents = d.integer(forKey: "bq-talents")
        progress = d.dictionary(forKey: "bq-progress") as? [String: [Int]] ?? [:]
        heartLosses = d.array(forKey: "bq-heart-losses") as? [TimeInterval] ?? []
        streak = d.integer(forKey: "bq-streak")
        lastStudy = d.string(forKey: "bq-laststudy")
        chests = d.dictionary(forKey: "bq-chests") as? [String: Bool] ?? [:]
        var seen = Set<String>()
        ownedCards = (d.stringArray(forKey: "bq-gift-log") ?? []).filter { seen.insert($0).inserted }
        dailyStations = d.dictionary(forKey: "bq-daily") as? [String: Int] ?? [:]
        firstStudy = d.object(forKey: "bq-first-study") as? TimeInterval
        pruneHeartLosses()

        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    var strings: Strings { Strings(lang: lang) }

    // MARK: - Hearts

    var currentHearts: Int { max(0, Self.heartsMax - heartLosses.count) }

    var secondsUntilNextHeart: TimeInterval {
        guard let earliest = heartLosses.min() else { return 0 }
        return max(0, Self.heartRegen - (now.timeIntervalSince1970 - earliest))
    }

    func formatCountdown(_ seconds: TimeInterval) -> String {
        let total = Int(ceil(seconds))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func tick() {
        pruneHeartLosses()
        if !heartLosses.isEmpty { now = Date() }
    }

    private func pruneHeartLosses() {
        let t = Date().timeIntervalSince1970
        let kept = heartLosses.filter { t - $0 < Self.heartRegen }
        if kept.count != heartLosses.count { heartLosses = kept }
    }

    private func loseHeart() {
        guard heartLosses.count < Self.heartsMax else { return }
        heartLosses.append(Date().timeIntervalSince1970)
        now = Date()
    }

    // MARK: - Progress

    func isStationDone(_ unitId: String, _ index: Int) -> Bool {
        progress[unitId]?.contains(index) ?? false
    }

    func doneCount(_ unitId: String) -> Int { progress[unitId]?.count ?? 0 }

    var totalStationsDone: Int { progress.values.reduce(0) { $0 + $1.count } }

    var totalStations: Int { content.units.reduce(0) { $0 + $1.stations.count } }

    func isUnitComplete(_ unit: PathUnit) -> Bool { doneCount(unit.id) >= unit.stations.count }

    func isUnitUnlocked(_ unitIndex: Int) -> Bool {
        unitIndex == 0 || isUnitComplete(content.units[unitIndex - 1])
    }

    private func markStationDone(_ unitId: String, _ index: Int) {
        var list = progress[unitId] ?? []
        if !list.contains(index) { list.append(index) }
        progress[unitId] = list
    }

    /// First station that is unlocked but not yet completed.
    var nextStation: (unitIndex: Int, stationIndex: Int)? {
        for (ui, unit) in content.units.enumerated() {
            guard isUnitUnlocked(ui) else { return nil }
            for si in unit.stations.indices where !isStationDone(unit.id, si) {
                return (ui, si)
            }
        }
        return nil
    }

    var levelName: String {
        content.levels.last { xp >= $0.min }?.name(lang) ?? ""
    }

    // MARK: - Streak & daily activity

    func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private var yesterdayKey: String {
        dayKey(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    }

    var displayStreak: Int {
        guard let last = lastStudy else { return 0 }
        return (last == dayKey(Date()) || last == yesterdayKey) ? streak : 0
    }

    /// Number of lessons played on a given day.
    func stationsPlayed(on date: Date) -> Int { dailyStations[dayKey(date)] ?? 0 }

    func studied(on date: Date) -> Bool { stationsPlayed(on: date) > 0 }

    /// A past day with no activity, after the player's first lesson – shown as "frozen" in the calendar.
    func missed(_ date: Date) -> Bool {
        guard let first = firstStudy else { return false }
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        let firstDay = cal.startOfDay(for: Date(timeIntervalSince1970: first))
        return day >= firstDay && day < cal.startOfDay(for: Date()) && !studied(on: date)
    }

    /// Lessons played since the start of the current week.
    var lessonsThisWeek: Int {
        let cal = Calendar.current
        guard let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return (0..<7).reduce(0) { sum, offset in
            guard let d = cal.date(byAdding: .day, value: offset, to: start) else { return sum }
            return sum + stationsPlayed(on: d)
        }
    }

    var lessonsTotal: Int { dailyStations.values.reduce(0, +) }

    @discardableResult
    private func registerActivityToday() -> Int {
        let today = dayKey(Date())
        dailyStations[today, default: 0] += 1
        if firstStudy == nil { firstStudy = Date().timeIntervalSince1970 }
        if lastStudy == today { return streak }
        streak = (lastStudy == yesterdayKey) ? streak + 1 : 1
        lastStudy = today
        return streak
    }

    // MARK: - Chests & gift cards

    func chestKey(_ unitId: String, _ stationIndex: Int) -> String { "\(unitId)-chest-\(stationIndex)" }

    func isChestClaimed(_ key: String) -> Bool { chests[key] ?? false }

    /// Opening a chest needs nothing but a tap once the station before it is done: it pays out talents.
    func claimChest(unitIndex: Int, stationIndex: Int) {
        let unit = content.units[unitIndex]
        let key = chestKey(unit.id, stationIndex)
        guard isUnitUnlocked(unitIndex),
              isStationDone(unit.id, stationIndex),
              !isChestClaimed(key)
        else { return }
        talents += Self.talentsPerChest
        chests[key] = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        screen = .chest(Self.talentsPerChest)
    }

    func ownsCard(_ gift: Gift) -> Bool { ownedCards.contains(gift.emoji) }

    func canBuyCard(_ gift: Gift) -> Bool { !ownsCard(gift) && talents >= Self.cardPrice }

    @discardableResult
    func buyCard(_ gift: Gift) -> Bool {
        guard canBuyCard(gift) else { return false }
        talents -= Self.cardPrice
        ownedCards.append(gift.emoji)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return true
    }

    // MARK: - Lesson flow

    func startStation(unitIndex: Int, stationIndex: Int) {
        guard currentHearts > 0 else { return }
        let station = content.units[unitIndex].stations[stationIndex]
        var state = LessonState(unitIndex: unitIndex,
                                stationIndex: stationIndex,
                                qs: station.qs.shuffled(),
                                hearts: currentHearts)
        state.prepareQuestion()
        lesson = state
        screen = .lesson
    }

    func answer(_ originalIndex: Int) {
        guard var state = lesson, state.answered == nil else { return }
        state.answered = originalIndex
        let isCorrect = originalIndex == state.current.c
        if isCorrect {
            state.correct += 1
        } else {
            loseHeart()
            state.hearts = currentHearts
        }
        lesson = state
        UINotificationFeedbackGenerator().notificationOccurred(isCorrect ? .success : .error)
    }

    func advance() {
        guard var state = lesson else { return }
        if state.hearts <= 0 {
            state.failed = true
            lesson = state
            finishStation()
        } else if state.isLast {
            finishStation()
        } else {
            state.idx += 1
            state.prepareQuestion()
            lesson = state
        }
    }

    private func finishStation() {
        guard let state = lesson else { return }
        let unit = content.units[state.unitIndex]
        let success = !state.failed
        let gain = state.correct * Self.xpPerCorrect + (success ? Self.completionBonus : 0)
        xp += gain
        // Only celebrate the section once: replaying a station in an already
        // finished section must not show the "section complete" banner again.
        let wasComplete = isUnitComplete(unit)
        var unitJustCompleted = false
        if success {
            markStationDone(unit.id, state.stationIndex)
            unitJustCompleted = !wasComplete && isUnitComplete(unit)
        }
        let streakNow = registerActivityToday()
        let hasNext = success && !unitJustCompleted && state.stationIndex + 1 < unit.stations.count
        screen = .result(LessonResult(success: success,
                                      xpGain: gain,
                                      streak: streakNow,
                                      unitJustCompleted: unitJustCompleted,
                                      hasNext: hasNext))
    }

    func goHome() {
        screen = .home
        lesson = nil
    }
}
