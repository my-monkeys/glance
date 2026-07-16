import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Référence stable vers un site. L'id d'un site n'est unique qu'au sein de son
/// compte (cf. `Site.==`) → l'appartenance à un groupe se stocke en couple.
@immutable
class SiteRef {
  const SiteRef(this.accountId, this.siteId);

  SiteRef.of(Site s)
      : accountId = s.accountId,
        siteId = s.id;

  final String accountId;
  final String siteId;

  bool matches(Site s) => s.accountId == accountId && s.id == siteId;

  @override
  bool operator ==(Object other) =>
      other is SiteRef &&
      other.accountId == accountId &&
      other.siteId == siteId;

  @override
  int get hashCode => Object.hash(accountId, siteId);

  Map<String, dynamic> toJson() => {'a': accountId, 's': siteId};

  factory SiteRef.fromJson(Map<String, dynamic> j) =>
      SiteRef(j['a'] as String, j['s'] as String);
}

/// Un groupe de sites = un **périmètre de lecture** : quand il est actif,
/// l'accueil, le direct et les totaux ne portent que sur ses sites.
///
/// À ne pas confondre avec `Account.sites`, qui décide ce que Glance va
/// *chercher* ; un groupe ne fait qu'organiser ce qui est déjà connu, et ne
/// peut donc jamais contenir un site hors du périmètre des comptes.
///
/// Une référence dont le site n'existe plus (compte retiré, site supprimé chez
/// le fournisseur) est ignorée à l'affichage : le filtrage fait l'intersection
/// avec les sites connus, donc il n'y a rien à nettoyer.
@immutable
class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    this.sites = const [],
  });

  final String id;
  final String name;
  final List<SiteRef> sites;

  bool contains(Site s) => sites.any((r) => r.matches(s));

  Workspace copyWith({String? name, List<SiteRef>? sites}) =>
      Workspace(id: id, name: name ?? this.name, sites: sites ?? this.sites);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sites': sites.map((r) => r.toJson()).toList(),
      };

  factory Workspace.fromJson(Map<String, dynamic> j) => Workspace(
        id: j['id'] as String,
        name: j['name'] as String,
        sites: ((j['sites'] as List?) ?? const [])
            .map((e) => SiteRef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static String encodeList(List<Workspace> l) =>
      jsonEncode(l.map((w) => w.toJson()).toList());

  static List<Workspace> decodeList(String? s) {
    if (s == null || s.isEmpty) return const [];
    return (jsonDecode(s) as List<dynamic>)
        .map((e) => Workspace.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
