import 'package:flutter/material.dart';

/// Five stars showing [rating]; with [onChanged] they become an input (C17).
class PaoRatingStars extends StatelessWidget {
  /// Creates the stars.
  const PaoRatingStars({
    required this.rating,
    required this.semanticLabel,
    this.onChanged,
    this.size = 20,
    super.key,
  });

  /// Rating from 0 to 5; halves are drawn as half stars.
  final double rating;

  /// Label such as "4.5 out of 5 stars".
  final String semanticLabel;

  /// Called with 1–5 when a star is tapped.
  final ValueChanged<int>? onChanged;

  /// Star size.
  final double size;

  static const _gold = Color(0xFFF5A524);

  @override
  Widget build(BuildContext context) {
    IconData icon(int i) => rating >= i
        ? Icons.star_rounded
        : (rating >= i - 0.5
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded);
    final stars = [
      for (var i = 1; i <= 5; i++)
        if (onChanged == null)
          Icon(icon(i), size: size, color: _gold)
        else
          IconButton(
            tooltip: '$i',
            onPressed: () => onChanged!(i),
            icon: Icon(icon(i), size: size, color: _gold),
          ),
    ];
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: stars),
    );
  }
}
