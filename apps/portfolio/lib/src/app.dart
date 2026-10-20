import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import 'portfolio_page.dart';

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEMRAS',
      debugShowCheckedModeBanner: false,
      theme: nemrasClinicalLightTheme(),
      home: const PortfolioPage(),
    );
  }
}
