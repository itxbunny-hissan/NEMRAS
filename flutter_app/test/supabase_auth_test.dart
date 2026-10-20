import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nemras/api.dart';
import 'package:nemras/auth/auth_service.dart';
import 'package:nemras/auth/supabase_config.dart';
import 'package:nemras/screens/dev_email_sign_in_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// No test here contacts Supabase or the NEMRAS backend. HTTP is served by
/// MockClient, and every token is an unsigned placeholder built below.

const _projectUrl = 'https://nemras-test-project.supabase.co';

String _b64(Map<String, Object?> json) =>
    base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

/// A JWT-shaped placeholder. It is unsigned and not a credential.
String _placeholderJwt(Map<String, Object?> claims) =>
    '${_b64({'alg': 'none'})}.${_b64(claims)}.placeholder-signature';

int _epoch(Duration offset) =>
    DateTime.now().add(offset).millisecondsSinceEpoch ~/ 1000;

Map<String, Object?> _sessionJson(
    {Duration expiresIn = const Duration(hours: 1)}) {
  final exp = _epoch(expiresIn);
  return {
    'access_token': _placeholderJwt({'sub': 'user-1', 'exp': exp}),
    'token_type': 'bearer',
    'expires_in': expiresIn.inSeconds,
    'expires_at': exp,
    'refresh_token': 'placeholder-refresh',
    'user': {
      'id': '8f14e45f-ceea-467a-9575-6a2f1c2b9e0d',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'demo-user@example.test',
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'created_at': '2026-10-01T00:00:00Z',
    },
  };
}

http.Response _json(int status, Object body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

/// Records every request and answers by path.
class _FakeSupabase {
  _FakeSupabase(this._handler);

  final http.Response Function(http.Request request) _handler;
  final requests = <http.Request>[];

  late final client = MockClient((request) async {
    requests.add(request);
    return _handler(request);
  });

  NemrasAuthService service() => NemrasAuthService(
        GoTrueClient(
          url: '$_projectUrl/auth/v1',
          headers: {'apikey': 'sb_publishable_placeholder'},
          httpClient: client,
          autoRefreshToken: false,
          flowType: AuthFlowType.implicit,
        ),
      );
}

http.Response _signInOk(http.Request request) {
  if (request.url.path.endsWith('/token')) return _json(200, _sessionJson());
  if (request.url.path.endsWith('/logout')) return http.Response('', 204);
  return _json(404, {'msg': 'not found'});
}

void main() {
  group('SupabaseConfig.validate', () {
    SupabaseConfigCheck check(String url, String key) =>
        SupabaseConfig.validate(url: url, publishableKey: key);

    test('the test harness build is not configured', () {
      expect(SupabaseConfig.current.isConfigured, isFalse);
      expect(SupabaseConfig.current.problem, contains('--dart-define'));
    });

    test('accepts a publishable key and normalises the URL', () {
      final result = check('$_projectUrl/', 'sb_publishable_abc');
      expect(result.isConfigured, isTrue);
      expect(result.config!.url, _projectUrl);
    });

    test('accepts a legacy anon JWT key', () {
      final anon = _placeholderJwt({'role': 'anon', 'iss': 'supabase'});
      expect(check(_projectUrl, anon).isConfigured, isTrue);
    });

    test('accepts the local Supabase CLI over http', () {
      expect(
        check('http://127.0.0.1:54321', 'sb_publishable_abc').config!.url,
        'http://127.0.0.1:54321',
      );
    });

    test('refuses secret and service-role keys without echoing them', () {
      const secret = 'sb_secret_DO_NOT_SHIP';
      final serviceRole = _placeholderJwt({'role': 'service_role'});
      for (final key in [secret, serviceRole]) {
        final result = check(_projectUrl, key);
        expect(result.isConfigured, isFalse);
        expect(result.problem, contains('SECRET key'));
        expect(result.problem, isNot(contains(key)));
      }
    });

    test('refuses unknown key formats and a missing key', () {
      expect(check(_projectUrl, 'just-some-string').isConfigured, isFalse);
      expect(check(_projectUrl, '').problem, contains('missing'));
    });

    test('refuses non-https and non-root URLs', () {
      for (final url in [
        'http://nemras-test-project.supabase.co',
        '$_projectUrl/auth/v1',
        '$_projectUrl?x=1',
        'nemras-test-project.supabase.co',
      ]) {
        expect(check(url, 'sb_publishable_abc').isConfigured, isFalse,
            reason: url);
      }
    });
  });

  group('mapAuthException', () {
    test('invalid credentials and unconfirmed email get fixed messages', () {
      expect(
        mapAuthException(const AuthApiException('server text',
                statusCode: '400', code: 'invalid_credentials'))
            .kind,
        AuthFailureKind.invalidCredentials,
      );
      expect(
        mapAuthException(const AuthApiException('server text',
                statusCode: '400', code: 'email_not_confirmed'))
            .kind,
        AuthFailureKind.emailNotConfirmed,
      );
    });

    test('network errors map to network, unknown errors hide server text', () {
      expect(
        mapAuthException(AuthRetryableFetchException()).kind,
        AuthFailureKind.network,
      );
      final unknown = mapAuthException(
          const AuthApiException('secret server detail', statusCode: '500'));
      expect(unknown.kind, AuthFailureKind.unknown);
      expect(unknown.message, isNot(contains('secret server detail')));
    });
  });

  group('NemrasAuthService', () {
    test('accessToken without a session throws SignInRequired', () async {
      final fake = _FakeSupabase(_signInOk);
      await expectLater(
        fake.service().accessToken(),
        throwsA(isA<SignInRequired>()),
      );
    });

    test('signs in, returns the session access token, and signs out', () async {
      final fake = _FakeSupabase(_signInOk);
      final auth = fake.service();

      await auth.signInWithPassword(
          email: ' demo-user@example.test ', password: 'pw');

      expect(auth.isSignedIn, isTrue);
      expect(auth.signedInEmail, 'demo-user@example.test');
      expect(await auth.accessToken(), startsWith(_b64({'alg': 'none'})));
      final signIn = fake.requests.single;
      expect(signIn.url.queryParameters['grant_type'], 'password');
      expect(jsonDecode(signIn.body)['email'], 'demo-user@example.test');

      await auth.signOut();
      expect(auth.isSignedIn, isFalse);
      await expectLater(auth.accessToken(), throwsA(isA<SignInRequired>()));
    });

    test('wrong password becomes invalidCredentials', () async {
      final fake = _FakeSupabase((_) => _json(400, {
            'code': 'invalid_credentials',
            'msg': 'Invalid login credentials',
          }));

      await expectLater(
        fake.service().signInWithPassword(email: 'a@b.test', password: 'x'),
        throwsA(isA<AuthFailure>()
            .having((f) => f.kind, 'kind', AuthFailureKind.invalidCredentials)),
      );
    });

    test('an unreachable server becomes a network failure', () async {
      final fake = _FakeSupabase(
          (_) => throw http.ClientException('connection refused'));

      await expectLater(
        fake.service().signInWithPassword(email: 'a@b.test', password: 'x'),
        throwsA(isA<AuthFailure>()
            .having((f) => f.kind, 'kind', AuthFailureKind.network)),
      );
    });

    test('an expired session that cannot refresh requires sign-in', () async {
      final fake = _FakeSupabase((request) {
        if (request.url.queryParameters['grant_type'] == 'password') {
          return _json(
              200, _sessionJson(expiresIn: const Duration(minutes: -5)));
        }
        return _json(400, {
          'code': 'refresh_token_not_found',
          'msg': 'Invalid Refresh Token',
        });
      });
      final auth = fake.service();
      await auth.signInWithPassword(email: 'a@b.test', password: 'x');

      await expectLater(auth.accessToken(), throwsA(isA<SignInRequired>()));
    });

    test('sign-out clears the local session even if the server fails',
        () async {
      final fake = _FakeSupabase((request) =>
          request.url.path.endsWith('/token')
              ? _json(200, _sessionJson())
              : _json(500, {'msg': 'down'}));
      final auth = fake.service();
      await auth.signInWithPassword(email: 'a@b.test', password: 'x');

      await auth.signOut();

      expect(auth.isSignedIn, isFalse);
    });
  });

  group('Api.issueMyPatientId', () {
    const issued = {
      'nemras_id': '1234567890128',
      'display_id': '1234 5678 9012 8',
      'status': 'active',
      'created_at': '2026-10-20T00:00:00.000000Z',
      'issued_at': '2026-10-20T00:00:00.000000Z',
      'newly_issued': true,
      'binding_status': 'not_bound',
      'record_access': 'none',
      'detail': 'not bound',
    };

    test('sends the token only as a Bearer Authorization header', () async {
      late http.Request seen;
      final client = MockClient((request) async {
        seen = request;
        return _json(201, issued);
      });

      final result = await Api.issueMyPatientId(
          accessToken: 'placeholder-access-token', client: client);

      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/v1/me/patient-id');
      expect(seen.headers['Authorization'], 'Bearer placeholder-access-token');
      expect(seen.url.query, isEmpty);
      expect(seen.body, isEmpty);
      expect(result.displayId, '1234 5678 9012 8');
      expect(result.bindingStatus, 'not_bound');
    });

    test('401 maps to unauthorized', () async {
      final client = MockClient((_) async =>
          _json(401, {'detail': 'Invalid or missing access token.'}));

      await expectLater(
        Api.issueMyPatientId(accessToken: 'x', client: client),
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
      );
    });
  });

  group('DevEmailSignInScreen', () {
    Future<void> pump(WidgetTester tester, Widget screen) async {
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pump();
    }

    testWidgets('explains missing configuration', (tester) async {
      await pump(tester, const DevEmailSignInScreen());

      expect(find.byKey(const Key('supabase-config-problem')), findsOneWidget);
      expect(find.textContaining('--dart-define'), findsOneWidget);
      expect(find.byKey(const Key('dev-sign-in')), findsNothing);
    });

    testWidgets('shows the issued ID after sign-in, never the token',
        (tester) async {
      final fake = _FakeSupabase(_signInOk);
      String? tokenSentToBackend;
      await pump(
        tester,
        DevEmailSignInScreen(
          authService: fake.service(),
          issuePatientId: (token) async {
            tokenSentToBackend = token;
            return IssuedPatientId.fromJson(const {
              'nemras_id': '1234567890128',
              'display_id': '1234 5678 9012 8',
              'status': 'active',
              'created_at': '2026-10-20T00:00:00Z',
              'binding_status': 'not_bound',
              'newly_issued': true,
            });
          },
        ),
      );

      await tester.enterText(
          find.byKey(const Key('dev-email')), 'demo-user@example.test');
      await tester.enterText(find.byKey(const Key('dev-password')), 'pw');
      await tester.tap(find.byKey(const Key('dev-sign-in')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('issued-patient-id')), findsOneWidget);
      expect(find.text('1234 5678 9012 8'), findsOneWidget);
      expect(find.textContaining('Not linked to a CNIC'), findsOneWidget);
      expect(tokenSentToBackend, isNotNull);
      expect(find.textContaining(tokenSentToBackend!), findsNothing);

      await tester.tap(find.byKey(const Key('dev-sign-out')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dev-sign-in')), findsOneWidget);
    });

    testWidgets('shows a safe message for wrong credentials', (tester) async {
      final fake = _FakeSupabase((_) => _json(400, {
            'code': 'invalid_credentials',
            'msg': 'Invalid login credentials',
          }));
      await pump(tester, DevEmailSignInScreen(authService: fake.service()));

      await tester.enterText(find.byKey(const Key('dev-email')), 'a@b.test');
      await tester.enterText(find.byKey(const Key('dev-password')), 'wrong');
      await tester.tap(find.byKey(const Key('dev-sign-in')));
      await tester.pumpAndSettle();

      expect(find.text('Email or password is incorrect.'), findsOneWidget);
      expect(find.byKey(const Key('issued-patient-id')), findsNothing);
    });

    testWidgets('explains a backend 401 without signing the user out',
        (tester) async {
      final fake = _FakeSupabase(_signInOk);
      await pump(
        tester,
        DevEmailSignInScreen(
          authService: fake.service(),
          issuePatientId: (_) async => throw Api.errorForStatus(401),
        ),
      );

      await tester.enterText(find.byKey(const Key('dev-email')), 'a@b.test');
      await tester.enterText(find.byKey(const Key('dev-password')), 'pw');
      await tester.tap(find.byKey(const Key('dev-sign-in')));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('did not accept this session'), findsOneWidget);
      expect(find.byKey(const Key('dev-get-id')), findsOneWidget);
    });
  });
}
