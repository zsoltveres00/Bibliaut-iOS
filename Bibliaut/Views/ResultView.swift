import SwiftUI

struct ResultView: View {
    @Environment(GameStore.self) private var store
    let result: LessonResult

    var body: some View {
        let s = store.strings
        ScrollView {
            VStack(spacing: 6) {
                Text(result.success ? "🎉" : "💔")
                    .font(.system(size: 42))
                Text(result.success ? s.successTitle : s.failTitle)
                    .font(.heading(24))
                    .foregroundStyle(Color.text)
                    .padding(.bottom, 8)
                Text("+\(result.xpGain) XP")
                    .font(.heading(38))
                    .foregroundStyle(Color.gold)

                if result.success {
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
            ChestIcon(size: 84, color: Color.gold)
                .padding(.vertical, 14)
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
