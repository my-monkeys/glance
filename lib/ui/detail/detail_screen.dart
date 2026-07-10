import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/countries.dart';
import '../../core/format.dart';
import '../../data/models/models.dart';
import '../../data/models/period.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../widgets/chip.dart';
import '../widgets/common.dart';
import '../widgets/glance_chart.dart';
import '../widgets/pulse_dot.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.site});
  final Site site;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  Period _period = Period.d7;
  DateTime? _customStart;
  DateTime? _customEnd;
  Timer? _timer;

  // Fenêtre figée : recalculée seulement au changement de période / refresh,
  // sinon la borne `now` bougerait à chaque build et la family Riverpod
  // rechargerait en boucle.
  late DateWindow _window = _computeWindow();

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

  @override
  void initState() {
    super.initState();
    final secs = ref.read(settingsProvider).refreshSeconds;
    _timer = Timer.periodic(Duration(seconds: secs), (_) {
      if (!mounted) return;
      setState(() => _window = _computeWindow());
      ref.invalidate(detailProvider((widget.site, _window)));
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
      _setPeriod(
        Period.custom,
        start: range.start,
        end: range.end.add(const Duration(hours: 23, minutes: 59)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final window = _window;
    final async = ref.watch(detailProvider((widget.site, window)));
    final detail = async.value;

    return Scaffold(
      body: RefreshIndicator(
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
                  LivePill(label: '${detail?.live ?? 0}'),
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
            const SizedBox(height: 22),

            if (async.hasError && detail == null)
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
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.window});
  final SiteDetail detail;
  final DateWindow window;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final s = detail.summary;
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
              _Kpi(label: 'Pages vues', value: fmtInt(s.pageviews)),
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
                    LivePill(label: '${detail.live}'),
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
