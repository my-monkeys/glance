import 'package:flutter_timezone/flutter_timezone.dart';

String? _cached;

/// Fuseau IANA de l'appareil (« Europe/Paris »), résolu une fois. Repli sur UTC
/// si la plateforme ne le dit pas : mieux vaut des buckets décalés qu'une
/// requête qui ne part pas.
Future<String> deviceTimezone() async {
  if (_cached != null) return _cached!;
  try {
    _cached = (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    _cached = 'UTC';
  }
  return _cached!;
}
