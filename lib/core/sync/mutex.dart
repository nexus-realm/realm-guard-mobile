import 'dart:async';

/// Verrou d'exclusion mutuelle **asynchrone** : sérialise des sections critiques
/// `async` en file **FIFO**. Une action qui lève ne bloque pas les suivantes
/// (l'erreur est propagée à son appelant, la file avance).
///
/// Sert à sérialiser tous les *read-modify-write* du doc CRDT (`crdt_docs`, ligne
/// unique) — écritures locales (`VaultCrdt`) et tirages (`SyncEngine`) — pour
/// qu'ils ne s'entrelacent pas (sinon : doc écrasé, curseur régressé). Le verrou
/// est **partagé par session** (créé par `VaultService`, passé aux deux).
class Mutex {
  Future<void> _tail = Future<void>.value();

  /// Exécute [action] en exclusion mutuelle ; renvoie son résultat (ou propage
  /// son erreur). Les appels concurrents s'exécutent l'un après l'autre, dans
  /// l'ordre d'arrivée.
  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _tail;
    // La prochaine action attend la fin de celle-ci (succès *ou* échec).
    _tail = completer.future.then((_) {}, onError: (_) {});
    previous.whenComplete(() {
      action().then(completer.complete, onError: completer.completeError);
    });
    return completer.future;
  }
}
