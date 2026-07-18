import 'dart:typed_data';

/// Un delta distant du log du compte, identifié par son `seq` (curseur).
class RemoteDelta {
  final int seq;
  final Uint8List payload;

  const RemoteDelta({required this.seq, required this.payload});
}

/// Une page de deltas tirés + le plus grand `seq` du compte — indique s'il reste
/// des pages à tirer (`deltas.last.seq < latest`).
class DeltaPage {
  final List<RemoteDelta> deltas;
  final int latest;

  const DeltaPage({required this.deltas, required this.latest});
}

/// Snapshot du compte : un coffre entier (opaque) + le `seq` qu'il couvre. Le
/// curseur repart de [coversSeq] après application.
class RemoteSnapshot {
  final Uint8List payload;
  final int coversSeq;

  const RemoteSnapshot({required this.payload, required this.coversSeq});
}
