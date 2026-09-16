import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/metric_icon.dart';
import 'package:glance/data/models/dimension.dart';

void main() {
  group('umamiSlug', () {
    test('met en minuscules et remplace espaces et soulignés', () {
      expect(umamiSlug('Android OS'), 'android-os');
      expect(umamiSlug('Windows 10'), 'windows-10');
      expect(umamiSlug('Mac_OS'), 'mac-os');
    });

    test('est idempotent sur les valeurs déjà slugifiées', () {
      expect(umamiSlug('chrome'), 'chrome');
      expect(umamiSlug('edge-chromium'), 'edge-chromium');
    });
  });

  group('metricIconSource', () {
    test('référent : favicon du domaine, sans www ni port', () {
      final src = metricIconSource(
        kind: MetricIconKind.favicon,
        code: 'www.google.com:443',
        instanceBase: null,
      );
      expect(src?.url, 'https://icons.duckduckgo.com/ip3/google.com.ico');
      expect(src?.cacheKey, 'ddg.google.com');
    });

    test('valeur qui n\'est pas un domaine : aucune requête', () {
      // Un échec serait mémorisé une semaine — mieux vaut ne pas demander.
      for (final code in ['Accès direct', 'localhost', '', '   ']) {
        expect(
          metricIconSource(
            kind: MetricIconKind.favicon,
            code: code,
            instanceBase: null,
          ),
          isNull,
        );
      }
    });

    test('navigateur : l\'URL vient du code brut, pas du libellé', () {
      final src = metricIconSource(
        kind: MetricIconKind.browser,
        code: 'crios', // libellé affiché : « Chrome (iOS) »
        instanceBase: 'https://uuu.my-monkey.fr',
      );
      expect(src?.url, 'https://uuu.my-monkey.fr/images/browser/crios.png');
    });

    test('la clé de cache porte l\'hôte de l\'instance', () {
      final a = metricIconSource(
        kind: MetricIconKind.os,
        code: 'Windows 10',
        instanceBase: 'https://uuu.my-monkey.fr',
      );
      final b = metricIconSource(
        kind: MetricIconKind.os,
        code: 'Windows 10',
        instanceBase: 'https://stats.exemple.fr',
      );
      expect(a?.cacheKey, 'umami.uuu.my-monkey.fr.os.windows-10');
      expect(a?.cacheKey == b?.cacheKey, isFalse);
    });

    test('instance en clair : le schéma est conservé', () {
      final src = metricIconSource(
        kind: MetricIconKind.browser,
        code: 'chrome',
        instanceBase: 'http://umami.local:3000',
      );
      expect(src?.url, 'http://umami.local:3000/images/browser/chrome.png');
    });

    test('hors Umami, navigateurs et systèmes n\'ont pas d\'image', () {
      expect(
        metricIconSource(
          kind: MetricIconKind.browser,
          code: 'chrome',
          instanceBase: null,
        ),
        isNull,
      );
    });

    test('appareils et drapeaux se dessinent localement', () {
      expect(
        metricIconSource(
          kind: MetricIconKind.device,
          code: 'mobile',
          instanceBase: 'https://uuu.my-monkey.fr',
        ),
        isNull,
      );
      expect(
        metricIconSource(
          kind: MetricIconKind.flag,
          code: 'FR',
          instanceBase: null,
        ),
        isNull,
      );
    });
  });
}
