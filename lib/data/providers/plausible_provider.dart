import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../core/countries.dart';
import '../models/models.dart';
import '../models/period.dart';
import 'analytics_provider.dart';

/// Client Plausible (Stats API v2 — `POST /api/v2/query`, via clé API). La Stats
/// API ne liste pas les sites, et en Community Edition la Sites API Bearer
/// `/api/v1/sites` n'existe pas (route Enterprise-only) : pour lister, on se
/// connecte à l'interface web (email + mot de passe) et on parse la page `/sites`
/// paginée (cf. [_listViaWeb]). Sinon, fallback sur le domaine saisi. Chaque
/// requête de stats cible `site.id` (le domaine).
class PlausibleProvider extends AnalyticsProvider {
  PlausibleProvider(super.account, super.creds) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBase(account.baseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json',
          'Authorization': 'Bearer ${creds['apiKey']}',
        },
      ),
    );
  }

  late final Dio _dio;

  /// Domaine saisi manuellement (facultatif, fallback sans email/mot de passe).
  String get _configuredSite => (creds['siteId'] ?? '').trim();

  static String _normalizeBase(String raw) {
    var s = raw.trim().isEmpty ? 'plausible.io' : raw.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'https://$s';
    final u = Uri.parse(s);
    return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
  }

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  // Listing web `/sites` : chaque carte de site porte data-domain="<domaine>"
  // (une occurrence par site ; les cartes « tous les sites »/CTA n'en ont pas).
  // Le bloc de pagination affiche « Page N of M » (absent s'il n'y a qu'une page).
  static final _siteDomain = RegExp(r'data-domain="([^"]+)"');
  static final _pageOf = RegExp(r'Page\s+(\d+)\s+of\s+(\d+)');

  Future<Map<String, dynamic>> _query(Map<String, dynamic> body) async {
    final r = await _dio.post('/api/v2/query', data: body);
    return (r.data as Map).cast<String, dynamic>();
  }

  List<dynamic> _rows(Map<String, dynamic> res) =>
      (res['results'] as List?) ?? const [];

  @override
  Future<int> verify() async {
    final listed = await _listViaWeb();
    // Site témoin pour valider la CLÉ API (les stats en dépendent) : 1er site
    // listé, sinon le domaine saisi.
    final probe = listed.isNotEmpty ? listed.first.id : _configuredSite;
    if (probe.isEmpty) {
      throw StateError('Renseignez un domaine, ou email + mot de passe pour '
          'lister vos sites automatiquement.');
    }
    // Valide la clé API : un 401 ici = clé refusée (même si le listing a marché).
    await _query({'site_id': probe, 'metrics': ['visitors'], 'date_range': '7d'});
    return listed.isNotEmpty ? listed.length : 1;
  }

  @override
  Future<List<Site>> listSites() async {
    final listed = await _listViaWeb();
    if (listed.isNotEmpty) return listed;
    final id = _configuredSite;
    if (id.isEmpty) return const [];
    return [Site(id: id, accountId: account.id, name: id, domain: id)];
  }

  /// Liste les sites en se connectant à l'interface web (email + mot de passe),
  /// puis en parsant la page paginée `/sites` (le HTML rendu côté serveur). Ni la
  /// Stats API ni (en Community Edition) la Sites API Bearer n'exposent le listing
  /// des sites ; on passe donc par la session web. Renvoie une liste vide si
  /// email/mdp absents ou si le flux échoue (→ fallback domaine manuel).
  /// N.B. : endpoints internes non documentés — cette voie sert uniquement à
  /// lister/rafraîchir ; les stats passent toujours par la clé API (stable).
  Future<List<Site>> _listViaWeb() async {
    final email = (creds['email'] ?? '').trim();
    final password = creds['password'] ?? '';
    if (email.isEmpty || password.isEmpty) return const [];

    // Dio dédié à la session web (cookies gérés à la main, sans le Bearer).
    final web = Dio(BaseOptions(
      baseUrl: _dio.options.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: false,
      validateStatus: (s) => s != null && s < 500,
    ));

    String? cookie;
    void absorb(Headers h) {
      final set = h.map['set-cookie'];
      if (set == null) return;
      final jar = <String, String>{};
      if (cookie != null) {
        for (final kv in cookie!.split('; ')) {
          final i = kv.indexOf('=');
          if (i > 0) jar[kv.substring(0, i)] = kv.substring(i + 1);
        }
      }
      for (final c in set) {
        final first = c.split(';').first.trim();
        final i = first.indexOf('=');
        if (i > 0) jar[first.substring(0, i)] = first.substring(i + 1);
      }
      cookie = jar.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }

    try {
      // 1. GET /login → cookie initial + jeton CSRF (champ caché du formulaire).
      final loginPage = await web.get<String>('/login',
          options: Options(responseType: ResponseType.plain));
      absorb(loginPage.headers);
      final html = loginPage.data ?? '';
      final csrf = RegExp(r'name="_csrf_token"[^>]*value="([^"]+)"')
              .firstMatch(html)
              ?.group(1) ??
          RegExp(r'value="([^"]+)"[^>]*name="_csrf_token"')
              .firstMatch(html)
              ?.group(1);
      if (csrf == null) return const [];

      // 2. POST /login (form) → session authentifiée.
      Map<String, String>? cookieHeader() {
        final ck = cookie;
        return ck == null ? null : {'cookie': ck};
      }

      final login = await web.post('/login',
          data: {'_csrf_token': csrf, 'email': email, 'password': password},
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: cookieHeader(),
          ));
      absorb(login.headers);
      // Échec d'auth : Plausible renvoie 200 (re-affiche le login) au lieu de 302.
      if (login.statusCode != 302 && login.statusCode != 303) return const [];

      // 3. Liste complète des sites. ⚠️ `/api/sites` est l'autocomplete du
      //    sélecteur (limite 9 EN DUR, sans pagination) et la Sites API Bearer
      //    `/api/v1/sites` n'existe pas en Community Edition → la seule source
      //    complète est la page web `/sites`, paginée (page_size plafonné à 100),
      //    dont on parse le HTML rendu côté serveur. Le listing est scopé à
      //    l'équipe Plausible courante.
      const pageSize = 100;
      final out = <Site>[];
      final seen = <String>{};
      for (var page = 1; page <= 200; page++) {
        final r = await web.get('/sites',
            queryParameters: {'page': page, 'page_size': pageSize},
            options: Options(
              responseType: ResponseType.plain,
              headers: cookieHeader(),
            ));
        if (r.statusCode != 200 || r.data is! String) break;
        final html = r.data as String;
        for (final m in _siteDomain.allMatches(html)) {
          final d = m.group(1)!.trim();
          if (d.isNotEmpty && seen.add(d)) {
            out.add(Site(id: d, accountId: account.id, name: d, domain: d));
          }
        }
        // Arrêt sur l'info de pagination du serveur : « Page N of M » (absent =
        // page unique) — plus fiable que compter les cartes.
        final pm = _pageOf.firstMatch(html);
        if (pm == null || int.parse(pm.group(1)!) >= int.parse(pm.group(2)!)) {
          break;
        }
      }
      return out;
    } on DioException {
      return const [];
    } finally {
      web.close();
    }
  }

  Future<int> _visitorsFor(String siteId, List<String> range) async {
    final res = await _query({
      'site_id': siteId,
      'metrics': ['visitors'],
      'date_range': range,
    });
    final rows = _rows(res);
    if (rows.isEmpty) return 0;
    return ((rows.first['metrics'] as List).first as num).round();
  }

  @override
  Future<StatsSummary> summary(Site site, DateWindow w) async {
    final metrics = [
      'visitors',
      'pageviews',
      'visits',
      'bounce_rate',
      'visit_duration',
    ];
    final res = await _query({
      'site_id': site.id,
      'metrics': metrics,
      'date_range': [_dateFmt.format(w.start), _dateFmt.format(w.end)],
    });
    final rows = _rows(res);
    final m = rows.isEmpty
        ? List.filled(metrics.length, 0)
        : (rows.first['metrics'] as List);
    num at(int i) => (m.length > i ? m[i] as num? : null) ?? 0;

    // Période précédente (même durée) pour le delta.
    final span = w.end.difference(w.start);
    int? prevVisitors;
    try {
      prevVisitors = await _visitorsFor(site.id, [
        _dateFmt.format(w.start.subtract(span)),
        _dateFmt.format(w.start),
      ]);
    } catch (_) {
      prevVisitors = null;
    }

    return StatsSummary(
      visitors: at(0).round(),
      pageviews: at(1).round(),
      visits: at(2).round(),
      bounceRatePct: at(3).toDouble(),
      avgVisitSec: at(4).round(),
      prevVisitors: prevVisitors,
    );
  }

  @override
  Future<List<SeriesPoint>> series(Site site, DateWindow w) async {
    final dim = switch (w.unit) {
      TimeUnit.hour => 'time:hour',
      TimeUnit.day => 'time:day',
      TimeUnit.month => 'time:month',
    };
    final res = await _query({
      'site_id': site.id,
      // Deux séries pour le graphe : visiteurs uniques (vert) + pages vues (gris).
      'metrics': ['visitors', 'pageviews'],
      // Dates (yyyy-MM-dd) : la Stats API v2 refuse le datetime ISO en date_range.
      'date_range': [_dateFmt.format(w.start), _dateFmt.format(w.end)],
      'dimensions': [dim],
    });
    return _rows(res)
        .map((r) {
          final dims = r['dimensions'] as List;
          final mm = r['metrics'] as List;
          final t = DateTime.tryParse(dims.first.toString()) ??
              DateTime.tryParse('${dims.first}T00:00:00');
          if (t == null) return null;
          return SeriesPoint(
            t,
            (mm[0] as num).toDouble(), // visiteurs
            (mm[1] as num).toDouble(), // pages vues
          );
        })
        .whereType<SeriesPoint>()
        .toList(growable: false);
  }

  @override
  Future<int> active(Site site) async {
    final r = await _dio.get(
      '/api/v1/stats/realtime/visitors',
      queryParameters: {'site_id': site.id},
    );
    return (r.data as num?)?.round() ?? 0;
  }

  @override
  Future<List<MetricRow>> metric(
    Site site,
    DateWindow w,
    MetricType type, {
    int limit = 8,
  }) async {
    final dim = switch (type) {
      MetricType.pages => 'event:page',
      MetricType.sources => 'visit:source',
      MetricType.countries => 'visit:country',
      MetricType.events => 'event:name',
    };
    final metric = type == MetricType.events ? 'events' : 'visitors';
    final res = await _query({
      'site_id': site.id,
      'metrics': [metric],
      'date_range': [_dateFmt.format(w.start), _dateFmt.format(w.end)],
      'dimensions': [dim],
      // La limite passe par `pagination` (un `limit` à la racine → 400).
      'pagination': {'limit': limit + (type == MetricType.events ? 1 : 0)},
    });
    final rows = _rows(res).map((r) {
      final label = (r['dimensions'] as List).first.toString();
      final value = ((r['metrics'] as List).first as num).round();
      if (type == MetricType.countries) {
        return MetricRow(label: countryName(label), value: value, code: label);
      }
      return MetricRow(label: label.isEmpty ? '/' : label, value: value);
    }).toList();
    if (type == MetricType.events) {
      // « pageview » n'est pas un événement personnalisé.
      return rows.where((r) => r.label != 'pageview').take(limit).toList();
    }
    return rows;
  }

  @override
  Future<List<EventSeries>> eventSeries(Site site, DateWindow w) async {
    final timeDim = switch (w.unit) {
      TimeUnit.hour => 'time:hour',
      TimeUnit.day => 'time:day',
      TimeUnit.month => 'time:month',
    };
    final res = await _query({
      'site_id': site.id,
      'metrics': ['events'],
      'date_range': [_dateFmt.format(w.start), _dateFmt.format(w.end)],
      'dimensions': [timeDim, 'event:name'],
    });
    // Regroupe par nom d'événement (exclut « pageview »).
    final byName = <String, Map<int, double>>{};
    for (final r in _rows(res)) {
      final dims = r['dimensions'] as List;
      final name = dims.length > 1 ? dims[1].toString() : '';
      if (name == 'pageview') continue;
      final t = DateTime.tryParse(dims.first.toString()) ??
          DateTime.tryParse('${dims.first}T00:00:00');
      if (t == null) continue;
      final v = ((r['metrics'] as List).first as num).toDouble();
      (byName[name] ??= {}).update(
        t.millisecondsSinceEpoch,
        (x) => x + v,
        ifAbsent: () => v,
      );
    }
    final out = byName.entries.map((entry) {
      final points = entry.value.entries
          .map((e) => SeriesPoint(
              DateTime.fromMillisecondsSinceEpoch(e.key), e.value, 0))
          .toList()
        ..sort((a, b) => a.t.compareTo(b.t));
      final total = entry.value.values.fold<double>(0, (a, b) => a + b).round();
      return EventSeries(
        name: entry.key.isEmpty ? '(sans nom)' : entry.key,
        points: points,
        total: total,
      );
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return out;
  }

  @override
  Future<List<LivePage>> livePages(Site site) async {
    // La Stats API v2 n'accepte pas date_range "realtime" (temps réel = un
    // endpoint séparé, cf. active()). On approxime avec les pages du jour.
    final res = await _query({
      'site_id': site.id,
      'metrics': ['visitors'],
      'date_range': 'day',
      'dimensions': ['event:page'],
      'pagination': {'limit': 5},
    });
    return _rows(res).map((r) {
      final path = (r['dimensions'] as List).first.toString();
      final n = ((r['metrics'] as List).first as num).round();
      return LivePage(path.isEmpty ? '/' : path, n);
    }).toList(growable: false);
  }
}
