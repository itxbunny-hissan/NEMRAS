import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nemras_design/nemras_design.dart';

import '../state/paramedic_session_controller.dart';
import '../widgets/paramedic_ui.dart';
import 'incoming_requests_screen.dart';

class ParamedicScanScreen extends StatefulWidget {
  const ParamedicScanScreen({
    super.key,
    required this.controller,
    required this.onOpenVoice,
  });

  final ParamedicSessionController controller;
  final VoidCallback onOpenVoice;

  @override
  State<ParamedicScanScreen> createState() => _ParamedicScanScreenState();
}

class _ParamedicScanScreenState extends State<ParamedicScanScreen> {
  final TextEditingController _cnic = TextEditingController();

  @override
  void dispose() {
    _cnic.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    FocusScope.of(context).unfocus();
    await widget.controller.lookupAndStartEmergency(_cnic.text);
  }

  Future<void> _openScanner() async {
    final scanned = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ParamedicScannerSheet(),
    );
    if (!mounted || scanned == null) return;
    _cnic.text = _formatCnic(scanned);
    await _lookup();
  }

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return ParamedicPage(
      title: 'Emergency Intake',
      subtitle: 'Scan or enter patient CNIC',
      controller: widget.controller,
      child: ListView(
        padding: const EdgeInsets.all(NemrasSpacing.xxl),
        children: <Widget>[
          FieldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'No unit is assigned',
                  style: NemrasTextStyles.summaryName,
                ),
                const SizedBox(height: NemrasSpacing.s),
                Text(
                  'Duty status is not connected. No priority dispatch is assigned.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.l),
                const SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    child: Text('Accept dispatch'),
                  ),
                ),
                const SizedBox(height: NemrasSpacing.s),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Theme(
                          data: nemrasFieldDarkTheme(),
                          child: IncomingRequestsScreen(
                            controller: widget.controller,
                          ),
                        ),
                      ),
                    ),
                    child: const Text('View all dispatches'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          FieldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.qr_code_scanner,
                  size: 58,
                  color: semantics.accent,
                ),
                const SizedBox(height: NemrasSpacing.xl),
                Text(
                  'Identify the patient',
                  style: NemrasTextStyles.summaryName,
                ),
                const SizedBox(height: NemrasSpacing.s),
                Text(
                  'Scan the CNIC barcode or enter the number manually. '
                  'Access starts a DEMO emergency session.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.xxl),
                const FieldSectionLabel('CNIC Number'),
                const SizedBox(height: NemrasSpacing.s),
                TextField(
                  key: const Key('paramedic-cnic-field'),
                  controller: _cnic,
                  keyboardType: TextInputType.number,
                  inputFormatters: const <TextInputFormatter>[
                    _ParamedicCnicFormatter(),
                  ],
                  onSubmitted: (_) => _lookup(),
                  style: NemrasTextStyles.dataValue,
                  decoration: InputDecoration(
                    hintText: 'XXXXX-XXXXXXX-X',
                    hintStyle: NemrasTextStyles.inputPlaceholder.copyWith(
                      color: semantics.textPlaceholder,
                    ),
                    filled: true,
                    fillColor: semantics.inputBackground,
                    suffixIcon: IconButton(
                      onPressed: _openScanner,
                      icon: const Icon(Icons.document_scanner_outlined),
                      tooltip: 'Scan CNIC',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: NemrasRadii.controlBorder,
                      borderSide: BorderSide(color: semantics.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: NemrasRadii.controlBorder,
                      borderSide: BorderSide(color: semantics.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: NemrasRadii.controlBorder,
                      borderSide: BorderSide(
                        color: semantics.inputBorderActive,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (widget.controller.lookupError != null) ...<Widget>[
                  const SizedBox(height: NemrasSpacing.xl),
                  Text(
                    widget.controller.lookupError!,
                    key: const Key('paramedic-lookup-error'),
                    style: NemrasTextStyles.bodySmall.copyWith(
                      color: semantics.critical.onSolid,
                    ),
                  ),
                ],
                const SizedBox(height: NemrasSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('paramedic-lookup-button'),
                    onPressed: widget.controller.isLookingUp ? null : _lookup,
                    icon: widget.controller.isLookingUp
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.emergency_outlined),
                    label: Text(
                      widget.controller.isLookingUp
                          ? 'Looking up…'
                          : 'Start Emergency Lookup',
                    ),
                  ),
                ),
                const SizedBox(height: NemrasSpacing.m),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onOpenVoice,
                    icon: const Icon(Icons.mic_none_outlined),
                    label: const Text('Use Voice / Handover Notes'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          FieldCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline, color: semantics.informational.solid),
                const SizedBox(width: NemrasSpacing.m),
                Expanded(
                  child: Text(
                    'DEMO mode uses the existing FastAPI lookup. CNIC entry '
                    'does not authenticate the paramedic and must not be used '
                    'as a production authorization boundary.',
                    style: NemrasTextStyles.bodyCaption.copyWith(
                      color: semantics.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParamedicCnicFormatter extends TextInputFormatter {
  const _ParamedicCnicFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _formatCnic(newValue.text);
    if (formatted.replaceAll('-', '').length > 13) return oldValue;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _formatCnic(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  final limited = digits.length > 13 ? digits.substring(0, 13) : digits;
  final buffer = StringBuffer();
  for (var index = 0; index < limited.length; index++) {
    if (index == 5 || index == 12) buffer.write('-');
    buffer.write(limited[index]);
  }
  return buffer.toString();
}

class _ParamedicScannerSheet extends StatefulWidget {
  const _ParamedicScannerSheet();

  @override
  State<_ParamedicScannerSheet> createState() => _ParamedicScannerSheetState();
}

class _ParamedicScannerSheetState extends State<_ParamedicScannerSheet> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(NemrasRadii.card),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            MobileScanner(
              controller: _scanner,
              onDetect: (capture) {
                if (_detected || capture.barcodes.isEmpty) return;
                final value = capture.barcodes.first.rawValue;
                if (value == null) return;
                _detected = true;
                Navigator.pop(context, value);
              },
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: NemrasRadii.metricBorder,
                    border: Border.all(
                      color: NemrasColors.fieldAccent,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: NemrasSpacing.xxl,
              left: NemrasSpacing.xxl,
              right: NemrasSpacing.xxl,
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Position CNIC barcode within frame',
                      style: TextStyle(color: NemrasColors.white),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close scanner',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
