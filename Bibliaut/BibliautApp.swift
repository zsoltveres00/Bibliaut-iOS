import SwiftUI

@main
struct BibliautApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}

/// Switches between the four screens of the app, mirroring the web version's `render()`.
struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            switch store.screen {
            case .home:
                MainView()
            case .lesson:
                LessonView()
            case .result(let result):
                ResultView(result: result)
            case .chest(let talents):
                ChestRewardView(talents: talents)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.screen)
    }
}
