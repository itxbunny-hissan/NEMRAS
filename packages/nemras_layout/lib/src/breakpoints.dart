import 'package:flutter/widgets.dart';

/// The three window classes NEMRAS lays out for.
enum NemrasWindowSize {
  /// Phones. Patient and paramedic surfaces live here.
  compact,

  /// Tablets and small windows.
  medium,

  /// Desktop. The hospital and ministry surfaces live here.
  expanded,
}

/// Window-size breakpoints.
///
/// [REC] These values are an implementation decision, not a requirement.
/// `NEMRAS_UI_Design.html` is a fixed-width gallery of device mock-ups and
/// specifies no application breakpoints, so its widths are not usable here.
/// The thresholds below follow Material 3's compact/medium/expanded window
/// classes, which Flutter already aligns to, rather than inventing a bespoke
/// scale.
abstract final class NemrasBreakpoints {
  /// Lower bound of [NemrasWindowSize.medium].
  static const double mediumMin = 600;

  /// Lower bound of [NemrasWindowSize.expanded]. The reference desktop layout
  /// needs a 200dp sidebar plus a usable content area, so this is the width at
  /// which that becomes viable.
  static const double expandedMin = 1024;

  static NemrasWindowSize fromWidth(double width) {
    if (width >= expandedMin) return NemrasWindowSize.expanded;
    if (width >= mediumMin) return NemrasWindowSize.medium;
    return NemrasWindowSize.compact;
  }

  /// Resolves against the window. Use this for shell-level decisions; use
  /// `ResponsiveBuilder` when the decision should follow the incoming
  /// constraints instead, such as inside a split pane.
  static NemrasWindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static bool isCompact(BuildContext context) =>
      of(context) == NemrasWindowSize.compact;

  static bool isMedium(BuildContext context) =>
      of(context) == NemrasWindowSize.medium;

  static bool isExpanded(BuildContext context) =>
      of(context) == NemrasWindowSize.expanded;
}
