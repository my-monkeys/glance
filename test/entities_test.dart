import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/countries.dart';
import 'package:glance/core/entities.dart';
import 'package:glance/data/models/dimension.dart';
import 'package:glance/data/models/models.dart';
import 'package:glance/l10n/app_localizations_en.dart';
import 'package:glance/l10n/app_localizations_fr.dart';
import 'package:intl/intl.dart';

final _fr = AppLocalizationsFr();
final _en = AppLocalizationsEn();

void main() {
  tearDown(() => Intl.defaultLocale = null);

  test('pays et langues suivent la langue active', () {
    Intl.defaultLocale = 'fr';
    expect(countryName('US'), 'États-Unis');
    expect(countryName('gb'), 'Royaume-Uni');
    expect(languageName(_fr, 'fr-fr'), 'Français');
    expect(languageName(_fr, 'pt-br'), 'Portugais (BR)');
    Intl.defaultLocale = 'en';
    expect(countryName('US'), 'United States');
    expect(languageName(_en, 'fr'), 'French');
  });

  test('une valeur inconnue reste telle quelle', () {
    expect(countryName('ZZZ'), 'ZZZ');
    expect(languageName(_fr, 'xx-zz'), 'xx-zz');
    expect(browserName(_fr, 'Netscape'), 'Netscape');
  });

  test('appareils, canaux et navigateurs génériques sont traduits', () {
    expect(deviceName(_fr, 'laptop'), 'Portable');
    expect(deviceName(_en, 'laptop'), 'Laptop');
    expect(channelName(_fr, 'Organic Search'), 'Recherche organique');
    expect(channelName(_en, 'paidSocial'), 'Paid social');
    expect(browserName(_fr, 'crios'), 'Chrome (iOS)');
    expect(browserName(_fr, 'searchbot'), 'Robot d\'indexation');
    expect(browserName(_en, ''), 'Unknown');
  });

  test('les lignes de métrique se traduisent à l\'affichage', () {
    const direct = MetricRow.direct(3);
    expect(metricRowLabel(_fr, MetricType.referrers, direct), 'Accès direct');
    expect(metricRowLabel(_en, MetricType.referrers, direct), 'Direct');
    const empty = MetricRow(label: '', value: 1, code: '');
    expect(metricRowLabel(_fr, MetricType.operatingSystems, empty), 'Inconnu');
    const dev = MetricRow(label: 'mobile', value: 1, code: 'mobile');
    expect(metricRowLabel(_en, MetricType.devices, dev), 'Mobile');
    const path = MetricRow(label: '/', value: 1, code: '');
    expect(metricRowLabel(_fr, MetricType.pages, path), '/');
  });
}
