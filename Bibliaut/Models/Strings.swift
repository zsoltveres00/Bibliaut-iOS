import Foundation

/// UI strings for both languages (same wording as the web version where it exists).
struct Strings {
    let lang: Lang

    private func t(_ hu: String, _ en: String) -> String { lang == .hu ? hu : en }

    var locale: Locale { Locale(identifier: lang == .hu ? "hu_HU" : "en_US") }

    // Home
    var brand: String { t("Bibliaút", "Bible Path") }
    var subtitle: String { t("Tanuld meg a Biblia történetét lépésről lépésre", "Learn the story of the Bible step by step") }
    func greeting(_ name: String) -> String { t("Szia, \(name)!", "Hi, \(name)!") }
    var level: String { t("Szint", "Level") }
    func unitProgress(_ done: Int, _ total: Int) -> String { t("\(done)/\(total) állomás", "\(done)/\(total) stations") }
    var section: String { t("SZAKASZ", "SECTION") }
    var station: String { t("ÁLLOMÁS", "STATION") }

    // Lesson & result
    var backHome: String { t("‹ Vissza az ösvényhez", "‹ Back to the path") }
    func stationTag(_ n: Int, _ total: Int) -> String { t("\(n)/\(total). állomás", "Station \(n)/\(total)") }
    var next: String { t("Következő", "Next") }
    var seeResult: String { t("Eredmény", "See result") }
    var endLesson: String { t("Lecke vége", "End lesson") }
    var successTitle: String { t("Állomás teljesítve!", "Station complete!") }
    var failTitle: String { t("Elfogytak az életeid", "Out of hearts") }
    var failBody: String { t("Semmi baj, a megszerzett pontjaid megmaradnak.", "No worries, the points you earned are kept.") }
    func waitForHeart(_ mmss: String) -> String { t("Következő szív: \(mmss)", "Next heart: \(mmss)") }
    func unitCompleteMsg(_ name: String) -> String { t("🏆 Teljes szakasz teljesítve: \(name)", "🏆 Section complete: \(name)") }
    var nextStation: String { t("Következő állomás", "Next station") }
    var retry: String { t("Próbáld újra", "Try again") }
    var streakSuffix: String { t("napos sorozat", "day streak") }
    var reviewTag: String { t("Hibák javítása", "Fix your mistakes") }
    var startReview: String { t("Hibák javítása", "Fix mistakes") }
    var reviewHint: String { t("Ami nem sikerült, azt még egyszer megkérdezzük.", "We'll ask the ones you missed once more.") }
    func starsTitle(_ stars: Int) -> String {
        switch stars {
        case 3: return t("Tökéletes!", "Perfect!")
        case 2: return t("Szép munka!", "Nice work!")
        default: return t("Állomás teljesítve!", "Station complete!")
        }
    }
    func mistakesFixed(_ n: Int) -> String {
        n == 0 ? t("Egy hibád sem volt!", "Not a single mistake!")
               : t("\(n) hibát kijavítottál", n == 1 ? "You fixed 1 mistake" : "You fixed \(n) mistakes")
    }
    func runBonus(_ multiplier: Double) -> String {
        let m = multiplier == 2 ? "2" : "1,5"
        return t("×\(m) sorozat-bónusz", "×\(multiplier == 2 ? "2" : "1.5") streak bonus")
    }

    // Chest & talents
    var talents: String { t("talentum", "talents") }
    var chestFound: String { t("Kincsesládát találtál!", "You found a treasure chest!") }
    func talentsGain(_ n: Int) -> String { t("+\(n) talentum", "+\(n) talents") }
    func talentsBalance(_ n: Int) -> String { t("Egyenleged: \(n) talentum", "Your balance: \(n) talents") }
    var chestHint: String { t("Minden teljesített állomás talentumot ad, a ládák minden 5. állomás után extra 20-at.", "Every finished station earns talents; chests after every 5th station hold 20 more.") }

    // Bottom bar & menu
    var tabHome: String { t("Ösvény", "Path") }
    var tabCollection: String { t("Gyűjtemény", "Collection") }
    var tabStats: String { t("Statisztika", "Stats") }
    var menu: String { t("Menü", "Menu") }
    var profile: String { t("Profil", "Profile") }
    var language: String { t("Nyelv", "Language") }
    var comingSoon: String { t("Hamarosan", "Coming soon") }
    var yourName: String { t("A neved", "Your name") }
    var namePlaceholder: String { t("Hogy szólíthatunk?", "What should we call you?") }
    var save: String { t("Mentés", "Save") }
    var close: String { t("Bezárás", "Close") }

    // Collection
    var collectionIntro: String { t("Gyűjtsd össze mind a 8 kártyát! Egy kártya ára:", "Collect all 8 cards! One card costs:") }
    var owned: String { t("Megvan", "Owned") }
    var buy: String { t("Megveszem", "Buy") }
    func cardsOwned(_ n: Int, _ total: Int) -> String { t("\(n)/\(total) kártya", "\(n)/\(total) cards") }

    // Stats
    var statLevel: String { t("Szint", "Level") }
    var statStreak: String { t("Sorozat", "Streak") }
    var statWeek: String { t("Ezen a héten", "This week") }
    var statStations: String { t("Állomások", "Stations") }
    var statLessons: String { t("Összes lecke", "Lessons played") }
    func lessons(_ n: Int) -> String { t("\(n) lecke", n == 1 ? "1 lesson" : "\(n) lessons") }
    func days(_ n: Int) -> String { t("\(n) nap", n == 1 ? "1 day" : "\(n) days") }
    var studiedDay: String { t("tanult nap", "studied") }
    var missedDay: String { t("kihagyott nap", "missed") }
    var calendarTitle: String { t("Naptár", "Calendar") }
    func monthSummary(_ studied: Int, _ missed: Int) -> String {
        t("\(studied) tanult · \(missed) kihagyott nap", "\(studied) studied · \(missed) missed days")
    }
}
