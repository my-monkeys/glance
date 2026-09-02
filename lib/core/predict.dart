import '../data/models/models.dart';
import '../data/models/period.dart';

/// Ce que la fenêtre courante permet de projeter.
///
/// [until] : fin de la période à projeter (exclu). Pour les périodes
/// calendaires (« Aujourd'hui », « Ce mois-ci », « Cette année ») c'est la fin
/// de l'unité calendaire ; pour les fenêtres glissantes (24 h, 7 j, 30 j, 12 m)
/// on ne complète que le bucket courant, donc `until` = fin de fenêtre.
///
/// [reference] : période précédente équivalente (hier / mois dernier / année
/// dernière) dont la série sert de *profil* à la projection. Null pour les
/// fenêtres glissantes (le rythme moyen des buckets écoulés suffit).
class ForecastSpec {
  const ForecastSpec({required this.until, this.reference});
  final DateTime until;
  final DateWindow? reference;
}

/// Détecte, à partir de la fenêtre seule, ce qu'on peut projeter. Null si la
/// fenêtre est entièrement passée (aucune prévision à afficher). La détection
/// par fenêtre (et non par [Period]) est volontaire : deux périodes qui
/// résolvent la même fenêtre (ex. « 12 m » en décembre ≡ « Cette année »)
/// affichent les mêmes données, donc la même prévision.
ForecastSpec? forecastSpecFor(DateWindow w, {DateTime? now}) {
  final n = now ?? DateTime.now();
  if (!w.end.isAfter(n)) return null;
  switch (w.unit) {
    case TimeUnit.hour:
      final dayStart = DateTime(n.year, n.month, n.day);
      if (w.start == dayStart) {
        return ForecastSpec(
          until: DateTime(n.year, n.month, n.day + 1),
          reference: DateWindow(
            DateTime(n.year, n.month, n.day - 1),
            dayStart,
            TimeUnit.hour,
          ),
        );
      }
    case TimeUnit.day:
      final monthStart = DateTime(n.year, n.month, 1);
      if (w.start == monthStart) {
        return ForecastSpec(
          until: DateTime(n.year, n.month + 1, 1),
          reference: DateWindow(
            DateTime(n.year, n.month - 1, 1),
            monthStart,
            TimeUnit.day,
          ),
        );
      }
    case TimeUnit.month:
      final yearStart = DateTime(n.year, 1, 1);
      if (w.start == yearStart) {
        return ForecastSpec(
          until: DateTime(n.year + 1, 1, 1),
          reference: DateWindow(
            DateTime(n.year - 1, 1, 1),
            yearStart,
            TimeUnit.month,
          ),
        );
      }
    }
  return ForecastSpec(until: w.end);
}

/// Fenêtre de référence à récupérer en plus de la série courante (null si la
/// prévision n'en a pas besoin). Utilisé par les providers de données.
DateWindow? forecastReferenceWindow(DateWindow w, {DateTime? now}) =>
    forecastSpecFor(w, now: now)?.reference;

/// Fenêtre « période précédente équivalente », pour la comparaison superposée
/// sur le graphique (bascule « Comparer »). Distincte de [forecastReferenceWindow] :
/// celle-ci ne sert qu'aux fenêtres calendaires en cours (pour profiler la
/// prévision) ; celle-ci se calcule pour toute fenêtre comparable — passée ou
/// en cours —, à la demande explicite de l'utilisateur.
///
/// Détection par la forme de [w] seule (comme [forecastSpecFor]) : un début
/// aligné sur le 1er du mois/de l'année donne le mois/l'année civile d'avant
/// (même s'il est plus court/long que [w] — un mois « en cours » se compare au
/// mois précédent en entier) ; sinon on décale [w] d'un cran de sa propre durée
/// (24 h avant, 7/30 j avant, 12 m avant…). Null pour une fenêtre trop large
/// (« Tout », > 400 j) où un « avant » n'a pas de sens.
DateWindow? previousPeriodWindow(DateWindow w) {
  final span = w.end.difference(w.start);
  if (span.inDays > 400) return null;
  switch (w.unit) {
    case TimeUnit.hour:
      final dayStart = DateTime(w.start.year, w.start.month, w.start.day);
      if (w.start == dayStart) {
        return DateWindow(
          dayStart.subtract(const Duration(days: 1)),
          dayStart,
          TimeUnit.hour,
        );
      }
      return DateWindow(w.start.subtract(span), w.start, TimeUnit.hour);
    case TimeUnit.day:
      final monthStart = DateTime(w.start.year, w.start.month, 1);
      if (w.start == monthStart) {
        return DateWindow(
          DateTime(w.start.year, w.start.month - 1, 1),
          monthStart,
          TimeUnit.day,
        );
      }
      return DateWindow(w.start.subtract(span), w.start, TimeUnit.day);
    case TimeUnit.month:
      final yearStart = DateTime(w.start.year, 1, 1);
      if (w.start == yearStart) {
        return DateWindow(
          DateTime(w.start.year - 1, 1, 1),
          yearStart,
          TimeUnit.month,
        );
      }
      return DateWindow(w.start.subtract(span), w.start, TimeUnit.month);
  }
}

/// Série prête à afficher pour une fenêtre large (« Tout ») : écarte les
/// buckets vides en tête pour ne pas peindre un graphe majoritairement plat
/// avant la première vraie donnée (cf. absence d'API « première donnée » chez
/// Umami/Plausible — on la déduit de la série déjà récupérée). Sans effet sur
/// les fenêtres normales (seule une fenêtre de plus de 400 j est concernée).
/// Garde la série intacte si elle est entièrement vide (état « zéro »
/// légitime) ou si le rognage la réduirait à moins de 2 points.
List<SeriesPoint> displaySeries(List<SeriesPoint> series, DateWindow window) {
  if (window.end.difference(window.start).inDays <= 400) return series;
  final i = series.indexWhere((p) => p.visitors > 0 || p.pageviews > 0);
  if (i <= 0) return series;
  final trimmed = series.sublist(i);
  return trimmed.length >= 2 ? trimmed : series;
}

/// Prévision prête à tracer.
class Forecast {
  const Forecast({required this.points, required this.growth});

  /// Points de la courbe pointillée (visiteurs uniquement, pageviews = 0).
  /// Le premier point coïncide avec un bucket observé (raccord visuel).
  final List<SeriesPoint> points;

  /// Facteur de croissance projeté de la somme des buckets (≥ 1). Sert à
  /// dériver un total période projeté : `total observé × growth`.
  final double growth;

  /// Total période projeté à partir du total observé (visiteurs uniques du
  /// résumé — la somme des buckets surcompterait, un visiteur pouvant
  /// apparaître dans plusieurs buckets).
  int projectedTotal(int observedTotal) => (observedTotal * growth).round();
}

DateTime _truncate(DateTime t, TimeUnit u) => switch (u) {
  TimeUnit.hour => DateTime(t.year, t.month, t.day, t.hour),
  TimeUnit.day => DateTime(t.year, t.month, t.day),
  TimeUnit.month => DateTime(t.year, t.month, 1),
};

DateTime _next(DateTime t, TimeUnit u) => switch (u) {
  TimeUnit.hour => DateTime(t.year, t.month, t.day, t.hour + 1),
  TimeUnit.day => DateTime(t.year, t.month, t.day + 1),
  TimeUnit.month => DateTime(t.year, t.month + 1, 1),
};

/// Construit la prévision pour une série observée sur [window].
///
/// Modèle : « observé + rythme attendu × temps restant ».
/// - Avec [reference] (période précédente équivalente), le rythme attendu de
///   chaque bucket restant est le bucket homologue de la référence, rescalé par
///   le ratio observé/référence à l'instant équivalent — la prévision épouse
///   le profil réel (creux de la nuit, week-ends…).
/// - Sans référence, le rythme attendu est la moyenne des buckets complets déjà
///   observés (projection plate, honnête à défaut de profil).
///
/// Null si rien à projeter (fenêtre passée, série vide ou désalignée).
Forecast? buildForecast({
  required List<SeriesPoint> series,
  required DateWindow window,
  List<SeriesPoint>? reference,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final spec = forecastSpecFor(window, now: n);
  if (spec == null || series.isEmpty) return null;

  final unit = window.unit;
  final curStart = _truncate(n, unit);
  final i = series.length - 1;
  if (series[i].t != curStart) return null;

  final bucketMs = _next(curStart, unit).difference(curStart).inMilliseconds;
  final f = (n.difference(curStart).inMilliseconds / bucketMs).clamp(0.02, 1.0);

  final obsCur = series[i].visitors;
  var obsSum = 0.0;
  for (final p in series) {
    obsSum += p.visitors;
  }
  final avgPrev = i == 0 ? 0.0 : (obsSum - obsCur) / i;

  // Profil de référence indexé bucket à bucket ; au-delà de sa longueur (mois
  // plus court…), sa moyenne. Ignoré s'il est vide ou nul.
  double refSum = 0;
  final ref = reference ?? const <SeriesPoint>[];
  for (final p in ref) {
    refSum += p.visitors;
  }
  final refAvg = ref.isEmpty ? 0.0 : refSum / ref.length;
  double refAt(int j) => j < ref.length ? ref[j].visitors : refAvg;

  double? ratio;
  if (refSum > 0) {
    var upToNow = 0.0;
    for (var j = 0; j < i; j++) {
      upToNow += refAt(j);
    }
    upToNow += refAt(i) * f;
    if (upToNow > 0) ratio = obsSum / upToNow;
  }

  // Référence morte sur le reste de la période (ex. instance analytics down
  // pendant la période de référence — vécu le 12/08 : 12 h sans collecte) :
  // le profil donnerait une prévision plate à zéro. On retombe sur le rythme
  // moyen observé, comme sans référence.
  if (ratio != null) {
    var refRest = refAt(i) * (1 - f);
    var t2 = _next(curStart, unit);
    var j2 = i + 1;
    while (t2.isBefore(spec.until)) {
      refRest += refAt(j2);
      t2 = _next(t2, unit);
      j2++;
    }
    if (refRest <= 0) ratio = null;
  }

  // Complétion du bucket courant, puis buckets futurs jusqu'à `until`.
  final double projCur;
  if (ratio != null) {
    projCur = obsCur + refAt(i) * (1 - f) * ratio;
  } else if (avgPrev > 0) {
    projCur = obsCur + avgPrev * (1 - f);
  } else {
    // Aucune base : run-rate borné (évite l'explosion en tout début de bucket).
    projCur = obsCur / (f < 0.25 ? 0.25 : f);
  }

  final points = <SeriesPoint>[
    if (i > 0) SeriesPoint(series[i - 1].t, series[i - 1].visitors, 0),
    SeriesPoint(curStart, projCur, 0),
  ];
  var projSum = obsSum - obsCur + projCur;
  var t = _next(curStart, unit);
  var j = i + 1;
  while (t.isBefore(spec.until)) {
    final v = ratio != null ? refAt(j) * ratio : (avgPrev > 0 ? avgPrev : projCur);
    points.add(SeriesPoint(t, v, 0));
    projSum += v;
    t = _next(t, unit);
    j++;
  }

  return Forecast(
    points: points,
    growth: obsSum > 0 ? projSum / obsSum : 1,
  );
}
