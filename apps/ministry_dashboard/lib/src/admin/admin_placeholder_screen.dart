import 'package:flutter/material.dart';

import '../widgets/national_ui.dart';

/// An administration destination that has no registry behind it yet.
class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return NationalContentArea(
      children: <Widget>[
        UnavailablePanel(
          headline: title,
          explanation: message,
          icon: Icons.lock_outline,
        ),
      ],
    );
  }
}
