import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// One consistent responsive decision point for NEMRAS screens.
///
/// Resolves against the incoming constraints rather than the window, so it
/// behaves correctly when nested inside a pane of a desktop layout. Falls back
/// to the window width when the constraints are unbounded.
///
/// [medium] falls back to [compact], and [expanded] falls back to [medium] and
/// then [compact], so a screen only supplies the layouts it actually differs
/// on.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        switch (NemrasBreakpoints.fromWidth(width)) {
          case NemrasWindowSize.expanded:
            return (expanded ?? medium ?? compact)(context);
          case NemrasWindowSize.medium:
            return (medium ?? compact)(context);
          case NemrasWindowSize.compact:
            return compact(context);
        }
      },
    );
  }
}
