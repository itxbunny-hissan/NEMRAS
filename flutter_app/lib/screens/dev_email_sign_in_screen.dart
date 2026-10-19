import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../api.dart';
import '../auth/auth_service.dart';
import '../auth/supabase_config.dart';

typedef IssuePatientId = Future<IssuedPatientId> Function(String accessToken);

/// DEVELOPMENT sign-in with a Supabase e-mail/password test account.
///
/// After signing in, the user can request their NEMRAS Patient ID from the
/// backend, which verifies the Supabase access token. The ID is not bound to
/// a CNIC and opens no patient record, so this screen deliberately does not
/// navigate into the patient shell.
class DevEmailSignInScreen extends StatefulWidget {
  const DevEmailSignInScreen({
    super.key,
    this.authService,
    this.issuePatientId,
    this.configCheck,
  });

  /// Injected in tests. Defaults to the app-wide Supabase session.
  final NemrasAuthService? authService;

  /// Injected in tests. Defaults to [Api.issueMyPatientId].
  final IssuePatientId? issuePatientId;

  /// Injected in tests. Defaults to the result of app start-up.
  final SupabaseConfigCheck? configCheck;

  @override
  State<DevEmailSignInScreen> createState() => _DevEmailSignInScreenState();
}

class _DevEmailSignInScreenState extends State<DevEmailSignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  NemrasAuthService? _auth;
  String? _configProblem;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  IssuedPatientId? _issued;

  @override
  void initState() {
    super.initState();
    final check = widget.configCheck ?? supabaseStartupCheck;
    if (widget.authService != null) {
      _auth = widget.authService;
    } else if (!check.isConfigured || !isSupabaseReady) {
      _configProblem =
          check.problem ?? 'Supabase sign-in is not configured in this build.';
    } else {
      try {
        _auth = NemrasAuthService.instance();
      } on AuthFailure catch (failure) {
        _configProblem = failure.message;
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _signedIn => _auth?.isSignedIn ?? false;

  Future<void> _signIn() async {
    final auth = _auth;
    if (auth == null) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Enter the test account email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.signInWithPassword(email: email, password: _passwordCtrl.text);
      _passwordCtrl.clear();
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _fetchPatientId();
  }

  Future<void> _fetchPatientId() async {
    final auth = _auth;
    if (auth == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await auth.accessToken();
      final issue = widget.issuePatientId ??
          (String accessToken) =>
              Api.issueMyPatientId(accessToken: accessToken);
      final issued = await issue(token);
      if (mounted) setState(() => _issued = issued);
    } on SignInRequired {
      if (mounted) {
        setState(() {
          _issued = null;
          _error = 'Your session has ended. Sign in again.';
        });
      }
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.kind == ApiErrorKind.unauthorized) {
          _error = 'The NEMRAS backend did not accept this session. Sign in '
              'again, and check that the backend has SUPABASE_URL configured.';
        } else if (error.isConnectivityIssue) {
          _error = 'Cannot reach the NEMRAS backend. Check that it is running '
              'and that NEMRAS_API_URL points to it.';
        } else {
          _error = error.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final auth = _auth;
    if (auth == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.signOut();
      if (mounted) setState(() => _issued = null);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer sign-in')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _Notice(
                  icon: Icons.science_outlined,
                  text: 'Development sign-in with a Supabase test account. '
                      'It authenticates you only: it is not linked to a CNIC '
                      'and opens no patient record.',
                ),
                const SizedBox(height: 20),
                if (_configProblem != null)
                  _Notice(
                    key: const Key('supabase-config-problem'),
                    icon: Icons.settings_outlined,
                    text: _configProblem!,
                    isError: true,
                  )
                else if (_signedIn)
                  ..._signedInContent()
                else
                  ..._signInForm(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _Notice(
                    key: const Key('dev-sign-in-error'),
                    icon: Icons.error_outline,
                    text: _error!,
                    isError: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _signInForm() {
    return [
      TextField(
        key: const Key('dev-email'),
        controller: _emailCtrl,
        enabled: !_busy,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.username],
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'Test account email'),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('dev-password'),
        controller: _passwordCtrl,
        enabled: !_busy,
        obscureText: _obscure,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => _signIn(),
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Show password' : 'Hide password',
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        key: const Key('dev-sign-in'),
        onPressed: _busy ? null : _signIn,
        child: _busy ? const _Spinner() : const Text('Sign in'),
      ),
    ];
  }

  List<Widget> _signedInContent() {
    final issued = _issued;
    final email = _auth?.signedInEmail;
    return [
      Text(
        email == null ? 'Signed in' : 'Signed in as $email',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      if (issued != null)
        Card(
          key: const Key('issued-patient-id'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your NEMRAS Patient ID'),
                const SizedBox(height: 8),
                SelectableText(
                  issued.displayId,
                  style: NemrasTextStyles.button.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text('Status: ${issued.status}'),
                const SizedBox(height: 8),
                const Text(
                  'Not linked to a CNIC. This ID does not open or authorise '
                  'access to any patient record.',
                ),
              ],
            ),
          ),
        )
      else
        FilledButton(
          key: const Key('dev-get-id'),
          onPressed: _busy ? null : _fetchPatientId,
          child: _busy ? const _Spinner() : const Text('Get my NEMRAS ID'),
        ),
      const SizedBox(height: 12),
      OutlinedButton(
        key: const Key('dev-sign-out'),
        onPressed: _busy ? null : _signOut,
        child: const Text('Sign out'),
      ),
    ];
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: color))),
      ],
    );
  }
}
