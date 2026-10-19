/// NEMRAS responsive layout and adaptive navigation infrastructure.
///
/// Provides breakpoints, a responsive decision point, the adaptive shell, the
/// mobile and desktop navigation primitives, and the role-to-shell model shared
/// by all five NEMRAS surfaces.
///
/// Depends on `nemras_design` for tokens and themes. The dependency is one-way:
/// `nemras_design` knows nothing about this package.
library;

export 'src/adaptive_scaffold.dart';
export 'src/breakpoints.dart';
export 'src/desktop_sidebar.dart';
export 'src/desktop_topbar.dart';
export 'src/mobile_navigation.dart';
export 'src/navigation_models.dart';
export 'src/responsive_builder.dart';
export 'src/roles.dart';
export 'src/route_names.dart';
