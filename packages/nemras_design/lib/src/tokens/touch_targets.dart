/// Interactive sizing constants.
///
/// The reference is an HTML mock-up and specifies painted box sizes, not tap
/// targets. Several of its controls are smaller than an accessible target, so
/// the painted size and the minimum target are separate tokens here.
abstract final class NemrasTouchTargets {
  /// Baseline minimum interactive target for patient and clinical surfaces.
  static const double minimum = 44;

  /// Paramedic and field controls, which are used one-handed, often gloved and
  /// under time pressure.
  static const double field = 48;

  /// Painted size of `.icon-btn`. Smaller than [minimum], so the painted box
  /// must sit inside a tap target of at least [minimum].
  static const double iconButtonVisual = 34;

  /// `.perm-item .pic`, also below [minimum] when made interactive.
  static const double listIconVisual = 38;

  /// `.field .input` height.
  static const double inputHeight = 46;

  /// `.app-top` / `.hd-top` height.
  static const double barHeight = 54;

  /// `.bottom-nav` height.
  static const double bottomNavHeight = 64;

  /// `.bottom-nav .nav-item svg` size.
  static const double navIconSize = 22;

  /// `.hd-sidebar` width.
  static const double sidebarWidth = 200;
}
