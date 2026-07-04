import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/exceptions/vault_unlock_exception.dart';

void main() {
  group('VaultUnlockException', () {
    test('ne divulgue pas la cause sous-jacente dans toString', () {
      const secret = "PRAGMA key = x'internal-secret-detail'";
      final exception = VaultUnlockException(Exception(secret));

      expect(exception.toString(), 'VaultUnlockException');
      expect(exception.toString(), isNot(contains(secret)));
    });

    test('conserve la cause pour le diagnostic', () {
      final cause = Exception('boom');
      final exception = VaultUnlockException(cause);

      expect(exception.cause, same(cause));
    });
  });
}
