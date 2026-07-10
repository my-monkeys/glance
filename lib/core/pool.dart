import 'dart:async';

/// Exécute [tasks] avec au plus [concurrency] en vol simultanément, en
/// préservant l'ordre des résultats. Évite de saturer l'API quand un compte
/// suit beaucoup de sites.
Future<List<T>> mapPool<T>(
  int concurrency,
  List<Future<T> Function()> tasks,
) async {
  final results = List<T?>.filled(tasks.length, null);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      final i = next;
      if (i >= tasks.length) return;
      next++;
      results[i] = await tasks[i]();
    }
  }

  final workers = List.generate(
    concurrency.clamp(1, tasks.isEmpty ? 1 : tasks.length),
    (_) => worker(),
  );
  await Future.wait(workers);
  return results.cast<T>();
}
