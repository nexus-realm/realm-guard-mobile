import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/home/data/base32.dart';
import 'package:realmguard/features/home/data/totp_generator.dart';

// Secret de référence RFC 6238 : ASCII "12345678901234567890".
// Base32 = GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
const _rfcSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

DateTime _utc(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

void main() {
  group('Base32', () {
    test('décode le secret de référence (20 octets ASCII)', () {
      final bytes = Base32.decode(_rfcSecret);
      expect(bytes, '12345678901234567890'.codeUnits);
    });

    test('tolère espaces, casse et padding', () {
      expect(Base32.decode('JBSW Y3DP'), Base32.decode('jbswy3dp'));
    });

    test('isValid', () {
      expect(Base32.isValid('JBSWY3DP'), isTrue);
      expect(Base32.isValid(''), isFalse);
      expect(Base32.isValid('0189!'), isFalse); // 0,1,8,9 hors alphabet
    });
  });

  group('TotpGenerator (vecteurs RFC 6238, SHA-1, 8 digits)', () {
    // Valeurs officielles de la RFC 6238 (Appendix B).
    final cases = {
      59: '94287082',
      1111111109: '07081804',
      1111111111: '14050471',
      1234567890: '89005924',
      2000000000: '69279037',
    };

    cases.forEach((time, expected) {
      test('t=$time → $expected', () async {
        final code = await TotpGenerator.generate(
          secretBase32: _rfcSecret,
          digits: 8,
          algorithm: TotpAlgorithm.sha1,
          now: _utc(time),
        );
        expect(code, expected);
      });
    });
  });

  group('TotpGenerator - divers', () {
    test('génère 6 chiffres par défaut', () async {
      final code = await TotpGenerator.generate(secretBase32: _rfcSecret);
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('secret invalide → FormatException', () {
      expect(
        () => TotpGenerator.generate(secretBase32: '!!!'),
        throwsFormatException,
      );
    });

    test('remainingSeconds dans (0, period]', () {
      final r = TotpGenerator.remainingSeconds(
        period: 30,
        now: _utc(1000), // 1000 % 30 = 10 → reste 20
      );
      expect(r, 20);
    });

    test('progress dans [0,1)', () {
      final p = TotpGenerator.progress(period: 30, now: _utc(1000));
      expect(p, closeTo(10 / 30, 0.0001));
    });
  });
}
