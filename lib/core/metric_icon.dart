import 'package:flutter/material.dart';

import '../data/models/dimension.dart';
import 'internal_traffic.dart';

/// D'où vient l'icône d'une ligne de métrique, et sous quelle clé la ranger.
/// Fonctions pures : elles se testent sans Flutter ni réseau.

/// Nom de fichier des images d'une instance Umami : minuscules, et **tout**
/// caractère non alphanumérique en tiret — c'est la règle d'Umami, vérifiée
/// contre ses fichiers : « Windows 8.1 » donne `windows-8-1.png` et « OS/2 »
/// `os-2.png`. Ne remplacer que les espaces laisserait un point dans le nom, et
/// une barre oblique sortirait même du dossier.
///
/// Idempotent : les valeurs `browser` d'Umami sont déjà des slugs.
String umamiSlug(String raw) => raw
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// Source réseau de l'icône d'une ligne, ou null quand elle se dessine
/// localement (appareil, drapeau) ou qu'il n'y a rien à montrer.
///
/// [code] est la valeur **brute** du fournisseur, jamais le libellé mis en
/// forme : `browserName('crios')` vaut « Chrome (iOS) », dont le slug
/// n'existe pas côté Umami — et un échec est mémorisé une semaine.
///
/// [instanceBase] est l'origine de l'instance Umami (`https://hôte`), qui fait
/// partie de la clé : deux comptes peuvent servir des images différentes sous
/// le même nom.
({String cacheKey, String url})? metricIconSource({
  required MetricIconKind kind,
  required String? code,
  required String? instanceBase,
}) {
  final raw = code?.trim() ?? '';
  if (raw.isEmpty) return null;
  switch (kind) {
    case MetricIconKind.favicon:
      final d = normDomain(raw);
      // « Accès direct », « localhost », valeurs non-domaines : rien à demander.
      if (d.isEmpty || !d.contains('.')) return null;
      return (
        cacheKey: 'ddg.$d',
        url: 'https://icons.duckduckgo.com/ip3/$d.ico',
      );
    case MetricIconKind.browser:
    case MetricIconKind.os:
      if (instanceBase == null || instanceBase.isEmpty) return null;
      final dir = kind == MetricIconKind.browser ? 'browser' : 'os';
      final slug = umamiSlug(raw);
      if (slug.isEmpty) return null;
      final host = Uri.tryParse(instanceBase)?.host ?? instanceBase;
      return (
        cacheKey: 'umami.$host.$dir.$slug',
        url: '$instanceBase/images/$dir/$slug.png',
      );
    case MetricIconKind.device:
    case MetricIconKind.flag:
    case MetricIconKind.none:
      return null;
  }
}

/// Icône d'un type d'appareil. Dessinée localement : les quatre catégories
/// d'Umami (et de Plausible) sont stables, et un glyphe reste net à toute
/// taille.
IconData deviceIcon(String code) => switch (code.trim().toLowerCase()) {
  'mobile' => Icons.smartphone_rounded,
  'tablet' => Icons.tablet_mac_rounded,
  'laptop' => Icons.laptop_mac_rounded,
  'desktop' => Icons.desktop_windows_rounded,
  'wearable' => Icons.watch_rounded,
  'console' => Icons.sports_esports_rounded,
  'tv' => Icons.tv_rounded,
  _ => Icons.devices_other_rounded,
};
