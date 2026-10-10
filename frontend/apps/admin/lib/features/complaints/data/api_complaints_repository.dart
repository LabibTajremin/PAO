import 'package:dio/dio.dart';
import 'package:pao_admin/features/complaints/domain/complaints_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Roles that work the complaints queue (02-architecture.md §6).
const Set<AdminRole> _complaintRoles = {
  AdminRole.supportAgent,
  AdminRole.superAdmin,
};

/// [ComplaintsRepository] on the PAO API.
class ApiComplaintsRepository implements ComplaintsRepository {
  /// Creates the repository.
  ApiComplaintsRepository(this._dio) : _api = AdminComplaintsApi(_dio);

  final Dio _dio;
  final AdminComplaintsApi _api;
  String? _me;

  @override
  Future<String> me() async => _me ??= (await MeApi(_dio).getMe()).data!.id;

  @override
  Future<Paged<Complaint>> list(ComplaintFilter filter, String? cursor) async {
    final res = await _api.listComplaints(
      status: filter.status?.value,
      assigneeId: filter.mine ? await me() : null,
      cursor: cursor,
    );
    return Paged(res.data!.items, res.data!.nextCursor);
  }

  @override
  Future<Complaint> detail(String id) async =>
      (await _api.getComplaint(complaintId: id)).data!;

  @override
  Future<Complaint> assign(String id, String assigneeId) async =>
      (await _api.assignComplaint(
        complaintId: id,
        complaintAssignInput: ComplaintAssignInput(assigneeId: assigneeId),
      )).data!;

  @override
  Future<Complaint> comment(String id, String body) async =>
      (await _api.commentOnComplaint(
        complaintId: id,
        complaintCommentInput: ComplaintCommentInput(body: body),
      )).data!;

  @override
  Future<Complaint> resolve(
    String id, {
    required String resolution,
    required bool verified,
  }) async => (await _api.resolveComplaint(
    complaintId: id,
    complaintResolveInput: ComplaintResolveInput(
      resolution: resolution,
      verified: verified,
    ),
  )).data!;

  @override
  Future<List<AdminUser>> agents() async {
    final res = await AdminSettingsApi(_dio).listAdminUsers();
    return [
      for (final u in res.data!.items)
        if (u.active && u.roles.any(_complaintRoles.contains)) u,
    ];
  }
}
