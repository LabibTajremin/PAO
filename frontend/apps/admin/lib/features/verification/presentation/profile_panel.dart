import 'package:flutter/material.dart';
import 'package:pao_admin/features/verification/presentation/formats.dart';
import 'package:pao_admin/features/verification/presentation/labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// The NID data and profile the documents are checked against, and the face
/// check result.
class ProfilePanel extends StatelessWidget {
  /// Creates the panel.
  const ProfilePanel({required this.review, super.key});

  /// The review.
  final VerificationReview review;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = review.profile;
    final rows = <(String, String?)>[
      (t.verifyNidNumber, p.nidNumber),
      (t.verifyFullName, p.fullName),
      (t.verifyDob, context.day(p.dateOfBirth)),
      (t.verifyGender, genderLabel(t, p.gender)),
      (t.verifyPhone, p.phone),
      (t.verifyPresentAddress, p.presentAddress),
      (t.verifyPermanentAddress, p.permanentAddress),
    ];
    return PaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PaoSpace.sm,
        children: [
          Text(
            t.verifyProfileTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final (label, value) in rows) _Fact(label: label, value: value),
          const Divider(),
          Text(
            t.verifyFaceTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Row(
            spacing: PaoSpace.sm,
            children: [
              Icon(
                Icons.face_retouching_natural,
                color: faceColor(review.faceMatch),
              ),
              Expanded(child: Text(faceLabel(t, review.faceMatch))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium!
            .copyWith(color: PaoColors.textSecondary),
      ),
      SelectableText(
        value == null || value!.isEmpty ? context.t.verifyNotGiven : value!,
      ),
    ],
  );
}
