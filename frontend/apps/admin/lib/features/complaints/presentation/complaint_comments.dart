import 'package:flutter/material.dart';
import 'package:pao_admin/features/complaints/domain/complaints_repository.dart';
import 'package:pao_admin/features/complaints/presentation/complaint_labels.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_admin/shared/ops/formats.dart';
import 'package:pao_admin/shared/ops/layout.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_ui/pao_ui.dart';

/// The team's internal notes on a complaint and a box to add one; the
/// reporter never sees them.
class ComplaintComments extends StatelessWidget {
  /// Creates the section; [onSend] resolves with whether the comment was
  /// saved.
  const ComplaintComments({
    required this.kase,
    required this.onSend,
    super.key,
  });

  /// The complaint.
  final ComplaintCase kase;

  /// Adds a comment.
  final Future<bool> Function(String body) onSend;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final comments = kase.complaint.comments ?? <ComplaintComment>[];
    return Section(
      title: t.complaintsComments,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PaoSpace.md,
        children: [
          if (comments.isEmpty) Text(t.complaintsNoComments),
          for (final c in comments)
            PaoListRow(
              title: c.body,
              subtitle:
                  '${adminLabel(t, c.authorId, kase.me)} · '
                  '${context.when(c.at)}',
            ),
          _Composer(onSend: onSend),
        ],
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.onSend});

  final Future<bool> Function(String body) onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _body = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _body.text.trim();
    if (body.isEmpty) return;
    setState(() => _busy = true);
    final saved = await widget.onSend(body);
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) _body.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: PaoSpace.sm,
      children: [
        PaoTextField(
          label: t.complaintsCommentHint,
          controller: _body,
          maxLines: 3,
        ),
        PaoButton(
          label: t.complaintsCommentSend,
          variant: PaoButtonVariant.soft,
          expand: false,
          loading: _busy,
          onPressed: _send,
        ),
      ],
    );
  }
}
