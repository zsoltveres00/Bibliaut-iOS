import SwiftUI

/// One drawable primitive parsed from an icon's SVG snippet.
struct IconElement {
    enum Paint {
        case current      // "currentColor" -> text color
        case surface      // "var(--surface)" -> card color
        case fixed(Color) // literal hex
    }

    var path: Path
    var fill: Paint?
    var stroke: Paint?
    var strokeWidth: CGFloat = 1
    var lineCap: CGLineCap = .butt
}

/// Minimal parser for the SVG subset used by the 25 picture-question icons:
/// `path` (M L Q T C A Z), `circle`, `ellipse`, `rect` (with rx), `line`.
/// Icons are drawn in a 48×48 viewBox.
enum IconRenderer {
    static let viewBox: CGFloat = 48

    private static let elementRegex = try! NSRegularExpression(pattern: "<([a-z]+)\\b([^>]*?)/?>")
    private static let attrRegex = try! NSRegularExpression(pattern: "([a-zA-Z0-9:-]+)=\"([^\"]*)\"")
    private static let pathTokenRegex = try! NSRegularExpression(pattern: "[MLQTACZz]|-?(?:\\d+\\.?\\d*|\\.\\d+)")

    private static var cache: [String: [IconElement]] = [:]
    private static let lock = NSLock()

    static func elements(for key: String, tint: String?) -> [IconElement] {
        let cacheKey = key + "|" + (tint ?? "")
        lock.lock(); defer { lock.unlock() }
        if let cached = cache[cacheKey] { return cached }

        guard let raw = Content.shared.icons[key] else { return [] }
        let svg = raw.replacingOccurrences(of: "{c}", with: tint ?? "currentColor")
        let ns = svg as NSString
        var out: [IconElement] = []

        for match in elementRegex.matches(in: svg, range: NSRange(location: 0, length: ns.length)) {
            let tag = ns.substring(with: match.range(at: 1))
            let attrs = parseAttrs(ns.substring(with: match.range(at: 2)))
            guard var element = makeElement(tag: tag, attrs: attrs) else { continue }
            element.fill = tag == "line" ? nil : paint(attrs["fill"] ?? "currentColor")
            element.stroke = paint(attrs["stroke"])
            element.strokeWidth = CGFloat(Double(attrs["stroke-width"] ?? "1") ?? 1)
            element.lineCap = attrs["stroke-linecap"] == "round" ? .round : .butt
            out.append(element)
        }
        cache[cacheKey] = out
        return out
    }

    // MARK: - Attributes

    private static func paint(_ value: String?) -> IconElement.Paint? {
        guard let value, value != "none" else { return nil }
        if value == "currentColor" { return .current }
        if value.hasPrefix("var(") { return .surface }
        if value.hasPrefix("#") { return .fixed(Color(hex: value)) }
        return .current
    }

    private static func parseAttrs(_ s: String) -> [String: String] {
        let ns = s as NSString
        var dict: [String: String] = [:]
        for m in attrRegex.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            dict[ns.substring(with: m.range(at: 1))] = ns.substring(with: m.range(at: 2))
        }
        return dict
    }

    private static func num(_ attrs: [String: String], _ key: String) -> CGFloat {
        CGFloat(Double(attrs[key] ?? "") ?? 0)
    }

    // MARK: - Elements

    private static func makeElement(tag: String, attrs: [String: String]) -> IconElement? {
        switch tag {
        case "path":
            guard let d = attrs["d"] else { return nil }
            return IconElement(path: parsePath(d))
        case "circle":
            let r = num(attrs, "r")
            let rect = CGRect(x: num(attrs, "cx") - r, y: num(attrs, "cy") - r, width: 2 * r, height: 2 * r)
            return IconElement(path: Path(ellipseIn: rect))
        case "ellipse":
            let rx = num(attrs, "rx"), ry = num(attrs, "ry")
            let rect = CGRect(x: num(attrs, "cx") - rx, y: num(attrs, "cy") - ry, width: 2 * rx, height: 2 * ry)
            return IconElement(path: Path(ellipseIn: rect))
        case "rect":
            let rect = CGRect(x: num(attrs, "x"), y: num(attrs, "y"), width: num(attrs, "width"), height: num(attrs, "height"))
            let rx = num(attrs, "rx")
            return IconElement(path: rx > 0 ? Path(roundedRect: rect, cornerRadius: rx) : Path(rect))
        case "line":
            var p = Path()
            p.move(to: CGPoint(x: num(attrs, "x1"), y: num(attrs, "y1")))
            p.addLine(to: CGPoint(x: num(attrs, "x2"), y: num(attrs, "y2")))
            return IconElement(path: p)
        default:
            return nil
        }
    }

    // MARK: - Path data

    private enum Token {
        case cmd(Character)
        case num(CGFloat)
    }

    private static func tokenize(_ d: String) -> [Token] {
        let ns = d as NSString
        return pathTokenRegex.matches(in: d, range: NSRange(location: 0, length: ns.length)).map { m in
            let s = ns.substring(with: m.range)
            if let v = Double(s) { return .num(CGFloat(v)) }
            return .cmd(Character(s.uppercased()))
        }
    }

    private static func parsePath(_ d: String) -> Path {
        var path = Path()
        let tokens = tokenize(d)
        var i = 0
        var cmd: Character = "M"
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastControl: CGPoint? = nil

        func next() -> CGFloat {
            guard i < tokens.count, case .num(let v) = tokens[i] else { return 0 }
            i += 1
            return v
        }
        func point() -> CGPoint { CGPoint(x: next(), y: next()) }

        while i < tokens.count {
            if case .cmd(let c) = tokens[i] {
                cmd = c
                i += 1
                if cmd == "Z" {
                    path.closeSubpath()
                    current = subpathStart
                    lastControl = nil
                }
                continue
            }
            switch cmd {
            case "M":
                current = point()
                path.move(to: current)
                subpathStart = current
                lastControl = nil
                cmd = "L" // implicit lineto after moveto
            case "L":
                current = point()
                path.addLine(to: current)
                lastControl = nil
            case "Q":
                let control = point()
                let end = point()
                path.addQuadCurve(to: end, control: control)
                lastControl = control
                current = end
            case "T":
                let control = lastControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                let end = point()
                path.addQuadCurve(to: end, control: control)
                lastControl = control
                current = end
            case "C":
                let c1 = point()
                let c2 = point()
                let end = point()
                path.addCurve(to: end, control1: c1, control2: c2)
                lastControl = nil
                current = end
            case "A":
                let rx = next(), ry = next()
                _ = next() // x-axis rotation (unused, all icon arcs are circular)
                let large = next() != 0
                let sweep = next() != 0
                let end = point()
                addArc(&path, from: current, to: end, rx: rx, ry: ry, large: large, sweep: sweep)
                lastControl = nil
                current = end
            default:
                i += 1
            }
        }
        return path
    }

    /// SVG endpoint-parameterised arc -> center arc (SVG spec appendix F.6.5).
    private static func addArc(_ path: inout Path, from a: CGPoint, to b: CGPoint,
                               rx rxIn: CGFloat, ry ryIn: CGFloat, large: Bool, sweep: Bool) {
        var rx = abs(rxIn), ry = abs(ryIn)
        guard rx > 0, ry > 0, a != b else { path.addLine(to: b); return }

        let x1p = (a.x - b.x) / 2
        let y1p = (a.y - b.y) / 2
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            rx *= sqrt(lambda)
            ry *= sqrt(lambda)
        }
        let numerator = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let denominator = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        var coef = denominator == 0 ? 0 : sqrt(max(0, numerator / denominator))
        if large == sweep { coef = -coef }
        let cxp = coef * (rx * y1p / ry)
        let cyp = coef * -(ry * x1p / rx)
        let center = CGPoint(x: cxp + (a.x + b.x) / 2, y: cyp + (a.y + b.y) / 2)

        let theta1 = atan2((y1p - cyp) / ry, (x1p - cxp) / rx)
        let theta2 = atan2((-y1p - cyp) / ry, (-x1p - cxp) / rx)
        var delta = theta2 - theta1
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }

        // In SwiftUI's y-down space, `clockwise: false` sweeps in the positive-angle direction.
        path.addArc(center: center,
                    radius: (rx + ry) / 2,
                    startAngle: .radians(theta1),
                    endAngle: .radians(theta1 + delta),
                    clockwise: delta < 0)
    }
}

/// Draws one of the picture-question icons at a given point size.
struct IconView: View {
    let key: String
    var tint: String? = nil
    var size: CGFloat = 38

    var body: some View {
        let elements = IconRenderer.elements(for: key, tint: tint)
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / IconRenderer.viewBox
            context.scaleBy(x: scale, y: scale)
            for element in elements {
                if let fill = element.fill {
                    context.fill(element.path, with: .color(resolve(fill)))
                }
                if let stroke = element.stroke {
                    context.stroke(element.path,
                                   with: .color(resolve(stroke)),
                                   style: StrokeStyle(lineWidth: element.strokeWidth, lineCap: element.lineCap))
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func resolve(_ paint: IconElement.Paint) -> Color {
        switch paint {
        case .current: return Color.text
        case .surface: return Color.surface
        case .fixed(let color): return color
        }
    }
}
