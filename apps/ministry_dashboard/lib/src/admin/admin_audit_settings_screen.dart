import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/governance_models.dart';
import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../screens/governance_screen.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Stitch Screen 40 — audit logs and system settings.
///
/// The only ledger this build has is the in-memory session trail already
/// shown on the national governance screen. Policy, certificate and
/// notification controls stay off because nothing persists them.
class AdminAuditSettingsScreen extends StatelessWidget {
  const AdminAuditSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);

    if (controller.auditState.isLoading) {
      return const NationalLoadingState(message: 'Reading the session audit');
    }
    if (controller.auditState.hasFailed) {
      return NationalErrorState(
        title: 'Session audit unavailable',
        message: controller.auditError ??
            'The session audit source returned an error.',
        onRetry: controller.refreshAudit,
      );
    }

    final semantics = NemrasSemantics.of(context);
    final analyst = controller.analyst;
    final events = controller.auditEvents;

    return NationalContentArea(
      children: <Widget>[
        const _AuditBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          'Audit logs and settings',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'Signed in as ${analyst.displayLabel} · ${analyst.analystId}.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.s),
        Text(
          'Demo session trail. Not a signed ledger, and not retained after '
          'this session.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: NationalMetric.demo(
                label: 'Session audit events',
                value: events.length,
                basis: 'Entries in the in-memory demo trail',
                caption: 'Not a count of events in the last 24 hours.',
              ),
            ),
            NationalKpiCard(
              metric: NationalMetric.demo(
                label: 'Break-glass events',
                value: controller.emergencyAccessCount,
                basis: 'Emergency-access entries in the demo trail',
                caption: 'Demo events. Not a live security anomaly count.',
              ),
            ),
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Security escalations',
                basis: 'No security-escalation feed is connected',
                caption: 'Not available.',
              ),
            ),
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Ledger integrity',
                basis: 'No certificate or hash chain is recorded',
                caption: 'Not available.',
              ),
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xl),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Search the audit trail',
            hintText: 'Not available',
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            for (final filter in GovernanceFilter.values)
              ChoiceChip(
                label: Text(filter.label),
                selected: filter == controller.governanceFilter,
                onSelected: (_) => controller.setGovernanceFilter(filter),
              ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'These filters read the session trail. They do not query a '
          'national ledger.',
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Expanded(child: NationalLabel('Session audit trail')),
                  DemoChip(),
                ],
              ),
              const SizedBox(height: NemrasSpacing.s),
              if (events.isEmpty)
                Text(
                  controller.governanceFilter == GovernanceFilter.all
                      ? 'No audit events are recorded for this session.'
                      : 'No ${controller.governanceFilter.label.toLowerCase()} '
                          'events are recorded.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                )
              else
                Text(
                  'Session audit events. Not a live enclave ledger.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              for (final event in events) ...<Widget>[
                const SizedBox(height: NemrasSpacing.l),
                Text(
                  event.action.label,
                  style: NemrasTextStyles.listTitle.copyWith(
                    color: semantics.textPrimary,
                  ),
                ),
                Text(
                  '${event.actorId}  ·  '
                  '${formatUtcTimestamp(event.timestamp)}',
                  style: NemrasTextStyles.bodyCaption.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        const NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NationalLabel('System policies'),
              SizedBox(height: NemrasSpacing.s),
              NationalWrapGrid(
                minTileWidth: 150,
                children: <Widget>[
                  NationalField(
                    label: 'Inactivity timeout',
                    value: 'Not recorded',
                  ),
                  NationalField(
                    label: 'Hardware token policy',
                    value: kNotAvailable,
                  ),
                  NationalField(
                    label: 'Gateway allow list',
                    value: kNotAvailable,
                  ),
                  NationalField(
                    label: 'Ledger retention',
                    value: 'Not recorded',
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Biometric re-authentication'),
                subtitle: Text('Not available. No biometric check is configured.'),
                value: false,
                onChanged: null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('SMS alert on override'),
                subtitle: Text(
                  'Not available. No notification gateway is connected.',
                ),
                value: false,
                onChanged: null,
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const NationalLabel('Unavailable controls'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'Node consensus, certificate checks and policy saves are '
                'not connected. Provincial node names are not shown.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              const FilledButton(
                onPressed: null,
                child: Text('Saving system policy is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Verifying a certificate chain is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Exporting an audit brief is not available'),
              ),
              const SizedBox(height: NemrasSpacing.l),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('National audit'),
                          leading: IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                        body: const GovernanceScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.gavel_outlined, size: 16),
                  label: const Text('Open national governance'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuditBanner extends StatelessWidget {
  const _AuditBanner();

  @override
  Widget build(BuildContext context) {
    final elevated = NemrasSemantics.of(context).elevated;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NemrasSpacing.l),
      decoration: BoxDecoration(
        color: elevated.soft,
        borderRadius: NemrasRadii.controlBorder,
        border: Border.all(color: elevated.solid),
      ),
      child: Text(
        'DEMO SESSION AUDIT. Entries below are the in-memory trail for this '
        'session. Nothing here is cryptographically signed, and past events '
        'cannot be edited.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: elevated.onSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
