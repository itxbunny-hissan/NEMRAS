import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/geography.dart';
import '../data/metric_provenance.dart';
import '../widgets/national_ui.dart';

/// Stitch Screen 30 — the national emergency map.
///
/// The reference draws a live CAD grid with incidents, ambulances and a
/// patient dossier. NEMRAS has no coordinate, province, dispatch or GPS
/// source, so this page states that no map can be drawn and leaves every
/// control disabled. No incident is invented to fill the dossier.
class EmergencyMapScreen extends StatelessWidget {
  const EmergencyMapScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
        builder: (_) => const EmergencyMapScreen(),
      );

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Scaffold(
      backgroundColor: semantics.screenBackground,
      appBar: AppBar(
        title: const Text('Emergency map'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: NationalContentArea(
        children: <Widget>[
          const ProvenanceNotice(
            title: 'No live map',
            message: 'No map is drawn. The dataset has no province, district '
                'or coordinate, and no CAD, GPS or ambulance feed is '
                'connected. Nothing here is a live incident.',
          ),
          const UnavailablePanel(
            headline: GeographicAvailability.notice,
            explanation: GeographicAvailability.explanation,
            requirements: GeographicAvailability.requirements,
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: NemrasSpacing.xl),
          const _MapControls(),
          const SizedBox(height: NemrasSpacing.xl),
          const _IncidentDossier(),
          const SizedBox(height: NemrasSpacing.xl),
          const NationalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                NationalLabel('Active queue'),
                SizedBox(height: NemrasSpacing.s),
                Text(
                  'Not available. No province and no live call is recorded, '
                  'so no queue is listed.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NationalLabel('Map controls'),
          const SizedBox(height: NemrasSpacing.l),
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Search by city, district or hospital',
              hintText: 'Not available',
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'Search, tier filters and map layers need a location feed, which '
            'NEMRAS does not have.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          const Wrap(
            spacing: NemrasSpacing.s,
            runSpacing: NemrasSpacing.s,
            children: <Widget>[
              ChoiceChip(
                label: Text('Tier filter not available'),
                selected: false,
                onSelected: null,
              ),
              ChoiceChip(
                label: Text('Category filter not available'),
                selected: false,
                onSelected: null,
              ),
            ],
          ),
          for (final layer in const <String>[
            'Trauma hospitals',
            'Responders',
            'Telemetry',
          ])
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: false,
              onChanged: null,
              dense: true,
              title: Text('$layer · not available'),
            ),
        ],
      ),
    );
  }
}

class _IncidentDossier extends StatelessWidget {
  const _IncidentDossier();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Expanded(child: NationalLabel('Selected incident')),
              ProvenanceBadge(MetricProvenance.unavailable),
            ],
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'No incident is selected. NEMRAS holds no live dispatch record.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          const NationalWrapGrid(
            minTileWidth: 160,
            children: <Widget>[
              NationalField(label: 'Incident reference', value: 'Not recorded'),
              NationalField(label: 'Patient', value: 'Not recorded'),
              NationalField(label: 'Triage assessment', value: 'Not recorded'),
              NationalField(label: 'Destination', value: 'Not available'),
              NationalField(label: 'Ambulance', value: 'Not recorded'),
              NationalField(label: 'ETA', value: 'Not available'),
            ],
          ),
          const SizedBox(height: NemrasSpacing.l),
          const Wrap(
            spacing: NemrasSpacing.s,
            runSpacing: NemrasSpacing.s,
            children: <Widget>[
              FilledButton(
                onPressed: null,
                child: Text('Opening an audit record is not available'),
              ),
              OutlinedButton(
                onPressed: null,
                child: Text('Route diversion is not available'),
              ),
              OutlinedButton(
                onPressed: null,
                child: Text('Exporting a log is not available'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
