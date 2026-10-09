import 'package:flutter/material.dart';
import 'package:pao_ui/pao_ui.dart';

/// Root widget of the PAO Admin app.
class PaoApp extends StatelessWidget {
  /// Creates the app root.
  const PaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAO Admin',
      theme: PaoTheme.light(),
      home: const PlaceholderPage(title: 'PAO Admin'),
    );
  }
}
