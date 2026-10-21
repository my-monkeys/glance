import '../data/models/indicator_result.dart';
import '../data/models/metrics_source.dart';
import '../data/models/models.dart';
import '../data/models/period.dart';
import '../data/providers/buckets.dart';

/// Sous ce dénominateur cumulé, le taux global n'est pas affiché : même seuil
/// de confidentialité que celui du serveur, qui renvoie alors `valeur: null`.
const kMinRatioDenominator = 5;

/// Granularité affichée d'une fenêtre : l'API n'a pas d'heures, donc une
/// fenêtre horaire se lit en jours (cf. `metricsRangeFor`).
TimeUnit externalUnitOf(TimeUnit u) => u == TimeUnit.hour ? TimeUnit.day : u;

/// La fenêtre telle que la source la voit : mêmes bornes, granularité
/// ramenée à [externalUnitOf], fin alignée sur le bucket suivant (une fenêtre
/// horaire s'arrête en cours de journée, et `bucketsOf` n'en verrait aucun).
DateWindow externalWindowOf(DateWindow w) {
  final unit = externalUnitOf(w.unit);
  final last = truncateBucket(w.end.subtract(const Duration(milliseconds: 1)), unit);
  return DateWindow(w.start, advanceBucket(last, unit), unit);
}

/// Durée d'une fenêtre en jours, arrondie au-dessus : « Aujourd'hui » et
/// « 24 h » valent 1, « 7 jours » 7. Sert à choisir le membre d'une famille.
int windowDays(DateWindow w) =>
    (w.end.difference(w.start).inMinutes / (24 * 60)).ceil().clamp(1, 1 << 20);

/// Un point de l'API rangé dans le bucket de sa date de MESURE.
class _Placed {
  const _Placed(this.point, this.done);
  final MetricPoint point;

  /// Faux tant que le jour de mesure n'est pas terminé : le point est alors un
  /// trou, quoi que dise le serveur.
  final bool done;

  double? get valeur => done ? point.valeur : null;
}

/// Points de l'API → résultat de carte, un point par bucket de la fenêtre.
///
/// Une métrique à délai ([delayDays] > 0, J7 → 7) est **mesurée** J + délai
/// jours après la cohorte J : chaque point est placé à cette date, pour que
/// l'axe reste celui de la période choisie, comme pour toutes les autres
/// cartes. Un point dont le jour de mesure n'est pas terminé (aujourd'hui, en
/// général) reste un trou. En mois, on décale de la même façon puis on rattache
/// au bucket du mois (`truncateBucket`) ; on ne regroupe PAS des cohortes
/// journalières côté client : le serveur agrège le mois entier, alors que
/// chaque jour isolé tombe souvent sous son seuil de confidentialité.
///
/// Les buckets que l'API ne renvoie pas, ou renvoie hors fenêtre, sont écartés
/// ou comblés. [now] est injectable pour les tests.
///
/// [dataUntil] (`donnees_jusqu_au` du catalogue) : dernier jour publié par la
/// source. Les buckets d'après sont des trous, même pour un nombre (un jour pas
/// encore publié n'est pas un jour à 0), et ne comptent pas dans les totaux.
IndicatorData externalDataOf(
  MetricUnit unit,
  DateWindow window,
  List<MetricPoint> points, {
  int delayDays = 0,
  DateTime? now,
  String? member,
  DateTime? dataUntil,
}) {
  final w = externalWindowOf(window);
  // Le dernier jour publié porte sur la date de la série ; son point est placé
  // à sa date de mesure, comme les autres.
  final lastPlaced = dataUntil == null
      ? null
      : DateTime(dataUntil.year, dataUntil.month, dataUntil.day + delayDays);
  bool published(DateTime bucket) =>
      lastPlaced == null || !bucket.isAfter(lastPlaced);
  final t0 = now ?? DateTime.now();
  final today = DateTime(t0.year, t0.month, t0.day);
  final byBucket = <DateTime, _Placed>{};
  for (final p in points) {
    final measured = DateTime(p.t.year, p.t.month, p.t.day + delayDays);
    byBucket[truncateBucket(measured, w.unit)] =
        _Placed(p, delayDays == 0 || measured.isBefore(today));
  }
  final buckets = bucketsOf(w);
  final firstGap = buckets.where((t) => !published(t)).firstOrNull;
  final unpublished = firstGap == null
      ? null
      : Unpublished(until: dataUntil!, from: firstGap);

  // Première et dernière cohortes réellement mesurées dans la fenêtre.
  DateTime? first;
  DateTime? last;
  void seen(DateTime? t) {
    if (t == null || delayDays == 0) return;
    final end = w.unit == TimeUnit.month ? DateTime(t.year, t.month + 1, 0) : t;
    if (first == null || t.isBefore(first!)) first = t;
    if (last == null || end.isAfter(last!)) last = end;
  }

  CohortSpan? span() => first == null ? null : CohortSpan(first!, last!);

  if (unit == MetricUnit.count) {
    // Un compteur n'est jamais « non mesurable » : un null serait un 0.
    double? value(DateTime t) => published(t) ? byBucket[t]?.valeur : null;
    final series = [
      for (final t in buckets) SeriesPoint(t, value(t) ?? 0, 0),
    ];
    for (final t in buckets) {
      if (value(t) != null) seen(byBucket[t]!.point.t);
    }
    final total = series.fold<double>(0, (a, s) => a + s.visitors);
    return CounterData(series, total.round(),
        cohorts: span(), member: member, unpublished: unpublished);
  }

  var num = 0;
  var den = 0;
  var anyDen = 0;
  // Un jour de mesure pas encore terminé dans la fenêtre (« Aujourd'hui »
  // en J1) : la carte est en attente, pas vide. On ne peut pas s'en remettre
  // aux effectifs : le serveur rend une cohorte non mesurable avec un
  // dénominateur à 0.
  var unfinished = false;
  final ratio = <RatioPoint>[];
  for (final t in buckets) {
    final p = published(t) ? byBucket[t] : null;
    final v = p?.valeur;
    anyDen += p?.point.denominateur ?? 0;
    if (delayDays > 0 && !t.isBefore(today)) unfinished = true;
    // Un bucket non mesurable reste un trou, quelle que soit l'option de trous
    // des taux : c'est une mesure refusée, pas un jour sans événement. Ses
    // effectifs ne comptent pas non plus dans le total.
    if (v != null) {
      num += p!.point.numerateur;
      den += p.point.denominateur;
      seen(p.point.t);
    }
    // Le jour de cohorte n'a de sens à l'infobulle qu'en jours : un bucket de
    // mois en regroupe trente.
    final cohort = v != null && delayDays > 0 && w.unit == TimeUnit.day
        ? p!.point.t
        : null;
    ratio.add(RatioPoint(t, v == null ? null : v / 100, cohort: cohort));
  }
  return RatioData(
    points: ratio,
    overall: den < kMinRatioDenominator ? null : num / den,
    numeratorTotal: num,
    denominatorTotal: den,
    cohorts: span(),
    member: member,
    pending: den == 0 && (anyDen > 0 || unfinished),
    delayDays: delayDays,
    unpublished: unpublished,
  );
}
