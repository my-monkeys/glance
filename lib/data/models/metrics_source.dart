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
  });

  final String id;
  final String libelle;
  final String description;
  final MetricUnit unite;
  final List<String> granularites;

  /// Jours qu'il faut attendre après un jour J pour que sa cohorte soit
  /// mesurable (J7 → 7). 0 pour un nombre, ou si le serveur ne le dit pas.
  final int delaiJours;

  factory MetricDef.fromJson(Map<String, dynamic> j) => MetricDef(
        id: j['id'] as String,
        libelle: j['libelle'] as String,
        description: (j['description'] as String?) ?? '',
        unite: MetricUnit.fromApi(j['unite'] as String?),
        granularites:
            ((j['granularites'] as List?) ?? const []).cast<String>().toList(),
        delaiJours: (j['delai_jours'] as num?)?.round() ?? 0,
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
