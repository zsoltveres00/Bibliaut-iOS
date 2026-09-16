import Foundation

enum Lang: String, CaseIterable, Codable {
    case hu, en
}

/// The whole curriculum, decoded once from `Resources/content.json`
/// (which was exported verbatim from the web version's data section).
struct Content: Decodable {
    let levels: [Level]
    let gifts: [Gift]
    let icons: [String: String]
    let units: [PathUnit]

    static let shared: Content = {
        guard let url = Bundle.main.url(forResource: "content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let content = try? JSONDecoder().decode(Content.self, from: data)
        else { fatalError("content.json is missing from the bundle or is invalid") }
        return content
    }()
}

struct Level: Decodable {
    let min: Int
    let hu: String
    let en: String
    func name(_ lang: Lang) -> String { lang == .hu ? hu : en }
}

struct Gift: Decodable, Equatable {
    let emoji: String
    let hu: String
    let en: String
    func name(_ lang: Lang) -> String { lang == .hu ? hu : en }
}

/// A section of the path (named `PathUnit` to avoid shadowing Foundation's `Unit`).
struct PathUnit: Decodable, Identifiable {
    let id: String
    let emoji: String
    let color: String
    let hu: String
    let en: String
    let stations: [Station]
    func name(_ lang: Lang) -> String { lang == .hu ? hu : en }
}

struct Station: Decodable {
    let hu: String
    let en: String
    let qs: [Question]
    func name(_ lang: Lang) -> String { lang == .hu ? hu : en }
}

struct Question: Decodable {
    struct Localized: Decodable {
        let q: String
        let o: [String]?
    }

    struct ImageOption: Decodable {
        let icon: String
        let hu: String
        let en: String
        let color: String?
        func label(_ lang: Lang) -> String { lang == .hu ? hu : en }
    }

    let type: String?
    let hu: Localized
    let en: Localized
    let opts: [ImageOption]?
    /// Index of the correct option (in original, unshuffled order).
    let c: Int

    var isImage: Bool { type == "image" }

    func prompt(_ lang: Lang) -> String { lang == .hu ? hu.q : en.q }

    var optionCount: Int {
        isImage ? (opts?.count ?? 0) : (hu.o?.count ?? 0)
    }

    func optionLabel(_ index: Int, _ lang: Lang) -> String {
        if isImage { return opts?[index].label(lang) ?? "" }
        let list = lang == .hu ? hu.o : en.o
        guard let list, index < list.count else { return "" }
        return list[index]
    }
}
