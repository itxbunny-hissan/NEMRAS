import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _setTab,
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
