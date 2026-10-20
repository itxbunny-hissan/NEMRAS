import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nemras_design/nemras_design.dart';

import '../navigation/clinical_navigation.dart';
import '../state/hospital_session_controller.dart';
import '../state/session_scope.dart';
import '../widgets/break_glass_dialog.dart';
import '../widgets/clinical_ui.dart';

/// Screen 4 — Patient search.
///
/// Looks a record up by CNIC against the NEMRAS backend. Two paths are
/// offered: an ordinary clinical search, and break-glass access that requires
/// a typed reason and writes an audit event.
///
/// The CNIC is only a lookup key here. It is not an authentication factor, and
/// the backend remains responsible for authorising the read — a point the
/// screen states rather than implies.
class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  final TextEditingController _cnic = TextEditingController();

  @override
  void dispose() {
    _cnic.dispose();
    super.dispose();
  }

  Future<void> _search(HospitalSessionController controller) async {
    final found = await controller.lookUpPatient(_cnic.text);
    if (!mounted) return;
    if (found) {
      widget.onNavigate(HospitalClinicalNavigation.clinicalRecordsIndex);
    }
  }

  Future<void> _breakGlass(HospitalSessionController controller) async {
    final cnic = _cnic.text.trim();
    if (cnic.isEmpty) {
      await controller.lookUpPatient(cnic);
      return;
    }
    final reason = await BreakGlassDialog.show(context, cnic: cnic);
    if (reason == null || !mounted) return;

    final found = await controller.lookUpPatient(
      cnic,
      basis: RecordAccessBasis.breakGlass,
      breakGlassReason: reason,
    );
    if (!mounted) return;
    if (found) {
      widget.onNavigate(HospitalClinicalNavigation.clinicalRecordsIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final busy = controller.recordState == LoadState.loading;

    return ClinicalContentArea(
      maxWidth: 860,
      children: <Widget>[
        ClinicalCard(
          title: 'Patient lookup by CNIC',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Enter the 13-digit CNIC exactly as it is recorded.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xl),
              TextField(
                controller: _cnic,
                enabled: !busy,
                autofocus: true,
                style: NemrasTextStyles.dataValue.copyWith(
                  color: semantics.textPrimary,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                onSubmitted: busy ? null : (_) => _search(controller),
                decoration: InputDecoration(
                  hintText: '00000-0000000-0',
                  hintStyle: NemrasTextStyles.dataValue.copyWith(
                    color: semantics.textPlaceholder,
                  ),
                  prefixIcon: const Icon(Icons.badge_outlined, size: 18),
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
              const SizedBox(height: NemrasSpacing.xl),
              Wrap(
                spacing: NemrasSpacing.l,
                runSpacing: NemrasSpacing.l,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: busy ? null : () => _search(controller),
                    icon: busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search, size: 16),
                    label: Text(busy ? 'Searching…' : 'Open record'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _breakGlass(controller),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: semantics.critical.onSoft,
                      side: BorderSide(color: semantics.critical.solid),
                    ),
                    icon: const Icon(Icons.lock_open_outlined, size: 16),
                    label: const Text('Break-glass access'),
                  ),
                ],
              ),
              if (controller.recordState == LoadState.failed &&
                  controller.recordError != null) ...<Widget>[
                const SizedBox(height: NemrasSpacing.xl),
                ClinicalAlertBox(
                  title: 'Lookup failed',
                  detail: controller.recordError!,
                  status: semantics.critical,
                ),
              ],
            ],
          ),
        ),
        const ProvenanceNotice(
          icon: Icons.gpp_maybe_outlined,
          message:
              'A CNIC entered here is a lookup key, not proof of identity. '
              'The NEMRAS backend is the authorization boundary; the record '
              'endpoint this screen calls is not authenticated yet, which is '
              'a known and separately reported gap.',
        ),
        ClinicalCard(
          title: 'Break-glass access',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Emergency access requires a typed reason before the record '
                'opens. The reason, your staff ID and the time are written '
                'to the access audit, and the record is then visibly marked '
                'as break-glass.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              Text(
                'This is an interface control. It is not production-grade '
                'authorization, which has to be enforced and audited by the '
                'backend.',
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
