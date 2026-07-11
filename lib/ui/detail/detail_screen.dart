import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/countries.dart';
import '../../core/format.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../state/period_state.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';
import '../widgets/day_nav.dart';
import '../widgets/events_chart.dart';
import '../widgets/glance_chart.dart';
import '../widgets/pulse_dot.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.site});
  final Site site;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

enum _DetailTab { overview, events }

class _DetailScreenState extends ConsumerState<DetailScreen> {
  _DetailTab _tab = _DetailTab.overview;
  Timer? _timer;

  // Cache anti-flash : garde le dernier détail affiché pendant un rechargement
  // en fond de la même fenêtre.
  SiteDetail? _lastDetail;
  DateWindow? _lastDetailWindow;

  @override
  void initState() {
    super.initState();
    final secs = ref.read(settingsProvider).refreshSeconds;
    _timer = Timer.periodic(Duration(seconds: secs), (_) {
      if (!mounted) return;
      final w = ref.read(periodProvider).window();
      ref.invalidate(detailProvider((widget.site, w)));
      ref.invalidate(eventsProvider((widget.site, w)));
    });
    // Rafraîchit en fond à l'ouverture si des données sont déjà en cache
    // (réouverture d'un site récent) : on affiche le cache tout de suite et on
    // met à jour derrière, sans repasser par le spinner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final w = ref.read(periodProvider).window();
      if (ref.read(detailProvider((widget.site, w))).hasValue) {
        ref.invalidate(detailProvider((widget.site, w)));
      }
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
  Widget build(BuildContext context) {
    final p = context.glance;
    final periodState = ref.watch(periodProvider);
    final window = periodState.window();
    final async = ref.watch(detailProvider((widget.site, window)));
    if (async.hasValue) {
      _lastDetail = async.value;
      _lastDetailWindow = window;
    }
    // Rechargement en fond de la même période → on garde l'affichage précédent.
    // Changement de période → on montre bien le chargement (données différentes).
    final detail =
        async.value ?? (_lastDetailWindow == window ? _lastDetail : null);
    final refreshing = async.isLoading && detail != null;
    final hasEvents =
        ref.watch(siteHasEventsProvider(widget.site)).value ?? false;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
        color: p.accent,
        backgroundColor: p.surface,
        onRefresh: () async {
          ref.invalidate(detailProvider((widget.site, window)));
          await ref.read(detailProvider((widget.site, window)).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            0,
            MediaQuery.of(context).padding.top + 14,
            0,
            40,
          ),
          children: [
            // En-tête.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GlanceIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.site.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GT.display(26, color: p.fg),
                    ),
                  ),
                  const SizedBox(width: 10),
                  LivePill(count: detail?.live ?? 0, text: '${detail?.live ?? 0}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Périodes.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ChipRow(
                children: [
                  for (final per in Period.values)
                    GlanceChip(
                      label: per.label,
                      selected: periodState.period == per,
                      onTap: () {
                        if (per == Period.custom) {
                          _pickCustom();
                        } else {
                          ref.read(periodProvider.notifier).set(per);
                        }
                      },
                    ),
                ],
              ),
            ),
            if (periodState.canNavigateDays) ...[
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: DayNav(),
              ),
            ],
            const SizedBox(height: 18),

            // Onglets Vue d'ensemble / Événements (le 2e uniquement si events).
            if (hasEvents) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SegTabs(
                  current: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_tab == _DetailTab.events && hasEvents)
              _EventsTab(site: widget.site, window: window)
            else if (async.hasError && detail == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Center(
                  child: Text('Chargement impossible.',
                      style: GT.body(15, color: p.fg2)),
                ),
              )
            else if (detail == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(
                    color: p.accent,
                    strokeWidth: 2.4,
                  ),
                ),
              )
            else
              _DetailBody(detail: detail, window: window),
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
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail, required this.window});
  final SiteDetail detail;
  final DateWindow window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final s = detail.summary;
    final hidden = ref.watch(settingsProvider.select((s) => s.hiddenSeries));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grand chiffre + delta.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Visiteurs uniques'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmtInt(s.visitors), style: GT.stat(54, color: p.fg)),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DeltaText(s.visitorsDeltaPct, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GlanceChart(
                series: detail.series,
                unit: detail.unit,
                height: 172,
                showPageviews: true,
                visitorsTotal: s.visitors,
                visitsTotal: s.visits,
                pageviewsTotal: s.pageviews,
                hidden: hidden,
                onToggle: (k) =>
                    ref.read(settingsProvider.notifier).toggleSeries(k),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // KPIs.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _Kpi(label: 'Visites', value: fmtInt(s.visits)),
              const SizedBox(width: 10),
              _Kpi(label: 'Durée moy.', value: fmtDuration(s.avgVisit)),
              const SizedBox(width: 10),
              _Kpi(
                label: 'Rebond',
                value: fmtPct(s.bounceRatePct, decimals: 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        // En direct.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlanceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SectionLabel('En direct maintenant'),
                    LivePill(count: detail.live, text: '${detail.live}'),
                  ],
                ),
                const SizedBox(height: 6),
                if (detail.livePages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Personne pour l\'instant.',
                      style: GT.body(13, color: p.fg3),
                    ),
                  )
                else
                  for (final lp in detail.livePages)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: p.line)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lp.path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GT.mono(12, color: p.fg),
                            ),
                          ),
                          Text(
                            '${lp.count}',
                            style: GT.mono(12, weight: 600, color: p.fg2),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _MetricCard(
          title: 'Pages populaires',
          rows: detail.topPages
              .map((r) => MetricBarRow(label: r.label, value: r.value))
              .toList(),
          mono: true,
        ),
        const SizedBox(height: 14),
        _MetricCard(
          title: 'Sources',
          rows: detail.sources
              .map((r) => MetricBarRow(label: r.label, value: r.value))
              .toList(),
        ),
        const SizedBox(height: 14),
        _MetricCard(
          title: 'Pays',
          leadingFlag: true,
          rows: detail.countries
              .map((r) => MetricBarRow(
                    label: r.label,
                    value: r.value,
                    flag: r.code != null ? countryFlag(r.code!) : null,
                  ))
              .toList(),
          valueLabel: (row) => s.visitors == 0
              ? fmtInt(row.value)
              : fmtPct(row.value / s.visitors * 100, decimals: 0),
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Expanded(
      child: GlanceCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(label),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: GT.stat(22, color: p.fg)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.rows,
    this.mono = false,
    this.leadingFlag = false,
    this.valueLabel,
  });

  final String title;
  final List<MetricBarRow> rows;
  final bool mono;
  final bool leadingFlag;
  final String Function(MetricBarRow row)? valueLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlanceCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SectionLabel(title),
            ),
            MetricBars(
              rows: rows,
              mono: mono,
              leadingFlag: leadingFlag,
              valueLabel: valueLabel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmenté à 2 onglets (Vue d'ensemble / Événements).
class _SegTabs extends StatelessWidget {
  const _SegTabs({required this.current, required this.onChanged});
  final _DetailTab current;
  final ValueChanged<_DetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    Widget seg(_DetailTab tab, String label) {
      final on = tab == current;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(tab),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? p.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: on ? p.shadow : null,
            ),
            child: Text(
              label,
              style: GT.body(14, weight: on ? 600 : 400,
                  color: on ? p.fg : p.fg2),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          seg(_DetailTab.overview, "Vue d'ensemble"),
          seg(_DetailTab.events, 'Événements'),
        ],
      ),
    );
  }
}

/// Contenu de l'onglet Événements : total + graphe + répartition par nom.
class _EventsTab extends ConsumerStatefulWidget {
  const _EventsTab({required this.site, required this.window});
  final Site site;
  final DateWindow window;

  @override
  ConsumerState<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<_EventsTab> {
  // Événements masqués du graphique (décochés dans la légende).
  final Set<String> _hidden = {};
  // Au-delà de ce nombre, on masque par défaut les événements les moins
  // fréquents pour garder le graphe lisible (ils restent activables).
  static const _defaultVisible = 6;
  bool _defaultsApplied = false;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final async = ref.watch(eventsProvider((widget.site, widget.window)));
    final data = async.value;

    if (data == null) {
      if (async.hasError) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Center(
            child: Text('Chargement impossible.',
                style: GT.body(15, color: p.fg2)),
          ),
        );
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          children: [
            Icon(Icons.bolt_outlined, size: 34, color: p.fg3),
            const SizedBox(height: 12),
            Text('Aucun événement sur cette période',
                style: GT.body(15, color: p.fg2)),
          ],
        ),
      );
    }

    // Couleur stable par nom (ordre global trié par total).
    final colors = <String, Color>{
      for (var i = 0; i < data.series.length; i++)
        data.series[i].name: eventColorAt(i),
    };

    // Masquage par défaut au-delà de N événements (une seule fois).
    if (!_defaultsApplied && data.series.length > _defaultVisible) {
      _hidden.addAll(data.series.skip(_defaultVisible).map((e) => e.name));
    }
    _defaultsApplied = true;

    final visible =
        data.series.where((s) => !_hidden.contains(s.name)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Événements déclenchés'),
              const SizedBox(height: 8),
              Text(fmtInt(data.total), style: GT.stat(54, color: p.fg)),
              const SizedBox(height: 16),
              // Légende cliquable = filtre des courbes.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in data.series)
                    _EventChip(
                      label: s.name,
                      color: colors[s.name]!,
                      on: !_hidden.contains(s.name),
                      onTap: () => setState(() {
                        if (!_hidden.remove(s.name)) _hidden.add(s.name);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              EventsChart(
                series: visible,
                colors: colors,
                unit: data.unit,
                height: 200,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _MetricCard(
          title: 'Par événement',
          mono: true,
          rows: data.breakdown
              .map((r) => MetricBarRow(
                    label: r.label,
                    value: r.value,
                    color: colors[r.label],
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Puce de légende cliquable (couleur + nom) qui active/désactive une courbe.
class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.label,
    required this.color,
    required this.on,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: on ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: p.chip,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? color : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(label, style: GT.mono(12, weight: 500, color: p.fg)),
            ],
          ),
        ),
      ),
    );
  }
}
