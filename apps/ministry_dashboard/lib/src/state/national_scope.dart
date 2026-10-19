import 'package:flutter/widgets.dart';

import 'national_console_controller.dart';

/// Makes the [NationalConsoleController] available to the dashboard subtree.
///
/// An [InheritedNotifier] keeps NEMRAS free of a state-management dependency
/// while still rebuilding dependents when the controller notifies, matching
/// the pattern the other four surfaces use.
class NationalScope extends InheritedNotifier<NationalConsoleController> {
  const NationalScope({
    super.key,
    required NationalConsoleController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller, subscribing the caller to its changes.
  static NationalConsoleController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NationalScope>();
    assert(scope != null, 'No NationalScope found above this widget.');
    return scope!.notifier!;
  }

  /// The controller without subscribing, for callbacks and event handlers.
  static NationalConsoleController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<NationalScope>();
    assert(scope != null, 'No NationalScope found above this widget.');
    return scope!.notifier!;
  }
}
