import 'package:flutter_test/flutter_test.dart';
import 'package:nemras/dev/demo_auth.dart';

void main() {
  group('Demo authentication (DEVELOPMENT only)', () {
    test('accepts the demo CNIC with or without separators', () {
      expect(isDemoLogin('36302-2493960-7', kDemoOtp), isTrue);
      expect(isDemoLogin('3630224939607', kDemoOtp), isTrue);
    });

    test('rejects a wrong OTP', () {
      expect(isDemoLogin('36302-2493960-7', '000000'), isFalse);
      expect(isDemoLogin('36302-2493960-7', ''), isFalse);
    });

    test('rejects any other CNIC', () {
      expect(isDemoLogin('11111-1111111-1', kDemoOtp), isFalse);
      expect(isDemoLogin('', kDemoOtp), isFalse);
    });

    test('demo record is clearly synthetic and self-consistent', () {
      final record = buildDemoPatientRecord();
      expect(record.summary.cnic, '36302-2493960-7');
      expect(record.summary.allergy, 'Penicillin');
      expect(record.alerts, isNotEmpty);
    });

    test('demo auth is on by default for the viva build', () {
      // Disable with --dart-define=NEMRAS_DEMO_AUTH=false.
      expect(kDemoAuthEnabled, isTrue);
    });
  });
}
