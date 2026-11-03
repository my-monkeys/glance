import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/providers/follow_redirects.dart';

typedef _Reply = ({int status, String? location});

/// Répond selon l'URL demandée et garde chaque requête reçue.
class _RoutingAdapter implements HttpClientAdapter {
  _RoutingAdapter(this.routes);
  final Map<String, _Reply> routes;
  final seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancel) async {
    seen.add(options);
    final reply = routes[options.uri.toString()] ?? (status: 404, location: null);
    return ResponseBody.fromString(
      jsonEncode({'token': 'ok'}),
      reply.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (reply.location != null) 'location': [reply.location!],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(String base, Map<String, _Reply> routes) {
  final dio = Dio(BaseOptions(baseUrl: base))
    ..httpClientAdapter = _RoutingAdapter(routes);
  return dio..interceptors.add(FollowRedirects(dio));
}

List<RequestOptions> _seen(Dio dio) =>
    (dio.httpClientAdapter as _RoutingAdapter).seen;

void main() {
  group('FollowRedirects', () {
    // Le vrai adaptateur (dart:io) : c'est lui qui refuse de suivre un POST.
    test('débloque un POST 308 sur un vrai serveur', () async {
      final canonical = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final legacy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => canonical.close(force: true));
      addTearDown(() => legacy.close(force: true));
      final target = 'http://127.0.0.1:${canonical.port}';
      legacy.listen((req) => req.response
        ..statusCode = 308
        ..headers.set('location', '$target${req.uri.path}')
        ..close());
      canonical.listen((req) async {
        final body = await utf8.decodeStream(req);
        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'method': req.method, 'body': body}))
          ..close();
      });

      final bare = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${legacy.port}'));
      await expectLater(
        bare.post('/api/auth/login', data: {'username': 'u'}),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'statut', 308)),
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${legacy.port}'));
      dio.interceptors.add(FollowRedirects(dio));
      final r = await dio.post('/api/auth/login', data: {'username': 'u'});
      expect(r.data, {'method': 'POST', 'body': '{"username":"u"}'});
      expect(dio.options.baseUrl, target);
    });

    test('rejoue un POST redirigé en 308 vers https et adopte l’origine', () async {
      final dio = _dio('http://umami.test', {
        'http://umami.test/api/auth/login':
            (status: 308, location: 'https://umami.test/api/auth/login'),
        'https://umami.test/api/auth/login': (status: 200, location: null),
      });

      final r = await dio.post('/api/auth/login', data: {'username': 'u'});

      expect(r.statusCode, 200);
      final replay = _seen(dio).last;
      expect(replay.method, 'POST');
      expect(replay.data, {'username': 'u'});
      expect(dio.options.baseUrl, 'https://umami.test');
    });

    test('suit le domaine nu vers www en 301 et garde les paramètres', () async {
      final dio = _dio('https://umami.test', {
        'https://umami.test/api/stats?a=1':
            (status: 301, location: 'https://www.umami.test/api/stats'),
        'https://www.umami.test/api/stats?a=1': (status: 200, location: null),
      });

      final r = await dio.post('/api/stats', queryParameters: {'a': '1'});

      expect(r.statusCode, 200);
      expect(dio.options.baseUrl, 'https://www.umami.test');
    });

    test('suit un 308 vers un autre chemin sans changer de base', () async {
      final dio = _dio('https://umami.test', {
        'https://umami.test/api/auth/login':
            (status: 308, location: '/api/auth/login/'),
        'https://umami.test/api/auth/login/': (status: 200, location: null),
      });

      final r = await dio.post('/api/auth/login');

      expect(r.statusCode, 200);
      expect(dio.options.baseUrl, 'https://umami.test');
    });

    test('ne suit pas un 302 vers un autre chemin', () async {
      final dio = _dio('https://umami.test', {
        'https://umami.test/api/auth/login': (status: 302, location: '/login'),
      });

      await expectLater(
        dio.post('/api/auth/login'),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'statut', 302)),
      );
      expect(_seen(dio), hasLength(1));
    });

    test('refuse de passer de https à http', () async {
      final dio = _dio('https://umami.test', {
        'https://umami.test/api/auth/login':
            (status: 308, location: 'http://umami.test/api/auth/login'),
      });

      await expectLater(dio.post('/api/auth/login'), throwsA(isA<DioException>()));
      expect(_seen(dio), hasLength(1));
    });

    test('s’arrête après cinq redirections', () async {
      final dio = _dio('https://umami.test', {
        'https://umami.test/api/auth/login':
            (status: 308, location: 'https://umami.test/api/auth/login'),
      });

      await expectLater(dio.post('/api/auth/login'), throwsA(isA<DioException>()));
      expect(_seen(dio), hasLength(6));
    });
  });
}
