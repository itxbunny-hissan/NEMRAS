import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import 'clinical_ui.dart';

/// Collects and confirms a break-glass justification.
///
/// Returns the trimmed reason, or null when the clinician cancels. The reason
/// field cannot be skipped: the confirm action stays disabled until something
/// is typed, and an empty submission is rejected.
///
/// This is an interface control, not an authorisation mechanism. Real
/// emergency access has to be enforced and audited by the backend.
class BreakGlassDialog extends StatefulWidget {
  const BreakGlassDialog({super.key, required this.cnic});

  /// Shown back to the clinician so they can confirm the subject of the
  /// override before committing to it.
  final String cnic;

  static Future<String?> show(BuildContext context, {required String cnic}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BreakGlassDialog(cnic: cnic),
    );
  }

  @override
  State<BreakGlassDialog> createState() => _BreakGlassDialogState();
}

class _BreakGlassDialogState extends State<BreakGlassDialog> {
  final TextEditingController _reason = TextEditingController();
  bool _acknowledged = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _acknowledged && _reason.text.trim().isNotEmpty;

  void _confirm() {
    final reason = _reason.text.trim();
    if (reason.isEmpty || !_acknowledged) return;
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return AlertDialog(
      backgroundColor: semantics.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: NemrasRadii.cardBorder,
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        NemrasSpacing.section,
        NemrasSpacing.section,
        NemrasSpacing.section,
        NemrasSpacing.l,
      ),
      title: Row(
        children: <Widget>[
          Icon(
            Icons.lock_open_outlined,
            size: 18,
            color: semantics.critical.solid,
          ),
          const SizedBox(width: NemrasSpacing.s),
          Expanded(
            child: Text(
              'Break-glass access',
              style: NemrasTextStyles.screenTitle.copyWith(
                color: semantics.textPrimary,
              ),
            ),
          ),
          const DemoChip(),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClinicalAlertBox(
                title: 'This override is recorded',
                detail:
                    'Emergency access bypasses the ordinary clinical search '
                    'path. Your staff ID, the time and the reason you give '
                    'are written to the access audit.',
                status: semantics.critical,
              ),
              const SizedBox(height: NemrasSpacing.xl),
              ClinicalDataField(label: 'Subject CNIC', value: widget.cnic),
              const SizedBox(height: NemrasSpacing.xl),
              const ClinicalSectionLabel('Reason for emergency access'),
              const SizedBox(height: NemrasSpacing.xs),
              TextField(
                controller: _reason,
                autofocus: true,
                minLines: 3,
                maxLines: 4,
                maxLength: 240,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'For example: unconscious patient, no consent '
                      'obtainable, treating clinician on scene.',
                  hintStyle: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textPlaceholder,
                  ),
                  filled: true,
                  fillColor: semantics.inputBackground,
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
                    ),
                  ),
                ),
              ),
              CheckboxListTile(
                value: _acknowledged,
                onChanged: (value) =>
                    setState(() => _acknowledged = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I confirm this access is clinically necessary.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const ProvenanceNotice(
                message:
                    'DEMO: this build records the override in a '
                    'session-scoped audit list. It is not production-grade '
                    'authorization and is not a durable audit trail.',
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        NemrasSpacing.section,
        0,
        NemrasSpacing.section,
        NemrasSpacing.huge,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _canConfirm ? _confirm : null,
          style: FilledButton.styleFrom(
            backgroundColor: semantics.critical.solid,
            foregroundColor: semantics.critical.onSolid,
            disabledBackgroundColor: semantics.controlBackground,
            disabledForegroundColor: semantics.textPlaceholder,
          ),
          icon: const Icon(Icons.lock_open, size: 16),
          label: const Text('Record reason and open record'),
        ),
      ],
    );
  }
}
