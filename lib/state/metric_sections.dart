import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/dimension.dart';
import 'providers.dart';

/// Sous-dimension affichée par chaque section de données (Chemins ou Titre dans
/// « Pages », Référents ou Canaux dans « Sources »…).
///
/// Persistée : on retrouve le découpage qu'on regarde d'habitude en rouvrant un
/// site, plutôt que de le resélectionner à chaque fois. Partagée par tous les
/// sites — c'est une habitude de lecture, pas une propriété d'un site.
class MetricSectionsNotifier extends Notifier<Map<MetricSection, MetricType>> {
  static String _key(MetricSection s) => 'glance.section.${s.name}';

  @override
  Map<MetricSection, MetricType> build() {
    final prefs = ref.read(sharedPrefsProvider);
    return {
      for (final section in MetricSection.values)
        section: _restore(section, prefs.getString(_key(section))),
    };
  }

  /// Une dimension enregistrée qui n'appartient plus à sa section (liste
  /// remaniée) retombe sur celle par défaut plutôt que de rendre la carte muette.
  static MetricType _restore(MetricSection section, String? key) {
    final saved = MetricSection.dimensionFromKey(key);
    if (saved != null && section.dimensions.contains(saved)) return saved;
    return section.defaultDimension;
  }

  void select(MetricSection section, MetricType type) {
    if (!section.dimensions.contains(type)) return;
    ref.read(sharedPrefsProvider).setString(_key(section), type.key);
    state = {...state, section: type};
  }
}

final metricSectionsProvider =
    NotifierProvider<MetricSectionsNotifier, Map<MetricSection, MetricType>>(
  MetricSectionsNotifier.new,
);
