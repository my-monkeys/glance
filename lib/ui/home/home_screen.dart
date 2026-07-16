import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../data/models/workspace.dart';
import '../../state/home_data.dart';
import '../../state/period_state.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../state/workspaces.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../settings/workspaces_screen.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';
import '../widgets/day_nav.dart';
import '../widgets/site_avatar.dart';
import '../widgets/field.dart';
import '../widgets/glance_chart.dart';
import '../widgets/pulse_dot.dart';
import '../widgets/sparkline.dart';
import '../widgets/workspace_switcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onGoSettings});
  final VoidCallback onGoSettings;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 29)),
        end: now,
      ),
    );
    if (range != null) {
      ref.read(periodProvider.notifier).setCustom(
            range.start,
            range.end.add(const Duration(hours: 23, minutes: 59)),
          );
    }
  }

  @override
  void initState() {
    super.initState();
    final secs = ref.read(settingsProvider).refreshSeconds;
    _timer = Timer.periodic(Duration(seconds: secs), (_) {
      if (!mounted) return;
      // Rafraîchit en place la SEULE fenêtre courante (les autres périodes
      // restent en cache) → valeurs mises à jour sans squelette. Limité au
      // groupe affiché : inutile de solliciter les sites qu'on ne regarde pas.
      final w = ref.read(periodProvider).window();
      for (final s in ref.read(visibleSitesProvider).value ?? const <Site>[]) {
        ref.invalidate(siteStatsProvider((s, w)));
      }
      ref.invalidate(siteLiveProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final hasAccounts = ref.watch(accountsProvider).isNotEmpty;
    if (!hasAccounts) {
      return _WelcomeEmpty(onAdd: () => openAddSource(context));
    }

    final periodState = ref.watch(periodProvider);
    final window = periodState.window();
    // Périmètre = le groupe actif (tous les sites si aucun n'est sélectionné).
    final sitesAsync = ref.watch(visibleSitesProvider);
    final sites = sitesAsync.value ?? const <Site>[];
    final group = ref.watch(activeWorkspaceProvider);
    final totals = ref.watch(homeTotalsProvider(window));
    final now = DateTime.now();
    final viewMode = ref.watch(settingsProvider.select((s) => s.homeView));
    // Barre de chargement tant que des sites arrivent encore.
    final refreshing = totals.loading && sites.isNotEmpty;

    // Tri par visiteurs uniques (desc) : sites chargés en tête, sites encore
    // en chargement (squelettes) à la suite dans leur ordre d'origine.
    final loaded = [...totals.data.cards]
      ..sort((a, b) => b.summary.visitors.compareTo(a.summary.visitors));
    final loadedSites = loaded.map((c) => c.site).toList();
    final loadedSet = loadedSites.toSet();
    final pendingSites = sites.where((s) => !loadedSet.contains(s)).toList();
    final orderedSites = [...loadedSites, ...pendingSites];

    return Stack(
      children: [
        RefreshIndicator(
          color: p.accent,
          backgroundColor: p.surface,
          onRefresh: () async {
            // Ne réactualise que la fenêtre courante (cache des autres périodes
            // préservé) ; les valeurs se mettent à jour en place.
            for (final s in sites) {
              ref.invalidate(siteStatsProvider((s, window)));
            }
            ref.invalidate(siteLiveProvider);
            await ref.read(sitesProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              0,
              MediaQuery.of(context).padding.top + 14,
              0,
              120,
            ),
            children: [
              _Header(
                period: periodState.period,
                now: now,
                viewMode: viewMode,
                onPeriod: (per) => per == Period.custom
                    ? _pickCustom()
                    : ref.read(periodProvider.notifier).set(per),
                onViewMode: (v) =>
                    ref.read(settingsProvider.notifier).setHomeView(v),
                onNewGroup: () => openWorkspaceEditor(context, null),
              ),
              if (periodState.canNavigateDays) ...[
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: DayNav(),
                ),
              ],
              const SizedBox(height: 18),

              if (sitesAsync.hasError && sites.isEmpty)
                _ErrorBox(
                  message: 'Chargement impossible.',
                  onRetry: () => ref.invalidate(sitesProvider),
                )
              else if (sites.isEmpty && sitesAsync.isLoading)
                const _HomeSkeleton()
              else if (sites.isEmpty)
                group != null
                    ? _EmptyGroupBox(group: group)
                    : _EmptyBox(
                        onChoose: widget.onGoSettings,
                        onAdd: () => openAddSource(context),
                      )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: totals.hasAny
                      ? _TotalCard(data: totals.data, unit: window.unit.api)
                      : const _TotalCardSkeleton(),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: viewMode == HomeViewMode.grid
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.12,
                          ),
                          itemCount: orderedSites.length,
                          itemBuilder: (context, i) => _SiteStatSlot(
                            key: ValueKey(orderedSites[i]),
                            site: orderedSites[i],
                            window: window,
                            grid: true,
                          ),
                        )
                      : Column(
                          children: [
                            for (final s in orderedSites) ...[
                              _SiteStatSlot(
                                key: ValueKey(s),
                                site: s,
                                window: window,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: RefreshBar(visible: refreshing),
        ),
      ],
    );
  }
}

/// En-tête : date + titre, boutons, périodes, bascule liste/grille.
/// Le titre porte le nom du groupe actif : c'est lui qui annonce le périmètre
/// sur lequel portent le total et la courbe juste en dessous. La pastille de
/// droite le montre et sert de sélecteur — pas de rangée de chips en plus.
class _Header extends ConsumerWidget {
  const _Header({
    required this.period,
    required this.now,
    required this.viewMode,
    required this.onPeriod,
    required this.onViewMode,
    required this.onNewGroup,
  });

  final Period period;
  final DateTime now;
  final HomeViewMode viewMode;
  final ValueChanged<Period> onPeriod;
  final ValueChanged<HomeViewMode> onViewMode;
  final VoidCallback onNewGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final active = ref.watch(activeWorkspaceProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('EEE d MMM', 'fr_FR').format(now)} · ${period.label}'
                          .toUpperCase(),
                      style: GT.label(color: p.fg2),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      active?.name ?? 'Mes sites',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GT.display(34, color: p.fg),
                    ),
                  ],
                ),
              ),
              GlanceIconButton(icon: Icons.add, onTap: onNewGroup),
              const SizedBox(width: 8),
              const WorkspaceSwitcher(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ChipRow(
                  children: [
                    for (final per in Period.values)
                      GlanceChip(
                        label: per.label,
                        selected: period == per,
                        onTap: () => onPeriod(per),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ViewToggle(mode: viewMode, onChanged: onViewMode),
            ],
          ),
        ),
      ],
    );
  }
}

/// Emplacement d'un site : charge ses stats + son live indépendamment, montre
/// un squelette tant que les stats ne sont pas arrivées.
class _SiteStatSlot extends ConsumerWidget {
  const _SiteStatSlot({
    super.key,
    required this.site,
    required this.window,
    this.grid = false,
  });

  final Site site;
  final DateWindow window;
  final bool grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(siteStatsProvider((site, window)));
    final live = ref.watch(siteLiveProvider(site));
    final sv = stats.value;

    if (sv == null) {
      // Pas encore de stats : squelette (ou état d'erreur discret).
      if (stats.hasError) {
        return _SiteErrorCard(site: site, grid: grid);
      }
      return grid ? const _GridSkeleton() : const _TileSkeleton();
    }

    final card = SiteCard(
      site: site,
      summary: sv.summary,
      series: sv.series,
      live: live.value ?? 0,
    );
    return grid ? _SiteGridCard(card: card) : _SiteCardTile(card: card);
  }
}

class _TotalCard extends ConsumerWidget {
  const _TotalCard({required this.data, required this.unit});
  final HomeData data;
  final String unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final hidden = ref.watch(settingsProvider.select((s) => s.hiddenSeries));
    return GlanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(
                      'Visiteurs · ${ref.watch(activeWorkspaceProvider)?.name ?? 'tous les sites'}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fmtInt(data.totalVisitors),
                      style: GT.stat(50, color: p.fg),
                    ),
                  ],
                ),
              ),
              LivePill(count: data.totalLive),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              DeltaText(data.totalDeltaPct),
              const SizedBox(width: 8),
              Text('vs période préc.', style: GT.body(12, color: p.fg2)),
            ],
          ),
          const SizedBox(height: 14),
          GlanceChart(
            series: data.totalSeries,
            unit: unit,
            height: 156,
            showPageviews: true,
            visitorsTotal: data.totalVisitors,
            pageviewsTotal: data.totalPageviews,
            hidden: hidden,
            onToggle: (k) => ref.read(settingsProvider.notifier).toggleSeries(k),
          ),
        ],
      ),
    );
  }
}

class _SiteCardTile extends StatelessWidget {
  const _SiteCardTile({required this.card});
  final SiteCard card;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      onTap: () => openSite(context, card.site),
      child: Row(
        children: [
          SiteAvatar(card.site),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.site.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GT.body(15, weight: 500, color: p.fg),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    PulseDot(
                      size: 8,
                      pulse: card.live > 0,
                      color: card.live > 0 ? p.accent : p.fg3,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${card.live} live',
                      style: GT.mono(11, color: card.live > 0 ? p.accent : p.fg3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Sparkline(
            values: _sparkValues(card),
            color: p.accent,
            width: 58,
            height: 26,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtInt(card.summary.visitors),
                style: GT.stat(24, color: p.fg),
              ),
              const SizedBox(height: 3),
              DeltaText(card.deltaPct, fontSize: 11),
            ],
          ),
        ],
      ),
    );
  }

  List<double> _sparkValues(SiteCard c) => _sparkOf(c);
}

List<double> _sparkOf(SiteCard c) {
  final v = c.series.map((e) => e.visitors).toList();
  if (v.length < 2) return const [0, 0];
  return v;
}

/// Bascule liste / grille (segmenté à deux icônes).
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.mode, required this.onChanged});
  final HomeViewMode mode;
  final ValueChanged<HomeViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    Widget seg(HomeViewMode m, IconData icon) {
      final on = mode == m;
      return GestureDetector(
        onTap: () => onChanged(m),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? p.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: on ? p.accentInk : p.fg2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(HomeViewMode.list, Icons.view_agenda_outlined),
          seg(HomeViewMode.grid, Icons.grid_view_rounded),
        ],
      ),
    );
  }
}

/// Grille 2 colonnes de cartes de sites.
class _SiteGridCard extends StatelessWidget {
  const _SiteGridCard({required this.card});
  final SiteCard card;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final live = card.live;
    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
      onTap: () => openSite(context, card.site),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.site.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GT.body(14, weight: 500, color: p.fg),
          ),
          const SizedBox(height: 6),
          // Nombre de visiteurs à gauche, « en direct » aligné à droite.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  fmtInt(card.summary.visitors),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GT.stat(30, color: p.fg),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulseDot(
                    size: 7,
                    pulse: live > 0,
                    color: live > 0 ? p.accent : p.fg3,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$live',
                    style: GT.mono(
                      13,
                      weight: 600,
                      color: live > 0 ? p.accent : p.fg3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 3),
          DeltaText(card.deltaPct, fontSize: 11),
          const Spacer(),
          LayoutBuilder(
            builder: (ctx, cons) => Sparkline(
              values: _sparkOf(card),
              color: p.accent,
              width: cons.maxWidth,
              height: 32,
              fill: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: p.fg3, size: 34),
          const SizedBox(height: 12),
          Text(message, style: GT.body(15, color: p.fg2)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Réessayer',
              style: GT.body(15, weight: 600, color: p.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vide quand une source existe mais ne suit aucun site (tout masqué, ou
/// fournisseur sans site) : le bon remède est d'aller choisir les sites, pas
/// d'ajouter une 2ᵉ source — cette dernière reste offerte en action secondaire.
class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.onChoose, required this.onAdd});
  final VoidCallback onChoose;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Column(
        children: [
          Text('Aucun site affiché', style: GT.display(22, color: p.fg)),
          const SizedBox(height: 8),
          Text(
            'Aucun site suivi pour le moment. Choisis ceux à afficher.',
            textAlign: TextAlign.center,
            style: GT.body(14, color: p.fg2),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onChoose,
            child: Text(
              'Choisir les sites',
              style: GT.body(15, weight: 600, color: p.accent),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              '+ Ajouter une source',
              style: GT.body(13.5, color: p.fg3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vide propre à un groupe : des sites sont suivis, mais aucun n'est dans ce
/// groupe. Le remède est de le remplir — pas de toucher aux comptes — d'où un
/// état distinct de [_EmptyBox].
class _EmptyGroupBox extends ConsumerWidget {
  const _EmptyGroupBox({required this.group});
  final Workspace group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Column(
        children: [
          Text('Groupe vide', style: GT.display(22, color: p.fg)),
          const SizedBox(height: 8),
          Text(
            '« ${group.name} » ne contient aucun site.',
            textAlign: TextAlign.center,
            style: GT.body(14, color: p.fg2),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => openWorkspaceEditor(context, group),
            child: Text(
              'Choisir ses sites',
              style: GT.body(15, weight: 600, color: p.accent),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => ref.read(activeWorkspaceIdProvider.notifier).set(null),
            child: Text(
              'Voir tous les sites',
              style: GT.body(13.5, color: p.fg3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accueil premier lancement : branding Glance + CTA d'ajout de source.
class _WelcomeEmpty extends StatelessWidget {
  const _WelcomeEmpty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(26, 40, 26, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 20),
            Text('Glance', style: GT.display(44, color: p.fg)),
            const SizedBox(height: 8),
            Text(
              "Vos statistiques, en un clin d'œil.",
              textAlign: TextAlign.center,
              style: GT.body(15, color: p.fg2),
            ),
            const SizedBox(height: 40),
            GlanceCard(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(
                children: [
                  Text(
                    'Connectez votre premier outil',
                    style: GT.body(16, weight: 600, color: p.fg),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Umami, Plausible… ajoutez une source puis choisissez les sites à suivre.',
                    textAlign: TextAlign.center,
                    style: GT.body(13, color: p.fg2, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  GlanceButton(
                    label: 'Ajouter une source',
                    icon: Icons.add,
                    onTap: onAdd,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Clé en lecture seule · vos données restent chez vous',
              textAlign: TextAlign.center,
              style: GT.body(12, color: p.fg3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit rectangle « placeholder » grisé (squelettes de chargement).
class _Skel extends StatelessWidget {
  const _Skel({required this.w, required this.h, this.radius = 6});
  final double w;
  final double h;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: context.glance.chip,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _TotalCardSkeleton extends StatelessWidget {
  const _TotalCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Skel(w: 160, h: 11),
          const SizedBox(height: 14),
          _Skel(w: 130, h: 44, radius: 10),
          const SizedBox(height: 18),
          _Skel(w: double.infinity, h: 150, radius: 12),
        ],
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Skel(w: 90, h: 11),
          const SizedBox(height: 14),
          _Skel(w: 70, h: 26, radius: 8),
          const SizedBox(height: 8),
          _Skel(w: 46, h: 10),
          const Spacer(),
          const _Skel(w: double.infinity, h: 28, radius: 8),
        ],
      ),
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 16),
      child: Row(
        children: [
          _Skel(w: 38, h: 38, radius: 10),
          const SizedBox(width: 13),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Skel(w: 120, h: 12),
              const SizedBox(height: 8),
              _Skel(w: 50, h: 10),
            ],
          ),
          const Spacer(),
          _Skel(w: 54, h: 22, radius: 8),
        ],
      ),
    );
  }
}

/// Carte discrète en cas d'échec de chargement d'un site (le reste continue).
class _SiteErrorCard extends StatelessWidget {
  const _SiteErrorCard({required this.site, required this.grid});
  final Site site;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            site.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GT.body(14, weight: 500, color: p.fg),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.cloud_off_rounded, size: 15, color: p.fg3),
              const SizedBox(width: 6),
              Text('Indisponible', style: GT.body(13, color: p.fg3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: p.line),
            ),
            child: Center(
              child: CircularProgressIndicator(color: p.accent, strokeWidth: 2.4),
            ),
          ),
        ],
      ),
    );
  }
}
