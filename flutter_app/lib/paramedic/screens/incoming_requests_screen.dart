import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../state/paramedic_session_controller.dart';
import '../widgets/paramedic_ui.dart';

/// Field-mode copy of the Screen 18 reference.
///
/// No request feed is connected, so the list stays empty and the accept
/// and decline actions stay disabled.
class IncomingRequestsScreen extends StatelessWidget {
  const IncomingRequestsScreen({super.key, required this.controller});

  final ParamedicSessionController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return ParamedicPage(
      title: 'Incoming requests',
      subtitle: 'No live feed',
      controller: controller,
      actions: <Widget>[
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(NemrasSpacing.xxl),
        children: <Widget>[
          FieldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Live incident stream',
                  style: NemrasTextStyles.summaryName,
                ),
                const SizedBox(height: NemrasSpacing.s),
                Text(
                  '0 pending · not connected',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.l),
                Text(
                  'No live emergency requests are connected in this prototype.',
                  style: NemrasTextStyles.body.copyWith(
                    color: semantics.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          const SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: null,
              child: Text('Accept dispatch'),
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          const SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              child: Text('Decline / pass request'),
            ),
          ),
        ],
      ),
    );
  }
}
