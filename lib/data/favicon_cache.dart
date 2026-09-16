import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Favicon d'un site : octets bruts + type (SVG ou raster) pour le rendu.
class Favicon {
  const Favicon(this.bytes, {required this.isSvg});
  final Uint8List bytes;
  final bool isSvg;
}

/// Récupère et met en cache les petites icônes de l'app, sur disque comme en
/// mémoire : le favicon d'un site suivi ([get], qui lit le HTML du site et suit
/// son `<link rel="icon">`) et n'importe quelle icône désignée par son URL
/// ([fromUrl] — favicon d'un domaine référent, logo de navigateur ou de système
/// servi par l'instance Umami).
///
/// Les `.ico` sont décodés nativement par Flutter (vérifié sur de vrais fichiers
/// ICO 32 bits non-PNG) : aucun décodeur à embarquer.
class FaviconCache {
  FaviconCache(this._dio);
  final Dio _dio;

  final Map<String, Favicon?> _mem = {};
  Directory? _dir;

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/favicons');
    if (!d.existsSync()) d.createSync(recursive: true);
    return _dir = d;
  }

  String _key(String domain) =>
      domain.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');

  Future<Favicon?> get(String domain) async {
    if (_mem.containsKey(domain)) return _mem[domain];
    final fav = await _load(domain);
    _mem[domain] = fav;
    return fav;
  }

  /// Icône d'une URL connue d'avance, rangée sous [cacheKey]. Sert aux icônes
  /// qui n'ont pas à être devinées : favicon d'un domaine référent, logo de
  /// navigateur ou de système d'une instance Umami.
  Future<Favicon?> fromUrl(String cacheKey, String url) async {
    if (_mem.containsKey(cacheKey)) return _mem[cacheKey];
    final fav = await _cached(cacheKey, () => _tryDownload(url));
    _mem[cacheKey] = fav;
    return fav;
  }

  /// Lit le cache disque, sinon appelle [fetch] et écrit le résultat. Un échec
  /// est mémorisé 7 jours pour ne pas re-tenter à chaque affichage.
  Future<Favicon?> _cached(String key, Future<Favicon?> Function() fetch) async {
    final dir = await _cacheDir();
    final safeKey = _key(key);
    final rasterFile = File('${dir.path}/$safeKey.img');
    final svgFile = File('${dir.path}/$safeKey.svg');
    final missFile = File('${dir.path}/$safeKey.miss');

    if (rasterFile.existsSync() && rasterFile.lengthSync() > 0) {
      return Favicon(await rasterFile.readAsBytes(), isSvg: false);
    }
    if (svgFile.existsSync() && svgFile.lengthSync() > 0) {
      return Favicon(await svgFile.readAsBytes(), isSvg: true);
    }
    if (missFile.existsSync() &&
        DateTime.now().difference(missFile.lastModifiedSync()).inDays < 7) {
      return null;
    }

    try {
      final fav = await fetch();
      if (fav == null) {
        missFile.writeAsStringSync('');
        return null;
      }
      await (fav.isSvg ? svgFile : rasterFile).writeAsBytes(fav.bytes);
      return fav;
    } catch (_) {
      return null;
    }
  }

  Future<Favicon?> _load(String domain) => _cached(domain, () => _fetch(domain));

  Future<Favicon?> _fetch(String domain) async {
    final origin = 'https://$domain';
    // 1. Lit le HTML et cherche les <link rel="...icon...">.
    final candidates = <String>[];
    try {
      final r = await _dio.get<String>(
        origin,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final html = r.data ?? '';
      final linkRe = RegExp(r'<link\b[^>]*>', caseSensitive: false);
      final relRe = RegExp(r'''rel\s*=\s*["']([^"']*)["']''', caseSensitive: false);
      final hrefRe = RegExp(r'''href\s*=\s*["']([^"']*)["']''', caseSensitive: false);
      final apple = <String>[];
      final pngIco = <String>[];
      final svg = <String>[];
      for (final m in linkRe.allMatches(html)) {
        final tag = m.group(0)!;
        final rel = relRe.firstMatch(tag)?.group(1)?.toLowerCase() ?? '';
        if (!rel.contains('icon')) continue;
        final href = hrefRe.firstMatch(tag)?.group(1);
        if (href == null || href.isEmpty) continue;
        if (rel.contains('apple-touch')) {
          apple.add(href);
        } else if (href.toLowerCase().contains('.svg')) {
          svg.add(href);
        } else {
          pngIco.add(href);
        }
      }
      // Préférence : apple-touch (grand PNG) > png/ico > svg.
      candidates.addAll([...apple, ...pngIco, ...svg]);
    } catch (_) {
      // pas de HTML → on tentera /favicon.ico
    }
    candidates.add('/favicon.ico');

    for (final href in candidates) {
      final url = _resolve(origin, domain, href);
      final fav = await _tryDownload(url);
      if (fav != null) return fav;
    }
    return null;
  }

  String _resolve(String origin, String domain, String href) {
    if (href.startsWith('http://') || href.startsWith('https://')) return href;
    if (href.startsWith('//')) return 'https:$href';
    if (href.startsWith('/')) return '$origin$href';
    return '$origin/$href';
  }

  Future<Favicon?> _tryDownload(String url) async {
    try {
      final r = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 8),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final bytes = Uint8List.fromList(r.data ?? const []);
      if (bytes.length < 40) return null; // trop petit = placeholder/vide
      final ct = (r.headers.value('content-type') ?? '').toLowerCase();
      final isSvg = ct.contains('svg') || _looksSvg(bytes);
      // Rejette le HTML (SPA qui répond index.html sur un chemin manquant).
      if (ct.contains('text/html') || (_looksHtml(bytes) && !isSvg)) return null;
      return Favicon(bytes, isSvg: isSvg);
    } on DioException catch (e) {
      // Une réponse du serveur (404, 403…) est un vrai « pas d'icône », qu'on
      // mémorise. Une panne de réseau, elle, ne dit rien de l'icône : la
      // relancer évite d'inscrire une absence pour une semaine parce que le
      // Wi-Fi a coupé une seconde.
      if (e.response != null) return null;
      rethrow;
    }
  }

  bool _looksSvg(Uint8List b) {
    final head = utf8.decode(b.take(200).toList(), allowMalformed: true).trimLeft();
    return head.startsWith('<?xml') || head.contains('<svg');
  }

  bool _looksHtml(Uint8List b) {
    final head =
        utf8.decode(b.take(200).toList(), allowMalformed: true).trimLeft().toLowerCase();
    return head.startsWith('<!doctype html') || head.startsWith('<html');
  }
}
