import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import 'navigation/clinical_navigation.dart';
import 'screens/clinical_shell.dart';
import 'screens/hospital_login_screen.dart';
import 'state/hospital_session_controller.dart';
import 'state/session_scope.dart';

/// Root of the NEMRAS Hospital Clinical Desktop.
///
/// A separate application from the patient/paramedic mobile app, in the same
/// repository, sharing `nemras_design` and `nemras_layout`. It declares no
/// design tokens of its own.
class HospitalDesktopApp extends StatefulWidget {
  const HospitalDesktopApp({super.key, this.controller});

  /// Injected by tests. Production builds let the app own the controller so it
  /// is disposed with the widget.
  final HospitalSessionController? controller;

  @override
  State<HospitalDesktopApp> createState() => _HospitalDesktopAppState();
}

class _HospitalDesktopAppState extends State<HospitalDesktopApp> {
  late final HospitalSessionController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? HospitalSessionController();
    _controller.probeBackend();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HospitalSessionScope(
      controller: _controller,
      child: MaterialApp(
        title: 'NEMRAS Clinical Desktop',
        debugShowCheckedModeBanner: false,
        theme: nemrasClinicalLightTheme(),
        initialRoute: NemrasRouteNames.hospitalLogin,
        onGenerateRoute: HospitalRouter.onGenerateRoute,
      ),
    );
  }
}

/// Maps NEMRAS hospital route names to clinical screens.
///
/// Only two routes are pushed onto the Navigator: the login entry point and
/// the clinical shell. Sidebar destinations swap the shell's content area
/// rather than pushing a page, which is how a desktop sidebar behaves.
abstract final class HospitalRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case NemrasRouteNames.hospitalLogin:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => HospitalLoginScreen(
            onSignedIn: () => Navigator.of(context).pushReplacementNamed(
              NemrasRouteNames.hospitalOverview,
            ),
          ),
        );

      // Every clinical destination resolves to the shell, opened on that
      // destination, so a deep link lands on the right panel.
      case NemrasRouteNames.hospitalOverview:
      case NemrasRouteNames.hospitalEmergency:
      case NemrasRouteNames.hospitalPatients:
      case NemrasRouteNames.hospitalClinicalRecords:
      case NemrasRouteNames.hospitalAiAssistant:
      case NemrasRouteNames.hospitalMedications:
      case NemrasRouteNames.hospitalHandover:
      case NemrasRouteNames.hospitalAuditTrail:
      case NemrasRouteNames.hospitalSettings:
        final index = indexForRoute(settings.name!) ?? 0;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ClinicalShell(initialIndex: index),
        );

      default:
        return null;
    }
  }

  /// The sidebar index a route opens on, or null when the route is not a
  /// clinical destination.
  static int? indexForRoute(String route) =>
      HospitalClinicalNavigation.clinicalSidebar.indexOfRoute(route);
}
