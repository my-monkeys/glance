import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/transfer/config_transfer.dart';
import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../../state/workspaces.dart';
import '../../theme/motion.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';
import '../root_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/field.dart';
import '../widgets/motion.dart';
import '../widgets/toast.dart';

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
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Head(
              title: l10n.transferExportTitle,
              subtitle: l10n.transferExportSubtitle,
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // QR / expiré / chargement / erreur : les états se fondent
                  // l'un dans l'autre (l'expiration ne fait plus « pouf »).
                  GlanceSwap(
                    child: KeyedSubtree(
                      key: ValueKey(_error != null
                          ? 'error'
                          : _data != null
                              ? 'qr'
                              : _left == Duration.zero
                                  ? 'expired'
                                  : 'loading'),
                      child: _buildExportState(context, p),
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

  Widget _buildExportState(BuildContext context, GlancePalette p) {
    if (_error != null) return _ErrorNote(error: _error!);
    if (_data == null && _left == Duration.zero) {
      return _Expired(onRegen: () {
        setState(() {
          _left = ConfigTransfer.validity;
          _error = null;
        });
        _build();
      });
    }
    if (_data == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: p.accent, strokeWidth: 2.4),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            context.l10n.transferExpiresIn(
                '${_left.inMinutes}:${(_left.inSeconds % 60).toString().padLeft(2, '0')}'),
            style: GT.mono(12, color: p.fg2),
          ),
        ),
        const SizedBox(height: 22),
        _Warning(),
      ],
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
        SectionLabel(context.l10n.transferCodeLabel),
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
              context.l10n.transferWarning,
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
          Text(context.l10n.transferExpiredTitle, style: GT.display(22, color: p.fg)),
          const SizedBox(height: 8),
          Text(
            context.l10n.transferExpiredBody,
            textAlign: TextAlign.center,
            style: GT.body(14, color: p.fg2),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRegen,
            child: Text(context.l10n.transferRegenerate,
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
    final l10n = context.l10n;
    final e = error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 34, color: p.neg),
          const SizedBox(height: 14),
          Text(
            e is TransferTooLarge
                ? l10n.transferTooLargeTitle
                : l10n.transferFailedTitle,
            style: GT.display(22, color: p.fg),
          ),
          const SizedBox(height: 8),
          Text(
            e is TransferTooLarge
                ? l10n.transferTooLargeBody(e.size, e.max)
                : l10n.transferFailedBody,
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
    final l10n = context.l10n;
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
      // Toast avant le pop : il vit dans l'overlay racine, pas dans la route.
      showGlanceToast(
        context,
        context.l10n.transferImported(
            payload.accounts.length, payload.workspaces.length),
      );
      Navigator.of(context).pop();
    } on TransferExpired {
      if (mounted) {
        setState(() => _error = l10n.transferErrExpired);
      }
    } on TransferBadCode {
      if (mounted) setState(() => _error = l10n.transferErrBadCode);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.transferErrFailed);
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
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Head(
              title: l10n.transferImportTitle,
              subtitle: _scanned == null
                  ? l10n.transferImportScanHint
                  : l10n.transferImportCodeHint,
            ),
            Expanded(
              // Caméra ↔ formulaire : la bascule la plus brutale de l'app,
              // fondue sur la durée longue.
              child: GlanceSwap(
                duration: kMotionSlow,
                dy: 0,
                child: _scanned == null
                    ? Padding(
                        key: const ValueKey('scan'),
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
                                    border:
                                        Border.all(color: p.accent, width: 2),
                                    borderRadius:
                                        BorderRadius.circular(kRadius),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        key: const ValueKey('form'),
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        children: [
                          Center(
                            child: Icon(Icons.qr_code_2_rounded,
                                size: 46, color: p.accent),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(l10n.transferScanned,
                                style: GT.body(14, color: p.fg2)),
                          ),
                          const SizedBox(height: 24),
                          GlanceField(
                            label: l10n.transferCodeField,
                            controller: _code,
                            hint: '0000',
                            mono: true,
                            autofocus: true,
                            onSubmitted: (_) => _apply(),
                          ),
                          GlanceReveal(
                            show: _error != null,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(_error ?? '',
                                  style: GT.body(13, color: p.neg)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GlanceButton(
                            label: l10n.transferImportButton,
                            busy: _busy,
                            onTap: _apply,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: _rescan,
                              child: Text(l10n.transferRescan,
                                  style: GT.body(13.5, color: p.fg3)),
                            ),
                          ),
                        ],
                      ),
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
    final l10n = context.l10n;
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
            refused
                ? l10n.transferCameraDenied
                : l10n.transferCameraUnavailable,
            style: GT.display(20, color: p.fg),
          ),
          const SizedBox(height: 8),
          Text(
            refused
                ? l10n.transferCameraDeniedBody
                : l10n.transferCameraUnavailableBody,
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
