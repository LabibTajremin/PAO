import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// What the complaints queue (A11) is narrowed to.
class ComplaintFilter {
  /// Creates the filter; the defaults show every complaint.
  const ComplaintFilter({this.status, this.mine = false});

  /// Complaint status.
  final ComplaintStatus? status;

  /// Only complaints assigned to the signed-in admin.
  final bool mine;

  /// This filter with [status] instead.
  ComplaintFilter withStatus(ComplaintStatus? status) =>
      ComplaintFilter(status: status, mine: mine);

  /// This filter with "assigned to me" turned over.
  ComplaintFilter toggleMine() => ComplaintFilter(status: status, mine: !mine);
}

/// A complaint as the signed-in admin sees it.
class ComplaintCase {
  /// Creates the case; [me] is the signed-in admin's ID.
  const ComplaintCase(this.complaint, this.me);

  /// The complaint.
  final Complaint complaint;

  /// The signed-in admin's ID, to tell their own assignments and comments.
  final String me;

  /// The same case after an action returned [updated].
  ComplaintCase updated(Complaint updated) => ComplaintCase(updated, me);
}

/// The complaints queue (A-07).
abstract interface class ComplaintsRepository {
  /// The signed-in admin's ID.
  Future<String> me();

  /// One page of complaints matching [filter].
  Future<Paged<Complaint>> list(ComplaintFilter filter, String? cursor);

  /// A complaint with its comments.
  Future<Complaint> detail(String id);

  /// Assigns complaint [id] to admin [assigneeId].
  Future<Complaint> assign(String id, String assigneeId);

  /// Adds an internal comment, never shown to the customer or provider.
  Future<Complaint> comment(String id, String body);

  /// Closes complaint [id] with a [resolution]; a [verified] complaint feeds
  /// the provider's quality review (PRD §6.4).
  Future<Complaint> resolve(
    String id, {
    required String resolution,
    required bool verified,
  });

  /// Active admins who can take complaints.
  Future<List<AdminUser>> agents();
}
