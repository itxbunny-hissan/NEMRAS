import 'package:flutter_test/flutter_test.dart';
import 'package:nemras/api.dart';

void main() {
  group('API configuration', () {
    test('base URL falls back to the development default', () {
      // No --dart-define in the test harness, so the default applies.
      expect(kBaseUrl, kDefaultApiUrl);
      expect(kBaseUrl, startsWith('http'));
    });
  });

  group('ApiException mapping', () {
    test('404 maps to notFound with the caller-supplied message', () {
      final e = Api.errorForStatus(404, notFoundMessage: 'No patient found.');
      expect(e.kind, ApiErrorKind.notFound);
      expect(e.statusCode, 404);
      expect(e.message, 'No patient found.');
      expect(e.isConnectivityIssue, isFalse);
    });

    test('503 maps to server with a start-up hint', () {
      final e = Api.errorForStatus(503);
      expect(e.kind, ApiErrorKind.server);
      expect(e.message, contains('unavailable'));
    });

    test('500 maps to server', () {
      expect(Api.errorForStatus(500).kind, ApiErrorKind.server);
    });

    test('422 maps to badRequest', () {
      final e = Api.errorForStatus(422);
      expect(e.kind, ApiErrorKind.badRequest);
      expect(e.statusCode, 422);
    });

    test('messages never leak the requested CNIC', () {
      for (final status in [400, 404, 422, 500, 503]) {
        expect(Api.errorForStatus(status).message, isNot(contains('-')));
      }
    });

    test('network and timeout are flagged as connectivity issues', () {
      expect(
        const ApiException(ApiErrorKind.network, 'x').isConnectivityIssue,
        isTrue,
      );
      expect(
        const ApiException(ApiErrorKind.timeout, 'x').isConnectivityIssue,
        isTrue,
      );
      expect(
        const ApiException(ApiErrorKind.decode, 'x').isConnectivityIssue,
        isFalse,
      );
    });
  });

  group('Response models', () {
    test('PatientSummary.fromJson fills defaults for missing fields', () {
      final s = PatientSummary.fromJson({'cnic': '11111-1111111-1'});
      expect(s.cnic, '11111-1111111-1');
      expect(s.patientName, '');
      expect(s.age, 0);
      expect(s.allergy, 'None');
      expect(s.chronicCondition, 'No');
    });

    test('DashboardStats.fromJson coerces counts and averages', () {
      final stats = DashboardStats.fromJson({
        'total_patients': 3,
        'avg_age': 41,
        'risk_score': {'Critical': 1, 'Stable': 2},
      });
      expect(stats.totalPatients, 3);
      expect(stats.avgAge, 41.0);
      expect(stats.riskScore['Critical'], 1);
      expect(stats.triageLevel, isEmpty);
    });

    test('Alert.fromJson defaults severity to info', () {
      expect(Alert.fromJson({'title': 'x'}).severity, 'info');
    });
  });
}
