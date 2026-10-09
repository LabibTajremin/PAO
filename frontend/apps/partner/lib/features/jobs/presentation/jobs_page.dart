import 'package:flutter/material.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_ui/pao_ui.dart';

/// Placeholder until the feature is built.
class JobsPage extends StatelessWidget {
  /// Creates the page.
  const JobsPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(appBar: PaoAppBar(title: 'JobsPage'));
}
