import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/countries.dart';
import '../../core/metric_icon.dart';
import '../../data/models/dimension.dart';
import '../../state/providers.dart';
import '../../theme/palette.dart';

/// Pastille devant une ligne de métrique : favicon du domaine référent, logo de
/// navigateur ou de système servi par l'instance Umami, glyphe d'appareil,
/// drapeau du pays.
///
/// Occupe toujours [size] de large, même sans icône : une ligne dont l'icône
/// manque ne doit pas décaler son libellé par rapport aux autres.
class MetricIcon extends ConsumerWidget {
  const MetricIcon({
    super.key,
    required this.kind,
    required this.code,
    required this.accountId,
    this.size = 17,
  });

  final MetricIconKind kind;

  /// Valeur brute du fournisseur (jamais le libellé mis en forme).
  final String? code;
  final String accountId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final raw = code?.trim() ?? '';

    if (kind == MetricIconKind.device && raw.isNotEmpty) {
      return SizedBox(
        width: size,
        child: Icon(deviceIcon(raw), size: size, color: p.fg2),
      );
    }
    if (kind == MetricIconKind.flag && raw.isNotEmpty) {
      return SizedBox(
        width: size,
        child: Text(
          countryFlag(raw),
          style: TextStyle(fontSize: size * 0.9),
          textAlign: TextAlign.center,
        ),
      );
    }

    final src = metricIconSource(
      kind: kind,
      code: raw,
      instanceBase: ref.watch(instanceBaseProvider(accountId)),
    );
    if (src == null) return SizedBox(width: size);

    final icon = ref.watch(iconProvider(src)).value;
    if (icon == null || icon.bytes.isEmpty) return SizedBox(width: size);
    return SizedBox(
      width: size,
      height: size,
      child: icon.isSvg
          ? SvgPicture.memory(
              icon.bytes,
              width: size,
              height: size,
              placeholderBuilder: (_) => SizedBox(width: size),
            )
          : Image.memory(
              icon.bytes,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => SizedBox(width: size),
            ),
    );
  }
}
