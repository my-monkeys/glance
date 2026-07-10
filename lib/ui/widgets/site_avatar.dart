import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../theme/palette.dart';
import '../../theme/type.dart';

/// Pastille d'un site : favicon récupéré + mis en cache, avec repli sur
/// l'initiale tant que l'icône n'est pas dispo (ou absente).
class SiteAvatar extends ConsumerWidget {
  const SiteAvatar(this.site, {super.key, this.size = 38, this.circle = false});
  final Site site;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.glance;
    final radius = circle ? size : 10.0;
    final fav = ref.watch(faviconProvider(site.domain)).value;

    Widget child;
    if (fav != null && fav.bytes.isNotEmpty) {
      final inset = size * 0.18;
      final iconSize = size - inset * 2;
      child = Padding(
        padding: EdgeInsets.all(inset),
        child: fav.isSvg
            ? SvgPicture.memory(
                fav.bytes,
                width: iconSize,
                height: iconSize,
                placeholderBuilder: (_) => _letter(p),
              )
            : Image.memory(
                fav.bytes,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _letter(p),
              ),
      );
    } else {
      child = _letter(p);
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _letter(GlancePalette p) => Text(
        site.initial,
        style: GT.mono(size * 0.4, weight: 600, color: p.fg),
      );
}
