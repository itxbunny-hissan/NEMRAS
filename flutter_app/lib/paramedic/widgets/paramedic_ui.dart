import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../state/paramedic_session_controller.dart';

class ParamedicPage extends StatelessWidget {
  const ParamedicPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.child,
    this.actions = const <Widget>[],
  });

  final String title;
  final String subtitle;
  final ParamedicSessionController controller;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: semantics.shellGradient,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              height: NemrasTouchTargets.barHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: NemrasSpacing.xxl,
              ),
              decoration: BoxDecoration(
                color: semantics.barBackground,
                border: Border(
                  bottom: BorderSide(color: semantics.barBorder),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NemrasTextStyles.screenTitle,
                        ),
                        Text(
                          subtitle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NemrasTextStyles.screenSubtitle.copyWith(
                            color: semantics.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const DemoBadge(),
                  ...actions,
                ],
              ),
            ),
            AssignmentStrip(controller: controller),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Semantics(
      label: 'Synthetic demo mode',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NemrasSpacing.s,
          vertical: NemrasSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: semantics.advisory.soft.withValues(alpha: 0.18),
          borderRadius: NemrasRadii.tagBorder,
          border: Border.all(color: semantics.advisory.solid),
        ),
        child: Text(
          'DEMO',
          style: NemrasTextStyles.tag.copyWith(
            color: semantics.advisory.onSolid,
          ),
        ),
      ),
    );
  }
}

class AssignmentStrip extends StatelessWidget {
  const AssignmentStrip({super.key, required this.controller});

  final ParamedicSessionController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.xxl,
        vertical: NemrasSpacing.s,
      ),
      color: semantics.controlBackground,
      child: Wrap(
        spacing: NemrasSpacing.xl,
        runSpacing: NemrasSpacing.xs,
        children: <Widget>[
          _AssignmentValue(
            icon: Icons.badge_outlined,
            value: controller.profile.paramedicId,
          ),
          _AssignmentValue(
            icon: Icons.emergency_outlined,
            value: controller.assignment.ambulanceId,
          ),
          _AssignmentValue(
            icon: Icons.circle,
            value: controller.assignment.status.name.toUpperCase(),
            color: semantics.stable.solid,
          ),
        ],
      ),
    );
  }
}

class _AssignmentValue extends StatelessWidget {
  const _AssignmentValue({
    required this.icon,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final resolved = color ?? semantics.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: resolved),
        const SizedBox(width: NemrasSpacing.xs),
        Text(
          value,
          style: NemrasTextStyles.dataCaption.copyWith(color: resolved),
        ),
      ],
    );
  }
}

class FieldCard extends StatelessWidget {
  const FieldCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NemrasSpacing.xxl),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? semantics.cardBackground,
        borderRadius: NemrasRadii.cardBorder,
        border: Border.all(color: borderColor ?? semantics.cardBorder),
      ),
      child: child,
    );
  }
}

class FieldSectionLabel extends StatelessWidget {
  const FieldSectionLabel(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Text(
      label.toUpperCase(),
      style: NemrasTextStyles.fieldLabel.copyWith(
        color: color ?? semantics.textSecondary,
      ),
    );
  }
}

class FieldStatusTag extends StatelessWidget {
  const FieldStatusTag({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final NemrasStatusColor status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.m,
        vertical: NemrasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.solid,
        borderRadius: NemrasRadii.pillBorder,
      ),
      child: Text(
        label.toUpperCase(),
        style: NemrasTextStyles.riskPill.copyWith(color: status.onSolid),
      ),
    );
  }
}

class EmptyEmergencyCard extends StatelessWidget {
  const EmptyEmergencyCard({
    super.key,
    required this.onOpenScan,
    required this.message,
  });

  final VoidCallback onOpenScan;
  final String message;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NemrasSpacing.xxl),
        child: FieldCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.emergency_outlined,
                size: 42,
                color: semantics.accent,
              ),
              const SizedBox(height: NemrasSpacing.xl),
              Text(
                message,
                textAlign: TextAlign.center,
                style: NemrasTextStyles.body.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xxl),
              FilledButton.icon(
                onPressed: onOpenScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Open Scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
