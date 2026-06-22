import 'package:flutter_test/flutter_test.dart';
import 'package:realm_guard_mobile/features/home/data/otpauth_parser.dart';

void main() {
  group('OtpauthParser.parse', () {
    test('extrait label, compte et secret d\'une URI complète', () {
      final draft = OtpauthParser.parse(
        'otpauth://totp/GitHub:me@example.com'
        '?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&digits=6&period=30&algorithm=SHA1',
      );
      expect(draft.label, 'GitHub');
      expect(draft.account, 'me@example.com');
      expect(draft.secret, 'JBSWY3DPEHPK3PXP');
      expect(draft.digits, 6);
      expect(draft.period, 30);
      expect(draft.algorithm, 'SHA1');
    });

    test('applique les valeurs par défaut si paramètres absents', () {
      final draft = OtpauthParser.parse(
        'otpauth://totp/Service?secret=JBSWY3DPEHPK3PXP',
      );
      expect(draft.digits, 6);
      expect(draft.period, 30);
      expect(draft.algorithm, 'SHA1');
      expect(draft.account, isNull);
      expect(draft.label, 'Service');
    });

    test('issuer du query prime sur celui du label', () {
      final draft = OtpauthParser.parse(
        'otpauth://totp/Ancien:me@x.com?secret=JBSWY3DPEHPK3PXP&issuer=Nouveau',
      );
      expect(draft.label, 'Nouveau');
      expect(draft.account, 'me@x.com');
    });

    test('gère les paramètres SHA256 / digits 8 / period 60', () {
      final draft = OtpauthParser.parse(
        'otpauth://totp/X?secret=JBSWY3DPEHPK3PXP'
        '&algorithm=SHA256&digits=8&period=60',
      );
      expect(draft.algorithm, 'SHA256');
      expect(draft.digits, 8);
      expect(draft.period, 60);
    });

    test('rejette un schéma non otpauth', () {
      expect(
        () => OtpauthParser.parse('https://example.com'),
        throwsFormatException,
      );
    });

    test('rejette un type hotp', () {
      expect(
        () => OtpauthParser.parse('otpauth://hotp/X?secret=JBSWY3DPEHPK3PXP'),
        throwsFormatException,
      );
    });

    test('rejette un secret invalide', () {
      expect(
        () => OtpauthParser.parse('otpauth://totp/X?secret=1189!!'),
        throwsFormatException,
      );
    });

    test('canParse reflète la validité', () {
      expect(
        OtpauthParser.canParse('otpauth://totp/X?secret=JBSWY3DPEHPK3PXP'),
        isTrue,
      );
      expect(OtpauthParser.canParse('pas une uri'), isFalse);
    });
  });
}
