import 'package:dio/dio.dart';

import '../l10n/l10n.dart';

/// Erreur dont le texte est choisi à l'affichage, dans la langue de l'app :
/// l'exception ne porte que ses données (code, opérateur…), jamais de phrase.
abstract interface class LocalizedError implements Exception {
  String message(AppLocalizations l10n);
}

/// Message court et lisible pour l'utilisateur à partir d'une exception réseau.
String friendlyError(AppLocalizations l10n, Object e) {
  if (e is LocalizedError) return e.message(l10n);
  if (e is DioException) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) return l10n.errorsAuthRefused;
    if (code == 400) return l10n.errorsRequestRefused;
    if (code == 404) return l10n.errorsNotFound;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return l10n.errorsTimeout;
      case DioExceptionType.connectionError:
        return l10n.errorsUnreachable;
      default:
        return code != null
            ? l10n.errorsServerCode(code)
            : l10n.errorsConnectionFailed;
    }
  }
  return l10n.errorsGeneric('$e');
}
