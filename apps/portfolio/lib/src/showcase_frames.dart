import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import 'content/portfolio_copy.dart';
import 'widgets/portfolio_widgets.dart';

class ShowcasePreview extends StatelessWidget {
  const ShowcasePreview({super.key, required this.frame});

  final ShowcaseFrame frame;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Structural preview of the ${frame.surface} surface. Not a screenshot.',
      child: PortfolioCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _FrameBar(frame: frame),
            switch (frame.surface) {
              'Patient' => const _PatientPreview(),
              'Paramedic' => const _ParamedicPreview(),
              'Hospital Clinical' => const _ClinicalPreview(),
              'Hospital Operations' => const _OperationsPreview(),
              'National / Ministry' => const _NationalPreview(),
              _ => const _PlaceholderBody(),
            },
          ],
        ),
      ),
    );
  }
}

class _FrameBar extends StatelessWidget {
  const _FrameBar({required this.frame});

  final ShowcaseFrame frame;

  @override
  Widget build(BuildContext context) {
    final field = frame.field;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.xxl,
        vertical: NemrasSpacing.l,
      ),
      decoration: BoxDecoration(
        color: field ? NemrasColors.ink2 : NemrasColors.paper,
        border: Border(
          bottom: BorderSide(
            color: field
                ? NemrasColors.fieldBorderOverlay
                : NemrasColors.line2,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              frame.surface,
              style: NemrasTextStyles.screenTitle.copyWith(
                color: field ? NemrasColors.white : NemrasColors.ink,
              ),
            ),
          ),
          const MarkBadge(PortfolioMark.demo),
        ],
      ),
    );
  }
}

class _PatientPreview extends StatelessWidget {
  const _PatientPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(NemrasSpacing.xxl),
          child: _SummaryStub(),
        ),
        const Divider(height: 1, color: NemrasColors.line2),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: NemrasSpacing.s),
          child: Row(
            children: <Widget>[
              for (final label in const <String>[
                'Home',
                'Record',
                'Assistant',
                'Profile',
              ])
                Expanded(child: _NavLabel(label)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParamedicPreview extends StatelessWidget {
  const _ParamedicPreview();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: NemrasColors.ink,
      child: Padding(
        padding: const EdgeInsets.all(NemrasSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'FIELD',
              style: NemrasTextStyles.fieldLabel.copyWith(
                color: NemrasColors.fieldAccent,
              ),
            ),
            const SizedBox(height: NemrasSpacing.l),
            for (final label in const <String>[
              'Scan',
              'Emergency summary',
              'Drugs',
              'Voice',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: NemrasSpacing.s),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: NemrasColors.fieldSurfaceOverlay,
                    borderRadius: NemrasRadii.controlBorder,
                    border: Border.all(color: NemrasColors.fieldBorderOverlay),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NemrasSpacing.l,
                      vertical: NemrasSpacing.m,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            label,
                            style: NemrasTextStyles.body.copyWith(
                              color: NemrasColors.white,
                            ),
                          ),
                        ),
                        Text(
                          'NOT AVAILABLE',
                          style: NemrasTextStyles.dataCaption.copyWith(
                            color: NemrasColors.fieldTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClinicalPreview extends StatelessWidget {
  const _ClinicalPreview();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sidebar = ColoredBox(
          color: NemrasColors.paper,
          child: Padding(
            padding: const EdgeInsets.all(NemrasSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final label in const <String>[
                  'Queue',
                  'Patients',
                  'Record',
                  'Audit',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: NemrasSpacing.s),
                    child: Text(
                      label,
                      style: NemrasTextStyles.tag.copyWith(
                        color: NemrasColors.tealDeep,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        const workspace = Padding(
          padding: EdgeInsets.all(NemrasSpacing.xxl),
          child: _SummaryStub(kicker: 'PATIENT CONTEXT'),
        );
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const ColoredBox(
                color: NemrasColors.paper,
                child: Padding(
                  padding: EdgeInsets.all(NemrasSpacing.l),
                  child: Wrap(
                    spacing: NemrasSpacing.l,
                    children: <Widget>[
                      _InlineNav('Queue'),
                      _InlineNav('Patients'),
                      _InlineNav('Record'),
                      _InlineNav('Audit'),
                    ],
                  ),
                ),
              ),
              workspace,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 120, child: sidebar),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: NemrasColors.line2),
                  ),
                ),
                child: workspace,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OperationsPreview extends StatelessWidget {
  const _OperationsPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(NemrasSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Expanded(child: _MetricStub(label: 'FLOW')),
              SizedBox(width: NemrasSpacing.s),
              Expanded(child: _MetricStub(label: 'BEDS')),
              SizedBox(width: NemrasSpacing.s),
              Expanded(child: _MetricStub(label: 'QUEUE')),
            ],
          ),
          SizedBox(height: NemrasSpacing.l),
          Text(
            'SYNTHETIC DATA',
            style: NemrasTextStyles.fieldLabel,
          ),
          SizedBox(height: NemrasSpacing.s),
          Text(
            'Operational figures are not shown here.',
            style: NemrasTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NationalPreview extends StatelessWidget {
  const _NationalPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(NemrasSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Wrap(
            spacing: NemrasSpacing.s,
            runSpacing: NemrasSpacing.s,
            children: <Widget>[
              _ChipNav('Overview'),
              _ChipNav('Trends'),
              _ChipNav('Network'),
              _ChipNav('Governance'),
            ],
          ),
          SizedBox(height: NemrasSpacing.xl),
          Row(
            children: <Widget>[
              Expanded(child: _MetricStub(label: 'AGGREGATE')),
              SizedBox(width: NemrasSpacing.s),
              Expanded(child: _MetricStub(label: 'NETWORK')),
              SizedBox(width: NemrasSpacing.s),
              Expanded(child: _MetricStub(label: 'GOVERNANCE')),
            ],
          ),
          SizedBox(height: NemrasSpacing.l),
          Text(
            'Aggregate view. No patient identifiers.',
            style: NemrasTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SummaryStub extends StatelessWidget {
  const _SummaryStub({this.kicker = 'SYNTHETIC DATA'});

  final String kicker;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          kicker,
          style: NemrasTextStyles.fieldLabel.copyWith(
            color: NemrasColors.teal,
          ),
        ),
        const SizedBox(height: NemrasSpacing.s),
        Text(
          'PATIENT ID',
          style: NemrasTextStyles.metricValue.copyWith(
            fontFamily: NemrasFonts.mono,
            package: NemrasFonts.package,
            fontWeight: FontWeight.w500,
            color: NemrasColors.ink,
          ),
        ),
        const SizedBox(height: NemrasSpacing.s),
        Text(
          'DEMO RECORD',
          style: NemrasTextStyles.body.copyWith(color: NemrasColors.muted),
        ),
        const SizedBox(height: NemrasSpacing.s),
        Text(
          'NOT AVAILABLE',
          style: NemrasTextStyles.dataValue.copyWith(
            color: NemrasColors.muted,
          ),
        ),
      ],
    );
  }
}

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(NemrasSpacing.xxl),
      child: _SummaryStub(),
    );
  }
}

class _MetricStub extends StatelessWidget {
  const _MetricStub({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NemrasColors.paper,
        borderRadius: NemrasRadii.metricBorder,
        border: Border.all(color: NemrasColors.line2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NemrasSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: NemrasTextStyles.fieldLabel.copyWith(
                color: NemrasColors.muted,
              ),
            ),
            const SizedBox(height: NemrasSpacing.s),
            Text(
              'NOT AVAILABLE',
              style: NemrasTextStyles.dataCaption.copyWith(
                color: NemrasColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: NemrasTextStyles.navLabel.copyWith(color: NemrasColors.tealDeep),
    );
  }
}

class _InlineNav extends StatelessWidget {
  const _InlineNav(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: NemrasTextStyles.tag.copyWith(color: NemrasColors.tealDeep),
    );
  }
}

class _ChipNav extends StatelessWidget {
  const _ChipNav(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.m,
        vertical: NemrasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: NemrasColors.tealSoft,
        borderRadius: NemrasRadii.badgeBorder,
      ),
      child: Text(
        label,
        style: NemrasTextStyles.tag.copyWith(color: NemrasColors.tealDeep),
      ),
    );
  }
}
