import WidgetKit
import SwiftUI
#if canImport(UIKit)
import UIKit
private typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
private typealias PlatformColor = NSColor
#endif

// MARK: - Palette Glance (Direction A : crème + vert forêt), adaptée clair/sombre

extension PlatformColor {
    fileprivate convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    // Couleur dynamique clair/sombre, portée sur UIKit (iOS) et AppKit (macOS).
    fileprivate init(light: UInt32, dark: UInt32) {
        #if canImport(UIKit)
        self = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
        })
        #elseif canImport(AppKit)
        self = Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? NSColor(rgb: dark) : NSColor(rgb: light)
        })
        #endif
    }
}

enum GT {
    static let accent = Color(light: 0x3B7A5A, dark: 0x5AA57E)
    static let bg = Color(light: 0xF7F5F1, dark: 0x1A1712)
    static let surface = Color(light: 0xFFFFFF, dark: 0x211D16)
    static let fg = Color(light: 0x211E19, dark: 0xF3F0E9)
    static let fg2 = Color(light: 0x8C857A, dark: 0xA69F91)
    static let fg3 = Color(light: 0xB4ADA1, dark: 0x6E685C)
    static let neg = Color(light: 0xB15A42, dark: 0xCF7A5F)
    static let line = Color(light: 0x1E190F, dark: 0xFAF5EB).opacity(0.10)
}

// MARK: - Données partagées (écrites par l'app via App Group)

struct SiteStat: Identifiable {
    let id = UUID()
    let name: String
    let value: Int
    let delta: Double?
    let spark: [Double]
}

struct GlanceData {
    var totalVisitors: Int
    var totalPageviews: Int
    var totalDelta: Double?
    var totalSpark: [Double]
    var periodLabel: String
    var updatedAt: Date?
    var siteCount: Int
    var sites: [SiteStat]

    // Sur macOS, l'identifiant d'App Group DOIT être préfixé par le Team ID ;
    // sur iOS c'est l'identifiant nu. Doit correspondre au suite name côté écriture
    // (home_widget sur iOS, MainFlutterWindow.swift sur macOS).
    #if os(macOS)
    static let appGroup = "5C67TFSJ2B.group.fr.mymonkey.glance"
    #else
    static let appGroup = "group.fr.mymonkey.glance"
    #endif

    static func load() -> GlanceData {
        let d = UserDefaults(suiteName: appGroup)
        func spark(_ key: String) -> [Double] {
            guard let s = d?.string(forKey: key), !s.isEmpty else { return [] }
            return s.split(separator: ",").compactMap { Double($0) }
        }
        func optDouble(_ key: String) -> Double? {
            (d?.object(forKey: key) as? NSNumber)?.doubleValue
        }
        let n = d?.integer(forKey: "site_count") ?? 0
        var sites: [SiteStat] = []
        for i in 0..<n {
            sites.append(SiteStat(
                name: d?.string(forKey: "site_\(i)_name") ?? "—",
                value: d?.integer(forKey: "site_\(i)_value") ?? 0,
                delta: optDouble("site_\(i)_delta"),
                spark: spark("site_\(i)_spark")
            ))
        }
        let ts = (d?.object(forKey: "updated_at") as? NSNumber)?.doubleValue
        return GlanceData(
            totalVisitors: d?.integer(forKey: "total_visitors") ?? 0,
            totalPageviews: d?.integer(forKey: "total_pageviews") ?? 0,
            totalDelta: optDouble("total_delta"),
            totalSpark: spark("total_spark"),
            periodLabel: d?.string(forKey: "period_label") ?? "",
            updatedAt: ts != nil ? Date(timeIntervalSince1970: ts! / 1000) : nil,
            siteCount: n,
            sites: sites
        )
    }

    var hasData: Bool { updatedAt != nil }

    static let placeholder = GlanceData(
        totalVisitors: 2104, totalPageviews: 8908, totalDelta: 14.3,
        totalSpark: [12, 18, 26, 40, 52, 44, 30, 24, 22, 18, 14, 10],
        periodLabel: "7 jours", updatedAt: Date(), siteCount: 3,
        sites: [
            SiteStat(name: "opensuperwhisper.com", value: 770, delta: -28.4,
                     spark: [40, 52, 44, 30, 24, 20]),
            SiteStat(name: "tamdoku.fr", value: 402, delta: 120,
                     spark: [10, 26, 30, 22, 18, 14]),
            SiteStat(name: "porndle-next", value: 345, delta: -0.6,
                     spark: [22, 20, 18, 17, 16, 15]),
        ]
    )
}

// MARK: - Helpers de format

func fmtInt(_ n: Int) -> String {
    let f = NumberFormatter()
    f.groupingSeparator = "\u{202F}" // espace fine insécable
    f.numberStyle = .decimal
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}

struct DeltaLabel: View {
    let pct: Double?
    var size: CGFloat = 12
    var body: some View {
        if let p = pct {
            let up = p >= 0
            let txt: String = abs(p) > 400
                ? "×\(Int((p / 100).rounded()) + 1)"
                : "\(Int(abs(p).rounded()))\u{202F}%"
            HStack(spacing: 2) {
                Image(systemName: up ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: size - 3))
                Text(txt).font(.system(size: size, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(up ? GT.accent : GT.neg)
        }
    }
}

struct SparkLine: Shape {
    let points: [Double]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard points.count > 1 else { return p }
        let maxV = max(points.max() ?? 1, 1)
        let minV = min(points.min() ?? 0, 0)
        let range = max(maxV - minV, 1)
        let stepX = rect.width / CGFloat(points.count - 1)
        for (i, v) in points.enumerated() {
            let x = rect.minX + CGFloat(i) * stepX
            let y = rect.maxY - CGFloat((v - minV) / range) * rect.height
            i == 0 ? p.move(to: CGPoint(x: x, y: y)) : p.addLine(to: CGPoint(x: x, y: y))
        }
        return p
    }
}

struct SparkView: View {
    let points: [Double]
    var color: Color = GT.accent
    var line: CGFloat = 2
    var body: some View {
        SparkLine(points: points)
            .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Timeline

struct GlanceEntry: TimelineEntry {
    let date: Date
    let data: GlanceData
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> GlanceEntry {
        GlanceEntry(date: Date(), data: .placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
        let data = context.isPreview ? .placeholder : GlanceData.load()
        completion(GlanceEntry(date: Date(), data: data.hasData ? data : .placeholder))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
        let data = GlanceData.load()
        let entry = GlanceEntry(date: Date(), data: data)
        // L'app republie à l'ouverture ; on redemande une timeline dans ~30 min.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Vues

/// Titre sur 2 lignes : nom + période (sans troncature).
struct TitleLines: View {
    var title: String = "Tous les sites"
    let periodLabel: String
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GT.fg).lineLimit(1).minimumScaleFactor(0.8)
            if !periodLabel.isEmpty {
                Text(periodLabel)
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(GT.fg3).lineLimit(1)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 22)).foregroundStyle(GT.fg3)
            Text("Ouvrez Glance").font(.system(size: 12)).foregroundStyle(GT.fg2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// En-tête sur 2 lignes (titre + période à gauche) avec les stats à droite.
struct TitleStatsRow: View {
    let title: String
    let periodLabel: String
    let value: Int
    let delta: Double?
    var valueSize: CGFloat = 27
    var titleLines: Int = 1
    var showPeriod: Bool = true
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GT.fg).lineLimit(titleLines).minimumScaleFactor(0.8)
                if showPeriod && !periodLabel.isEmpty {
                    Text(periodLabel)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(GT.fg3).lineLimit(1)
                }
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 1) {
                Text(fmtInt(value))
                    .font(.system(size: valueSize, weight: .bold, design: .rounded))
                    .foregroundStyle(GT.fg).lineLimit(1).minimumScaleFactor(0.5)
                DeltaLabel(pct: delta, size: 11)
            }
        }
    }
}

struct SmallView: View {
    let d: GlanceData
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Titre sur 2 lignes à gauche, stats à droite (période masquée ici,
            // gardée sur les grandes tailles).
            TitleStatsRow(
                title: "Tous les sites", periodLabel: d.periodLabel,
                value: d.totalVisitors, delta: d.totalDelta,
                valueSize: 24, titleLines: 2, showPeriod: false
            )
            Spacer(minLength: 8)
            SparkView(points: d.totalSpark)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
        }
    }
}

struct SiteRow: View {
    let s: SiteStat
    var body: some View {
        HStack(spacing: 7) {
            Text(s.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GT.fg).lineLimit(1).truncationMode(.tail)
                .layoutPriority(1)
            Spacer(minLength: 4)
            if s.spark.count > 1 {
                SparkView(points: s.spark, color: GT.accent.opacity(0.8), line: 1.5)
                    .frame(width: 32, height: 14)
            }
            Text(fmtInt(s.value))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(GT.fg).fixedSize()
            DeltaLabel(pct: s.delta, size: 10).fixedSize()
        }
    }
}

/// Item de site sur 2 lignes (nom + valeur/delta, puis courbe en dessous), pour
/// laisser toute la largeur au nom dans une colonne étroite (widget moyen).
struct SiteRowStacked: View {
    let s: SiteStat
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(s.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(GT.fg).lineLimit(1).truncationMode(.tail)
                Spacer(minLength: 4)
                Text(fmtInt(s.value))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(GT.fg).fixedSize()
                DeltaLabel(pct: s.delta, size: 9).fixedSize()
            }
            SparkView(points: s.spark, color: GT.accent.opacity(0.75), line: 1.4)
                .frame(maxWidth: .infinity).frame(height: 14)
        }
    }
}

struct MediumView: View {
    let d: GlanceData
    var rows: Int = 3
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                TitleLines(periodLabel: d.periodLabel)
                Spacer(minLength: 4)
                Text(fmtInt(d.totalVisitors))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(GT.fg).minimumScaleFactor(0.6).lineLimit(1)
                DeltaLabel(pct: d.totalDelta)
                Spacer(minLength: 6)
                SparkView(points: d.totalSpark).frame(height: 26)
            }
            .frame(width: 118)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(d.sites.prefix(rows))) { s in
                    SiteRowStacked(s: s)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct LargeView: View {
    let d: GlanceData
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Titre + stats en haut, courbe pleine largeur en dessous.
            TitleStatsRow(
                title: "Tous les sites", periodLabel: d.periodLabel,
                value: d.totalVisitors, delta: d.totalDelta, valueSize: 32
            )
            SparkView(points: d.totalSpark)
                .frame(maxWidth: .infinity).frame(height: 46)
            Divider().overlay(GT.line)
            VStack(spacing: 0) {
                ForEach(Array(d.sites.prefix(6))) { s in
                    SiteRow(s: s).padding(.vertical, 6)
                    if s.id != d.sites.prefix(6).last?.id {
                        Divider().overlay(GT.line)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// Fond du widget : `containerBackground` sur iOS 17+, sinon fond + marges.
struct GlanceBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            content.containerBackground(for: .widget) { GT.bg }
        } else {
            content.padding(16).background(GT.bg)
        }
    }
}

struct GlanceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        Group {
            if !entry.data.hasData {
                EmptyStateView()
            } else {
                switch family {
                case .systemSmall: SmallView(d: entry.data)
                case .systemLarge: LargeView(d: entry.data)
                default: MediumView(d: entry.data)
                }
            }
        }
        .modifier(GlanceBackground())
    }
}

struct GlanceOverviewWidget: Widget {
    let kind = "GlanceOverviewWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GlanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Glance — Aperçu")
        .description("Visiteurs de tous vos sites et le top des sites.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
