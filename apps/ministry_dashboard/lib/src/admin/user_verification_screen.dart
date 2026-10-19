import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/national_models.dart';
import '../screens/governance_screen.dart';
import '../widgets/national_ui.dart';

/// Stitch Screen 36 — user verification and approvals.
///
/// NEMRAS has no identity-verification registry and does not submit dossiers
/// to an external authority. The queue is empty and every approval control
/// is disabled.
class UserVerificationScreen extends StatelessWidget {
  const UserVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return NationalContentArea(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(NemrasSpacing.l),
          decoration: BoxDecoration(
            color: semantics.informational.soft,
            borderRadius: NemrasRadii.controlBorder,
            border: Border.all(color: semantics.informational.solid),
          ),
          child: Text(
            'NO VERIFICATION REGISTRY. No applicant, licence or identity '
            'document is stored here, and none is sent to an external '
            'authority.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.informational.onSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          'User verification',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'The reference shows a clearance queue. This build has no queue '
          'to clear.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
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
        const SizedBox(height: NemrasSpacing.section),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Search applicants',
            hintText: 'Not available',
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        const Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            ChoiceChip(
              label: Text('Role filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Region filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Date window not available'),
              selected: false,
              onSelected: null,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xl),
        const NationalWrapGrid(
          minTileWidth: 140,
          children: <Widget>[
            NationalField(label: 'Pending review', value: 'Not recorded'),
            NationalField(label: 'Approved', value: 'Not recorded'),
            NationalField(label: 'Flagged', value: 'Not recorded'),
            NationalField(label: 'Rejected', value: 'Not recorded'),
            NationalField(label: 'Queue latency', value: kNotAvailable),
          ],
        ),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const NationalLabel('Verification queue'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'No verification dossiers are recorded.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const NationalLabel('Selected applicant'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'No applicant is selected.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              const NationalWrapGrid(
                minTileWidth: 150,
                children: <Widget>[
                  NationalField(label: 'Credentials', value: 'Not recorded'),
                  NationalField(label: 'Licence', value: 'Not recorded'),
                  NationalField(label: 'Role scope', value: 'Not recorded'),
                  NationalField(
                    label: 'Integrity checks',
                    value: kNotAvailable,
                  ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.l),
              const FilledButton(
                onPressed: null,
                child: Text('Approving credentials is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Requesting corrections is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Rejecting an application is not available'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
