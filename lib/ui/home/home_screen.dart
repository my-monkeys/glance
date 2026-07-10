import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/models/period.dart';
import '../../state/home_data.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';
import '../widgets/glance_chart.dart';
import '../widgets/pulse_dot.dart';
import '../widgets/sparkline.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onGoSettings});
  final VoidCallback onGoSettings;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Period _period = Period.d7;
  DateTime? _customStart;
  DateTime? _customEnd;
  Timer? _timer;

  // Fenêtre figée : recalculée seulement au changement de période / refresh,
  // sinon la borne `now` bougerait à chaque build et rechargerait en boucle.
  late DateWindow _window = _computeWindow();
  HomeData? _lastData;

  DateWindow _computeWindow() =>
      _period.window(customStart: _customStart, customEnd: _customEnd);

  void _setPeriod(Period p, {DateTime? start, DateTime? end}) {
    setState(() {
      _period = p;
      _customStart = start ?? _customStart;
      _customEnd = end ?? _customEnd;
      _window = _computeWindow();
    });
  }

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
      _setPeriod(
        Period.custom,
        start: range.start,
        end: range.end.add(const Duration(hours: 23, minutes: 59)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final secs = ref.read(settingsProvider).refreshSeconds;
    _timer = Timer.periodic(Duration(seconds: secs), (_) {
      if (!mounted) return;
      setState(() => _window = _computeWindow());
      ref.invalidate(homeProvider(_window));
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

    final async = ref.watch(homeProvider(_window));
    // Garde la dernière donnée affichée pendant un rechargement en fond : la
    // mise à jour se fait en place, sans masquer puis réafficher l'écran.
    if (async.hasValue) _lastData = async.value;
    final data = async.value ?? _lastData;
    final now = DateTime.now();
    final viewMode = ref.watch(settingsProvider.select((s) => s.homeView));

    return RefreshIndicator(
      color: p.accent,
      backgroundColor: p.surface,
      onRefresh: () async {
        ref.invalidate(homeProvider(_window));
        await ref.read(homeProvider(_window).future);
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
          // En-tête.
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
                        '${DateFormat('EEE d MMM', 'fr_FR').format(now)} · ${_period.label}'
                            .toUpperCase(),
                        style: GT.label(color: p.fg2),
                      ),
                      const SizedBox(height: 9),
                      Text('Mes sites', style: GT.display(34, color: p.fg)),
                    ],
                  ),
                ),
                GlanceIconButton(
                  icon: Icons.add,
                  onTap: () => openAddSource(context),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onGoSettings,
                  child: const Mark('M', circle: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sélecteur de période + bascule liste/grille.
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
                          selected: _period == per,
                          onTap: () {
                            if (per == Period.custom) {
                              _pickCustom();
                            } else {
                              _setPeriod(per);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ViewToggle(
                  mode: viewMode,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setHomeView(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (async.hasError && data == null)
            _ErrorBox(
              message: 'Chargement impossible.',
              onRetry: () => ref.invalidate(homeProvider(_window)),
            )
          else if (data == null)
            const _HomeSkeleton()
          else if (data.isEmpty)
            _EmptyBox(onAdd: () => openAddSource(context))
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TotalCard(data: data, unit: _window.unit.api),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: viewMode == HomeViewMode.grid
                  ? _SiteGrid(cards: data.cards)
                  : Column(
                      children: [
                        for (final c in data.cards) ...[
                          _SiteCardTile(card: c),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.data, required this.unit});
  final HomeData data;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
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
                    SectionLabel('Visiteurs · tous les sites'),
                    const SizedBox(height: 8),
                    Text(
                      fmtInt(data.totalVisitors),
                      style: GT.stat(50, color: p.fg),
                    ),
                  ],
                ),
              ),
              LivePill(label: '${data.totalLive} live'),
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
          Mark(card.site.initial),
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
                    const PulseDot(size: 8),
                    const SizedBox(width: 6),
                    Text(
                      '${card.live} live',
                      style: GT.mono(11, color: p.accent),
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
class _SiteGrid extends StatelessWidget {
  const _SiteGrid({required this.cards});
  final List<SiteCard> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1, // cartes carrées
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => _SiteGridCard(card: cards[i]),
    );
  }
}

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
          const Spacer(),
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

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Column(
        children: [
          Text('Aucun site', style: GT.display(22, color: p.fg)),
          const SizedBox(height: 8),
          Text(
            'Ajoute une source pour voir tes stats.',
            style: GT.body(14, color: p.fg2),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              '+ Ajouter une source',
              style: GT.body(15, weight: 600, color: p.accent),
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
