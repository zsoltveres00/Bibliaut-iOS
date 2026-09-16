import SwiftUI

/// The tabbed shell shown while no lesson is running: path / collection / stats + bottom bar.
struct MainView: View {
    @Environment(GameStore.self) private var store
    @State private var showMenu = false

    var body: some View {
        Group {
            switch store.tab {
            case .home: HomeView()
            case .collection: CollectionView()
            case .stats: StatsView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomNav(showMenu: $showMenu)
        }
        .sheet(isPresented: $showMenu) {
            MenuSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

/// The path page.
struct HomeView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let s = store.strings
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.brand)
                        .font(.heading(28))
                    Text(store.playerName.isEmpty ? s.subtitle : s.greeting(store.playerName))
                        .font(.system(size: 15))
                        .opacity(0.9)
                    HStack(spacing: 6) {
                        Image(systemName: "rosette")
                        Text("\(s.level): \(store.levelName)")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.18), in: Capsule())
                    .padding(.top, 8)
                }
                .foregroundStyle(Color.bannerInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color.heroGradient, in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.shadow, radius: 8, y: 4)

                StatsBar()
                    .padding(.vertical, 12)

                if let next = store.nextStation {
                    ModuleBanner(unitIndex: next.unitIndex, stationIndex: next.stationIndex)
                        .padding(.bottom, 14)
                }

                PathView()
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color.bg)
    }
}

// MARK: - Stats chips

struct StatsBar: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        // Four equal tiles in one row: icon on top, value below.
        HStack(spacing: 8) {
            Chip(value: "\(store.displayStreak)", color: Color.gold) {
                Image(systemName: "flame.fill")
            }
            Chip(value: "\(store.xp)", detail: "XP", color: Color.brand) {
                Image(systemName: "book.fill")
            }
            Chip(value: "\(store.currentHearts)/\(GameStore.heartsMax)", detail: heartsDetail, color: Color.wrong) {
                Image(systemName: "heart.fill")
            }
            Chip(value: "\(store.talents)", color: Color.text) {
                TalentCoin(size: 20)
            }
        }
    }

    /// Countdown to the next heart while any is missing.
    private var heartsDetail: String? {
        store.currentHearts < GameStore.heartsMax ? store.formatCountdown(store.secondsUntilNextHeart) : nil
    }
}

/// Stat tile: icon above the value, optional small detail line under it.
struct Chip<Icon: View>: View {
    let value: String
    var detail: String? = nil
    let color: Color
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        VStack(spacing: 3) {
            icon()
                .font(.system(size: 18, weight: .bold))
                .frame(height: 22)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail ?? " ")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.muted)
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
    }
}

// MARK: - "Continue" banner

struct ModuleBanner: View {
    @Environment(GameStore.self) private var store
    let unitIndex: Int
    let stationIndex: Int

    var body: some View {
        let unit = store.content.units[unitIndex]
        let s = store.strings
        let enabled = store.currentHearts > 0
        Button {
            store.startStation(unitIndex: unitIndex, stationIndex: stationIndex)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(unitIndex + 1). \(s.section), \(stationIndex + 1). \(s.station)")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .opacity(0.85)
                    Text(unit.stations[stationIndex].name(store.lang))
                        .font(.heading(18))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 12)
                Text(unit.emoji)
                    .font(.system(size: 22))
                    .opacity(0.9)
            }
            .foregroundStyle(Color.bannerInk)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: unit.color), in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.shadow, radius: 5, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.6)
    }
}

// MARK: - Path

enum HPos { case c, l, r }

enum PathRow: Identifiable {
    case marker(Int)
    case station(Int, Int, HPos)
    case chest(Int, Int)

    var id: String {
        switch self {
        case .marker(let u): return "m\(u)"
        case .station(let u, let s, _): return "s\(u)-\(s)"
        case .chest(let u, let s): return "c\(u)-\(s)"
        }
    }
}

/// Every node on the path reports its center so the connecting line can be drawn behind them.
struct NodeAnchorKey: PreferenceKey {
    static let defaultValue: [Anchor<CGPoint>] = []
    static func reduce(value: inout [Anchor<CGPoint>], nextValue: () -> [Anchor<CGPoint>]) {
        value.append(contentsOf: nextValue())
    }
}

struct PathView: View {
    @Environment(GameStore.self) private var store

    /// Vertical gap between consecutive nodes (~0.5 cm on an iPhone).
    static let rowSpacing: CGFloat = 8

    private var rows: [PathRow] {
        var out: [PathRow] = []
        var flat = 0
        let pattern: [HPos] = [.c, .r, .l]
        for (ui, unit) in store.content.units.enumerated() {
            out.append(.marker(ui))
            for si in unit.stations.indices {
                out.append(.station(ui, si, pattern[flat % pattern.count]))
                flat += 1
                if GameStore.chestAfter.contains(si) {
                    out.append(.chest(ui, si))
                    flat += 1
                }
            }
        }
        return out
    }

    var body: some View {
        VStack(spacing: Self.rowSpacing) {
            ForEach(rows) { row in
                switch row {
                case .marker(let ui):
                    MarkerRow(unitIndex: ui)
                case .station(let ui, let si, let pos):
                    StationRow(unitIndex: ui, stationIndex: si, pos: pos)
                case .chest(let ui, let si):
                    ChestRow(unitIndex: ui, stationIndex: si)
                }
            }
        }
        .backgroundPreferenceValue(NodeAnchorKey.self) { anchors in
            GeometryReader { geo in
                Path { p in
                    let points = anchors.map { geo[$0] }
                    guard let first = points.first else { return }
                    p.move(to: first)
                    for pt in points.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(Color.border, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

struct MarkerRow: View {
    @Environment(GameStore.self) private var store
    let unitIndex: Int

    var body: some View {
        let unit = store.content.units[unitIndex]
        let unlocked = store.isUnitUnlocked(unitIndex)
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color(hex: unit.color) : Color.surface)
                    .shadow(color: Color.shadow, radius: 6, y: 4)
                Circle()
                    .stroke(unlocked ? Color.surface : Color.border, lineWidth: unlocked ? 3 : 2)
                if unlocked {
                    Text(unit.emoji).font(.system(size: 30))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.muted)
                }
            }
            .frame(width: 74, height: 74)
            .opacity(unlocked ? 1 : 0.55)
            .anchorPreference(key: NodeAnchorKey.self, value: .center) { [$0] }

            Text(unit.name(store.lang))
                .font(.heading(16))
                .foregroundStyle(Color.text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 220)
            Text(store.strings.unitProgress(unlocked ? store.doneCount(unit.id) : 0, unit.stations.count))
                .font(.system(size: 12))
                .foregroundStyle(Color.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}

struct StationRow: View {
    @Environment(GameStore.self) private var store
    let unitIndex: Int
    let stationIndex: Int
    let pos: HPos

    var body: some View {
        let unit = store.content.units[unitIndex]
        let unitColor = Color(hex: unit.color)
        let completed = store.isStationDone(unit.id, stationIndex)
        let unlocked = store.isUnitUnlocked(unitIndex)
            && (stationIndex == 0 || store.isStationDone(unit.id, stationIndex - 1))
        let canPlay = unlocked && store.currentHearts > 0
        let next = store.nextStation
        let isNext = next?.unitIndex == unitIndex && next?.stationIndex == stationIndex

        HStack(spacing: 0) {
            if pos != .l { Spacer(minLength: 0) }
            Button {
                store.startStation(unitIndex: unitIndex, stationIndex: stationIndex)
            } label: {
                VStack(spacing: 2) {
                    ZStack {
                        if isNext {
                            Circle()
                                .stroke(unitColor.opacity(0.35), lineWidth: 5)
                                .padding(-6)
                        }
                        Circle()
                            .fill(unlocked ? unitColor : Color.surface)
                            .shadow(color: unlocked ? unitColor.opacity(0.45) : Color.shadow, radius: 4, y: 3)
                        Circle()
                            .stroke(unlocked ? Color.white.opacity(0.7) : Color.border, lineWidth: 2)
                        if completed {
                            StationStar(stars: store.stationStars(unit.id, stationIndex), size: 22)
                        } else if unlocked {
                            Text("\(stationIndex + 1)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color.bannerInk)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.muted)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .opacity(!unlocked || (!completed && !canPlay) ? 0.5 : 1)
                    .anchorPreference(key: NodeAnchorKey.self, value: .center) { [$0] }

                    Text(unit.stations[stationIndex].name(store.lang))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(width: 104)
            }
            .buttonStyle(.plain)
            .disabled(!canPlay)
            if pos != .r { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, pos == .l ? 24 : 0)
        .padding(.trailing, pos == .r ? 24 : 0)
    }
}

struct ChestRow: View {
    @Environment(GameStore.self) private var store
    let unitIndex: Int
    let stationIndex: Int

    var body: some View {
        let unit = store.content.units[unitIndex]
        let claimed = store.isChestClaimed(store.chestKey(unit.id, stationIndex))
        let ready = store.isUnitUnlocked(unitIndex) && store.isStationDone(unit.id, stationIndex) && !claimed

        Button {
            store.claimChest(unitIndex: unitIndex, stationIndex: stationIndex)
        } label: {
            ZStack {
                if ready {
                    Circle()
                        .fill(Color.star.opacity(0.35))
                        .blur(radius: 10)
                        .frame(width: 70, height: 70)
                }
                ChestView(open: claimed, size: 54)
                    .saturation(ready || claimed ? 1 : 0.2)
                if !ready && !claimed {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.bannerInk)
                        .padding(5)
                        .background(Color.muted, in: Circle())
                        .offset(x: 20, y: -18)
                }
            }
            .frame(width: 60, height: 60)
            .opacity(claimed ? 0.75 : (ready ? 1 : 0.55))
            .anchorPreference(key: NodeAnchorKey.self, value: .center) { [$0] }
        }
        .buttonStyle(.plain)
        .disabled(!ready)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bottom bar

struct BottomNav: View {
    @Environment(GameStore.self) private var store
    @Binding var showMenu: Bool

    var body: some View {
        let s = store.strings
        HStack(spacing: 0) {
            tabButton(.home, icon: "house.fill", label: s.tabHome)
            tabButton(.collection, icon: "archivebox.fill", label: s.tabCollection)
            tabButton(.stats, icon: "chart.bar.fill", label: s.tabStats)
            Button {
                showMenu = true
            } label: {
                VStack(spacing: 3) {
                    ZStack {
                        Circle().fill(Color.brand)
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.brandInk)
                    }
                    .frame(width: 28, height: 28)
                    Text(s.menu)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.muted)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.border).frame(height: 1)
        }
    }

    private func tabButton(_ tab: HomeTab, icon: String, label: String) -> some View {
        let active = store.tab == tab
        return Button {
            store.tab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(height: 28)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(active ? Color.brand : Color.muted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Menu & profile

struct MenuSheet: View {
    @Environment(GameStore.self) private var store
    @State private var showProfile = false

    var body: some View {
        let s = store.strings
        VStack(alignment: .leading, spacing: 8) {
            Text(s.menu)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.muted)
                .padding(.bottom, 4)

            MenuRow(icon: "person.crop.circle.fill", title: s.profile,
                    detail: store.playerName.isEmpty ? nil : store.playerName) {
                showProfile = true
            }

            // Language: inline HU / EN toggle.
            HStack(spacing: 12) {
                MenuIcon(name: "globe")
                Text(s.language)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.text)
                Spacer()
                ForEach(Lang.allCases, id: \.self) { lang in
                    let active = store.lang == lang
                    Button {
                        store.lang = lang
                    } label: {
                        Text(lang.rawValue.uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(active ? Color.brandInk : Color.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(active ? Color.brand : Color.bg, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? Color.brand : Color.border, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.bg, in: RoundedRectangle(cornerRadius: 12))

            // Two slots reserved for later features.
            MenuRow(icon: "sparkles", title: s.comingSoon, detail: nil, enabled: false) {}
            MenuRow(icon: "sparkles", title: s.comingSoon, detail: nil, enabled: false) {}

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.surface)
        .sheet(isPresented: $showProfile) {
            ProfileSheet()
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
        }
    }
}

struct MenuIcon: View {
    let name: String

    var body: some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.brand)
            .frame(width: 28)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let detail: String?
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                MenuIcon(name: icon)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.text)
                Spacer()
                if let detail {
                    Text(detail)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.muted)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.bg, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}

struct ProfileSheet: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        let s = store.strings
        VStack(alignment: .leading, spacing: 12) {
            Text(s.profile)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.muted)
            Text(s.yourName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.text)
            TextField(s.namePlaceholder, text: $name)
                .textInputAutocapitalization(.words)
                .font(.system(size: 16))
                .foregroundStyle(Color.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.bg, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border, lineWidth: 1.5))
            PrimaryButton(s.save) {
                store.playerName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                dismiss()
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.surface)
        .onAppear { name = store.playerName }
    }
}
