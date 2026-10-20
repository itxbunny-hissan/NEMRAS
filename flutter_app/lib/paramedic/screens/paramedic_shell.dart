import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import '../state/paramedic_session_controller.dart';
import 'emergency_patient_summary_screen.dart';
import 'paramedic_drugs_screen.dart';
import 'paramedic_handover_screen.dart';
import 'paramedic_scan_screen.dart';
import 'paramedic_voice_screen.dart';

/// Role-specific mobile shell for the dark NEMRAS field surface.
///
/// It shares the Phase 1A/1B design and layout packages with the Patient shell
/// but owns separate state and screens. The default Patient flow is untouched.
class ParamedicShell extends StatefulWidget {
  const ParamedicShell({
    super.key,
    this.initialIndex = 0,
    this.controller,
  });

  final int initialIndex;
  final ParamedicSessionController? controller;

  @override
  State<ParamedicShell> createState() => _ParamedicShellState();
}

class _ParamedicShellState extends State<ParamedicShell> {
  static final NemrasRoleConfig _role =
      NemrasRoleConfig.of(NemrasRole.paramedic);

  late final ParamedicSessionController _controller =
      widget.controller ?? ParamedicSessionController();
  late final bool _ownsController = widget.controller == null;
  late int _tab = widget.initialIndex.clamp(0, _role.navigation.length - 1);

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _select(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: nemrasFieldDarkTheme(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scanSurface = _controller.hasActiveEmergency
              ? EmergencyPatientSummaryScreen(
                  controller: _controller,
                  onOpenRoute: () => _select(3),
                  onNewScan: () => _select(0),
                )
              : ParamedicScanScreen(
                  controller: _controller,
                  onOpenVoice: () => _select(1),
                );

          return AdaptiveScaffold(
            navigation: _role.navigation,
            pattern: _role.navigationPattern,
            selectedIndex: _tab,
            onDestinationSelected: _select,
            body: IndexedStack(
              index: _tab,
              children: <Widget>[
                scanSurface,
                ParamedicVoiceScreen(
                  controller: _controller,
                  onOpenScan: () => _select(0),
                ),
                ParamedicDrugsScreen(
                  controller: _controller,
                  onOpenScan: () => _select(0),
                ),
                ParamedicHandoverScreen(
                  controller: _controller,
                  onOpenScan: () => _select(0),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
