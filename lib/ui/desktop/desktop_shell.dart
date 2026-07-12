import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../state/desktop_nav.dart';
import '../../state/home_data.dart';
import '../../state/period_state.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../detail/detail_screen.dart';
import '../root_scaffold.dart';
import '../settings/settings_screen.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';
import '../widgets/glance_chart.dart';
import '../widgets/pulse_dot.dart';
import '../widgets/site_avatar.dart';
import '../widgets/sparkline.dart';

/// Largeur minimale pour basculer en shell desktop master-détail.
const double kDesktopBreakpoint = 860;

const double _sidebarWidth = 320;
const double _centerMaxWidth = 900;

/// Fournit aux écrans embarqués (Direct, détail…) un moyen d'ouvrir un site
/// *dans le panneau central* au lieu de pousser une page. `openSite` le consulte.
class DesktopShellScope extends InheritedWidget {
  const DesktopShellScope({
    required this.onOpenSite,
    required super.child,
    super.key,
  });

  final void Function(Site site) onOpenSite;

  static DesktopShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesktopShellScope>();

  @override
  bool updateShouldNotify(DesktopShellScope oldWidget) => false;
}

/// Shell desktop : liste des sites à gauche, contenu (vue d'ensemble ou détail
/// d'un site, direct, réglages) à droite.
class DesktopShell extends ConsumerWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final hasAccounts = ref.watch(accountsProvider).isNotEmpty;

    final Widget content = hasAccounts
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: _sidebarWidth, child: _Sidebar()),
              Container(width: 1, color: p.line),
              const Expanded(child: _Center()),
            ],
          )
        : const _DesktopEmpty();

    return DesktopShellScope(
      onOpenSite: (s) => ref.read(desktopNavProvider.notifier).openSite(s),
      child: Scaffold(body: SafeArea(child: content)),
    );
  }
}

// ---------------------------------------------------------------------------
// Panneau gauche : navigation + liste des sites.
// ---------------------------------------------------------------------------

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final nav = ref.watch(desktopNavProvider);
    final window = ref.watch(periodProvider).window();
    final totals = ref.watch(homeTotalsProvider(window));
    final sitesAsync = ref.watch(sitesProvider);
    final sites = sitesAsync.value ?? const <Site>[];

    // Sites chargés triés par visiteurs, puis ceux encore en chargement.
    final loaded = [...totals.data.cards]
      ..sort((a, b) => b.summary.visitors.compareTo(a.summary.visitors));
    final loadedSites = loaded.map((c) => c.site).toSet();
    final pending = sites.where((s) => !loadedSites.contains(s)).toList();

    return Container(
      color: p.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text('Mes sites', style: GT.display(24, color: p.fg)),
                ),
                GlanceIconButton(
                  icon: Icons.add,
                  onTap: () => openAddSource(context),
                ),
              ],
            ),
          ),
          // Liste défilante : « Vue d'ensemble » + sites.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              children: [
                _OverviewTile(
                  selected: nav.view == DesktopView.overview,
                  visitors: totals.data.totalVisitors,
                  live: totals.data.totalLive,
                  loading: totals.loading && totals.data.cards.isEmpty,
                  onTap: () => ref.read(desktopNavProvider.notifier).overview(),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                  child: SectionLabel('Sites (${sites.length})'),
                ),
                for (final c in loaded)
                  _SiteTile(
                    key: ValueKey(c.site),
                    card: c,
                    selected: nav.isSite(c.site),
                    onTap: () =>
                        ref.read(desktopNavProvider.notifier).openSite(c.site),
                  ),
                for (final s in pending) _SiteTileSkeleton(key: ValueKey(s)),
              ],
            ),
          ),
          // Pied : Réglages. (« Direct » fusionné dans la vue d'ensemble.)
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.line)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _NavTile(
              icon: Icons.tune_rounded,
              label: 'Réglages',
              selected: nav.view == DesktopView.settings,
              onTap: () => ref.read(desktopNavProvider.notifier).settings(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne « Vue d'ensemble » (tous les sites) en tête de la liste.
class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.selected,
    required this.visitors,
    required this.live,
    required this.loading,
    required this.onTap,
  });
  final bool selected;
  final int visitors;
  final int live;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return _TileFrame(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? p.accent : p.chip,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.donut_large_rounded,
                size: 19, color: selected ? p.accentInk : p.fg2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vue d\'ensemble',
                    style: GT.body(14, weight: 600, color: p.fg)),
                Text('Tous les sites', style: GT.body(11.5, color: p.fg3)),
              ],
            ),
          ),
          if (!loading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total de la période (pas le direct).
                Text(fmtInt(visitors), style: GT.stat(17, color: p.fg)),
                // Direct : sous la valeur + label explicite pour ne pas
                // confondre avec le total de la période.
                if (live > 0) ...[
                  const SizedBox(height: 3),
                  _LiveTag(count: live),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// Petit indicateur « N live » (point qui pulse + compte + label), utilisé sous
/// une valeur totale pour bien la distinguer des visiteurs en direct.
class _LiveTag extends StatelessWidget {
  const _LiveTag({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PulseDot(size: 6, color: p.accent),
        const SizedBox(width: 4),
        Text('$count live', style: GT.mono(10, color: p.accent)),
      ],
    );
  }
}

/// Ligne de site dans la liste de gauche.
class _SiteTile extends StatelessWidget {
  const _SiteTile({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });
  final SiteCard card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final spark = card.series.map((e) => e.visitors).toList();
    return _TileFrame(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          SiteAvatar(card.site, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        card.site.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GT.body(14, weight: 600, color: p.fg),
                      ),
                    ),
                    if (card.live > 0) ...[
                      const SizedBox(width: 6),
                      PulseDot(size: 6, color: p.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (spark.length >= 2)
                  Sparkline(
                    values: spark,
                    color: p.accent.withValues(alpha: 0.85),
                    width: 120,
                    height: 16,
                    strokeWidth: 1.6,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtInt(card.summary.visitors), style: GT.stat(17, color: p.fg)),
              DeltaText(card.deltaPct, fontSize: 11),
            ],
          ),
        ],
      ),
    );
  }
}

class _SiteTileSkeleton extends StatelessWidget {
  const _SiteTileSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    Widget box(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: p.chip,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return _TileFrame(
      selected: false,
      onTap: null,
      child: Row(
        children: [
          box(34, 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [box(110, 12), const SizedBox(height: 8), box(70, 10)],
            ),
          ),
          box(34, 18),
        ],
      ),
    );
  }
}

/// Ligne de navigation (Direct / Réglages) du pied de sidebar.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return _TileFrame(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: selected ? p.accent : p.fg2),
          const SizedBox(width: 12),
          Text(label,
              style: GT.body(14,
                  weight: selected ? 600 : 400,
                  color: selected ? p.fg : p.fg2)),
        ],
      ),
    );
  }
}

/// Cadre commun d'une ligne de la sidebar (fond au survol/sélection).
class _TileFrame extends StatelessWidget {
  const _TileFrame({
    required this.child,
    required this.selected,
    required this.onTap,
  });
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? p.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          hoverColor: p.chip.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panneau central : vue d'ensemble | détail d'un site | réglages.
// ---------------------------------------------------------------------------

class _Center extends ConsumerWidget {
  const _Center();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final nav = ref.watch(desktopNavProvider);
    // Site sélectionné retiré (compte supprimé) → retour à l'aperçu. On attend
    // que la liste soit chargée et non vide pour ne pas reset pendant un refresh.
    final sitesAsync = ref.watch(sitesProvider);
    if (nav.view == DesktopView.site &&
        sitesAsync.hasValue &&
        sitesAsync.value!.isNotEmpty &&
        (nav.site == null || !sitesAsync.value!.contains(nav.site))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(desktopNavProvider.notifier).overview();
      });
    }

    final Widget body = switch (nav.view) {
      DesktopView.overview => const _Overview(),
      DesktopView.site when nav.site != null =>
        DetailScreen(key: ValueKey(nav.site), site: nav.site!, embedded: true),
      DesktopView.site => const _Overview(),
      DesktopView.settings => const SettingsScreen(),
    };

    return Container(
      color: p.bg,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _centerMaxWidth),
        child: body,
      ),
    );
  }
}

/// Vue d'ensemble « tous les sites » (défaut du centre) : gros total + graphe.
class _Overview extends ConsumerStatefulWidget {
  const _Overview();
  @override
  ConsumerState<_Overview> createState() => _OverviewState();
}

class _OverviewState extends ConsumerState<_Overview> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final secs = ref.read(settingsProvider).refreshSeconds;
    _timer = Timer.periodic(Duration(seconds: secs), (_) {
      if (!mounted) return;
      ref.invalidate(siteStatsProvider);
      ref.invalidate(siteLiveProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (range != null) {
      ref.read(periodProvider.notifier).setCustom(
            range.start,
            range.end.add(const Duration(hours: 23, minutes: 59)),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final periodState = ref.watch(periodProvider);
    final window = periodState.window();
    final totals = ref.watch(homeTotalsProvider(window));
    final data = totals.data;
    final hidden = ref.watch(settingsProvider.select((s) => s.hiddenSeries));
    final refreshing = totals.loading && data.cards.isNotEmpty;
    final dateLabel = DateFormat('EEE d MMM', 'fr_FR').format(DateTime.now());

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
          children: [
            Text('${dateLabel.toUpperCase()} · ${periodState.period.label}',
                style: GT.mono(11.5, color: p.fg3)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text('Tous les sites', style: GT.display(30, color: p.fg)),
                ),
                LivePill(count: data.totalLive, text: '${data.totalLive} live'),
              ],
            ),
            const SizedBox(height: 16),
            ChipRow(
              children: [
                for (final per in Period.values)
                  GlanceChip(
                    label: per.label,
                    selected: periodState.period == per,
                    onTap: () => per == Period.custom
                        ? _pickCustom()
                        : ref.read(periodProvider.notifier).set(per),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            GlanceCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel('Visiteurs · tous les sites'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmtInt(data.totalVisitors),
                          style: GT.stat(52, color: p.fg)),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            DeltaText(data.totalDeltaPct, fontSize: 13),
                            const SizedBox(width: 6),
                            Text('vs période préc.',
                                style: GT.body(12.5, color: p.fg3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlanceChart(
                    series: data.totalSeries,
                    unit: window.unit.api,
                    height: 220,
                    showPageviews: true,
                    visitorsTotal: data.totalVisitors,
                    pageviewsTotal: data.totalPageviews,
                    hidden: hidden,
                    onToggle: (k) =>
                        ref.read(settingsProvider.notifier).toggleSeries(k),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _OverviewKpi(label: 'Visites', value: fmtInt(data.totalVisits)),
                const SizedBox(width: 12),
                _OverviewKpi(
                    label: 'Pages vues', value: fmtInt(data.totalPageviews)),
                const SizedBox(width: 12),
                _OverviewKpi(
                    label: 'Sites', value: '${totals.siteCount}'),
              ],
            ),
            const SizedBox(height: 24),
            _LiveNow(
              cards: data.cards,
              onOpen: (s) => ref.read(desktopNavProvider.notifier).openSite(s),
            ),
          ],
        ),
        Positioned(top: 0, left: 0, right: 0, child: RefreshBar(visible: refreshing)),
      ],
    );
  }
}

class _OverviewKpi extends StatelessWidget {
  const _OverviewKpi({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Expanded(
      child: GlanceCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(label),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: GT.stat(24, color: p.fg)),
            ),
          ],
        ),
      ),
    );
  }
}

/// « En direct maintenant » : sites ayant des visiteurs live (fusion de l'ancien
/// onglet Direct dans la vue d'ensemble). Chaque ligne ouvre le détail du site.
class _LiveNow extends StatelessWidget {
  const _LiveNow({required this.cards, required this.onOpen});
  final List<SiteCard> cards;
  final void Function(Site site) onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final live = [...cards.where((c) => c.live > 0)]
      ..sort((a, b) => b.live.compareTo(a.live));

    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('En direct maintenant'),
          if (live.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('Personne en ce moment.',
                  style: GT.body(14, color: p.fg3)),
            )
          else
            for (final c in live)
              _LiveRow(card: c, onTap: () => onOpen(c.site)),
        ],
      ),
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.card, required this.onTap});
  final SiteCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: p.chip.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Row(
            children: [
              SiteAvatar(card.site, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(card.site.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GT.body(14, weight: 600, color: p.fg)),
              ),
              PulseDot(size: 7, color: p.accent),
              const SizedBox(width: 8),
              Text(fmtInt(card.live),
                  style: GT.stat(18, color: p.accent)),
            ],
          ),
        ),
      ),
    );
  }
}

/// État vide desktop (aucune source).
class _DesktopEmpty extends StatelessWidget {
  const _DesktopEmpty();
  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: p.accentSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.donut_large_rounded, color: p.accent, size: 30),
            ),
            const SizedBox(height: 20),
            Text('Glance', style: GT.display(30, color: p.fg)),
            const SizedBox(height: 8),
            Text(
              'Vos statistiques, en un clin d\'œil.',
              textAlign: TextAlign.center,
              style: GT.body(15, color: p.fg2),
            ),
            const SizedBox(height: 24),
            Builder(
              builder: (context) => FilledButton.icon(
                onPressed: () => openAddSource(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter une source'),
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.accentInk,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
