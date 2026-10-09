import 'package:flutter/material.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_ui/pao_ui.dart';

/// Placeholder until the feature is built.
class EnrolmentPage extends StatelessWidget {
  /// Creates the page.
  const EnrolmentPage({required this.services, required this.step, super.key});

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String step;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(appBar: PaoAppBar(title: 'EnrolmentPage'));
}
