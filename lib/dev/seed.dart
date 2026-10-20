import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/account.dart';
import '../data/models/indicator.dart';
import '../data/models/models.dart';
import '../data/repository/accounts_repository.dart';
import '../state/indicators.dart';
import '../state/providers.dart';

/// Amorçage de développement : si des identifiants sont passés en
/// `--dart-define` et qu'aucun compte n'existe, crée un compte Umami. Purement
/// pour itérer sur simulateur — inerte en l'absence des defines.
const _seedUrl = String.fromEnvironment('SEED_UMAMI_URL');
const _seedUser = String.fromEnvironment('SEED_UMAMI_USER');
const _seedPass = String.fromEnvironment('SEED_UMAMI_PASS');
const _seedSites = String.fromEnvironment('SEED_UMAMI_SITES'); // ids séparés par des virgules

/// Indicateurs d'amorçage : le site visé et le jeu prédéfini (`geography`).
/// Sert à voir l'onglet Tableaux avant que l'éditeur existe.
const _seedIndicatorsSite = String.fromEnvironment('SEED_INDICATORS_SITE');
const _seedIndicators = String.fromEnvironment('SEED_INDICATORS');

Future<void> maybeSeed(ProviderContainer container) async {
  await _seedAccount(container);
  await _seedIndicatorSet(container);
}

Future<void> _seedAccount(ProviderContainer container) async {
  if (_seedUrl.isEmpty || _seedUser.isEmpty || _seedPass.isEmpty) return;
  final repo = container.read(accountsRepoProvider);
  if (repo.loadAccounts().isNotEmpty) return;

  final sites = _seedSites.isEmpty
      ? null
      : _seedSites.split(',').map((s) => s.trim()).toList();
  final account = Account(
    id: AccountsRepository.newId(),
    kind: ProviderKind.umami,
    baseUrl: _seedUrl,
    label: null,
    sites: sites,
  );
  await container
      .read(accountsProvider.notifier)
      .add(account, {'username': _seedUser, 'password': _seedPass});
}

/// Le compte porte les indicateurs, pas le site : on prend le compte seedé, ou
/// à défaut le premier. Sans effet si le site a déjà des indicateurs — un
/// redémarrage ne les duplique pas.
Future<void> _seedIndicatorSet(ProviderContainer container) async {
  if (_seedIndicatorsSite.isEmpty || _seedIndicators != 'geography') return;
  final accounts = container.read(accountsProvider);
  if (accounts.isEmpty) return;
  final site = Site(
    id: _seedIndicatorsSite,
    accountId: accounts.first.id,
    name: _seedIndicatorsSite,
    domain: '',
  );
  final notifier = container.read(indicatorsProvider.notifier);
  if (notifier.forSite(site).isNotEmpty) return;
  for (final i in _geographyIndicators()) {
    await notifier.add(site, i);
  }
}

List<Indicator> _geographyIndicators() {
  // Un seul horodatage : les quatre ids se distinguent par leur suffixe.
  final base = IndicatorsNotifier.newId();
  const demarree = EventQuery('partie_demarree');
  EventFilter eq(String property, String value, [PropertyType? type]) =>
      EventFilter(
        property: property,
        type: type ?? PropertyType.string,
        op: FilterOp.eq,
        value: value,
      );
  EventQuery jalon(int part) => EventQuery(
      'partie_jalon', [eq('part', '$part', PropertyType.number)]);

  return [
    CounterIndicator(
      id: '$base-c',
      name: 'Parties démarrées',
      query: demarree,
    ),
    RatioIndicator(
      id: '$base-r',
      name: "Taux d'achèvement",
      numerator: EventQuery('partie_terminee', [eq('issue', 'complet')]),
      denominator: demarree,
    ),
    FunnelIndicator(
      id: '$base-f',
      name: "Parcours d'une partie",
      steps: [
        const EventQuery('jeu_choisi'),
        demarree,
        jalon(25),
        jalon(50),
        jalon(75),
        EventQuery('partie_terminee', [eq('issue', 'complet')]),
      ],
    ),
    BreakdownIndicator(
      id: '$base-b',
      name: 'Parties par jeu',
      event: 'partie_demarree',
      property: 'jeu',
    ),
  ];
}
