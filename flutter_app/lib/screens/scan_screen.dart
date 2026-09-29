import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../api.dart';
import 'patient_shell.dart';

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

    bool hasBio = false;
    List<BiometricType> types = [];
    try {
      hasBio = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (hasBio) types = await _localAuth.getAvailableBiometrics();
    } catch (_) {}

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

  Future<void> _biometricLogin() async {
    if (_savedCnic == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      bool authenticated = false;
      if (_hasBiometric) {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Scan to access your NEMRAS health record',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      } else {
        authenticated = true; // fallback: no biometric hardware
      }
      if (!authenticated || !mounted) {
        setState(() => _loading = false);
        return;
      }
      final record = await Api.getPatient(_savedCnic!);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => PatientShell(record: record)));
    } catch (e) {
      setState(() => _error = 'Could not authenticate. Try manual login.');
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

  void _sendOtp() {
    setState(() => _error = null);
    if (!_cnicValid) {
      setState(() => _error = 'Enter a valid CNIC first.');
      return;
    }
    _otpCtrl.text = '123456';
    setState(() => _otpSent = true);
    _otpFocus.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Demo OTP: 123456  —  sent to registered number'),
      backgroundColor: AppTheme.primary,
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
    setState(() => _loading = true);
    try {
      final record = await Api.getPatient(_cnicCtrl.text.trim());
      if (!mounted) return;
      await _saveSession(_cnicCtrl.text.trim(), record.summary.patientName);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => PatientShell(record: record)));
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('timed out') ||
          msg.contains('SocketException') ||
          msg.contains('Connection refused')) {
        msg = 'Cannot reach backend. Ensure it is running:\n'
            'cd backend && uvicorn main:app --host 0.0.0.0 --port 8000';
      }
      setState(() => _error = msg);
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

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasSavedUser = _savedCnic != null && _savedName != null;
    final showBioFirst = hasSavedUser && _hasBiometric && !_showManualForm;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Offline banner
            if (_backendOnline == false) ...[
              _OfflineBanner(onRetry: _checkConnection),
              const SizedBox(height: 20),
            ],

            // ── Logo ────────────────────────────────────────
            Center(
              child: Column(children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 10),
                const Text('NEMRAS',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        letterSpacing: 1.5)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('PATIENT',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8)),
                ),
              ]),
            ),
            const SizedBox(height: 36),

            // ── Returning user — biometric CTA ──────────────
            if (showBioFirst) ...[
              const Text(
                'Welcome back,',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.muted),
              ),
              const SizedBox(height: 2),
              Text(_savedName!,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink)),
              const SizedBox(height: 28),

              // Fingerprint card
              if (_biometricTypes.contains(BiometricType.fingerprint) ||
                  _biometricTypes.isEmpty)
                _BiometricCard(
                  icon: Icons.fingerprint,
                  label: 'Continue with Fingerprint',
                  loading: _loading,
                  onTap: _biometricLogin,
                ),
              if (_biometricTypes.contains(BiometricType.face)) ...[
                const SizedBox(height: 12),
                _BiometricCard(
                  icon: Icons.face_unlock_outlined,
                  label: 'Sign in with Face ID',
                  loading: _loading,
                  onTap: _biometricLogin,
                ),
              ],

              const SizedBox(height: 24),
              // Error
              if (_error != null) _ErrorBox(_error!),
              const SizedBox(height: 8),

              // "Use different account" link
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  onTap: () => setState(() => _showManualForm = true),
                  child: const Text('Use a different account',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _clearSession,
                  child: Text('Sign out',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.muted.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            ],

            // ── Manual login form ────────────────────────────
            if (!showBioFirst || _showManualForm) ...[
              if (!hasSavedUser) ...[
                const Text('Welcome back',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink)),
                const SizedBox(height: 6),
                const Text(
                    'Enter your CNIC to access your medical record.',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.muted, height: 1.4)),
                const SizedBox(height: 28),
              ] else ...[
                const SizedBox(height: 16),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR SIGN IN MANUALLY',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.muted.withValues(alpha: 0.7),
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 24),
              ],

              // CNIC field
              const _FieldLabel('CNIC NUMBER'),
              const SizedBox(height: 7),
              TextField(
                controller: _cnicCtrl,
                focusNode: _cnicFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [_CnicFormatter()],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'XXXXX-XXXXXXX-X',
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: _fieldBorder(),
                  enabledBorder: _fieldBorder(),
                  focusedBorder: _focusBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.document_scanner_outlined,
                            size: 21),
                        color: AppTheme.primary,
                        tooltip: 'Scan CNIC card',
                        onPressed: _openScanner,
                      ),
                      if (_cnicValid)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.check_circle,
                              color: AppTheme.stable, size: 21),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // OTP field
              Row(children: [
                const _FieldLabel('ONE-TIME PASSWORD'),
                const Spacer(),
                GestureDetector(
                  onTap: _sendOtp,
                  child: Text(
                    _otpSent ? 'Resend OTP' : 'Send OTP',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
              const SizedBox(height: 7),
              TextField(
                controller: _otpCtrl,
                focusNode: _otpFocus,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _signIn(),
                decoration: InputDecoration(
                  hintText: '6-digit code from SMS',
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: _fieldBorder(),
                  enabledBorder: _fieldBorder(),
                  focusedBorder: _focusBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(Icons.lock_outline,
                        size: 20,
                        color: _otpValid
                            ? AppTheme.primary
                            : AppTheme.muted),
                  ),
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBox(_error!),
              ],
              const SizedBox(height: 22),

              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor:
                        AppTheme.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Sign In Securely',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),

              // Biometric quick-login when no saved user
              if (!hasSavedUser && _hasBiometric) ...[
                const SizedBox(height: 26),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('OR CONTINUE WITH',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.muted.withValues(alpha: 0.75),
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 22),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _AltButton(
                    icon: Icons.fingerprint,
                    tooltip: 'Fingerprint',
                    onTap: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                      content: Text(
                          'Sign in once to enable biometric login'),
                    )),
                  ),
                  if (_biometricTypes.contains(BiometricType.face)) ...[
                    const SizedBox(width: 20),
                    _AltButton(
                      icon: Icons.face_unlock_outlined,
                      tooltip: 'Face ID',
                      onTap: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text(
                            'Sign in once to enable Face ID'),
                      )),
                    ),
                  ],
                ]),
              ],
            ],
          ]),
        ),
      ),
    );
  }

  OutlineInputBorder _fieldBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE2EAEC)),
      );

  OutlineInputBorder _focusBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      );
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
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EAEC)),
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
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary))
                  : Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.muted),
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
    const c = AppTheme.primary;
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
                AppTheme.primary.withValues(alpha: 0.8),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.muted,
          letterSpacing: 0.6));
}

class _AltButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _AltButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFE2EAEC)),
            ),
            child: Icon(icon, size: 30, color: AppTheme.ink),
          ),
        ),
      );
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
            color: AppTheme.critical.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppTheme.critical.withValues(alpha: 0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.cloud_off, size: 16, color: AppTheme.critical),
            SizedBox(width: 8),
            Expanded(
              child: Text('Backend offline — tap to retry',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.critical,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.refresh, size: 16, color: AppTheme.critical),
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
          color: AppTheme.critical.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppTheme.critical.withValues(alpha: 0.3)),
        ),
        child: Text(message,
            style: const TextStyle(
                color: AppTheme.critical,
                fontSize: 12.5,
                height: 1.4)),
      );
}
