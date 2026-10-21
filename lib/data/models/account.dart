import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Fournisseurs d'analytics supportés.
enum ProviderKind {
  umami('Umami'),
  plausible('Plausible'),
  fathom('Fathom');

  const ProviderKind(this.displayName);
  final String displayName;

  String get initial => displayName[0];

  static ProviderKind fromName(String n) => ProviderKind.values.firstWhere(
    (p) => p.name == n,
    orElse: () => ProviderKind.umami,
  );
}

/// Descriptif d'un champ d'identifiant (pour générer le formulaire d'ajout).
@immutable
class CredentialField {
  const CredentialField({
    required this.key,
    required this.label,
    this.secret = false,
    this.placeholder,
    this.keyboardUrl = false,
    this.optional = false,
    this.hint,
  });
  final String key;
  final String label;
  final bool secret;
  final String? placeholder;
  final bool keyboardUrl;

  /// Champ facultatif : le formulaire n'exige pas qu'il soit rempli.
  final bool optional;

  /// Aide affichée sous le champ (contrainte non évidente).
  final String? hint;
}

/// Un compte configuré : le fournisseur + son URL d'instance + un libellé.
/// Les identifiants sensibles ne vivent PAS ici : ils sont dans le secure
/// storage, indexés par [id].
@immutable
class Account {
  const Account({
    required this.id,
    required this.kind,
    required this.baseUrl,
    this.label,
    this.sites,
    this.excludedSites = const [],
  });

  final String id;
  final ProviderKind kind;
  final String baseUrl;
  final String? label;

  /// Ids des sites à afficher. `null` = tous les sites du compte, y compris
  /// ceux créés plus tard, sauf [excludedSites].
  final List<String>? sites;

  /// Sites écartés quand [sites] vaut `null`. Une exclusion plutôt qu'une
  /// liste : un site créé après coup n'y figure pas, il s'affiche donc seul.
  final List<String> excludedSites;

  bool get followsNewSites => sites == null;

  bool includesSite(String id) =>
      sites == null ? !excludedSites.contains(id) : sites!.contains(id);

  String get title => (label != null && label!.trim().isNotEmpty)
      ? label!.trim()
      : _hostOf(baseUrl);

  static String _hostOf(String url) {
    final u = Uri.tryParse(url);
    if (u == null || u.host.isEmpty) return url;
    return u.host;
  }

  /// [allSites] passe en « tous les sites, sauf [excluded] » ; [sites] en
  /// sélection explicite. Sans l'un ni l'autre, la sélection est conservée.
  Account copyWith({
    String? label,
    List<String>? sites,
    bool allSites = false,
    List<String> excluded = const [],
  }) {
    final explicit = !allSites && (sites != null || this.sites != null);
    return Account(
      id: id,
      kind: kind,
      baseUrl: baseUrl,
      label: label ?? this.label,
      sites: allSites ? null : (sites ?? this.sites),
      excludedSites: allSites
          ? excluded
          : explicit
              ? const []
              : excludedSites,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'baseUrl': baseUrl,
    'label': label,
    'sites': sites,
    // Clé facultative : une app plus ancienne l'ignore et suit tous les sites.
    if (excludedSites.isNotEmpty) 'excludedSites': excludedSites,
  };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
    id: j['id'] as String,
    kind: ProviderKind.fromName(j['kind'] as String),
    baseUrl: j['baseUrl'] as String,
    label: j['label'] as String?,
    sites: (j['sites'] as List?)?.map((e) => e.toString()).toList(),
    excludedSites: [
      for (final e in (j['excludedSites'] as List?) ?? const []) e.toString(),
    ],
  );

  static String encodeList(List<Account> l) =>
      jsonEncode(l.map((a) => a.toJson()).toList());

  static List<Account> decodeList(String? s) {
    if (s == null || s.isEmpty) return const [];
    final raw = jsonDecode(s) as List<dynamic>;
    return raw
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
