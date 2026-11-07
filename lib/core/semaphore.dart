import 'dart:async';
import 'dart:collection';

/// Sémaphore asynchrone : plafonne le nombre d'opérations en vol. Utilisé pour
/// que le chargement incrémental (un provider par site) ne sature pas l'API
/// avec des dizaines de requêtes simultanées.
///
/// Une opération `urgent` passe devant toutes les autres en attente : c'est le
/// site affiché, qui ne doit pas attendre la barre latérale entière.
class Semaphore {
  Semaphore(this.max);

  final int max;
  int _inFlight = 0;
  final Queue<Completer<void>> _urgent = Queue();
  final Queue<Completer<void>> _waiters = Queue();

  Future<void> acquire({bool urgent = false}) {
    if (_inFlight < max) {
      _inFlight++;
      return Future.value();
    }
    final c = Completer<void>();
    (urgent ? _urgent : _waiters).add(c);
    return c.future;
  }

  void release() {
    if (_urgent.isNotEmpty) {
      _urgent.removeFirst().complete();
    } else if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    } else if (_inFlight > 0) {
      _inFlight--;
    }
  }

  /// Exécute [task] en tenant un jeton du sémaphore.
  Future<T> run<T>(Future<T> Function() task, {bool urgent = false}) async {
    await acquire(urgent: urgent);
    try {
      return await task();
    } finally {
      release();
    }
  }
}
