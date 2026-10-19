import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/analyst_identity.dart';
import '../screens/governance_screen.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Stitch Screen 37 — roles and permissions.
///
/// The only roles this build defines are the three national analyst roles,
/// and every one of them is aggregate-only. Nothing here grants, revokes or
/// saves a permission.
class RolesPermissionsScreen extends StatelessWidget {
  const RolesPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final analyst = controller.analyst;

    return NationalContentArea(
      children: <Widget>[
        const _PolicyBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          'Roles and permissions',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'Signed in as ${analyst.displayLabel} · ${analyst.analystId} · '
          '${analyst.role.label}.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.s),
        Text(
          analyst.role.dataScope,
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            if (analyst.isDemo) const DemoChip(),
            for (final role in AnalystRole.values)
              ChoiceChip(
                label: Text(role.label),
                selected: role == analyst.role,
                onSelected: null,
              ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'Switching roles is not available. These labels grant no access.',
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const _PermissionGroup(
          title: 'Patient records',
          rows: <_Permission>[
            _Permission(
              'View a patient summary',
              'Not available. No national role has a patient-level view.',
            ),
            _Permission(
              'Open a full clinical record',
              'Not granted. This console does not hold clinical records.',
            ),
            _Permission(
              'Emergency break-glass override',
              'Not configured here. Break-glass stays a facility action.',
            ),
          ],
        ),
        const _PermissionGroup(
          title: 'Capacity and dispatch',
          rows: <_Permission>[
            _Permission(
              'Update emergency bed capacity',
              'Not available. NEMRAS records no bed counts.',
            ),
            _Permission(
              'Declare a regional surge',
              'Not available. No diversion channel is connected.',
            ),
            _Permission(
              'Reassign triage or shift rosters',
              'Not recorded.',
            ),
          ],
        ),
        const _PermissionGroup(
          title: 'Accounts',
          rows: <_Permission>[
            _Permission(
              'Approve hospital staff',
              'Not available. No staff registry is connected.',
            ),
            _Permission(
              'Provision enclave keys',
              'Not available.',
            ),
            _Permission(
              'Suspend an account',
              'Not available.',
            ),
          ],
        ),
        const _PermissionGroup(
          title: 'Audit',
          rows: <_Permission>[
            _Permission(
              'Modify historical audit trails',
              'Not available. Past audit events cannot be edited or deleted.',
            ),
            _Permission(
              'Export a statutory permission report',
              'Not available. Saving a schema produces no file.',
            ),
          ],
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
            label: const Text('Open session audit'),
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        const FilledButton(
          onPressed: null,
          child: Text('Saving a permission schema is not available'),
        ),
      ],
    );
  }
}

class _PolicyBanner extends StatelessWidget {
  const _PolicyBanner();

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
        'DEMO POLICY VIEW. No permission is granted or revoked from this '
        'page. Every switch below is off.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: elevated.onSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Permission {
  const _Permission(this.title, this.detail);

  final String title;
  final String detail;
}

class _PermissionGroup extends StatelessWidget {
  const _PermissionGroup({required this.title, required this.rows});

  final String title;
  final List<_Permission> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NemrasSpacing.xl),
      child: NationalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NationalLabel(title),
            for (final row in rows) _PermissionSwitch(permission: row),
          ],
        ),
      ),
    );
  }
}

class _PermissionSwitch extends StatelessWidget {
  const _PermissionSwitch({required this.permission});

  final _Permission permission;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: false,
      onChanged: null,
      title: Text(permission.title),
      subtitle: Text(
        permission.detail,
        style: NemrasTextStyles.bodyCaption.copyWith(
          color: semantics.textSecondary,
        ),
      ),
    );
  }
}
