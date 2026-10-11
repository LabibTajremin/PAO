import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/verification/domain/verification_repository.dart';
import 'package:pao_admin/features/verification/presentation/zoomable_image.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_ui/pao_ui.dart';

/// One document to show: its media ID and a caption.
typedef ViewerDocument = ({String mediaId, String label});

/// Builds the picture for a signed [url].
typedef DocumentImageBuilder = Widget Function(String url);

/// The document image from storage; a picture that fails to load says so
/// instead of breaking the viewer.
Widget networkDocument(String url) =>
    Image.network(url, fit: BoxFit.contain, errorBuilder: brokenDocument);

/// The documents of [item]; the selfie is checked against the NID photo, so
/// the NID front opens beside it.
List<ReviewDocument> documentsToCompare(
  VerificationReview review,
  ReviewItem item,
) => [
  ...?item.documents,
  if (item.type == ItemType.selfie)
    for (final i in review.items)
      if (i.type == ItemType.nid)
        ...?i.documents?.where((d) => d.kind == 'nid_front'),
];

/// Shown in place of a document that could not be loaded.
Widget brokenDocument(BuildContext context, Object error, StackTrace? stack) =>
    PaoMessageState(
      icon: Icons.broken_image_outlined,
      title: context.t.verifyViewerBroken,
    );

/// [documents] side by side, each with zoom and rotate, so a verifier can
/// compare them (e.g. the selfie against the NID photo); show it with
/// `showDialog`.
class DocumentsDialog extends StatelessWidget {
  /// Creates the dialog.
  const DocumentsDialog({
    required this.title,
    required this.documents,
    required this.repo,
    this.image = networkDocument,
    super.key,
  });

  /// Heading, e.g. the item's name.
  final String title;

  /// Documents to compare.
  final List<ViewerDocument> documents;

  /// Where signed URLs come from.
  final VerificationRepository repo;

  /// Builds the pictures.
  final DocumentImageBuilder image;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(PaoSpace.xxl),
    child: SizedBox(
      width: 1200,
      height: 800,
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: Theme.of(context).textTheme.titleLarge),
            trailing: CloseButton(onPressed: () => Navigator.pop(context)),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (_, box) => Flex(
                direction: box.maxWidth >= 700
                    ? Axis.horizontal
                    : Axis.vertical,
                children: [
                  for (final d in documents)
                    Expanded(
                      child: DocumentPanel(
                        document: d,
                        repo: repo,
                        image: image,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One document: fetches a fresh signed URL (every view is audited), then
/// shows it zoomable and rotatable.
class DocumentPanel extends StatelessWidget {
  /// Creates the panel.
  const DocumentPanel({
    required this.document,
    required this.repo,
    required this.image,
    super.key,
  });

  /// The document.
  final ViewerDocument document;

  /// Where signed URLs come from.
  final VerificationRepository repo;

  /// Builds the picture.
  final DocumentImageBuilder image;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        LoadCubit<String>(() => repo.documentUrl(document.mediaId)).loading(),
    child: BlocBuilder<LoadCubit<String>, ViewState<String>>(
      builder: (context, state) => Padding(
        padding: const EdgeInsets.all(PaoSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(document.label, style: Theme.of(context).textTheme.titleSmall),
            Expanded(
              child: ViewStateView<String>(
                state: state,
                onRetry: context.read<LoadCubit<String>>().load,
                builder: (_, url) => ZoomableImage(child: image(url)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
