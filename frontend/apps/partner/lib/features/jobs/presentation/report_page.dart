import 'package:flutter/material.dart';
import 'package:pao_partner/app/services.dart';
import 'package:pao_ui/pao_ui.dart';

/// Placeholder until the feature is built.
class ReportPage extends StatelessWidget {
  /// Creates the page.
  const ReportPage({
    required this.services,
    required this.bookingId,
    super.key,
  });

  /// App services.
  final AppServices services;

  /// Route parameter.
  final String bookingId;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(appBar: PaoAppBar(title: 'ReportPage'));
}
