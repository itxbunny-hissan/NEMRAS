import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';
import 'summary_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  List<Map<String, dynamic>> _critical = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        Api.getStats(),
        Api.criticalPatients(limit: 15),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as DashboardStats;
        _critical = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Cannot reach backend. Start the server and check kBaseUrl.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Dashboard',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off, size: 48, color: AppTheme.muted),
                    const SizedBox(height: 16),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.critical)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewCards(),
                          const SizedBox(height: 20),
                          _sectionTitle('Risk Distribution'),
                          const SizedBox(height: 10),
                          _buildRiskBars(),
                          const SizedBox(height: 20),
                          _sectionTitle('Conditions Breakdown'),
                          const SizedBox(height: 10),
                          _buildConditionBars(),
                          const SizedBox(height: 20),
                          _sectionTitle('Triage Levels'),
                          const SizedBox(height: 10),
                          _buildTriageBars(),
                          const SizedBox(height: 20),
                          _sectionTitle('Critical Patients Feed'),
                          const SizedBox(height: 10),
                          _buildCriticalList(),
                          const SizedBox(height: 30),
                        ]),
                  ),
                ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink));

  Widget _buildOverviewCards() {
    final s = _stats!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _statCard('Total Patients', s.totalPatients.toString(),
            Icons.people, AppTheme.primary),
        _statCard('Avg Age', '${s.avgAge.toStringAsFixed(1)} yrs',
            Icons.calendar_today, AppTheme.accent),
        _statCard('Critical', (s.riskScore['Critical'] ?? 0).toString(),
            Icons.warning_amber, AppTheme.critical),
        _statCard('Elevated', (s.riskScore['Elevated'] ?? 0).toString(),
            Icons.trending_up, AppTheme.high),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: c),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: c)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
      ]),
    );
  }

  Widget _buildRiskBars() {
    final s = _stats!;
    final total = s.totalPatients;
    final items = [
      ('Critical', s.riskScore['Critical'] ?? 0, AppTheme.critical),
      ('Elevated', s.riskScore['Elevated'] ?? 0, AppTheme.high),
      ('Stable', s.riskScore['Stable'] ?? 0, AppTheme.stable),
    ];
    return Column(
      children: items.map((e) => _barRow(e.$1, e.$2, total, e.$3)).toList(),
    );
  }

  Widget _buildConditionBars() {
    final s = _stats!;
    final total = s.totalPatients;
    final colors = [
      AppTheme.primary,
      AppTheme.accent,
      AppTheme.high,
      const Color(0xFF7B1FA2),
      AppTheme.critical,
      const Color(0xFF00838F),
    ];
    int i = 0;
    final sorted = s.medicalCondition.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: sorted
          .map((e) => _barRow(e.key, e.value, total, colors[i++ % colors.length]))
          .toList(),
    );
  }

  Widget _buildTriageBars() {
    final s = _stats!;
    final total = s.totalPatients;
    final items = [
      ('High', s.triageLevel['High'] ?? 0, AppTheme.critical),
      ('Medium', s.triageLevel['Medium'] ?? 0, AppTheme.high),
      ('Low', s.triageLevel['Low'] ?? 0, AppTheme.stable),
    ];
    return Column(
      children: items.map((e) => _barRow(e.$1, e.$2, total, e.$3)).toList(),
    );
  }

  Widget _barRow(String label, int count, int total, Color c) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 18,
                backgroundColor: c.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(c),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 65,
            child: Text('${(pct * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: c)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildCriticalList() {
    if (_critical.isEmpty) {
      return const Text('No critical patients.',
          style: TextStyle(color: AppTheme.muted));
    }
    return Column(
      children: _critical.map((p) {
        final risk = p['Risk_Score'] ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () async {
              try {
                final record = await Api.getPatient(p['CNIC']);
                if (!mounted) return;
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => SummaryScreen(record: record)));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')));
              }
            },
            leading: CircleAvatar(
              backgroundColor: AppTheme.riskColor(risk).withValues(alpha: 0.12),
              child: const Icon(Icons.person, size: 20),
            ),
            title: Text(p['Patient_Name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(
                '${p['Medical_Condition']} · ${p['Hospital']} · Age ${p['Age']}',
                style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.riskColor(risk).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(risk,
                  style: TextStyle(
                      color: AppTheme.riskColor(risk),
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
