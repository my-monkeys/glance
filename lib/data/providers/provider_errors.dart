import '../../core/errors.dart';
import '../../l10n/l10n.dart';
import '../models/indicator.dart';

/// Fonction qu'un fournisseur ne sait pas calculer (la valeur par défaut de
/// [AnalyticsProvider] la signale).
enum UnsupportedFeature { indicators, siteTables, funnels, breakdowns }

class FeatureUnsupported implements LocalizedError {
  const FeatureUnsupported(this.feature);
  final UnsupportedFeature feature;

  @override
  String message(AppLocalizations l10n) => switch (feature) {
    UnsupportedFeature.indicators => l10n.errUnsupportedIndicators,
    UnsupportedFeature.siteTables => l10n.errUnsupportedSiteTables,
    UnsupportedFeature.funnels => l10n.errUnsupportedFunnels,
    UnsupportedFeature.breakdowns => l10n.errUnsupportedBreakdowns,
  };
}

/// Opérateur de filtre que le fournisseur ne sait pas exprimer.
class OperatorUnavailable implements LocalizedError {
  const OperatorUnavailable(this.op, {required this.umamiFunnel});
  final FilterOp op;

  /// Vrai pour un filtre d'étape d'entonnoir Umami, faux pour Plausible.
  final bool umamiFunnel;

  @override
  String message(AppLocalizations l10n) => umamiFunnel
      ? l10n.errOperatorUmamiFunnel(op.label(l10n))
      : l10n.errOperatorPlausible(op.label(l10n));
}

class FathomComingSoon implements LocalizedError {
  const FathomComingSoon();

  @override
  String message(AppLocalizations l10n) => l10n.errFathomSoon;
}

class PlausibleNeedsSite implements LocalizedError {
  const PlausibleNeedsSite();

  @override
  String message(AppLocalizations l10n) => l10n.errPlausibleNeedsSite;
}

class UmamiLoginUnexpected implements LocalizedError {
  const UmamiLoginUnexpected();

  @override
  String message(AppLocalizations l10n) => l10n.errUmamiLoginUnexpected;
}

/// La fenêtre donnerait plus de [max] buckets.
class BucketsTooFine implements LocalizedError {
  const BucketsTooFine(this.max);
  final int max;

  @override
  String message(AppLocalizations l10n) => l10n.errBucketsTooFine(max);
}
