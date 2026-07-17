import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/transfer/config_transfer.dart';
import '../../state/providers.dart';
import '../../state/workspaces.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';

/// Affiche le QR de transfert (appareil source).
Future<void> openTransferExport(BuildContext context) =>
    showGlanceModal<void>(context, const TransferExportScreen());

/// Ouvre le scanner d'import (appareil cible).
Future<void> openTransferImport(BuildContext context) =>
    showGlanceModal<void>(context, const TransferImportScreen());

// ---------------------------------------------------------------------------
// Export : code à 4 chiffres + QR
// ---------------------------------------------------------------------------

class TransferExportScreen extends ConsumerStatefulWidget {
  const TransferExportScreen({super.key});

  @override
  ConsumerState<TransferExportScreen> createState() =>
      _TransferExportScreenState();
}

class _TransferExportScreenState extends ConsumerState<TransferExportScreen> {
  /// Le code est tiré au sort, pas choisi : un code deviné (« 1234 ») rendrait
  /// le chiffrement décoratif.
  late final String _code = (Random.secure().nextInt(10000)).toString().padLeft(4, '0');

  String? _data;
  Object? _error;
  Timer? _tick;
  Duration _left = ConfigTransfer.validity;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _build() async {
    try {
      final accounts = ref.read(accountsProvider);
      final repo = ref.read(accountsRepoProvider);
      final creds = <String, Map<String, String>>{};
      for (final a in accounts) {
        creds[a.id] = await repo.credentials(a.id);
      }
      final data = await ConfigTransfer.encode(
        TransferPayload(
          accounts: accounts,
          credentials: creds,
          workspaces: ref.read(workspacesProvider),
        ),
        _code,
      );
      if (!mounted) return;
      setState(() => _data = data);
      _startCountdown();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _startCountdown() {
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _left - const Duration(seconds: 1);
      // Périmé : le QR disparaît de l'écran de lui-même.
      if (left <= Duration.zero) {
        _tick?.cancel();
        setState(() {
          _left = Duration.zero;
          _data = null;
        });
      } else {
        setState(() => _left = left);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Head(
              title: 'Transférer',
              subtitle: 'Scannez ce code depuis l\'autre appareil.',
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  if (_error != null)
                    _ErrorNote(error: _error!)
                  else if (_data == null && _left == Duration.zero)
                    _Expired(onRegen: () {
                      setState(() {
                        _left = ConfigTransfer.validity;
                        _error = null;
                      });
                      _build();
                    })
                  else if (_data == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: p.accent,
                          strokeWidth: 2.4,
                        ),
                      ),
                    )
                  else ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          // Fond blanc franc : un QR sur crème se scanne mal.
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(kRadiusSm),
                        ),
                        child: QrImageView(
                          data: _data!,
                          version: QrVersions.auto,
                          size: 260,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _CodeBox(code: _code),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Expire dans ${_left.inMinutes}:${(_left.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: GT.mono(12, color: p.fg2),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _Warning(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le code à taper sur l'autre appareil.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Column(
      children: [
        SectionLabel('Code à saisir sur l\'autre appareil'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final c in code.split(''))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 48,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.chip,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(c, style: GT.stat(28, color: p.fg)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return GlanceCard(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: p.fg2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ce code contient vos identifiants. Ne le photographiez pas et '
              'ne le partagez pas : le QR seul ne suffit pas, mais avec le code '
              'à 4 chiffres il donne accès à vos comptes.',
              style: GT.body(12.5, color: p.fg2),
            ),
          ),
        ],
      ),
    );
  }
}

class _Expired extends StatelessWidget {
  const _Expired({required this.onRegen});
  final VoidCallback onRegen;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(Icons.timer_off_rounded, size: 34, color: p.fg3),
          const SizedBox(height: 14),
          Text('Code expiré', style: GT.display(22, color: p.fg)),
          const SizedBox(height: 8),
          Text(
            'Un transfert ne reste valable que quelques minutes.',
            textAlign: TextAlign.center,
            style: GT.body(14, color: p.fg2),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRegen,
            child: Text('Régénérer',
                style: GT.body(15, weight: 600, color: p.accent)),
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final e = error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 34, color: p.neg),
          const SizedBox(height: 14),
          Text(
            e is TransferTooLarge ? 'Config trop grosse' : 'Transfert impossible',
            style: GT.display(22, color: p.fg),
          ),
          const SizedBox(height: 8),
          Text(
            e is TransferTooLarge
                ? 'Elle ne tient pas dans un QR code (${e.size} caractères pour '
                    '${e.max} au maximum). Suivez « tous les sites » sur vos '
                    'comptes plutôt qu\'une sélection, puis réessayez.'
                : 'Impossible de préparer le transfert.',
            textAlign: TextAlign.center,
            style: GT.body(14, color: p.fg2),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Import : scan + code
// ---------------------------------------------------------------------------

class TransferImportScreen extends ConsumerStatefulWidget {
  const TransferImportScreen({super.key});

  @override
  ConsumerState<TransferImportScreen> createState() =>
      _TransferImportScreenState();
}

class _TransferImportScreenState extends ConsumerState<TransferImportScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final _code = TextEditingController();

  String? _scanned;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _code.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned != null) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _controller.stop();
    setState(() => _scanned = raw);
  }

  Future<void> _apply() async {
    final code = _code.text.trim();
    if (code.length != 4 || _scanned == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = await ConfigTransfer.decode(_scanned!, code);
      await ref.read(accountsProvider.notifier).import(
            payload.accounts,
            payload.credentials,
          );
      await ref.read(workspacesProvider.notifier).upsertAll(payload.workspaces);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${payload.accounts.length} compte${payload.accounts.length > 1 ? 's' : ''} '
            'et ${payload.workspaces.length} groupe${payload.workspaces.length > 1 ? 's' : ''} importés',
          ),
        ),
      );
    } on TransferExpired {
      if (mounted) {
        setState(() => _error =
            'Ce code a expiré. Régénérez-le sur l\'autre appareil.');
      }
    } on TransferBadCode {
      if (mounted) setState(() => _error = 'Code incorrect.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Import impossible.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _rescan() {
    setState(() {
      _scanned = null;
      _error = null;
      _code.clear();
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Head(
              title: 'Importer',
              subtitle: _scanned == null
                  ? 'Visez le QR affiché sur l\'autre appareil.'
                  : 'Saisissez le code affiché à côté du QR.',
            ),
            Expanded(
              child: _scanned == null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(kRadius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _controller,
                              onDetect: _onDetect,
                              errorBuilder: (context, error) =>
                                  _ScannerError(error: error),
                            ),
                            IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: p.accent, width: 2),
                                  borderRadius: BorderRadius.circular(kRadius),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        Center(
                          child: Icon(Icons.qr_code_2_rounded,
                              size: 46, color: p.accent),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text('Code scanné',
                              style: GT.body(14, color: p.fg2)),
                        ),
                        const SizedBox(height: 24),
                        GlanceField(
                          label: 'Code à 4 chiffres',
                          controller: _code,
                          hint: '0000',
                          mono: true,
                          autofocus: true,
                          onSubmitted: (_) => _apply(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: GT.body(13, color: p.neg)),
                        ],
                        const SizedBox(height: 20),
                        GlanceButton(
                          label: 'Importer',
                          busy: _busy,
                          onTap: _apply,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: _rescan,
                            child: Text('Scanner à nouveau',
                                style: GT.body(13.5, color: p.fg3)),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Caméra indisponible (refusée, ou simulateur qui n'en a pas).
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});
  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    final refused =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: p.chip,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_photography_rounded, size: 34, color: p.fg3),
          const SizedBox(height: 14),
          Text(
            refused ? 'Caméra refusée' : 'Caméra indisponible',
            style: GT.display(20, color: p.fg),
          ),
          const SizedBox(height: 8),
          Text(
            refused
                ? 'Autorisez l\'accès à la caméra dans les réglages du système '
                    'pour scanner un transfert.'
                : 'Aucune caméra utilisable sur cet appareil.',
            textAlign: TextAlign.center,
            style: GT.body(13.5, color: p.fg2),
          ),
        ],
      ),
    );
  }
}

/// En-tête commun aux deux écrans.
class _Head extends StatelessWidget {
  const _Head({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.glance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          GlanceIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GT.display(26, color: p.fg)),
                const SizedBox(height: 2),
                Text(subtitle, style: GT.body(13, color: p.fg2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
