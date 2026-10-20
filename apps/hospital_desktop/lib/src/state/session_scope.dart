import 'package:flutter/widgets.dart';

import 'hospital_session_controller.dart';

/// Makes the [HospitalSessionController] available to the clinical screens.
///
/// An [InheritedNotifier] keeps Phase 3A free of a state-management
/// dependency, which the architecture rules ask for, while still rebuilding
/// dependents when the controller notifies.
class HospitalSessionScope extends InheritedNotifier<HospitalSessionController> {
  const HospitalSessionScope({
    super.key,
    required HospitalSessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static HospitalSessionController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<HospitalSessionScope>();
    assert(
      scope?.notifier != null,
      'HospitalSessionScope is missing. Wrap the clinical surface in one.',
    );
    return scope!.notifier!;
  }

  /// Reads the controller without subscribing to its notifications. Use this
  /// from callbacks, which do not need to rebuild on every change.
  static HospitalSessionController read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<HospitalSessionScope>()
        ?.widget as HospitalSessionScope?;
    assert(
      scope?.notifier != null,
      'HospitalSessionScope is missing. Wrap the clinical surface in one.',
    );
    return scope!.notifier!;
  }
}
