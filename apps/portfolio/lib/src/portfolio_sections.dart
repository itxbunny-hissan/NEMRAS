import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import 'content/portfolio_copy.dart';
import 'showcase_frames.dart';
import 'widgets/portfolio_widgets.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.onExplore,
    required this.onArchitecture,
    required this.onCaseStudy,
  });

  final VoidCallback onExplore;
  final VoidCallback onArchitecture;
  final VoidCallback onCaseStudy;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          PortfolioSection.hero.number,
          style: NemrasTextStyles.fieldLabel.copyWith(color: semantics.accent),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            TextButton(
              style: portfolioButtonStyle(),
              onPressed: onExplore,
              child: const Text('Platform and modules'),
            ),
            TextButton(
              style: portfolioButtonStyle(),
              onPressed: onArchitecture,
              child: const Text('How it works'),
            ),
            TextButton(
              style: portfolioButtonStyle(),
              onPressed: onCaseStudy,
              child: const Text('Project case study'),
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          PortfolioCopy.productName,
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.accent,
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Semantics(
          header: true,
          headingLevel: 1,
          child: Text(
            'The emergency medical record that follows the patient, not the hospital.',
            style: NemrasTextStyles.pageTitle.copyWith(
              color: semantics.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Text(
          PortfolioCopy.subtitle,
          style: NemrasTextStyles.summaryName.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          PortfolioCopy.context,
          style: NemrasTextStyles.body.copyWith(
            color: semantics.textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Text(
          PortfolioCopy.heroBoundary,
          style: NemrasTextStyles.body.copyWith(
            color: semantics.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        const Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            _HeroMark(PortfolioCopy.demoMark),
            _HeroMark(PortfolioCopy.deploymentMark),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        Wrap(
          spacing: NemrasSpacing.l,
          runSpacing: NemrasSpacing.l,
          children: <Widget>[
            PortfolioAction(
              label: 'Explore System',
              filled: true,
              onPressed: onExplore,
            ),
            PortfolioAction(
              label: 'Architecture',
              filled: false,
              onPressed: onArchitecture,
            ),
          ],
        ),
      ],
    );

    final panel = const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _LiveCaseUnavailable(),
        SizedBox(height: NemrasSpacing.l),
        _IdentityPanel(),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            constraints.maxWidth >= NemrasBreakpoints.expandedMin;
        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              copy,
              const SizedBox(height: NemrasSpacing.section),
              panel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 6, child: copy),
            const SizedBox(width: NemrasSpacing.section),
            Expanded(flex: 5, child: panel),
          ],
        );
      },
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.l,
        vertical: NemrasSpacing.s,
      ),
      decoration: BoxDecoration(
        color: NemrasColors.ink,
        borderRadius: NemrasRadii.pillBorder,
      ),
      child: Text(
        label,
        style: NemrasTextStyles.tag.copyWith(color: NemrasColors.white),
      ),
    );
  }
}

class _LiveCaseUnavailable extends StatelessWidget {
  const _LiveCaseUnavailable();

  @override
  Widget build(BuildContext context) {
    return PortfolioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'NO LIVE DISPATCH CASE',
            style: NemrasTextStyles.fieldLabel.copyWith(
              color: NemrasColors.tealDeep,
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'The reference shows a citizen alert, a rescue unit, and a hospital bay. None of those feeds are connected to this page.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: NemrasColors.ink,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          const _UnavailableRow(label: 'Citizen alert', value: 'Not available'),
          const _UnavailableRow(label: 'Rescue unit', value: 'Not recorded'),
          const _UnavailableRow(label: 'Hospital bay', value: 'Not available'),
          const SizedBox(height: NemrasSpacing.l),
          const SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              child: Text(
                'Opening a live case is not available',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableRow extends StatelessWidget {
  const _UnavailableRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NemrasSpacing.s),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: NemrasTextStyles.bodySmall.copyWith(
                color: NemrasColors.muted,
              ),
            ),
          ),
          Text(
            value,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: NemrasColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: NemrasColors.summaryGradient,
        ),
        borderRadius: NemrasRadii.cardBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.all(NemrasSpacing.section),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'FIVE SURFACES',
              style: NemrasTextStyles.fieldLabel.copyWith(
                color: NemrasColors.fieldAccent,
              ),
            ),
            const SizedBox(height: NemrasSpacing.s),
            Text(
              'One record context. Four workspaces, plus this case study.',
              style: NemrasTextStyles.summaryName.copyWith(
                color: NemrasColors.white,
              ),
            ),
            const SizedBox(height: NemrasSpacing.xxl),
            for (var index = 0; index < PortfolioCopy.surfaces.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: NemrasSpacing.l),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 28,
                      child: Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: NemrasTextStyles.dataCaption.copyWith(
                          color: NemrasColors.fieldAccent,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        PortfolioCopy.surfaces[index].name,
                        style: NemrasTextStyles.body.copyWith(
                          color: NemrasColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProblemSection extends StatelessWidget {
  const ProblemSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.problem,
          title: 'Why the record has to travel',
          lede:
              'NEMRAS starts from the emergency, not from a hospital that already holds the file. This case study does not report a measured golden-hour statistic.',
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioGrid(
          maxColumns: 2,
          children: <Widget>[
            for (final point in PortfolioCopy.problem)
              PortfolioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      point.title,
                      style: NemrasTextStyles.screenTitle.copyWith(
                        color: NemrasColors.ink,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.l),
                    Text(
                      point.detail,
                      style: NemrasTextStyles.body.copyWith(
                        color: NemrasColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TrajectoryStage {
  const _TrajectoryStage({
    required this.step,
    required this.title,
    required this.mark,
    required this.detail,
  });

  final String step;
  final String title;
  final PortfolioMark mark;
  final String detail;
}

const List<_TrajectoryStage> _trajectory = <_TrajectoryStage>[
  _TrajectoryStage(
    step: '01',
    title: 'Incident trigger',
    mark: PortfolioMark.demo,
    detail:
        'The patient app has an emergency-request screen. This page does not receive a live alert.',
  ),
  _TrajectoryStage(
    step: '02',
    title: 'Identity',
    mark: PortfolioMark.partial,
    detail:
        'CNIC is the patient identifier and the Firebase UID is separate. No identity bureau is connected.',
  ),
  _TrajectoryStage(
    step: '03',
    title: 'Field dispatch',
    mark: PortfolioMark.proposed,
    detail:
        'No responder or vehicle registry is connected. A unit cannot be assigned from here.',
  ),
  _TrajectoryStage(
    step: '04',
    title: 'On-scene summary',
    mark: PortfolioMark.ruleBased,
    detail:
        'The paramedic demo can show a dataset summary and rule-based alerts. Live vitals are not connected.',
  ),
  _TrajectoryStage(
    step: '05',
    title: 'Hospital intake',
    mark: PortfolioMark.demo,
    detail:
        'The hospital demo has a queue and an encounter. Bed assignment is not available.',
  ),
  _TrajectoryStage(
    step: '06',
    title: 'Handover',
    mark: PortfolioMark.demo,
    detail:
        'A handoff screen exists. Signature, admission, and a receiving clinician are not completed from here.',
  ),
];

class _GoldenHourTrajectory extends StatelessWidget {
  const _GoldenHourTrajectory({
    required this.onHome,
    required this.onStatus,
  });

  final VoidCallback onHome;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          headingLevel: 3,
          child: Text(
            'How NEMRAS coordinates the golden hour',
            style: NemrasTextStyles.screenTitle.copyWith(
              color: semantics.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: NemrasSpacing.s),
        Text(
          'A proposed path from an emergency request to hospital handover. No stage on this page is a live operation.',
          style: NemrasTextStyles.body.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioGrid(
          maxColumns: 3,
          children: <Widget>[
            for (final stage in _trajectory)
              PortfolioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stage.step,
                      style: NemrasTextStyles.fieldLabel.copyWith(
                        color: semantics.accent,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.s),
                    Text(
                      stage.title,
                      style: NemrasTextStyles.screenTitle.copyWith(
                        color: semantics.textPrimary,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.l),
                    MarkBadge(stage.mark),
                    const SizedBox(height: NemrasSpacing.l),
                    Text(
                      stage.detail,
                      style: NemrasTextStyles.bodySmall.copyWith(
                        color: semantics.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Verification stream',
                style: NemrasTextStyles.screenTitle.copyWith(
                  color: semantics.textPrimary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'No live payload, ingest, or dual-authorisation stream is connected. Break-glass in the hospital demo keeps a session justification only.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              const _UnavailableRow(
                label: 'Payload signature',
                value: 'Not available',
              ),
              const _UnavailableRow(
                label: 'Critical ingest',
                value: 'Not available',
              ),
              const _UnavailableRow(
                label: 'Dual authorisation',
                value: 'Not available',
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        Text(
          'Where a record would travel',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.s),
        Text(
          'Clients talk to the dataset API. A national router and a federation bus are not running.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        const PortfolioGrid(
          maxColumns: 3,
          children: <Widget>[
            _PathCard(
              title: 'Client apps',
              mark: PortfolioMark.demo,
              detail: 'Patient, paramedic, hospital, and national screens are built.',
            ),
            _PathCard(
              title: 'Dataset API',
              mark: PortfolioMark.demo,
              detail: 'FastAPI serves the read-only dataset. Most routes are still unauthenticated.',
            ),
            _PathCard(
              title: 'Federation bus',
              mark: PortfolioMark.proposed,
              detail: 'No node router, event stream, or FHIR store exists.',
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const PortfolioGrid(
          maxColumns: 2,
          children: <Widget>[
            _PathCard(
              title: 'In this repository',
              mark: PortfolioMark.demo,
              detail:
                  'Dataset lookup, rule-based alerts, and a session break-glass justification exist. They are not a production dispatch system.',
            ),
            _PathCard(
              title: 'Not in this build',
              mark: PortfolioMark.planned,
              detail:
                  'Trained ML, RAG, an LLM, a durable audit trail, live dispatch, and federation are not running.',
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: null,
            child: const Text(
              'Replaying a live trajectory is not available',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Wrap(
          spacing: NemrasSpacing.l,
          runSpacing: NemrasSpacing.l,
          children: <Widget>[
            OutlinedButton(
              style: portfolioButtonStyle(),
              onPressed: onHome,
              child: const Text('Return to homepage'),
            ),
            OutlinedButton(
              style: portfolioButtonStyle(),
              onPressed: onStatus,
              child: const Text('Open project status'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.title,
    required this.mark,
    required this.detail,
  });

  final String title;
  final PortfolioMark mark;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return PortfolioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: NemrasTextStyles.screenTitle.copyWith(
              color: NemrasColors.ink,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          MarkBadge(mark),
          const SizedBox(height: NemrasSpacing.l),
          Text(
            detail,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: NemrasColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class ArchitectureSection extends StatelessWidget {
  const ArchitectureSection({
    super.key,
    required this.onHome,
    required this.onStatus,
  });

  final VoidCallback onHome;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.architecture,
          title: 'Architecture',
          lede:
              'The proposed path is five layers. Only the clients, the dataset API, and the rule-based responder exist in this build. Proposed layers stay marked proposed.',
        ),
        const SizedBox(height: NemrasSpacing.section),
        _GoldenHourTrajectory(onHome: onHome, onStatus: onStatus),
        const SizedBox(height: NemrasSpacing.section),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= NemrasBreakpoints.expandedMin;
            final layers = PortfolioCopy.architecture;
            if (!wide) {
              return Column(
                children: <Widget>[
                  for (var index = 0; index < layers.length; index++) ...<Widget>[
                    _LayerCard(layer: layers[index], step: index + 1),
                    if (index < layers.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: NemrasSpacing.s),
                        child: Icon(
                          Icons.arrow_downward,
                          color: NemrasColors.teal,
                          size: 18,
                        ),
                      ),
                  ],
                ],
              );
            }
            return Column(
              children: <Widget>[
                _ArchitectureRow(
                  layers: layers.sublist(0, 3),
                  firstStep: 1,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: NemrasSpacing.m),
                  child: Icon(
                    Icons.arrow_downward,
                    color: NemrasColors.teal,
                    size: 18,
                  ),
                ),
                _ArchitectureRow(
                  layers: layers.sublist(3),
                  firstStep: 4,
                  leadingSpacer: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ArchitectureRow extends StatelessWidget {
  const _ArchitectureRow({
    required this.layers,
    required this.firstStep,
    this.leadingSpacer = false,
  });

  final List<ArchitectureLayer> layers;
  final int firstStep;
  final bool leadingSpacer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (leadingSpacer) const Expanded(child: SizedBox.shrink()),
        if (leadingSpacer) const SizedBox(width: NemrasSpacing.xl),
        for (var index = 0; index < layers.length; index++) ...<Widget>[
          if (index > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: NemrasSpacing.s),
              child: Icon(
                Icons.arrow_forward,
                color: NemrasColors.teal,
                size: 18,
              ),
            ),
          Expanded(
            child: _LayerCard(
              layer: layers[index],
              step: firstStep + index,
            ),
          ),
        ],
      ],
    );
  }
}

class _LayerCard extends StatelessWidget {
  const _LayerCard({required this.layer, required this.step});

  final ArchitectureLayer layer;
  final int step;

  @override
  Widget build(BuildContext context) {
    return PortfolioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            step.toString().padLeft(2, '0'),
            style: NemrasTextStyles.fieldLabel.copyWith(
              color: NemrasColors.teal,
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            layer.title,
            style: NemrasTextStyles.screenTitle.copyWith(
              color: NemrasColors.ink,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          MarkBadge(layer.mark),
          const SizedBox(height: NemrasSpacing.l),
          Text(
            layer.summary,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: NemrasColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class SurfacesSection extends StatelessWidget {
  const SurfacesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.surfaces,
          title: 'Five NEMRAS surfaces',
          lede:
              'Each surface has a job. The status on the card is the state of this repository, not a deployment claim. Live vitals, dispatch timers, and bed counts from the reference are not connected.',
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioGrid(
          maxColumns: 3,
          children: <Widget>[
            for (final surface in PortfolioCopy.surfaces)
              PortfolioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(surface.icon, color: NemrasColors.teal),
                    const SizedBox(height: NemrasSpacing.l),
                    Text(
                      surface.name,
                      style: NemrasTextStyles.screenTitle.copyWith(
                        color: NemrasColors.ink,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.l),
                    MarkBadge(surface.mark),
                    const SizedBox(height: NemrasSpacing.l),
                    Text(
                      surface.purpose,
                      style: NemrasTextStyles.body.copyWith(
                        color: NemrasColors.ink,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.l),
                    for (final destination in surface.destinations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: NemrasSpacing.s),
                        child: Text(
                          destination,
                          style: NemrasTextStyles.bodySmall.copyWith(
                            color: NemrasColors.muted,
                          ),
                        ),
                      ),
                    const SizedBox(height: NemrasSpacing.s),
                    Text(
                      surface.state,
                      style: NemrasTextStyles.bodySmall.copyWith(
                        color: NemrasColors.ink2,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.l),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: null,
                        child: Text(
                          'Opening ${surface.name} is not available from this page',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class IntelligenceSection extends StatelessWidget {
  const IntelligenceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.intelligence,
          title: 'Intelligence',
          lede:
              'Rule-based and demo behaviour is what runs today. Trained ML, RAG, and an LLM are planned and are not operational.',
        ),
        const SizedBox(height: NemrasSpacing.section),
        const _IntelligenceGroup(
          title: 'Current demo / rule-based',
          mark: PortfolioMark.ruleBased,
          capabilities: PortfolioCopy.intelligence,
        ),
        const SizedBox(height: NemrasSpacing.section),
        const _IntelligenceGroup(
          title: 'Planned',
          mark: PortfolioMark.planned,
          capabilities: PortfolioCopy.plannedIntelligence,
        ),
      ],
    );
  }
}

class _IntelligenceGroup extends StatelessWidget {
  const _IntelligenceGroup({
    required this.title,
    required this.mark,
    required this.capabilities,
  });

  final String title;
  final PortfolioMark mark;
  final List<CapabilityCard> capabilities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: NemrasSpacing.l,
          runSpacing: NemrasSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Semantics(
              header: true,
              headingLevel: 3,
              child: Text(
                title,
                style: NemrasTextStyles.screenTitle.copyWith(
                  color: NemrasColors.ink,
                ),
              ),
            ),
            MarkBadge(mark),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xl),
        PortfolioGrid(
          maxColumns: capabilities.length >= 3 ? 3 : 2,
          children: <Widget>[
            for (final capability in capabilities)
              _CapabilityTile(capability: capability),
          ],
        ),
      ],
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({required this.capability});

  final CapabilityCard capability;

  @override
  Widget build(BuildContext context) {
    return PortfolioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            capability.name,
            style: NemrasTextStyles.screenTitle.copyWith(
              color: NemrasColors.ink,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          MarkBadge(capability.mark),
          const SizedBox(height: NemrasSpacing.l),
          Text(
            capability.detail,
            style: NemrasTextStyles.body.copyWith(color: NemrasColors.muted),
          ),
        ],
      ),
    );
  }
}

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.security,
          title: 'Security and privacy',
          lede:
              'The identity direction is real. Most record access in this demo is not enforced by the backend yet.',
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Reference controls that are not in this build',
                style: NemrasTextStyles.screenTitle,
              ),
              SizedBox(height: NemrasSpacing.l),
              Text(
                'A cryptographic ledger, a k-anonymity threshold, and an instant audit message are not recorded here.',
                style: NemrasTextStyles.body,
              ),
              SizedBox(height: NemrasSpacing.l),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  child: Text(
                    'Verifying a certificate chain is not available',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioGrid(
          maxColumns: 2,
          children: <Widget>[
            for (final point in PortfolioCopy.security)
              PortfolioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      point.title,
                      style: NemrasTextStyles.screenTitle.copyWith(
                        color: NemrasColors.ink,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.l),
                    Text(
                      point.detail,
                      style: NemrasTextStyles.body.copyWith(
                        color: NemrasColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.data,
          title: 'Data',
          lede:
              'The dataset stays in the backend. This page does not open a patient row.',
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'DATASET ROWS',
                style: NemrasTextStyles.fieldLabel.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                PortfolioCopy.datasetRows,
                style: NemrasTextStyles.pageTitle.copyWith(
                  color: semantics.textPrimary,
                  fontFamily: NemrasFonts.mono,
                  package: NemrasFonts.package,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'Read-only. Not modified by this portfolio.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        PortfolioGrid(
          maxColumns: 2,
          children: <Widget>[
            for (final point in PortfolioCopy.dataPoints)
              PortfolioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      point.title,
                      style: NemrasTextStyles.screenTitle.copyWith(
                        color: NemrasColors.ink,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.l),
                    Text(
                      point.detail,
                      style: NemrasTextStyles.body.copyWith(
                        color: NemrasColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class TechnologySection extends StatelessWidget {
  const TechnologySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.technology,
          title: 'Technology',
          lede:
              'Current means it is in this repository and used. Proposed means it is not running.',
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioGrid(
          maxColumns: 2,
          children: <Widget>[
            _TechColumn(
              title: 'Current',
              mark: PortfolioMark.current,
              items: PortfolioCopy.currentTechnology,
            ),
            _TechColumn(
              title: 'Proposed',
              mark: PortfolioMark.proposed,
              items: PortfolioCopy.proposedTechnology,
            ),
          ],
        ),
      ],
    );
  }
}

class _TechColumn extends StatelessWidget {
  const _TechColumn({
    required this.title,
    required this.mark,
    required this.items,
  });

  final String title;
  final PortfolioMark mark;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return PortfolioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: NemrasTextStyles.screenTitle.copyWith(
              color: NemrasColors.ink,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          MarkBadge(mark),
          const SizedBox(height: NemrasSpacing.xl),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: NemrasSpacing.m),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: NemrasColors.teal,
                    ),
                  ),
                  const SizedBox(width: NemrasSpacing.s),
                  Expanded(
                    child: Text(
                      item,
                      style: NemrasTextStyles.body.copyWith(
                        color: NemrasColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ShowcaseSection extends StatelessWidget {
  const ShowcaseSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.showcase,
          title: 'Product showcase',
          lede:
              'Structural frames of the real navigation. They are not screenshots and they do not contain a patient record.',
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioGrid(
          maxColumns: 2,
          children: <Widget>[
            for (final frame in PortfolioCopy.showcase)
              ShowcasePreview(frame: frame),
          ],
        ),
      ],
    );
  }
}

class StatusSection extends StatelessWidget {
  const StatusSection({super.key, required this.onShowcase});

  final VoidCallback onShowcase;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.status,
          title: 'Project status',
          lede:
              'Implemented means the behaviour is in the repository. Demo means it runs without being the production version of that idea.',
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Academic case study',
                style: NemrasTextStyles.screenTitle.copyWith(
                  color: semantics.textPrimary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'Authors and the supervisor are named in the team section. Roll numbers are not shown. No thesis file is attached to this page.',
                style: NemrasTextStyles.body.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              Text(
                'The problem, architecture, and technology sections are the research record. A national census and a certification claim are not used.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.section),
              Text(
                'Surface deliverables',
                style: NemrasTextStyles.screenTitle.copyWith(
                  color: semantics.textPrimary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'A numbered 40-screen completion ledger is not recorded. The built surfaces are listed below.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              for (final frame in PortfolioCopy.showcase)
                Padding(
                  padding: const EdgeInsets.only(bottom: NemrasSpacing.s),
                  child: Text(
                    '${frame.surface} · ${frame.mark.label}',
                    style: NemrasTextStyles.body.copyWith(
                      color: semantics.textPrimary,
                    ),
                  ),
                ),
              const SizedBox(height: NemrasSpacing.l),
              const SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  child: Text(
                    'Downloading a thesis is not available',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: null,
                  child: Text(
                    'A numbered screen ledger is not available',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              OutlinedButton(
                style: portfolioButtonStyle(),
                onPressed: onShowcase,
                child: const Text('Review product frames'),
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        PortfolioGrid(
          maxColumns: 2,
          children: <Widget>[
            for (final group in PortfolioCopy.status)
              PortfolioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MarkBadge(group.mark),
                    const SizedBox(height: NemrasSpacing.xl),
                    for (final entry in group.entries)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: NemrasSpacing.l,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              entry.title,
                              style: NemrasTextStyles.button.copyWith(
                                color: NemrasColors.ink,
                              ),
                            ),
                            const SizedBox(height: NemrasSpacing.xs),
                            Text(
                              entry.detail,
                              style: NemrasTextStyles.bodySmall.copyWith(
                                color: NemrasColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class TeamSection extends StatelessWidget {
  const TeamSection({super.key});

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionIntro(
          section: PortfolioSection.team,
          title: 'Team and supervision',
          lede: PortfolioCopy.programme,
        ),
        const SizedBox(height: NemrasSpacing.section),
        Text(
          'NEMRAS Project Team',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        PortfolioGrid(
          maxColumns: 3,
          children: <Widget>[
            for (final person in PortfolioCopy.team) _PersonCard(person: person),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        Text(
          'Supervisor',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: _PersonCard(person: PortfolioCopy.supervisor),
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person});

  final PortfolioPerson person;

  @override
  Widget build(BuildContext context) {
    return PortfolioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PersonPortrait(person: person),
          const SizedBox(height: NemrasSpacing.xl),
          Text(
            person.name,
            style: NemrasTextStyles.screenTitle.copyWith(
              color: NemrasColors.ink,
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            person.responsibility,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: NemrasColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class PortfolioFooter extends StatelessWidget {
  const PortfolioFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: NemrasColors.summaryGradient,
        ),
        borderRadius: NemrasRadii.cardBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.all(NemrasSpacing.section),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '12',
              style: NemrasTextStyles.fieldLabel.copyWith(
                color: NemrasColors.fieldAccent,
              ),
            ),
            const SizedBox(height: NemrasSpacing.s),
            Text(
              PortfolioCopy.productName,
              style: NemrasTextStyles.metricValue.copyWith(
                color: NemrasColors.white,
              ),
            ),
            const SizedBox(height: NemrasSpacing.s),
            Text(
              PortfolioCopy.subtitle,
              style: NemrasTextStyles.body.copyWith(
                color: NemrasColors.fieldTextSecondary,
              ),
            ),
            const SizedBox(height: NemrasSpacing.xl),
            Text(
              PortfolioCopy.programme,
              style: NemrasTextStyles.body.copyWith(color: NemrasColors.white),
            ),
            const SizedBox(height: NemrasSpacing.s),
            Text(
              'FYP demo. Not a production deployment.',
              style: NemrasTextStyles.body.copyWith(
                color: NemrasColors.fieldTextSecondary,
              ),
            ),
            const SizedBox(height: NemrasSpacing.xl),
            Text(
              'Flutter, Dart, FastAPI, Python, Firebase Auth, Firebase Admin, SQLite, CSV.',
              style: NemrasTextStyles.dataCaption.copyWith(
                color: NemrasColors.fieldAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
