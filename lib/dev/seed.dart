import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/account.dart';
import '../data/repository/accounts_repository.dart';
import '../state/providers.dart';

/// Amorçage de développement : si des identifiants sont passés en
/// `--dart-define` et qu'aucun compte n'existe, crée un compte Umami. Purement
/// pour itérer sur simulateur — inerte en l'absence des defines.
const _seedUrl = String.fromEnvironment('SEED_UMAMI_URL');
const _seedUser = String.fromEnvironment('SEED_UMAMI_USER');
const _seedPass = String.fromEnvironment('SEED_UMAMI_PASS');
const _seedSites = String.fromEnvironment('SEED_UMAMI_SITES'); // ids séparés par des virgules

Future<void> maybeSeed(ProviderContainer container) async {
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
