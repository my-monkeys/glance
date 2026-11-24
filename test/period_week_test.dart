import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/core/predict.dart';
import 'package:glance/data/models/period.dart';
import 'package:glance/state/period_state.dart';
import 'package:glance/state/providers.dart';
import 'package:glance/state/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Mardi 24 novembre 2026, 14 h 30.
  final now = DateTime(2026, 11, 24, 14, 30);

  group('Period.thisWeek', () {
    test('du lundi à demain minuit, en jours, marquée semaine', () {
      final w = Period.thisWeek.window(now: now);
      expect(w.start, DateTime(2026, 11, 23));
      expect(w.end, DateTime(2026, 11, 25));
      expect(w.unit, TimeUnit.day);
      expect(w.week, isTrue);
    });

    test('début réglé au dimanche', () {
      final w = Period.thisWeek.window(now: now, firstWeekday: DateTime.sunday);
      expect(w.start, DateTime(2026, 11, 22));
    });

    test('le dimanche reste dans la semaine du lundi précédent', () {
      final sunday = DateTime(2026, 11, 29, 20);
      expect(Period.thisWeek.window(now: sunday).start, DateTime(2026, 11, 23));
      expect(
          Period.thisWeek
              .window(now: sunday, firstWeekday: DateTime.sunday)
              .start,
          DateTime(2026, 11, 29));
    });

    test('semaine passée : sept jours entiers', () {
      final w = Period.thisWeek.window(now: now, weekOffset: -1);
      expect(w.start, DateTime(2026, 11, 16));
      expect(w.end, DateTime(2026, 11, 23));
    });

    test('à cheval sur deux mois', () {
      final w = Period.thisWeek.window(now: DateTime(2026, 12, 2, 9));
      expect(w.start, DateTime(2026, 11, 30));
    });

    test('une semaine ne se confond pas avec « 7 jours » le dimanche', () {
      final sunday = DateTime(2026, 11, 29, 20);
      final week = Period.thisWeek.window(now: sunday);
      final d7 = Period.d7.window(now: sunday);
      expect(week.start, d7.start);
      expect(week.end, d7.end);
      expect(week == d7, isFalse);
    });
  });

  group('portée semaine', () {
    test('lue sur la fenêtre, même un lundi en heures', () {
      final monday = DateTime(2026, 11, 23, 10);
      final w = Period.thisWeek.window(now: monday, unit: TimeUnit.hour);
      expect(calendarScopeOf(w), CalendarScope.week);
    });

    test('prévision jusqu’au bout de la semaine, référence = semaine d’avant',
        () {
      final spec = forecastSpecFor(Period.thisWeek.window(now: now), now: now)!;
      expect(spec.until, DateTime(2026, 11, 30));
      expect(spec.reference!.start, DateTime(2026, 11, 16));
      expect(spec.reference!.end, DateTime(2026, 11, 23));
    });

    test('se compare à la semaine d’avant', () {
      final prev = previousPeriodWindow(Period.thisWeek.window(now: now))!;
      expect(prev.start, DateTime(2026, 11, 16));
      expect(prev.end, DateTime(2026, 11, 23));
    });

    test('au même avancement : lundi 16 → mardi 17 à 14 h 30', () {
      final prev =
          previousPeriodSoFar(Period.thisWeek.window(now: now), now: now)!;
      expect(prev.start, DateTime(2026, 11, 16));
      expect(prev.end, DateTime(2026, 11, 17, 14, 30));
    });

    test('la veille / 7 jours avant ne s’applique pas à la semaine', () {
      expect(compareBaseApplies(Period.thisWeek.window(now: now)), isFalse);
    });
  });

  group('réglage « Début de semaine »', () {
    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      return c;
    }

    test('la fenêtre suit le réglage, qui est persisté', () async {
      final c = await container();
      c.read(periodProvider.notifier).set(Period.thisWeek);
      expect(c.read(windowProvider)!.start.weekday, DateTime.monday);

      c.read(settingsProvider.notifier).setWeekStart(WeekStart.sunday);
      expect(c.read(windowProvider)!.start.weekday, DateTime.sunday);
      expect(c.read(sharedPrefsProvider).getString('glance.week.start'),
          'sunday');
    });

    test('navigation semaine par semaine, jamais dans le futur', () async {
      final c = await container();
      final n = c.read(periodProvider.notifier)..set(Period.thisWeek);
      n.shiftWeek(1);
      expect(c.read(periodProvider).weekOffset, 0);
      n.shiftWeek(-2);
      expect(c.read(periodProvider).weekOffset, -2);
      final w = c.read(windowProvider)!;
      // Sept jours civils, pas 7 × 24 h : un changement d'heure en fait 167.
      expect(w.end, DateTime(w.start.year, w.start.month, w.start.day + 7));
    });
  });
}
