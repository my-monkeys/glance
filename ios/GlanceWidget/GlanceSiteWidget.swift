import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Données d'un site (JSON `all_sites` écrit par l'app)

struct SiteRecord: Decodable, Identifiable {
    let i: String   // id
    let n: String   // nom
    let v: Int      // visiteurs
    let p: Int      // pages vues
    let d: Double?  // delta %
    let s: String   // sparkline CSV

    var id: String { i }
    var spark: [Double] { s.split(separator: ",").compactMap { Double($0) } }

    static let placeholder = SiteRecord(
        i: "demo", n: "tamdoku.fr", v: 402, p: 989, d: 120,
        s: "10,26,30,22,18,14,12"
    )
}

func loadAllSites() -> [SiteRecord] {
    guard let ud = UserDefaults(suiteName: GlanceData.appGroup),
          let json = ud.string(forKey: "all_sites"),
          let data = json.data(using: .utf8),
          let arr = try? JSONDecoder().decode([SiteRecord].self, from: data)
    else { return [] }
    return arr
}

// MARK: - App Intent de configuration (choix du site)

@available(iOS 17.0, macOS 14.0, *)
struct SiteEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Site" }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    static var defaultQuery = SiteQuery()
}

@available(iOS 17.0, macOS 14.0, *)
struct SiteQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SiteEntity] {
        loadAllSites().filter { identifiers.contains($0.i) }
            .map { SiteEntity(id: $0.i, name: $0.n) }
    }
    func suggestedEntities() async throws -> [SiteEntity] {
        loadAllSites().map { SiteEntity(id: $0.i, name: $0.n) }
    }
    func defaultResult() async -> SiteEntity? {
        loadAllSites().first.map { SiteEntity(id: $0.i, name: $0.n) }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct SelectSiteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Site"
    static var description = IntentDescription("Choisir le site à afficher.")

    @Parameter(title: "Site") var site: SiteEntity?
}

// MARK: - Timeline

@available(iOS 17.0, macOS 14.0, *)
struct SiteEntry: TimelineEntry {
    let date: Date
    let record: SiteRecord?
    let periodLabel: String
}

@available(iOS 17.0, macOS 14.0, *)
struct SiteProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SiteEntry {
        SiteEntry(date: Date(), record: .placeholder, periodLabel: "7 jours")
    }
    func snapshot(for configuration: SelectSiteIntent, in context: Context) async -> SiteEntry {
        resolve(configuration, preview: context.isPreview)
    }
    func timeline(for configuration: SelectSiteIntent, in context: Context) async -> Timeline<SiteEntry> {
        let entry = resolve(configuration, preview: false)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(next))
    }
    private func resolve(_ configuration: SelectSiteIntent, preview: Bool) -> SiteEntry {
        let all = loadAllSites()
        if preview && all.isEmpty {
            return SiteEntry(date: Date(), record: .placeholder, periodLabel: "7 jours")
        }
        let rec = all.first(where: { $0.i == configuration.site?.id }) ?? all.first
        let period = UserDefaults(suiteName: GlanceData.appGroup)?
            .string(forKey: "period_label") ?? ""
        return SiteEntry(date: Date(), record: rec, periodLabel: period)
    }
}

// MARK: - Vues

@available(iOS 17.0, macOS 14.0, *)
struct SiteSmallView: View {
    let r: SiteRecord
    let period: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TitleStatsRow(
                title: r.n, periodLabel: period, value: r.v, delta: r.d,
                valueSize: 24, titleLines: 2, showPeriod: false
            )
            Spacer(minLength: 8)
            SparkView(points: r.spark).frame(maxWidth: .infinity).frame(height: 42)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct SiteMediumView: View {
    let r: SiteRecord
    let period: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TitleStatsRow(
                title: r.n, periodLabel: period, value: r.v, delta: r.d, valueSize: 28
            )
            SparkView(points: r.spark).frame(maxWidth: .infinity).frame(height: 40)
            Divider().overlay(GT.line)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(fmtInt(r.p))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(GT.fg)
                Text("pages vues").font(.system(size: 12)).foregroundStyle(GT.fg2)
            }
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct SiteWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SiteEntry
    var body: some View {
        Group {
            if let r = entry.record {
                switch family {
                case .systemMedium: SiteMediumView(r: r, period: entry.periodLabel)
                default: SiteSmallView(r: r, period: entry.periodLabel)
                }
            } else {
                EmptyStateView()
            }
        }
        .modifier(GlanceBackground())
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct GlanceSiteWidget: Widget {
    let kind = "GlanceSiteWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind, intent: SelectSiteIntent.self, provider: SiteProvider()
        ) { entry in
            SiteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Glance — Site")
        .description("Les visiteurs d'un site que vous choisissez.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
