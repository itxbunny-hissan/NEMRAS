import 'package:flutter/material.dart';
import 'package:nemras_layout/nemras_layout.dart';
import '../api.dart';
import 'patient_home_screen.dart';
import 'record_timeline_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class PatientShell extends StatefulWidget {
  final PatientRecord record;
  const PatientShell({super.key, required this.record});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _tab = 0;

  void _setTab(int i) => setState(() => _tab = i);

  static final _role = NemrasRoleConfig.of(NemrasRole.patient);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      navigation: _role.navigation,
      pattern: _role.navigationPattern,
      selectedIndex: _tab,
      onDestinationSelected: _setTab,
      body: IndexedStack(
        index: _tab,
        children: [
          PatientHomeScreen(record: widget.record, onTabChange: _setTab),
          RecordTimelineScreen(record: widget.record),
          ChatScreen(
              cnic: widget.record.summary.cnic,
              name: widget.record.summary.patientName),
          ProfileScreen(record: widget.record),
        ],
      ),
    );
  }
}
