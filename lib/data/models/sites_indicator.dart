part of 'indicator.dart';

/// Quels visiteurs d'un site une ligne retient, selon leur référent.
enum ReferrerMode {
  /// Tous les visiteurs du site.
  all,

  /// Seulement ceux venus de ce domaine.
  only,

  /// Tous sauf ceux venus de ce domaine.
  except;

  static ReferrerMode fromName(String? n) =>
      values.firstWhere((m) => m.name == n, orElse: () => all);
}

/// Une ligne d'un tableau « Sites » : les visiteurs uniques d'un site, filtrés
/// ou non par leur référent (« geography sauf alldle.net »).
@immutable
class SiteLine {
  const SiteLine({
    required this.site,
    required this.label,
    this.mode = ReferrerMode.all,
    this.referrer = '',
  });

  /// Peut appartenir à un autre compte que le site qui porte le tableau.
  final SiteRef site;
  final String label;
  final ReferrerMode mode;

  /// Domaine exact, tel qu'Umami le range (`alldle.net`, sans `www.`).
  final String referrer;

  SiteLine copyWith({
    SiteRef? site,
    String? label,
    ReferrerMode? mode,
    String? referrer,
  }) =>
      SiteLine(
        site: site ?? this.site,
        label: label ?? this.label,
        mode: mode ?? this.mode,
        referrer: referrer ?? this.referrer,
      );

  Map<String, dynamic> toJson() => {
        'site': site.toJson(),
        'label': label,
        if (mode != ReferrerMode.all) ...{'mode': mode.name, 'referrer': referrer},
      };

  factory SiteLine.fromJson(Map<String, dynamic> j) => SiteLine(
        site: SiteRef.fromJson(j['site'] as Map<String, dynamic>),
        label: j['label'] as String,
        mode: ReferrerMode.fromName(j['mode'] as String?),
        referrer: (j['referrer'] as String?) ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is SiteLine &&
      other.site == site &&
      other.label == label &&
      other.mode == mode &&
      other.referrer == referrer;

  @override
  int get hashCode => Object.hash(site, label, mode, referrer);
}

/// Visiteurs uniques de plusieurs sites (ou parts de site) côte à côte : une
/// courbe et une part par ligne, le total en tête.
class SitesIndicator extends Indicator {
  const SitesIndicator({
    required super.id,
    required super.name,
    required this.lines,
  });

  final List<SiteLine> lines;

  @override
  IndicatorKind get kind => IndicatorKind.sites;

  @override
  Map<String, dynamic> toJson() =>
      _base({'lines': [for (final l in lines) l.toJson()]});

  factory SitesIndicator.fromJson(String id, String name, Map<String, dynamic> j) =>
      SitesIndicator(
        id: id,
        name: name,
        lines: [
          for (final l in (j['lines'] as List).cast<Map<String, dynamic>>())
            SiteLine.fromJson(l),
        ],
      );

  @override
  bool operator ==(Object other) =>
      other is SitesIndicator &&
      other.id == id &&
      other.name == name &&
      listEquals(other.lines, lines);

  @override
  int get hashCode => Object.hash(kind, id, name, Object.hashAll(lines));
}
