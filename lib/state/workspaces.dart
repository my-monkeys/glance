import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/models.dart';
import '../data/models/workspace.dart';
import 'providers.dart';

/// Groupes de sites (persistés en clair : ce ne sont que des libellés et des
/// références, rien de sensible).
class WorkspacesNotifier extends Notifier<List<Workspace>> {
  static const _key = 'glance.workspaces';

  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  List<Workspace> build() => Workspace.decodeList(_p.getString(_key));

  Future<void> _save(List<Workspace> next) async {
    await _p.setString(_key, Workspace.encodeList(next));
    state = next;
  }

  Future<Workspace> create(
    String name,
    List<SiteRef> sites, {
    WorkspaceIcon icon = WorkspaceIcon.dossier,
    WorkspaceColor color = WorkspaceColor.forest,
  }) async {
    final w = Workspace(
      id: _newId(),
      name: name.trim(),
      sites: sites,
      icon: icon,
      color: color,
    );
    await _save([...state, w]);
    return w;
  }

  Future<void> update(Workspace w) =>
      _save([for (final e in state) if (e.id == w.id) w else e]);

  /// Supprime le groupe. Si c'était le groupe actif, [activeWorkspaceProvider]
  /// retombe seul sur « Tous » (il ne résout plus l'id) — rien à faire ici.
  Future<void> remove(String id) =>
      _save(state.where((w) => w.id != id).toList());

  static String _newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

final workspacesProvider =
    NotifierProvider<WorkspacesNotifier, List<Workspace>>(
  WorkspacesNotifier.new,
);

/// Id du groupe actif (`null` = tous les sites). Persisté : on retrouve son
/// périmètre au lancement.
class ActiveWorkspaceNotifier extends Notifier<String?> {
  static const _key = 'glance.workspace.active';

  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  String? build() => _p.getString(_key);

  void set(String? id) {
    if (id == null) {
      _p.remove(_key);
    } else {
      _p.setString(_key, id);
    }
    state = id;
  }
}

final activeWorkspaceIdProvider =
    NotifierProvider<ActiveWorkspaceNotifier, String?>(
  ActiveWorkspaceNotifier.new,
);

/// Groupe actif résolu, `null` = tous les sites. Un id qui ne correspond à
/// aucun groupe (supprimé entre-temps) vaut « Tous » → l'état se répare seul.
final activeWorkspaceProvider = Provider<Workspace?>((ref) {
  final id = ref.watch(activeWorkspaceIdProvider);
  if (id == null) return null;
  for (final w in ref.watch(workspacesProvider)) {
    if (w.id == id) return w;
  }
  return null;
});

/// Les sites du périmètre courant : ceux du groupe actif, ou tous les sites
/// suivis si aucun groupe n'est sélectionné. C'est cette liste — et pas
/// [sitesProvider] — que lisent l'accueil, le direct et la liste desktop.
///
/// Le filtrage est pur : les stats restent chargées par site et gardées en
/// cache, donc changer de groupe n'entraîne aucun appel réseau — les sites déjà
/// vus s'affichent immédiatement.
final visibleSitesProvider = Provider<AsyncValue<List<Site>>>((ref) {
  final all = ref.watch(sitesProvider);
  final group = ref.watch(activeWorkspaceProvider);
  if (group == null) return all;
  return all.whenData((sites) => sites.where(group.contains).toList());
});
