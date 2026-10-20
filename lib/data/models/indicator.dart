import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'workspace.dart';

/// Type d'une propriété d'événement. Le code est celui de `dataType` côté Umami
/// (1 texte, 2 nombre, 3 booléen) : il sert aussi de préfixe aux filtres `epf`.
enum PropertyType {
  string(1),
  number(2),
  boolean(3);

  const PropertyType(this.code);
  final int code;

  static PropertyType fromCode(int? c) => PropertyType.values.firstWhere(
        (t) => t.code == c,
        orElse: () => PropertyType.string,
      );
}

/// Opérateur d'un filtre de propriété. [api] est la forme attendue par Umami.
enum FilterOp {
  eq('eq', '='),
  neq('neq', '≠'),
  contains('c', 'contient'),
  notContains('dnc', 'ne contient pas'),
  gt('gt', '>'),
  gte('gte', '≥'),
  lt('lt', '<'),
  lte('lte', '≤');

  const FilterOp(this.api, this.label);
  final String api;
  final String label;

  /// Opérateurs qui ont un sens pour un type de propriété.
  static List<FilterOp> forType(PropertyType t) => switch (t) {
        PropertyType.string => const [eq, neq, contains, notContains],
        PropertyType.number => const [eq, neq, gt, gte, lt, lte],
        PropertyType.boolean => const [eq],
      };

  static FilterOp fromApi(String? a) =>
      FilterOp.values.firstWhere((o) => o.api == a, orElse: () => FilterOp.eq);
}

/// Condition sur une propriété d'événement (`reussite ≥ 80`).
@immutable
class EventFilter {
  const EventFilter({
    required this.property,
    required this.type,
    required this.op,
    required this.value,
  });

  final String property;
  final PropertyType type;
  final FilterOp op;
  final String value;

  Map<String, dynamic> toJson() => {
        'p': property,
        't': type.code,
        'o': op.api,
        'v': value,
      };

  factory EventFilter.fromJson(Map<String, dynamic> j) => EventFilter(
        property: j['p'] as String,
        type: PropertyType.fromCode(j['t'] as int?),
        op: FilterOp.fromApi(j['o'] as String?),
        value: j['v'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is EventFilter &&
      other.property == property &&
      other.type == type &&
      other.op == op &&
      other.value == value;

  @override
  int get hashCode => Object.hash(property, type, op, value);
}

/// Un événement, éventuellement restreint par des filtres (combinés en ET).
@immutable
class EventQuery {
  const EventQuery(this.event, [this.filters = const []]);

  final String event;
  final List<EventFilter> filters;

  EventQuery copyWith({String? event, List<EventFilter>? filters}) =>
      EventQuery(event ?? this.event, filters ?? this.filters);

  Map<String, dynamic> toJson() => {
        'event': event,
        'filters': filters.map((f) => f.toJson()).toList(),
      };

  factory EventQuery.fromJson(Map<String, dynamic> j) => EventQuery(
        j['event'] as String,
        ((j['filters'] as List?) ?? const [])
            .map((e) => EventFilter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      other is EventQuery &&
      other.event == event &&
      listEquals(other.filters, filters);

  @override
  int get hashCode => Object.hash(event, Object.hashAll(filters));
}

enum IndicatorKind { counter, ratio, funnel, breakdown }

/// Un indicateur personnalisé d'un site. L'égalité porte sur TOUS les champs
/// (id compris) : un indicateur sert de clé de `family` Riverpod, donc le
/// modifier doit changer la clé — sinon l'ancien résultat resterait servi.
@immutable
sealed class Indicator {
  const Indicator({required this.id, required this.name});

  final String id;
  final String name;

  IndicatorKind get kind;

  Map<String, dynamic> toJson();

  Map<String, dynamic> _base(Map<String, dynamic> body) =>
      {'id': id, 'name': name, 'kind': kind.name, ...body};

  /// Null pour un `kind` inconnu : l'indicateur d'une version plus récente de
  /// l'app (ex. importé par synchro) ne doit pas faire planter une plus
  /// ancienne — on l'ignore.
  static Indicator? fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    final name = j['name'] as String;
    switch (j['kind']) {
      case 'counter':
        return CounterIndicator(
          id: id,
          name: name,
          query: EventQuery.fromJson(j['query'] as Map<String, dynamic>),
        );
      case 'ratio':
        return RatioIndicator(
          id: id,
          name: name,
          numerator: EventQuery.fromJson(j['num'] as Map<String, dynamic>),
          denominator: EventQuery.fromJson(j['den'] as Map<String, dynamic>),
          gapsWhenEmpty: (j['gaps'] as bool?) ?? false,
        );
      case 'funnel':
        return FunnelIndicator(
          id: id,
          name: name,
          steps: (j['steps'] as List)
              .map((e) => EventQuery.fromJson(e as Map<String, dynamic>))
              .toList(),
          windowMinutes: (j['window'] as int?) ?? 60,
        );
      case 'breakdown':
        return BreakdownIndicator(
          id: id,
          name: name,
          event: j['event'] as String,
          property: j['property'] as String,
        );
    }
    return null;
  }
}

/// Nombre d'occurrences d'un événement par bucket.
class CounterIndicator extends Indicator {
  const CounterIndicator({
    required super.id,
    required super.name,
    required this.query,
  });

  final EventQuery query;

  @override
  IndicatorKind get kind => IndicatorKind.counter;

  CounterIndicator copyWith({String? name, EventQuery? query}) =>
      CounterIndicator(id: id, name: name ?? this.name, query: query ?? this.query);

  @override
  Map<String, dynamic> toJson() => _base({'query': query.toJson()});

  @override
  bool operator ==(Object other) =>
      other is CounterIndicator &&
      other.id == id &&
      other.name == name &&
      other.query == query;

  @override
  int get hashCode => Object.hash(kind, id, name, query);
}

/// Rapport entre deux événements (taux de complétion…).
class RatioIndicator extends Indicator {
  const RatioIndicator({
    required super.id,
    required super.name,
    required this.numerator,
    required this.denominator,
    this.gapsWhenEmpty = false,
  });

  final EventQuery numerator;
  final EventQuery denominator;

  /// Un bucket sans dénominateur : trou dans la courbe si vrai, 0 % sinon.
  final bool gapsWhenEmpty;

  @override
  IndicatorKind get kind => IndicatorKind.ratio;

  RatioIndicator copyWith({
    String? name,
    EventQuery? numerator,
    EventQuery? denominator,
    bool? gapsWhenEmpty,
  }) =>
      RatioIndicator(
        id: id,
        name: name ?? this.name,
        numerator: numerator ?? this.numerator,
        denominator: denominator ?? this.denominator,
        gapsWhenEmpty: gapsWhenEmpty ?? this.gapsWhenEmpty,
      );

  @override
  Map<String, dynamic> toJson() => _base({
        'num': numerator.toJson(),
        'den': denominator.toJson(),
        if (gapsWhenEmpty) 'gaps': true,
      });

  @override
  bool operator ==(Object other) =>
      other is RatioIndicator &&
      other.id == id &&
      other.name == name &&
      other.numerator == numerator &&
      other.denominator == denominator &&
      other.gapsWhenEmpty == gapsWhenEmpty;

  @override
  int get hashCode =>
      Object.hash(kind, id, name, numerator, denominator, gapsWhenEmpty);
}

/// Entonnoir : parcours ordonné d'événements. [windowMinutes] = délai laissé à un
/// visiteur entre une étape et la suivante. ⚠️ En minutes, pas en jours : la
/// doc d'Umami dit « jours », son SQL fait `interval <window> minute`. 60 = le
/// défaut de son propre formulaire.
class FunnelIndicator extends Indicator {
  // Pas const : `steps.length` n'est pas évaluable à la compilation.
  // ignore: prefer_const_constructors_in_immutables
  FunnelIndicator({
    required super.id,
    required super.name,
    required this.steps,
    this.windowMinutes = 60,
  }) : assert(steps.length >= 2 && steps.length <= 8,
            'Un entonnoir compte de 2 à 8 étapes');

  final List<EventQuery> steps;
  final int windowMinutes;

  @override
  IndicatorKind get kind => IndicatorKind.funnel;

  FunnelIndicator copyWith({
    String? name,
    List<EventQuery>? steps,
    int? windowMinutes,
  }) =>
      FunnelIndicator(
        id: id,
        name: name ?? this.name,
        steps: steps ?? this.steps,
        windowMinutes: windowMinutes ?? this.windowMinutes,
      );

  @override
  Map<String, dynamic> toJson() => _base({
        'steps': steps.map((s) => s.toJson()).toList(),
        'window': windowMinutes,
      });

  @override
  bool operator ==(Object other) =>
      other is FunnelIndicator &&
      other.id == id &&
      other.name == name &&
      listEquals(other.steps, steps) &&
      other.windowMinutes == windowMinutes;

  @override
  int get hashCode =>
      Object.hash(kind, id, name, Object.hashAll(steps), windowMinutes);
}

/// Répartition des valeurs d'une propriété d'événement.
class BreakdownIndicator extends Indicator {
  const BreakdownIndicator({
    required super.id,
    required super.name,
    required this.event,
    required this.property,
  });

  final String event;
  final String property;

  @override
  IndicatorKind get kind => IndicatorKind.breakdown;

  BreakdownIndicator copyWith({String? name, String? event, String? property}) =>
      BreakdownIndicator(
        id: id,
        name: name ?? this.name,
        event: event ?? this.event,
        property: property ?? this.property,
      );

  @override
  Map<String, dynamic> toJson() => _base({'event': event, 'property': property});

  @override
  bool operator ==(Object other) =>
      other is BreakdownIndicator &&
      other.id == id &&
      other.name == name &&
      other.event == event &&
      other.property == property;

  @override
  int get hashCode => Object.hash(kind, id, name, event, property);
}

/// Les indicateurs d'un site, dans l'ordre choisi par l'utilisateur.
@immutable
class SiteIndicators {
  const SiteIndicators(this.site, this.indicators);

  final SiteRef site;
  final List<Indicator> indicators;

  Map<String, dynamic> toJson() => {
        'site': site.toJson(),
        'indicators': indicators.map((i) => i.toJson()).toList(),
      };

  /// Les indicateurs de `kind` inconnu sont écartés (cf. [Indicator.fromJson]).
  factory SiteIndicators.fromJson(Map<String, dynamic> j) => SiteIndicators(
        SiteRef.fromJson(j['site'] as Map<String, dynamic>),
        ((j['indicators'] as List?) ?? const [])
            .map((e) => Indicator.fromJson(e as Map<String, dynamic>))
            .whereType<Indicator>()
            .toList(),
      );

  static String encodeList(List<SiteIndicators> l) =>
      jsonEncode(l.map((s) => s.toJson()).toList());

  static List<SiteIndicators> decodeList(String? s) {
    if (s == null || s.isEmpty) return const [];
    return (jsonDecode(s) as List<dynamic>)
        .map((e) => SiteIndicators.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
