import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'workspace.dart';

/// L'API d'agrégats d'un site : indicateurs calculés par le site lui-même.
/// Le jeton n'est PAS ici : il vit dans le secure storage, jamais en prefs.
@immutable
class MetricsSource {
  const MetricsSource({required this.site, required this.baseUrl});

  final SiteRef site;
  final String baseUrl;

  Map<String, dynamic> toJson() => {'site': site.toJson(), 'url': baseUrl};

  factory MetricsSource.fromJson(Map<String, dynamic> j) => MetricsSource(
        site: SiteRef.fromJson(j['site'] as Map<String, dynamic>),
        baseUrl: j['url'] as String,
      );

  static String encodeList(List<MetricsSource> l) =>
      jsonEncode(l.map((s) => s.toJson()).toList());

  static List<MetricsSource> decodeList(String? s) {
    if (s == null || s.isEmpty) return const [];
    return (jsonDecode(s) as List<dynamic>)
        .map((e) => MetricsSource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      other is MetricsSource && other.site == site && other.baseUrl == baseUrl;

  @override
  int get hashCode => Object.hash(site, baseUrl);
}

/// `percent` est une valeur de 0 à 100 (déjà un pourcentage), `count` un nombre.
enum MetricUnit {
  percent('pourcentage'),
  count('nombre');

  const MetricUnit(this.api);
  final String api;

  /// Inconnue → `count` : un nombre brut s'affiche toujours sans mentir.
  static MetricUnit fromApi(String? a) =>
      MetricUnit.values.firstWhere((u) => u.api == a, orElse: () => count);
}

/// Un indicateur du catalogue d'une source.
@immutable
class MetricDef {
  const MetricDef({
    required this.id,
    required this.libelle,
    required this.description,
    required this.unite,
    required this.granularites,
    this.delaiJours = 0,
    this.famille,
    this.libelleFamille,
    this.donneesJusquAu,
  });

  final String id;
  final String libelle;
  final String description;
  final MetricUnit unite;
  final List<String> granularites;

  /// Jours qu'il faut attendre après un jour J pour que sa cohorte soit
  /// mesurable (J7 → 7). 0 pour un nombre, ou si le serveur ne le dit pas.
  final int delaiJours;

  /// Famille d'indicateurs qui ne diffèrent que par leur délai (J1, J7, J30) ;
  /// null pour une métrique seule.
  final String? famille;
  final String? libelleFamille;

  /// Dernier jour publié par la source (`donnees_jusqu_au`, « AAAA-MM-JJ »),
  /// pour des données qui arrivent en retard (stores : J-1 à J-7). Les jours
  /// suivants sont des trous, pas des zéros. Null = tout est à jour.
  final DateTime? donneesJusquAu;

  factory MetricDef.fromJson(Map<String, dynamic> j) => MetricDef(
        id: j['id'] as String,
        libelle: j['libelle'] as String,
        description: (j['description'] as String?) ?? '',
        unite: MetricUnit.fromApi(j['unite'] as String?),
        granularites:
            ((j['granularites'] as List?) ?? const []).cast<String>().toList(),
        delaiJours: (j['delai_jours'] as num?)?.round() ?? 0,
        famille: j['famille'] as String?,
        libelleFamille: j['libelle_famille'] as String?,
        donneesJusquAu: _localDay(j['donnees_jusqu_au']),
      );

  /// « 2026-10-18 » → minuit local ; tout autre format est ignoré.
  static DateTime? _localDay(Object? v) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch('${v ?? ''}');
    if (m == null) return null;
    return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }
}

/// Les indicateurs d'une famille, du plus court délai au plus long.
@immutable
class MetricFamily {
  const MetricFamily(this.id, this.libelle, this.membres);
  final String id;
  final String libelle;
  final List<MetricDef> membres;

  MetricUnit get unite => membres.first.unite;
}

/// Regroupe le catalogue en familles, dans l'ordre où elles apparaissent.
/// Les métriques sans `famille` n'y figurent pas.
List<MetricFamily> metricFamiliesOf(List<MetricDef> defs) {
  final byId = <String, List<MetricDef>>{};
  for (final d in defs) {
    if (d.famille != null) (byId[d.famille!] ??= []).add(d);
  }
  return [
    for (final e in byId.entries)
      MetricFamily(
        e.key,
        e.value.map((d) => d.libelleFamille).whereType<String>().firstOrNull ??
            e.key,
        [...e.value]..sort((a, b) => a.delaiJours.compareTo(b.delaiJours)),
      ),
  ];
}

/// Une période doit couvrir au moins [kFamilyWindowRatio] fois le délai du
/// membre retenu.
const kFamilyWindowRatio = 4;

/// Le membre d'une famille qui convient à une fenêtre de [windowDays] jours :
/// le plus grand délai qui y tient [kFamilyWindowRatio] fois, sinon le plus
/// court. [membres] est non vide.
///
/// Pas « le plus grand délai qui tient une fois » : sur « 30 j », J30 ne
/// mesurait que des cohortes vieilles de 30 à 60 jours (avant le lancement
/// de geography, toutes à 0) et la courbe était plate. Quatre fois le délai
/// garantit des cohortes assez récentes pour dessiner une tendance : J1 sur
/// « 7 jours », J7 sur « 30 j », J30 sur « 12 m ».
MetricDef chooseFamilyMember(List<MetricDef> membres, int windowDays) {
  final sorted = [...membres]..sort((a, b) => a.delaiJours.compareTo(b.delaiJours));
  return sorted.lastWhere(
    (m) => m.delaiJours * kFamilyWindowRatio <= windowDays,
    orElse: () => sorted.first,
  );
}

/// Un bucket d'une série. [valeur] null = **non mesurable** (cohorte pas
/// terminée, ou dénominateur sous le seuil de confidentialité) : un trou, jamais
/// un zéro.
@immutable
class MetricPoint {
  const MetricPoint({
    required this.t,
    required this.valeur,
    required this.numerateur,
    required this.denominateur,
  });

  final DateTime t;
  final double? valeur;
  final int numerateur;
  final int denominateur;

  /// `t` est une date locale `YYYY-MM-DD` : on la lit sans fuseau.
  factory MetricPoint.fromJson(Map<String, dynamic> j) {
    final d = DateTime.parse(j['t'] as String);
    return MetricPoint(
      t: DateTime(d.year, d.month, d.day),
      valeur: (j['valeur'] as num?)?.toDouble(),
      numerateur: (j['numerateur'] as num?)?.round() ?? 0,
      denominateur: (j['denominateur'] as num?)?.round() ?? 0,
    );
  }
}

/// Une source avec son jeton, pour la synchro chiffrée de bout en bout (le
/// jeton n'existe en clair nulle part ailleurs que dans le secure storage).
@immutable
class SyncedMetricsSource {
  const SyncedMetricsSource(this.source, this.token);

  final MetricsSource source;
  final String token;

  Map<String, dynamic> toJson() => {...source.toJson(), 'token': token};

  factory SyncedMetricsSource.fromJson(Map<String, dynamic> j) =>
      SyncedMetricsSource(MetricsSource.fromJson(j), j['token'] as String);

  @override
  bool operator ==(Object other) =>
      other is SyncedMetricsSource &&
      other.source == source &&
      other.token == token;

  @override
  int get hashCode => Object.hash(source, token);
}
