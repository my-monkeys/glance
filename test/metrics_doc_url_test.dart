import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/ui/dashboards/metrics_source_screen.dart';

void main() {
  test('la page de doc suit la langue : français, sinon anglais', () {
    expect(metricsDocUrl(const Locale('fr')),
        'https://glance-analytics.com/docs/source-de-metriques.html');
    expect(metricsDocUrl(const Locale('fr', 'CA')),
        'https://glance-analytics.com/docs/source-de-metriques.html');
    expect(metricsDocUrl(const Locale('en')),
        'https://glance-analytics.com/en/docs/metrics-source.html');
    expect(metricsDocUrl(const Locale('de')),
        'https://glance-analytics.com/en/docs/metrics-source.html');
  });
}
