import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/metrics_source.dart';
import '../models/period.dart';

/// Seule version du contrat que ce client sait lire.
const kMetricsApiVersion = 1;

/// Cloudflare, devant ces hôtes, répond 403 / 1010 à un client sans
/// User-Agent de navigateur.
const _userAgent =
    'Mozilla/5.0 (compatible; Glance/1.0; +https://glance.my-monkey.fr)';

/// Échec typé de l'API d'agrégats : l'écran affiche [message] tel quel.
sealed class MetricsApiException implements Exception {
  const MetricsApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 404 : le serveur n'a pas activé la source.
class MetricsNotConfigured extends MetricsApiException {
  const MetricsNotConfigured() : super('Source non configurée sur le serveur');
}

/// 401 : jeton absent ou faux.
class MetricsBadToken extends MetricsApiException {
  const MetricsBadToken() : super('Jeton refusé');
}

/// 400 : paramètre invalide ; [code] est celui de `{error:{code}}`.
class MetricsBadRequest extends MetricsApiException {
  const MetricsBadRequest(this.code) : super('Requête refusée ($code)');
  final String code;
}

class MetricsUnsupportedVersion extends MetricsApiException {
  const MetricsUnsupportedVersion() : super('Version d\'API non prise en charge');
}

class MetricsUnexpectedResponse extends MetricsApiException {
  const MetricsUnexpectedResponse() : super('Réponse inattendue du serveur');
}

/// Plage maximale d'une requête `series`, en jours (limite du serveur).
const kMetricsMaxDays = 400;

/// Paramètres de temps d'une requête `series`.
typedef MetricsRange = ({String de, String a, String granularite});

/// Fenêtre Glance → plage de l'API. `a` est le jour qui contient le dernier
/// instant de la fenêtre (`end` est exclusif : pile minuit, c'est la veille).
/// L'API n'a pas d'heures : une fenêtre horaire demande des jours, et la carte
/// n'affiche alors qu'un point par jour.
///
/// [delayDays] : une métrique à délai est mesurée J + délai jours après sa
/// cohorte J, donc on demande les cohortes de `[début − délai, fin − délai]`
/// pour que leurs mesures tombent dans la fenêtre.
MetricsRange metricsRangeFor(DateWindow w, {int delayDays = 0}) {
  final last = w.end.subtract(const Duration(milliseconds: 1));
  final start =
      DateTime(w.start.year, w.start.month, w.start.day - delayDays);
  final fin = DateTime(last.year, last.month, last.day - delayDays);
  // Le serveur refuse plus de 400 jours (400) : « Tout » ou une période perso
  // longue est ramenée aux 400 derniers. Les buckets d'avant restent vides côté
  // carte (trou pour un %, 0 pour un nombre), comme ceux que l'API omet.
  final earliest = DateTime(fin.year, fin.month, fin.day - (kMetricsMaxDays - 1));
  final de = start.isBefore(earliest) ? earliest : start;
  return (
    de: _date(de),
    a: _date(fin.isBefore(de) ? de : fin),
    granularite: w.unit == TimeUnit.month ? 'mois' : 'jour',
  );
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}'
    '-${d.day.toString().padLeft(2, '0')}';

/// Client de l'API d'agrégats d'un site. [dio] est injectable pour les tests.
class MetricsApi {
  MetricsApi({required String baseUrl, required String token, Dio? dio})
      : _dio = (dio ?? Dio())
          ..options = BaseOptions(
            baseUrl: normalizeBase(baseUrl),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 25),
            // Les statuts d'erreur sont traduits ici, en exceptions typées.
            validateStatus: (_) => true,
            // Décodé ici : un corps illisible doit donner notre exception.
            responseType: ResponseType.plain,
            headers: {
              'accept': 'application/json',
              'user-agent': _userAgent,
              'authorization': 'Bearer $token',
            },
          );

  final Dio _dio;

  /// https:// par défaut, slash final garanti (les chemins sont relatifs).
  static String normalizeBase(String raw) {
    var s = raw.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'https://$s';
    return s.endsWith('/') ? s : '$s/';
  }

  Future<List<MetricDef>> catalogue() async {
    final j = await _get('catalogue');
    return [
      for (final e in (j['indicateurs'] as List).cast<Map<String, dynamic>>())
        MetricDef.fromJson(e),
    ];
  }

  /// Séries par id d'indicateur.
  Future<Map<String, MetricSeries>> series({
    required List<String> ids,
    required MetricsRange range,
    required String tz,
  }) async {
    final j = await _get('series', {
      'ids': ids.join(','),
      'de': range.de,
      'a': range.a,
      'granularite': range.granularite,
      'tz': tz,
    });
    return {
      for (final s in (j['series'] as List).cast<Map<String, dynamic>>())
        s['id'] as String: MetricSeries.fromJson(s),
    };
  }

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? query]) async {
    final r = await _dio.get<dynamic>(path, queryParameters: query);
    switch (r.statusCode) {
      case 200:
        break;
      case 401:
        throw const MetricsBadToken();
      case 404:
        throw const MetricsNotConfigured();
      case 400:
        throw MetricsBadRequest(_errorCode(_asMap(r.data)));
      default:
        throw const MetricsUnexpectedResponse();
    }
    final j = _asMap(r.data);
    if (j == null) throw const MetricsUnexpectedResponse();
    if (j['version'] != kMetricsApiVersion) throw const MetricsUnsupportedVersion();
    return j;
  }

  static Map<String, dynamic>? _asMap(dynamic data) {
    try {
      final d = data is String ? jsonDecode(data) : data;
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      return null;
    }
  }

  static String _errorCode(Map<String, dynamic>? j) {
    final e = j?['error'];
    return e is Map && e['code'] is String ? e['code'] as String : 'inconnu';
  }
}
