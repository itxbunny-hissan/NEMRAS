import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/handover_models.dart';
import '../state/hospital_session_controller.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';
import 'emergency_encounter_screen.dart';

/// Screen 3 — Emergency queue.
///
/// A desktop master/detail: the announced cases on the left, the selected
/// encounter on the right. Selecting a case opens
/// [EmergencyEncounterScreen] in the detail pane rather than pushing a page,
/// which keeps the sidebar context visible.
class EmergencyQueueScreen extends StatelessWidget {
  const EmergencyQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);

    switch (controller.queueState) {
      case LoadState.idle:
      case LoadState.loading:
        return const ClinicalLoadingState(
          message: 'Loading emergency queue…',
        );
      case LoadState.failed:
        return ClinicalErrorState(
          message: controller.queueError ??
              'The emergency queue could not be loaded.',
          onRetry: controller.refreshQueue,
        );
      case LoadState.ready:
        break;
    }

    if (controller.queue.isEmpty) {
      return ClinicalEmptyState(
        icon: Icons.emergency_outlined,
        title: 'No emergency cases',
        message:
            'No case has been announced to ${controller.hospital.hospitalId}. '
            'Cases arrive from the paramedic field app; this build reads them '
            'from a local demo repository.',
        action: OutlinedButton.icon(
          onPressed: controller.refreshQueue,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh queue'),
        ),
      );
    }

    final selected = controller.selectedCase;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1000;
        final list = _QueueList(controller: controller);
        final detail = selected == null
            ? const _NoCaseSelected()
            : EmergencyEncounterScreen(handover: selected);

        if (stacked) {
          // Narrow content area: show one pane at a time so neither becomes
          // unreadable.
          return selected == null
              ? list
              : Column(
                  children: <Widget>[
                    _BackToQueueBar(onBack: controller.clearSelectedCase),
                    Expanded(child: detail),
                  ],
                );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: 380, child: list),
            const _PaneDivider(),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}

class _PaneDivider extends StatelessWidget {
  const _PaneDivider();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Container(width: 1, color: semantics.cardBorder);
  }
}

class _BackToQueueBar extends StatelessWidget {
  const _BackToQueueBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.l,
        vertical: NemrasSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: semantics.cardBorder)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to queue'),
        ),
      ),
    );
  }
}

class _NoCaseSelected extends StatelessWidget {
  const _NoCaseSelected();

  @override
  Widget build(BuildContext context) {
    return const ClinicalEmptyState(
      icon: Icons.touch_app_outlined,
      title: 'Select a case',
      message:
          'Choose an announced emergency to open its handover context and '
          'status controls.',
    );
  }
}

/// How the triage stream is ordered. Both orders use only recorded fields.
enum _QueueSort { newest, triage }

int _triageRank(String triage) {
  switch (triage.toLowerCase()) {
    case 'high':
      return 0;
    case 'medium':
      return 1;
    case 'low':
      return 2;
    default:
      return 3;
  }
}

class _QueueList extends StatefulWidget {
  const _QueueList({required this.controller});

  final HospitalSessionController controller;

  @override
  State<_QueueList> createState() => _QueueListState();
}

class _QueueListState extends State<_QueueList> {
  static const List<String> _triageLevels = <String>['High', 'Medium', 'Low'];

  String? _triageFilter;
  _QueueSort _sort = _QueueSort.newest;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final semantics = NemrasSemantics.of(context);
    final selectedId = controller.selectedCase?.emergencyId;
    final queue = controller.queue;

    int countFor(String triage) => queue
        .where((c) => c.snapshot.triageLevel.toLowerCase() ==
            triage.toLowerCase())
        .length;

    final visible = queue
        .where(
          (c) =>
              _triageFilter == null ||
              c.snapshot.triageLevel.toLowerCase() ==
                  _triageFilter!.toLowerCase(),
        )
        .toList();
    if (_sort == _QueueSort.triage) {
      visible.sort((a, b) {
        final byTriage = _triageRank(a.snapshot.triageLevel)
            .compareTo(_triageRank(b.snapshot.triageLevel));
        if (byTriage != 0) return byTriage;
        return b.announcedAt.compareTo(a.announcedAt);
      });
    } else {
      visible.sort((a, b) => b.announcedAt.compareTo(a.announcedAt));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NemrasSpacing.huge,
            NemrasSpacing.huge,
            NemrasSpacing.huge,
            NemrasSpacing.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Incoming cases & triage queue',
                      style: NemrasTextStyles.screenTitle.copyWith(
                        color: semantics.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.refreshQueue,
                    tooltip: 'Refresh queue',
                    iconSize: 16,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.xxs),
              ClinicalSectionLabel(
                '${queue.length} announced '
                '${queue.length == 1 ? 'case' : 'cases'}',
              ),
              const SizedBox(height: NemrasSpacing.l),
              Wrap(
                spacing: NemrasSpacing.s,
                runSpacing: NemrasSpacing.xs,
                children: <Widget>[
                  _FilterChip(
                    label: 'All (${queue.length})',
                    selected: _triageFilter == null,
                    onSelected: () => setState(() => _triageFilter = null),
                  ),
                  for (final triage in _triageLevels)
                    _FilterChip(
                      label: '$triage (${countFor(triage)})',
                      selected: _triageFilter == triage,
                      onSelected: () => setState(() => _triageFilter = triage),
                    ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.s),
              Wrap(
                spacing: NemrasSpacing.s,
                runSpacing: NemrasSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'Sort',
                    style: NemrasTextStyles.dataCaption.copyWith(
                      color: semantics.textSecondary,
                    ),
                  ),
                  _FilterChip(
                    label: 'Newest',
                    selected: _sort == _QueueSort.newest,
                    onSelected: () =>
                        setState(() => _sort = _QueueSort.newest),
                  ),
                  _FilterChip(
                    label: 'Triage level',
                    selected: _sort == _QueueSort.triage,
                    onSelected: () =>
                        setState(() => _sort = _QueueSort.triage),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(NemrasSpacing.huge),
                  child: Text(
                    'No case matches this triage filter.',
                    style: NemrasTextStyles.bodySmall.copyWith(
                      color: semantics.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    NemrasSpacing.huge,
                    0,
                    NemrasSpacing.huge,
                    NemrasSpacing.huge,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: NemrasSpacing.l),
                  itemBuilder: (context, index) {
                    final handover = visible[index];
                    return _QueueTile(
                      handover: handover,
                      selected: handover.emergencyId == selectedId,
                      onTap: () => controller.selectCase(handover.emergencyId),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(NemrasSpacing.l),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: semantics.cardBorder)),
          ),
          child: Text(
            'DEMO queue. No live hospital network or dispatch connection '
            'exists in this build. Triage levels are the labels carried in '
            'each handover snapshot; the attending clinician confirms them.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.handover,
    required this.selected,
    required this.onTap,
  });

  final EmergencyHandover handover;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final snapshot = handover.snapshot;

    return Semantics(
      selected: selected,
      button: true,
      label: '${handover.emergencyId}, ${handover.status.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: NemrasRadii.cardBorder,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: NemrasTouchTargets.minimum,
          ),
          padding: const EdgeInsets.all(NemrasSpacing.xl),
          decoration: BoxDecoration(
            color: selected
                ? semantics.informational.soft
                : semantics.cardBackground,
            borderRadius: NemrasRadii.cardBorder,
            border: Border.all(
              color: selected ? semantics.accent : semantics.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      handover.emergencyId,
                      style: NemrasTextStyles.dataValue.copyWith(
                        color: semantics.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (handover.isDemo) const DemoChip(),
                ],
              ),
              const SizedBox(height: NemrasSpacing.xs),
              Text(
                '${snapshot.medicalCondition}  ·  ${snapshot.gender}  ·  '
                'AGE ${snapshot.ageLabel}',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: NemrasSpacing.l),
              Wrap(
                spacing: NemrasSpacing.xs,
                runSpacing: NemrasSpacing.xs,
                children: <Widget>[
                  ClinicalStatusPill(
                    label: handover.status.label,
                    status: _statusColour(semantics, handover.status),
                  ),
                  ClinicalTag(
                    label: 'TRIAGE ${snapshot.triageLevel}',
                    status: semantics.triage(snapshot.triageLevel),
                  ),
                  ClinicalTag(
                    label: snapshot.riskCategory,
                    status: semantics.risk(snapshot.riskCategory),
                  ),
                  if (snapshot.hasRecordedAllergy)
                    ClinicalTag(
                      label: 'ALLERGY',
                      status: semantics.allergy,
                      icon: Icons.warning_amber_outlined,
                    ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                '${handover.ambulanceId}  ·  ${handover.paramedicId}',
                style: NemrasTextStyles.dataCaption.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xxs),
              Text(
                'Field vitals not recorded  ·  ETA not available',
                style: NemrasTextStyles.dataCaption.copyWith(
                  color: semantics.textPlaceholder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static NemrasStatusColor _statusColour(
    NemrasSemantics semantics,
    EmergencyCaseStatus status,
  ) {
    switch (status) {
      case EmergencyCaseStatus.pending:
        return semantics.critical;
      case EmergencyCaseStatus.accepted:
        return semantics.elevated;
      case EmergencyCaseStatus.inProgress:
        return semantics.informational;
      case EmergencyCaseStatus.completed:
        return semantics.stable;
    }
  }
}
