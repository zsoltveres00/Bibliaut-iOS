import SwiftUI

struct ResultView: View {
    @Environment(GameStore.self) private var store
    let result: LessonResult

    var body: some View {
        let s = store.strings
        ScrollView {
            VStack(spacing: 6) {
                if result.success {
                    ResultStars(stars: result.stars)
                        .padding(.bottom, 6)
                } else {
                    Text("💔")
                        .font(.system(size: 42))
                }
                Text(result.success ? s.starsTitle(result.stars) : s.failTitle)
                    .font(.heading(24))
                    .foregroundStyle(Color.text)
                Text(s.mistakesFixed(result.mistakes))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.muted)
                    .padding(.bottom, 8)
                    .opacity(result.success ? 1 : 0)
                Text("+\(result.xpGain) XP")
                    .font(.heading(38))
                    .foregroundStyle(Color.gold)

                if result.success {
                    HStack(spacing: 6) {
                        TalentCoin(size: 20)
                        Text(s.talentsGain(result.talentGain))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.text)
                        if result.talentMultiplier > 1 {
                            Text(s.runBonus(result.talentMultiplier))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.bannerInk)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.heroGradient, in: Capsule())
                        }
                    }
                    .padding(.top, 4)
                    Text("🔥 \(result.streak) \(s.streakSuffix)")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.muted)
                    if result.unitJustCompleted, let lesson = store.lesson {
                        banner(s.unitCompleteMsg(store.content.units[lesson.unitIndex].name(store.lang)), color: Color.gold)
                            .padding(.top, 12)
                    }
                } else {
                    Text(s.failBody)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.muted)
                    if store.currentHearts <= 0 {
                        banner("❤️ " + s.waitForHeart(store.formatCountdown(store.secondsUntilNextHeart)), color: Color.wrong)
                            .padding(.top, 16)
                    }
                }

                VStack(spacing: 10) { actions }
                    .padding(.top, 28)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 40)
            .padding(.bottom, 24)
        }
        .background(Color.bg)
    }

    private func banner(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 1))
    }

    @ViewBuilder
    private var actions: some View {
        let s = store.strings
        if !result.success {
            if store.currentHearts > 0, let lesson = store.lesson {
                PrimaryButton(s.retry) {
                    store.startStation(unitIndex: lesson.unitIndex, stationIndex: lesson.stationIndex)
                }
                SecondaryButton(s.backHome) { store.goHome() }
            } else {
                PrimaryButton(s.backHome) { store.goHome() }
            }
        } else if result.hasNext, let lesson = store.lesson {
            PrimaryButton(s.nextStation) {
                store.startStation(unitIndex: lesson.unitIndex, stationIndex: lesson.stationIndex + 1)
            }
            SecondaryButton(s.backHome) { store.goHome() }
        } else {
            PrimaryButton(s.backHome) { store.goHome() }
        }
    }
}

/// Three big stars that pop in one after another; the unearned ones stay grey outlines.
struct ResultStars: View {
    let stars: Int
    @State private var shown = 0

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { i in
                let earned = i < stars
                Image(systemName: earned ? "star.fill" : "star")
                    .font(.system(size: i == 1 ? 54 : 42, weight: .bold))
                    .foregroundStyle(earned ? Color.star : Color.border)
                    .shadow(color: earned ? Color.star.opacity(0.6) : .clear, radius: 8)
                    .scaleEffect(i < shown ? 1 : 0.3)
                    .opacity(i < shown ? 1 : 0)
                    .offset(y: i == 1 ? -8 : 0)
            }
        }
        .frame(height: 70)
        .task {
            for i in 0..<3 {
                try? await Task.sleep(for: .milliseconds(i == 0 ? 150 : 220))
                withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { shown = i + 1 }
            }
        }
    }
}

/// Shown right after a treasure chest on the path was tapped open.
struct ChestRewardView: View {
    @Environment(GameStore.self) private var store
    let talents: Int

    var body: some View {
        let s = store.strings
        VStack(spacing: 6) {
            Text(s.chestFound)
                .font(.heading(24))
                .foregroundStyle(Color.text)
            ChestView(open: true, size: 120)
                .padding(.vertical, 20)
            HStack(spacing: 8) {
                TalentCoin(size: 30)
                Text(s.talentsGain(talents))
                    .font(.heading(34))
                    .foregroundStyle(Color.gold)
            }
            Text(s.talentsBalance(store.talents))
                .font(.system(size: 15))
                .foregroundStyle(Color.muted)
                .padding(.top, 4)
            PrimaryButton(s.backHome) { store.goHome() }
                .padding(.top, 28)
            SecondaryButton(s.tabCollection) {
                store.tab = .collection
                store.goHome()
            }
            .padding(.top, 10)
            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.top, 60)
        .background(Color.bg)
    }
}
