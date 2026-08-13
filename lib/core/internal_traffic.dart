import '../data/models/models.dart';

/// Trafic interne : visiteurs qu'un site suivi envoie vers un autre site
/// suivi, reconstitué en croisant les referrers de chaque site avec la liste
/// des domaines suivis (même principe que la vue « referrals » du dashboard
/// monkey, mais sur la fenêtre courante — pas de série journalière, trop
/// coûteuse en appels sur mobile).

/// Normalise un domaine tel qu'il apparaît en referrer (ou en `Site.domain`) :
/// minuscules, sans schéma, sans chemin/port, sans `www.`.
String normDomain(String raw) {
  var d = raw.trim().toLowerCase();
  d = d.replaceFirst(RegExp(r'^[a-z]+://'), '');
  d = d.split('/').first.split(':').first;
  if (d.startsWith('www.')) d = d.substring(4);
  return d;
}

/// Un flux source → destination sur la fenêtre.
class InternalFlow {
  const InternalFlow(this.from, this.to, this.visitors);
  final String from;
  final String to;
  final int visitors;
}

/// Agrégat par site (côté émetteur ou récepteur).
class InternalPeer {
  const InternalPeer(this.domain, this.total, this.flows);
  final String domain;
  final int total;

  /// Flux triés par visiteurs décroissants.
  final List<InternalFlow> flows;
}

class InternalTraffic {
  const InternalTraffic(this.flows);

  /// Croise les referrers de chaque destination avec les domaines suivis.
  /// [referrersByDest] : domaine normalisé du site destination → ses sources.
  factory InternalTraffic.build(
    Map<String, List<MetricRow>> referrersByDest,
    Set<String> knownDomains,
  ) {
    final flows = <InternalFlow>[];
    referrersByDest.forEach((dest, rows) {
      for (final r in rows) {
        final src = normDomain(r.label);
        if (r.value <= 0 || src == dest || !knownDomains.contains(src)) continue;
        flows.add(InternalFlow(src, dest, r.value));
      }
    });
    flows.sort((a, b) => b.visitors - a.visitors);
    return InternalTraffic(flows);
  }

  final List<InternalFlow> flows;

  bool get isEmpty => flows.isEmpty;

  int get total => flows.fold(0, (a, f) => a + f.visitors);

  List<InternalPeer> _group(String Function(InternalFlow) key) {
    final byKey = <String, List<InternalFlow>>{};
    for (final f in flows) {
      byKey.putIfAbsent(key(f), () => []).add(f);
    }
    final peers = byKey.entries
        .map((e) => InternalPeer(
              e.key,
              e.value.fold(0, (a, f) => a + f.visitors),
              e.value,
            ))
        .toList();
    peers.sort((a, b) => b.total - a.total);
    return peers;
  }

  /// Sites émetteurs, triés par visiteurs envoyés.
  List<InternalPeer> get sources => _group((f) => f.from);

  /// Sites récepteurs, triés par visiteurs reçus.
  List<InternalPeer> get destinations => _group((f) => f.to);
}
