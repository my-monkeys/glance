import 'package:dio/dio.dart';

/// dart:io ne suit une redirection que pour GET et HEAD : un POST qui reçoit un
/// 301, 302, 307 ou 308 remonte en erreur (« Erreur 308 du serveur »). Vécu à
/// l'ajout d'une source Umami, dont le login est un POST : le proxy de
/// l'instance (Traefik, Caddy, Vercel…) renvoie l'adresse saisie vers son
/// adresse canonique (http → https, domaine nu → www).
///
/// La requête est rejouée avec la même méthode et le même corps :
/// - même chemin, autre origine : l'origine est adoptée pour la suite. Sinon
///   chaque requête repasserait par la redirection, et dart:io retire le Bearer
///   d'un GET redirigé vers une autre origine (un 401 qui ne se corrige pas) ;
/// - autre chemin : seulement pour un 307 ou un 308, qui promettent la même
///   méthode. Un 301 ou un 302 vers un autre chemin n'est pas une adresse
///   canonique (une page de connexion, par exemple).
///
/// Jamais de https vers http : le corps porte le mot de passe.
class FollowRedirects extends Interceptor {
  FollowRedirects(this._dio);

  final Dio _dio;

  static const _maxHops = 5;
  static const _hopsKey = 'glance.redirectHops';
  static const _canonical = {301, 302, 307, 308};
  static const _methodPreserving = {307, 308};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retry = _retryOf(err);
    if (retry == null) return handler.next(err);
    try {
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  RequestOptions? _retryOf(DioException err) {
    final res = err.response;
    final location = res?.headers.value('location');
    final req = err.requestOptions;
    final hops = (req.extra[_hopsKey] as int?) ?? 0;
    if (res == null || location == null || hops >= _maxHops) return null;

    final from = req.uri;
    final to = from.resolve(location);
    if (!to.isScheme('http') && !to.isScheme('https')) return null;
    if (from.isScheme('https') && to.isScheme('http')) return null;

    final status = res.statusCode;
    final Uri target;
    if (to.path == from.path && _canonical.contains(status)) {
      // La requête d'origine garde ses paramètres, même si `Location` les omet.
      target = from.replace(scheme: to.scheme, host: to.host, port: to.port);
      _dio.options.baseUrl = to.origin;
    } else if (_methodPreserving.contains(status)) {
      target = to;
    } else {
      return null;
    }
    return req.copyWith(
      path: target.toString(),
      queryParameters: const {},
      extra: {...req.extra, _hopsKey: hops + 1},
    );
  }
}
