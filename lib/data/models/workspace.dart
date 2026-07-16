import 'dart:convert';

import 'package:flutter/material.dart';

import 'models.dart';

/// Couleurs proposées pour un groupe. Mêmes teintes que la palette des
/// événements (`kEventPalette`) pour ne pas introduire un 2ᵉ nuancier ; chaque
/// entrée porte sa variante sombre, sinon les teintes claires bavent sur le
/// fond sombre.
enum WorkspaceColor {
  forest(Color(0xFF3B7A5A), Color(0xFF5AA57E)),
  ocre(Color(0xFFC97F44), Color(0xFFDDA06B)),
  ardoise(Color(0xFF4A6FA5), Color(0xFF7595C4)),
  prune(Color(0xFF9A5BA6), Color(0xFFBC82C6)),
  sarcelle(Color(0xFF3E9188), Color(0xFF5FB4AA)),
  rose(Color(0xFFB0658A), Color(0xFFCE8CAC)),
  or(Color(0xFF9A8A3C), Color(0xFFC0B060)),
  rouille(Color(0xFFC2603F), Color(0xFFD98865));

  const WorkspaceColor(this.light, this.dark);
  final Color light;
  final Color dark;

  Color of(Brightness b) => b == Brightness.dark ? dark : light;

  static WorkspaceColor fromName(String? n) => WorkspaceColor.values.firstWhere(
        (c) => c.name == n,
        orElse: () => WorkspaceColor.forest,
      );
}

/// Icônes proposées pour un groupe.
enum WorkspaceIcon {
  dossier(Icons.folder_rounded),
  jeu(Icons.sports_esports_rounded),
  travail(Icons.work_rounded),
  fusee(Icons.rocket_launch_rounded),
  courbe(Icons.insights_rounded),
  etoile(Icons.star_rounded),
  globe(Icons.public_rounded),
  code(Icons.code_rounded),
  boutique(Icons.shopping_bag_rounded),
  photo(Icons.photo_camera_rounded),
  musique(Icons.music_note_rounded),
  coeur(Icons.favorite_rounded);

  const WorkspaceIcon(this.data);
  final IconData data;

  static WorkspaceIcon fromName(String? n) => WorkspaceIcon.values.firstWhere(
        (i) => i.name == n,
        orElse: () => WorkspaceIcon.dossier,
      );
}

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
    this.icon = WorkspaceIcon.dossier,
    this.color = WorkspaceColor.forest,
  });

  final String id;
  final String name;
  final List<SiteRef> sites;
  final WorkspaceIcon icon;
  final WorkspaceColor color;

  bool contains(Site s) => sites.any((r) => r.matches(s));

  Workspace copyWith({
    String? name,
    List<SiteRef>? sites,
    WorkspaceIcon? icon,
    WorkspaceColor? color,
  }) =>
      Workspace(
        id: id,
        name: name ?? this.name,
        sites: sites ?? this.sites,
        icon: icon ?? this.icon,
        color: color ?? this.color,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sites': sites.map((r) => r.toJson()).toList(),
        'icon': icon.name,
        'color': color.name,
      };

  /// Icône et couleur absentes = groupe créé avant qu'elles existent → valeurs
  /// par défaut plutôt qu'une migration.
  factory Workspace.fromJson(Map<String, dynamic> j) => Workspace(
        id: j['id'] as String,
        name: j['name'] as String,
        sites: ((j['sites'] as List?) ?? const [])
            .map((e) => SiteRef.fromJson(e as Map<String, dynamic>))
            .toList(),
        icon: WorkspaceIcon.fromName(j['icon'] as String?),
        color: WorkspaceColor.fromName(j['color'] as String?),
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
