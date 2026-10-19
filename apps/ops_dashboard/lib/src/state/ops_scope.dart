import 'package:flutter/widgets.dart';

import 'ops_console_controller.dart';

/// Makes the [OpsConsoleController] available to the dashboard subtree.
///
/// An [InheritedNotifier] keeps NEMRAS free of a state-management dependency
/// while still rebuilding dependents when the controller notifies, matching
/// the pattern the other three surfaces use.
class OpsScope extends InheritedNotifier<OpsConsoleController> {
  const OpsScope({
    super.key,
    required OpsConsoleController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller, subscribing the caller to its changes.
  static OpsConsoleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OpsScope>();
    assert(scope != null, 'No OpsScope found above this widget.');
    return scope!.notifier!;
  }

  /// The controller without subscribing, for callbacks and event handlers.
  static OpsConsoleController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<OpsScope>();
    assert(scope != null, 'No OpsScope found above this widget.');
    return scope!.notifier!;
  }
}
