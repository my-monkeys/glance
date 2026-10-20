import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../state/metrics_sources.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';
import '../widgets/motion.dart';
import '../widgets/toast.dart';
import 'editor/confirm_button.dart';
import 'labels.dart';

/// Ouvre l'écran de la source de métriques d'un site.
Future<void> openMetricsSource(BuildContext context, Site site) =>
    showGlanceModal<void>(context, MetricsSourceScreen(site: site));

/// URL + jeton de l'API d'agrégats d'un site, testables avant d'être gardés.
class MetricsSourceScreen extends ConsumerStatefulWidget {
  const MetricsSourceScreen({super.key, required this.site});
  final Site site;

  @override
  ConsumerState<MetricsSourceScreen> createState() =>
      _MetricsSourceScreenState();
}

class _MetricsSourceScreenState extends ConsumerState<MetricsSourceScreen> {
  final _url = TextEditingController();
  final _token = TextEditingController();
  bool _testing = false;

  /// Résultat du dernier test : message, et vrai s'il est positif.
  (String, bool)? _result;

  bool get _exists =>
      ref.read(siteHasMetricsSourceProvider(widget.site));

  bool get _filled => _url.text.trim().isNotEmpty && _token.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(metricsSourcesProvider.notifier);
    final source = notifier.sourceFor(widget.site);
    if (source == null) return;
    _url.text = source.baseUrl;
    notifier.tokenFor(source.site).then((t) {
      if (mounted && t != null) setState(() => _token.text = t);
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  /// Un résultat ne vaut que pour l'URL et le jeton testés.
  void _edited() => setState(() => _result = null);

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    (String, bool) result;
    try {
      final api = ref.read(metricsApiFactoryProvider)(
        _url.text.trim(),
        _token.text.trim(),
      );
      final n = (await api.catalogue()).length;
      result = (n == 1 ? '1 indicateur disponible' : '$n indicateurs disponibles', true);
    } catch (e) {
      result = (metricsErrorMessage(e), false);
    }
    if (mounted) {
      setState(() {
        _testing = false;
        _result = result;
      });
    }
  }

  Future<void> _save() async {
    await ref
        .read(metricsSourcesProvider.notifier)
        .set(widget.site, _url.text, _token.text);
    if (!mounted) return;
    showGlanceToast(context, 'Source enregistrée');
    Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await ref.read(metricsSourcesProvider.notifier).remove(widget.site);
    if (!mounted) return;
    showGlanceToast(context, 'Source retirée', kind: ToastKind.info);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final bottom = MediaQuery.of(context).padding.bottom;
    final result = _result;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  GlanceIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Source de métriques',
                        style: GT.display(24, color: p.fg)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Text(
                    'Une API qui fournit des indicateurs calculés par le site '
                    'lui-même (rétention, comptes…).',
                    style: GT.body(13.5, color: p.fg2),
                  ),
                  const SizedBox(height: 22),
                  GlanceField(
                    label: 'Adresse de l\'API',
                    controller: _url,
                    hint: 'https://exemple.fr/api/interne/metriques/',
                    url: true,
                    onChanged: (_) => _edited(),
                  ),
                  const SizedBox(height: 14),
                  GlanceField(
                    label: 'Jeton',
                    controller: _token,
                    obscure: true,
                    onChanged: (_) => _edited(),
                  ),
                  const SizedBox(height: 18),
                  GlanceButtonOutline(
                    label: 'Tester',
                    busy: _testing,
                    onTap: _filled ? _test : null,
                  ),
                  GlanceReveal(
                    show: result != null,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, left: 3),
                      child: Text(
                        result?.$1 ?? '',
                        style: GT.body(13,
                            color: result?.$2 == true ? p.accent : p.neg),
                      ),
                    ),
                  ),
                  if (_exists) ...[
                    const SizedBox(height: 28),
                    ConfirmButton(
                      label: 'Retirer la source',
                      confirmLabel: 'Confirmer le retrait',
                      onConfirmed: _remove,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 12),
              child: GlanceButton(
                label: 'Enregistrer',
                onTap: _filled ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
