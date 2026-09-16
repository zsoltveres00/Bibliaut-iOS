import SwiftUI

struct LessonView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        if let lesson = store.lesson {
            LessonContent(lesson: lesson)
        }
    }
}

enum OptionState { case idle, correct, wrong }

private struct LessonContent: View {
    @Environment(GameStore.self) private var store
    let lesson: LessonState

    var body: some View {
        let s = store.strings
        let unit = store.content.units[lesson.unitIndex]
        let question = lesson.current

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BackLink(title: s.backHome) { store.goHome() }
                    .padding(.bottom, 14)

                HStack {
                    Text("\(unit.emoji) \(s.stationTag(lesson.stationIndex + 1, unit.stations.count))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.muted)
                    Spacer()
                    Text(heartsString(lesson.hearts))
                        .font(.system(size: 16))
                        .tracking(2)
                }
                .padding(.bottom, 16)

                HStack(spacing: 5) {
                    ForEach(0..<lesson.queue.count, id: \.self) { i in
                        Circle()
                            .fill(i < lesson.pos ? dotColor : Color.clear)
                            .overlay(Circle().stroke(i <= lesson.pos ? dotColor : Color.border, lineWidth: 2))
                            .frame(width: 9, height: 9)
                    }
                    if lesson.reviewing {
                        Label(s.reviewTag, systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.wrong)
                            .padding(.leading, 6)
                    }
                }
                .padding(.bottom, 20)

                Text(question.prompt(store.lang))
                    .font(.heading(20, weight: .semibold))
                    .foregroundStyle(Color.text)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 20)

                if question.isImage {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(lesson.optionOrder, id: \.self) { orig in
                            let opt = question.opts?[orig]
                            OptionButton(state: state(for: orig), disabled: lesson.answered != nil) {
                                store.answer(orig)
                            } label: {
                                VStack(spacing: 8) {
                                    IconView(key: opt?.icon ?? "", tint: opt?.color)
                                    Text(question.optionLabel(orig, store.lang))
                                        .font(.system(size: 13, weight: .semibold))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(lesson.optionOrder, id: \.self) { orig in
                            OptionButton(state: state(for: orig), disabled: lesson.answered != nil) {
                                store.answer(orig)
                            } label: {
                                Text(question.optionLabel(orig, store.lang))
                                    .font(.system(size: 16, weight: .medium))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .id("\(lesson.reviewing)-\(lesson.pos)") // reset scroll position for each question
        .background(Color.bg)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if lesson.answered != nil {
                PrimaryButton(nextLabel(s)) { store.advance() }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(Color.bg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: lesson.answered)
    }

    private var dotColor: Color { lesson.reviewing ? Color.wrong : Color.gold }

    private func nextLabel(_ s: Strings) -> String {
        if lesson.hearts <= 0 { return s.endLesson }
        guard lesson.isLastInPass else { return s.next }
        return lesson.toReview.isEmpty ? s.seeResult : s.startReview
    }

    private func state(for orig: Int) -> OptionState {
        guard let answered = lesson.answered else { return .idle }
        if orig == lesson.current.c { return .correct }
        if orig == answered { return .wrong }
        return .idle
    }

    private func heartsString(_ n: Int) -> String {
        (0..<GameStore.heartsMax).map { $0 < n ? "❤️" : "🤍" }.joined()
    }
}

/// Answer card: neutral until answered, then green for the right answer / red for a wrong pick.
struct OptionButton<LabelView: View>: View {
    let state: OptionState
    let disabled: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> LabelView

    var body: some View {
        Button(action: action) {
            label()
                .foregroundStyle(Color.text)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surface)
                        .overlay(RoundedRectangle(cornerRadius: 12).fill(tint.opacity(state == .idle ? 0 : 0.16)))
                }
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1.5))
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var tint: Color {
        switch state {
        case .idle: return .clear
        case .correct: return Color.correct
        case .wrong: return Color.wrong
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle: return Color.border
        case .correct: return Color.correct
        case .wrong: return Color.wrong
        }
    }
}
