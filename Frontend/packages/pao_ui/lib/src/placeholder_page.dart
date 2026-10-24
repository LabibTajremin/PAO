import 'package:flutter/material.dart';

/// A centred title used by an app until its real screens exist.
class PlaceholderPage extends StatelessWidget {
  /// Creates a page that shows [title] in the middle of the screen.
  const PlaceholderPage({required this.title, super.key});

  /// The text shown in the centre of the page.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}
