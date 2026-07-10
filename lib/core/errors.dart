import 'package:dio/dio.dart';

/// Message court et lisible pour l'utilisateur à partir d'une exception réseau.
String friendlyError(Object e) {
  if (e is UnimplementedError) {
    return e.message ?? 'Fonctionnalité indisponible.';
  }
  if (e is DioException) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) return 'Identifiants refusés.';
    if (code == 400) return 'Requête refusée par le serveur.';
    if (code == 404) return 'Instance ou API introuvable.';
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Délai dépassé — instance lente ou injoignable.';
      case DioExceptionType.connectionError:
        return 'Instance injoignable. Vérifie l\'URL.';
      default:
        return code != null ? 'Erreur $code du serveur.' : 'Connexion impossible.';
    }
  }
  return 'Erreur : $e';
}
