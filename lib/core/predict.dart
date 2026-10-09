import 'dart:math' as math;

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
/// Ce qu'une fenêtre recouvre : une journée, un mois, une année, ou rien de
/// calendaire (fenêtre glissante).
enum CalendarScope { day, month, year, sliding }

/// Portée calendaire d'une fenêtre, déduite de son début, de sa fin **et** de
/// sa granularité — les trois sont nécessaires.
///
/// Le début seul confond, le 1er du mois, « aujourd'hui » et « ce mois-ci »,
/// et projetterait trente jours à partir de onze heures observées. La
/// granularité seule confond « ce mois-ci » découpé en heures avec
/// « aujourd'hui ». C'est la **fin** qui tranche : une journée ne dure pas plus
/// de vingt-quatre heures, un mois pas plus d'un mois.
///
/// Reste un cas que rien ne peut départager : le 1er du mois, « aujourd'hui »
/// et « ce mois-ci » découpé en heures donnent la même fenêtre au bucket près.
/// On retient alors la portée la plus étroite — un horizon sous-estimé se lit,
/// là où un horizon surestimé donne un chiffre aberrant.
CalendarScope calendarScopeOf(DateWindow w) {
  if (w.allTime) return CalendarScope.sliding;
  final dayStart = DateTime(w.start.year, w.start.month, w.start.day);
  final monthStart = DateTime(w.start.year, w.start.month, 1);
  final yearStart = DateTime(w.start.year, 1, 1);

  if (w.unit == TimeUnit.hour &&
      w.start == dayStart &&
      !w.end.isAfter(DateTime(dayStart.year, dayStart.month, dayStart.day + 1))) {
    return CalendarScope.day;
  }
  if (w.unit != TimeUnit.month &&
      w.start == monthStart &&
      !w.end.isAfter(DateTime(monthStart.year, monthStart.month + 1, 1))) {
    return CalendarScope.month;
  }
  if (w.start == yearStart &&
      !w.end.isAfter(DateTime(yearStart.year + 1, 1, 1))) {
    return CalendarScope.year;
  }
  return CalendarScope.sliding;
}

ForecastSpec? forecastSpecFor(DateWindow w, {DateTime? now}) {
  final n = now ?? DateTime.now();
  if (!w.end.isAfter(n)) return null;

  switch (calendarScopeOf(w)) {
    case CalendarScope.day:
      final dayStart = DateTime(n.year, n.month, n.day);
      return ForecastSpec(
        until: DateTime(n.year, n.month, n.day + 1),
        reference: DateWindow(
          DateTime(n.year, n.month, n.day - 1),
          dayStart,
          w.unit,
        ),
      );
    case CalendarScope.month:
      final monthStart = DateTime(n.year, n.month, 1);
      return ForecastSpec(
        until: DateTime(n.year, n.month + 1, 1),
        reference:
            DateWindow(DateTime(n.year, n.month - 1, 1), monthStart, w.unit),
      );
    case CalendarScope.year:
      final yearStart = DateTime(n.year, 1, 1);
      return ForecastSpec(
        until: DateTime(n.year + 1, 1, 1),
        reference: DateWindow(DateTime(n.year - 1, 1, 1), yearStart, w.unit),
      );
    case CalendarScope.sliding:
      // Fenêtre glissante : on ne complète que le bucket courant.
      return ForecastSpec(until: w.end);
  }
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
  // « Tout » n'a pas d'« avant » : l'historique complet se compare au néant, ce
  // qui donnait un delta « ×N » trompeur.
  if (w.allTime) return null;
  final span = w.end.difference(w.start);
  if (span.inDays > 400) return null;

  // La portée se lit sur la fenêtre entière, pas sur sa granularité : depuis
  // que le découpage se choisit, « ce mois-ci » peut être en heures — et se
  // comparerait alors à la veille au lieu du mois précédent.
  switch (calendarScopeOf(w)) {
    case CalendarScope.day:
      final dayStart = DateTime(w.start.year, w.start.month, w.start.day);
      return DateWindow(
        DateTime(dayStart.year, dayStart.month, dayStart.day - 1),
        dayStart,
        w.unit,
      );
    case CalendarScope.month:
      final monthStart = DateTime(w.start.year, w.start.month, 1);
      return DateWindow(
        DateTime(monthStart.year, monthStart.month - 1, 1),
        monthStart,
        w.unit,
      );
    case CalendarScope.year:
      final yearStart = DateTime(w.start.year, 1, 1);
      return DateWindow(
        DateTime(yearStart.year - 1, 1, 1),
        yearStart,
        w.unit,
      );
    case CalendarScope.sliding:
      return DateWindow(w.start.subtract(span), w.start, w.unit);
  }
}

/// Série prête à afficher pour la période « Tout » : écarte les buckets vides
/// en tête pour ne pas peindre un long trait plat avant la première vraie
/// donnée. Sans effet sur les autres fenêtres.
///
/// Indispensable depuis que « Tout » a une fenêtre **commune** à tous les
/// sites : elle commence à la première donnée du plus ancien, si bien qu'un
/// site créé trois mois plus tard traîne trois mois de zéros — ce qui se voyait
/// surtout sur les sparklines et les widgets, trop petits pour qu'on distingue
/// un plat d'un creux.
///
/// Deux coupes possibles, dans cet ordre :
///  - le préfixe vide, jusqu'à la première donnée ;
///  - un **grand trou** situé après elle, qui trahit une visite isolée (test,
///    robot) suivie de mois de silence avant le vrai démarrage. « Grand » veut
///    dire au moins [_gapShare] de la série : un site qui n'a personne pendant
///    deux jours ne doit pas voir son historique rogné pour autant.
///
/// Garde la série intacte si elle est entièrement vide (état « zéro »
/// légitime) ou si le rognage la réduirait à moins de 2 points.
List<SeriesPoint> displaySeries(List<SeriesPoint> series, DateWindow window) {
  if (!window.allTime) return series;
  bool empty(SeriesPoint p) => p.visitors <= 0 && p.pageviews <= 0;

  final first = series.indexWhere((p) => !empty(p));
  if (first < 0) return series; // jamais aucune donnée : rien à rogner
  var cut = first;

  // Un trou doit peser dans la série pour être pris pour un « avant le début ».
  const gapShare = 0.15;
  final minGap = math.max(2, (series.length * gapShare).round());
  var i = first;
  while (i < series.length) {
    if (!empty(series[i])) {
      i++;
      continue;
    }
    var j = i;
    while (j < series.length && empty(series[j])) {
      j++;
    }
    if (j - i >= minGap && j < series.length) cut = j;
    i = j;
  }

  if (cut <= 0) return series;
  final trimmed = series.sublist(cut);
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
/// - Sans référence, le bucket courant se complète à son propre rythme, adossé
///   au dernier bucket complet ; les buckets futurs le reprennent (projection
///   plate, honnête à défaut de profil).
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

  // Profil de référence indexé bucket à bucket ; au-delà de sa longueur (mois
  // plus court…), sa moyenne. Ignoré s'il est vide ou nul.
  double refSum = 0;
  final ref = reference ?? const <SeriesPoint>[];
  for (final p in ref) {
    refSum += p.visitors;
  }
  final refAvg = ref.isEmpty ? 0.0 : refSum / ref.length;
  double refAt(int j) => j < ref.length ? ref[j].visitors : refAvg;

  // Le profil est indexé bucket à bucket : une référence récupérée dans une
  // autre granularité appliquerait ses valeurs à des buckets d'une autre durée
  // (une moyenne journalière sur des heures surestime d'un facteur vingt-quatre).
  // On la compare à SA fenêtre, pas à la série en cours : celle-ci n'est qu'un
  // préfixe de la période — un mois entamé le 2 ne compte qu'un bucket face aux
  // trente de sa référence, ce qui est normal.
  final refWindow = spec.reference;
  final refConsistent = ref.isEmpty ||
      refWindow == null ||
      (ref.length * 2 >= refWindow.bucketCount &&
          refWindow.bucketCount * 2 >= ref.length);

  double? ratio;
  if (refSum > 0 && refConsistent) {
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
  } else if (i > 0) {
    // Rythme attendu du bucket entier : son propre rythme pour la part écoulée,
    // le dernier bucket complet pour le reste. Pas la moyenne de toute la
    // fenêtre : sur « 12 m », elle mêle les mois d'avant le lancement et
    // projetait 1 565 sur un mois parti pour 4 000 (vécu le 09/10).
    final expected = obsCur + series[i - 1].visitors * (1 - f);
    projCur = obsCur + expected * (1 - f);
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
    // Sans profil, les buckets futurs reprennent le dernier rythme connu : la
    // moyenne de la fenêtre traînerait les mois d'avant le lancement.
    final v = ratio != null ? refAt(j) * ratio : projCur;
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
