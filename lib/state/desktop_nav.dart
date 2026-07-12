import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';

/// Ce que montre le panneau central du shell desktop (master-détail).
/// (Le temps réel est fusionné dans [overview], pas un onglet séparé.)
enum DesktopView { overview, site, settings }

@immutable
class DesktopNav {
  const DesktopNav({this.view = DesktopView.overview, this.site});

  final DesktopView view;

  /// Site affiché quand [view] == [DesktopView.site].
  final Site? site;

  bool isSite(Site s) => view == DesktopView.site && site == s;
}

class DesktopNavNotifier extends Notifier<DesktopNav> {
  @override
  DesktopNav build() => const DesktopNav();

  void overview() => state = const DesktopNav();
  void openSite(Site s) => state = DesktopNav(view: DesktopView.site, site: s);
  void settings() => state = const DesktopNav(view: DesktopView.settings);
}

/// Sélection centrale du desktop. Sur mobile ce provider n'est pas utilisé
/// (navigation par pile + bottom nav).
final desktopNavProvider =
    NotifierProvider<DesktopNavNotifier, DesktopNav>(DesktopNavNotifier.new);
