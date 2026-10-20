import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../screens/governance_screen.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Stitch Screen 39 — responders and fleet.
///
/// No personnel, vehicle, licence or dispatch source exists. The page keeps
/// the reference hierarchy and leaves every registry action disabled.
class AdminFleetScreen extends StatelessWidget {
  const AdminFleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final analyst = NationalScope.of(context).analyst;

    return NationalContentArea(
      children: <Widget>[
        const _FleetBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          'Responders and fleet',
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
          'No personnel, vehicle, licence or dispatch registry is connected.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Registered personnel',
                basis: 'No responder registry is connected',
                caption: 'Not available.',
              ),
            ),
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Commissioned vehicles',
                basis: 'No vehicle registry is connected',
                caption: 'Not available.',
              ),
            ),
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Active on call',
                basis: 'No duty-state feed is connected',
                caption: 'Not available.',
              ),
            ),
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Fleet readiness',
                basis: 'No readiness measure is recorded',
                caption: 'Not available.',
              ),
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xl),
        const Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            ChoiceChip(
              label: Text('Personnel directory not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Vehicle registry not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Audit manifest not available'),
              selected: false,
              onSelected: null,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.l),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Search personnel or vehicles',
            hintText: 'Not available',
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        const Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            ChoiceChip(
              label: Text('Organisation filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Jurisdiction filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Duty-state filter not available'),
              selected: false,
              onSelected: null,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const NationalLabel('Personnel directory'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'No personnel are recorded.',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const NationalLabel('Vehicle registry'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'No vehicles are recorded.',
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
              const NationalLabel('Selected unit'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'No unit is selected.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              const NationalWrapGrid(
                minTileWidth: 150,
                children: <Widget>[
                  NationalField(label: 'Badge', value: 'Not recorded'),
                  NationalField(label: 'Licence', value: 'Not recorded'),
                  NationalField(
                    label: 'Vehicle registration',
                    value: 'Not recorded',
                  ),
                  NationalField(label: 'Station', value: 'Not recorded'),
                  NationalField(label: 'Duty state', value: kNotAvailable),
                  NationalField(label: 'Coordinates', value: kNotAvailable),
                  NationalField(label: 'On-board telemetry', value: kNotAvailable),
                ],
              ),
              const SizedBox(height: NemrasSpacing.l),
              const FilledButton(
                onPressed: null,
                child: Text('Updating a unit assignment is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Suspending a unit is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Registering a vehicle or crew is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Decommissioning a vehicle is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Exporting a fleet manifest is not available'),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _FleetBanner extends StatelessWidget {
  const _FleetBanner();

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
        'NO RESPONDER OR FLEET REGISTRY. Personnel, vehicles, licences and '
        'locations on the reference are not used. Nothing here dispatches '
        'a unit.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: elevated.onSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
