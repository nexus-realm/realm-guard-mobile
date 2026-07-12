import 'dart:typed_data';

import '../../../src/rust/api/opaque.dart';

/// Client OPAQUE côté appareil (abstraction pour la testabilité).
///
/// L'implémentation réelle délègue au FFI Rust ; les tests fournissent un faux.
abstract interface class OpaqueClient {
  Future<OpaqueClientStart> registerStart(String password);
  Future<OpaqueRegisterFinish> registerFinish(
    Uint8List state,
    String password,
    Uint8List response,
  );
  Future<OpaqueClientStart> loginStart(String password);
  Future<OpaqueLoginFinish> loginFinish(
    Uint8List state,
    String password,
    Uint8List response,
  );
}

/// Implémentation réelle : appelle les fonctions FFI générées. Elles sont
/// **asynchrones** (Argon2 exécuté hors de l'isolate principal).
class FrbOpaqueClient implements OpaqueClient {
  const FrbOpaqueClient();

  @override
  Future<OpaqueClientStart> registerStart(String password) =>
      opaqueRegisterStart(password: password);

  @override
  Future<OpaqueRegisterFinish> registerFinish(
    Uint8List state,
    String password,
    Uint8List response,
  ) => opaqueRegisterFinish(state: state, password: password, response: response);

  @override
  Future<OpaqueClientStart> loginStart(String password) =>
      opaqueLoginStart(password: password);

  @override
  Future<OpaqueLoginFinish> loginFinish(
    Uint8List state,
    String password,
    Uint8List response,
  ) => opaqueLoginFinish(state: state, password: password, response: response);
}
