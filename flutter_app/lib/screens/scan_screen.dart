import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../dev/demo_auth.dart';
import '../navigation/app_router.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _cnicCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _cnicFocus = FocusNode();
  final _otpFocus = FocusNode();
  final _localAuth = LocalAuthentication();

  bool _loading = false;
  bool _otpSent = false;
  String? _error;
  bool? _backendOnline;

  // Saved session
  String? _savedCnic;
  String? _savedName;
  bool _hasBiometric = false;
  List<BiometricType> _biometricTypes = [];

  // Manual form visible even when saved user exists
  bool _showManualForm = false;
  bool _citizenTab = true;
  bool _obscurePasscode = true;
  bool _rememberCnic = true;

  bool get _cnicValid =>
      RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(_cnicCtrl.text);
  bool get _otpValid => _otpCtrl.text.length == 6;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadSession();
  }

  @override
  void dispose() {
    _cnicCtrl.dispose();
    _otpCtrl.dispose();
    _cnicFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  // ── Session ────────────────────────────────────────────────

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cnic = prefs.getString('saved_cnic');
    final name = prefs.getString('saved_name');

    // Only treat the device as biometric-capable if local_auth can actually
    // perform a check. Anything else must fall back to manual sign-in.
    bool hasBio = false;
    List<BiometricType> types = [];
    try {
      hasBio = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (hasBio) types = await _localAuth.getAvailableBiometrics();
    } catch (_) {
      hasBio = false;
      types = [];
    }

    if (mounted) {
      setState(() {
        _savedCnic = cnic;
        _savedName = name;
        _hasBiometric = hasBio;
        _biometricTypes = types;
      });
    }
  }

  Future<void> _saveSession(String cnic, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_cnic', cnic);
    await prefs.setString('saved_name', name);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_cnic');
    await prefs.remove('saved_name');
    setState(() {
      _savedCnic = null;
      _savedName = null;
      _showManualForm = true;
    });
  }

  // ── Biometric ──────────────────────────────────────────────

  /// Biometric unlock of an already-established session.
  ///
  /// This is a convenience unlock, never an authentication bypass: if the
  /// device cannot perform a local-auth check, or the user fails/cancels it,
  /// the user is sent back to manual sign-in. There is deliberately no
  /// "no hardware means authenticated" path.
  ///
  /// TODO(production-auth): the unlocked session must carry a Firebase ID
  /// token that the backend verifies on every record request. Right now the
  /// unlock only gates the local UI, so the backend is still the component
  /// that must enforce authorisation.
  Future<void> _biometricLogin() async {
    if (_savedCnic == null) return;

    if (!_hasBiometric) {
      setState(() {
        _error = 'Biometric unlock is not available on this device. '
            'Please sign in with your CNIC and OTP.';
        _showManualForm = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan to access your NEMRAS health record',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (!authenticated) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Biometric check failed. Try again or sign in manually.';
          });
        }
        return;
      }
      if (!mounted) return;
      final record = await Api.getPatient(_savedCnic!);
      if (!mounted) return;
      Navigator.pushReplacement(context, AppRouter.patientShell(record));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      // local_auth platform failure - never fall through to authenticated.
      if (mounted) {
        setState(() {
          _error = 'Could not complete the biometric check. '
              'Please sign in with your CNIC and OTP.';
          _showManualForm = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Connection ─────────────────────────────────────────────

  Future<void> _checkConnection() async {
    final ok = await Api.ping();
    if (mounted) setState(() => _backendOnline = ok);
  }

  // ── OTP ────────────────────────────────────────────────────

  /// DEVELOPMENT/DEMO ONLY. No SMS is sent and nothing is verified
  /// server-side; see lib/dev/demo_auth.dart.
  ///
  /// TODO(production-auth): replace with
  /// FirebaseAuth.instance.verifyPhoneNumber(), after calling
  /// `/api/auth/phone/{cnic}` to confirm eligibility and show the masked
  /// number hint. The OTP must be generated and verified by Firebase, never
  /// by NEMRAS, and never pre-filled into the field.
  void _sendOtp() {
    setState(() => _error = null);
    if (!_cnicValid) {
      setState(() => _error = 'Enter a valid CNIC first.');
      return;
    }
    if (!kDemoAuthEnabled) {
      setState(() => _error =
          'OTP delivery is not configured in this build. Demo sign-in is disabled.');
      return;
    }
    _otpCtrl.text = kDemoOtp;
    setState(() => _otpSent = true);
    _otpFocus.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Demo OTP: $kDemoOtp  —  sent to registered number'),
      backgroundColor: NemrasColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Sign in ────────────────────────────────────────────────

  Future<void> _signIn() async {
    setState(() => _error = null);
    if (!_cnicValid) {
      setState(() => _error = 'Enter a valid CNIC (XXXXX-XXXXXXX-X).');
      return;
    }
    if (!_otpValid) {
      setState(() =>
          _error = 'Enter the 6-digit OTP. Tap "Send OTP" to receive it.');
      return;
    }

    // ---- DEVELOPMENT/DEMO LOGIN (works without backend) ----
    // Isolated in lib/dev/demo_auth.dart. Disable with
    // --dart-define=NEMRAS_DEMO_AUTH=false.
    if (isDemoLogin(_cnicCtrl.text, _otpCtrl.text)) {
      final demoRecord = buildDemoPatientRecord();
      if (!mounted) return;
      Navigator.pushReplacement(context, AppRouter.patientShell(demoRecord));
      return;
    }
    // ---- END DEVELOPMENT/DEMO LOGIN ----

    // TODO(production-auth): the OTP above is not verified by anything. Once
    // Firebase Phone Auth is in place, exchange the Firebase ID token with the
    // backend here and let the backend authorise the record lookup.
    setState(() => _loading = true);
    try {
      final record = await Api.getPatient(_cnicCtrl.text.trim());
      if (!mounted) return;
      if (_rememberCnic) {
        await _saveSession(_cnicCtrl.text.trim(), record.summary.patientName);
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, AppRouter.patientShell(record));
    } on ApiException catch (e) {
      setState(() => _error = e.isConnectivityIssue
          ? 'Cannot reach backend. Ensure it is running:\n'
              'cd backend && uvicorn main:app --host 0.0.0.0 --port 8000'
          : e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Scanner ────────────────────────────────────────────────

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CnicScannerSheet(
        onScanned: (raw) {
          Navigator.pop(context);
          final digits = raw.replaceAll(RegExp(r'\D'), '');
          final formatted = digits.length == 13
              ? '${digits.substring(0, 5)}-'
                '${digits.substring(5, 12)}-'
                '${digits[12]}'
              : raw;
          setState(() {
            _cnicCtrl.text = formatted;
            _error = null;
          });
          if (RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(formatted)) {
            _otpFocus.requestFocus();
          }
        },
      ),
    );
  }

  void _back() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(NemrasRouteNames.onboarding);
  }

  void _openForgotPassword() {
    Navigator.pushNamed(context, NemrasRouteNames.forgotPassword);
  }

  void _openSignUp() {
    Navigator.pushNamed(context, NemrasRouteNames.signUp);
  }

  void _biometricFromForm() {
    if (_savedCnic != null && _hasBiometric) {
      _biometricLogin();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
        'Device biometric unlock is available after one CNIC sign-in '
        'on this device. NADRA fingerprint sign-in is not available.',
      ),
    ));
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasSavedUser = _savedCnic != null && _savedName != null;
    final showBioFirst = hasSavedUser && _hasBiometric && !_showManualForm;

    return Scaffold(
      backgroundColor: _LoginPalette.canvas,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth - 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_backendOnline == false) ...[
                      _OfflineBanner(onRetry: _checkConnection),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: _back,
                          style: IconButton.styleFrom(
                            backgroundColor: _LoginPalette.card,
                            side: const BorderSide(color: _LoginPalette.border),
                            fixedSize: const Size(36, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.chevron_left, size: 18),
                        ),
                        const Spacer(),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: _LoginPalette.tealLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              'CNIC SIGN-IN',
                              style: NemrasTextStyles.tag.copyWith(
                                color: _LoginPalette.teal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign In to NEMRAS',
                      style: NemrasTextStyles.summaryName.copyWith(
                        fontSize: 24,
                        color: _LoginPalette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Access your health summary with your CNIC '
                      'and one-time passcode.',
                      style: NemrasTextStyles.bodySmall.copyWith(
                        fontSize: 13,
                        color: _LoginPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LoginTabs(
                      citizenSelected: _citizenTab,
                      onCitizen: () => setState(() => _citizenTab = true),
                      onStaff: () => setState(() => _citizenTab = false),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBox(_error!),
                    ],
                    const SizedBox(height: 14),
                    if (showBioFirst) ...[
                      Text(
                        'Welcome back,',
                        style: NemrasTextStyles.bodySmall.copyWith(
                          color: _LoginPalette.textSecondary,
                        ),
                      ),
                      Text(
                        _savedName!,
                        style: NemrasTextStyles.summaryName.copyWith(
                          fontSize: 22,
                          color: _LoginPalette.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_biometricTypes.contains(BiometricType.fingerprint) ||
                          _biometricTypes.isEmpty)
                        _BiometricCard(
                          icon: Icons.fingerprint,
                          label: 'Continue with device fingerprint',
                          loading: _loading,
                          onTap: _biometricLogin,
                        ),
                      if (_biometricTypes.contains(BiometricType.face)) ...[
                        const SizedBox(height: 12),
                        _BiometricCard(
                          icon: Icons.face_unlock_outlined,
                          label: 'Continue with device face unlock',
                          loading: _loading,
                          onTap: _biometricLogin,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _showManualForm = true),
                            child: const Text('Use a different account'),
                          ),
                          TextButton(
                            onPressed: _clearSession,
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    ],
                    if (!_citizenTab && !showBioFirst)
                      const _StaffUnavailable()
                    else if (!showBioFirst || _showManualForm) ...[
                      if (hasSavedUser) ...[
                        const SizedBox(height: 8),
                        Text(
                          'OR SIGN IN MANUALLY',
                          textAlign: TextAlign.center,
                          style: NemrasTextStyles.fieldLabel.copyWith(
                            color: _LoginPalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const _FieldHeading(
                        label: 'CNIC',
                        hint: '13 Digits',
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cnicCtrl,
                        focusNode: _cnicFocus,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [_CnicFormatter()],
                        style: NemrasTextStyles.dataValue.copyWith(
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: _LoginPalette.text,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: _fieldDecoration(
                          hint: 'XXXXX-XXXXXXX-X',
                          suffix: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_cnicValid)
                                const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: _LoginPalette.success,
                                ),
                              IconButton(
                                tooltip: 'Scan CNIC card',
                                onPressed: _openScanner,
                                icon: const Icon(
                                  Icons.document_scanner_outlined,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: _FieldHeading(
                              label: 'One-time passcode',
                              hint: '6 digits',
                            ),
                          ),
                          TextButton(
                            onPressed: _sendOtp,
                            style: TextButton.styleFrom(
                              foregroundColor: _LoginPalette.teal,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(_otpSent ? 'Resend OTP' : 'Send OTP'),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _otpCtrl,
                        focusNode: _otpFocus,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        obscureText: _obscurePasscode,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _signIn(),
                        decoration: _fieldDecoration(
                          hint: '6-digit code',
                          suffix: IconButton(
                            tooltip: _obscurePasscode
                                ? 'Show passcode'
                                : 'Hide passcode',
                            onPressed: () => setState(
                              () => _obscurePasscode = !_obscurePasscode,
                            ),
                            icon: Icon(
                              _obscurePasscode
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: _LoginPalette.textSecondary,
                            ),
                          ),
                        ).copyWith(counterText: ''),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          InkWell(
                            onTap: () => setState(
                              () => _rememberCnic = !_rememberCnic,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _rememberCnic
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                  color: _LoginPalette.teal,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Remember CNIC',
                                  style: NemrasTextStyles.bodySmall.copyWith(
                                    color: _LoginPalette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _openForgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: _LoginPalette.teal,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _LoginPalette.teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                _LoginPalette.teal.withValues(alpha: 0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Sign In Securely  →',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NemrasTextStyles.button.copyWith(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'DEVICE BIOMETRIC',
                              style: NemrasTextStyles.fieldLabel.copyWith(
                                color: _LoginPalette.textMuted,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _biometricFromForm,
                        icon: const Icon(Icons.fingerprint, size: 18),
                        label: const Text(
                          'Sign in with device fingerprint / face',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _LoginPalette.text,
                          backgroundColor: _LoginPalette.card,
                          side: const BorderSide(color: _LoginPalette.border),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const Key('open-dev-email-sign-in'),
                        onPressed: _loading
                            ? null
                            : () => Navigator.push(
                                  context,
                                  AppRouter.devEmailSignIn(),
                                ),
                        icon: const Icon(Icons.science_outlined, size: 18),
                        label: const Text('Developer sign-in (email test account)'),
                        style: TextButton.styleFrom(
                          foregroundColor: _LoginPalette.teal,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have a registered record? ",
                          style: NemrasTextStyles.bodySmall.copyWith(
                            color: _LoginPalette.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: _openSignUp,
                          style: TextButton.styleFrom(
                            foregroundColor: _LoginPalette.teal,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Create Citizen Account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required Widget suffix,
  }) {
    const radius = BorderRadius.all(Radius.circular(12));
    const enabled = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: _LoginPalette.border, width: 1.5),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _LoginPalette.textMuted, fontSize: 13),
      filled: true,
      fillColor: _LoginPalette.card,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: enabled,
      enabledBorder: enabled,
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _LoginPalette.teal, width: 1.5),
      ),
      suffixIcon: suffix,
    );
  }
}

abstract final class _LoginPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFFE8F6F3);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF16A34A);
  static const Color alertBg = Color(0xFFFEF2F2);
  static const Color alertBorder = Color(0xFFFECACA);
  static const Color alertText = Color(0xFF991B1B);
  static const Color track = Color(0xFFEDF2F7);
}

class _LoginTabs extends StatelessWidget {
  const _LoginTabs({
    required this.citizenSelected,
    required this.onCitizen,
    required this.onStaff,
  });

  final bool citizenSelected;
  final VoidCallback onCitizen;
  final VoidCallback onStaff;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _LoginPalette.track,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _LoginTab(
                label: 'Citizen / CNIC',
                selected: citizenSelected,
                onTap: onCitizen,
              ),
            ),
            Expanded(
              child: _LoginTab(
                label: 'Paramedic / Hospital ID',
                selected: !citizenSelected,
                onTap: onStaff,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _LoginPalette.card : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: selected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: NemrasTextStyles.chip.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? _LoginPalette.text : _LoginPalette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldHeading extends StatelessWidget {
  const _FieldHeading({required this.label, required this.hint});

  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NemrasTextStyles.listTitle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _LoginPalette.text,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          hint,
          style: NemrasTextStyles.dataCaption.copyWith(
            color: _LoginPalette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StaffUnavailable extends StatelessWidget {
  const _StaffUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Paramedic and hospital ID sign-in is not available on this screen. '
      'Use Citizen / CNIC. The paramedic console stays on its existing entry.',
      style: TextStyle(
        fontSize: 13,
        height: 1.45,
        color: _LoginPalette.textSecondary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Biometric card
// ─────────────────────────────────────────────────────────────
class _BiometricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _BiometricCard({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: NemrasColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NemrasColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _LoginPalette.tealLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _LoginPalette.teal))
                  : Icon(icon, color: _LoginPalette.teal, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _LoginPalette.text,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: _LoginPalette.textMuted),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// CNIC camera scanner bottom sheet
// ─────────────────────────────────────────────────────────────
class _CnicScannerSheet extends StatefulWidget {
  final ValueChanged<String> onScanned;
  const _CnicScannerSheet({required this.onScanned});

  @override
  State<_CnicScannerSheet> createState() => _CnicScannerSheetState();
}

class _CnicScannerSheetState extends State<_CnicScannerSheet> {
  final _ctrl = MobileScannerController();
  bool _detected = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.78;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        const Text('Scan CNIC Card',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Point at the barcode on the back of your CNIC',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(fit: StackFit.expand, children: [
                MobileScanner(
                  controller: _ctrl,
                  onDetect: (capture) {
                    if (_detected) return;
                    final code = capture.barcodes.isNotEmpty
                        ? capture.barcodes.first.rawValue
                        : null;
                    if (code != null) {
                      _detected = true;
                      widget.onScanned(code);
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 270,
                    height: 170,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(children: _cornerBrackets()),
                  ),
                ),
                const _ScanLine(),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
              color: Colors.white70,
            ),
            onPressed: () {
              _ctrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            tooltip: 'Toggle torch',
          ),
          const SizedBox(width: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }

  List<Widget> _cornerBrackets() {
    const s = 22.0;
    const t = 3.0;
    const c = NemrasColors.teal;
    return [
      Positioned(top: 0, left: 0, child: Container(width: s, height: t, color: c)),
      Positioned(top: 0, left: 0, child: Container(width: t, height: s, color: c)),
      Positioned(top: 0, right: 0, child: Container(width: s, height: t, color: c)),
      Positioned(top: 0, right: 0, child: Container(width: t, height: s, color: c)),
      Positioned(bottom: 0, left: 0, child: Container(width: s, height: t, color: c)),
      Positioned(bottom: 0, left: 0, child: Container(width: t, height: s, color: c)),
      Positioned(bottom: 0, right: 0, child: Container(width: s, height: t, color: c)),
      Positioned(bottom: 0, right: 0, child: Container(width: t, height: s, color: c)),
    ];
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Positioned(
          top: _anim.value * (MediaQuery.of(context).size.height * 0.38),
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                NemrasColors.teal.withValues(alpha: 0.8),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue val) {
    final digits = val.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 13) return old;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return val.copyWith(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: NemrasColors.red.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: NemrasColors.red.withValues(alpha: 0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.cloud_off, size: 16, color: NemrasColors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text('Backend offline — tap to retry',
                  style: TextStyle(
                      fontSize: 12,
                      color: NemrasColors.red,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.refresh, size: 16, color: NemrasColors.red),
          ]),
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _LoginPalette.alertBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _LoginPalette.alertBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 16, color: _LoginPalette.alertText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: _LoginPalette.alertText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}