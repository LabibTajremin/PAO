import 'package:dio/dio.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// [Level2Repository] on the PAO API.
class ApiLevel2Repository implements Level2Repository {
  /// Creates the repository; the admin's permissions decide which lookups
  /// are tried.
  ApiLevel2Repository(Dio api, this._permissions)
    : _api = AdminVerificationApi(api),
      _people = AdminPeopleApi(api),
      _catalog = CustomerApi(api);

  final AdminVerificationApi _api;
  final AdminPeopleApi _people;
  final CustomerApi _catalog;
  final PermissionService _permissions;
  final Map<String, Future<AdminProviderSummary?>> _names = {};

  @override
  Future<Paged<Level2Row>> sessions({
    String? providerId,
    Level2SessionStatusEnum? status,
    String? cursor,
  }) async {
    final res = await _api.listLevel2Sessions(
      providerId: providerId,
      status: status?.value,
      cursor: cursor,
    );
    final rows = await Future.wait(res.data!.items.map(_row));
    return Paged(rows, res.data!.nextCursor);
  }

  @override
  Future<Level2Row> session(String id) async {
    final res = await _api.getLevel2Session(sessionId: id);
    return await _row(res.data!);
  }

  @override
  Future<List<AdminProviderSummary>> providers(
    String query, {
    int? level,
  }) async {
    final res = await _people.listAdminProviders(q: query.trim(), level: level);
    return res.data!.items;
  }

  // The service's checklist only pre-fills the form; the verifier can still
  // type the items, so a failed lookup leaves the form empty.
  @override
  Future<List<LocalizedText>> checklist(String serviceId) async {
    if (!_permissions.can(catalogReadPermission)) return const [];
    try {
      final res = await _catalog.getService(serviceId: serviceId);
      return res.data!.level2Checklist ?? const [];
    } on Object {
      return const [];
    }
  }

  @override
  Future<Level2Session> schedule(Level2Booking booking) async =>
      (await _api.scheduleLevel2Session(
        level2SessionInput: Level2SessionInput(
          providerId: booking.providerId,
          serviceId: booking.serviceId,
          scheduledAt: booking.at.toUtc(),
          location: booking.location.trim(),
        ),
      )).data!;

  @override
  Future<Level2Session> record(String id, Level2ResultInput result) async =>
      (await _api.recordLevel2Result(
        sessionId: id,
        level2ResultInput: result,
      )).data!;

  Future<Level2Row> _row(Level2Session s) async {
    final provider = await (_names[s.providerId] ??= _provider(s.providerId));
    final service = provider?.services?.where((r) => r.id == s.serviceId);
    return Level2Row(
      s,
      providerName: provider?.name,
      serviceName: service == null || service.isEmpty
          ? null
          : service.first.name,
    );
  }

  // Sessions carry only IDs. Names make the list readable but are not
  // essential, so a failed lookup falls back to the short ID instead of
  // failing the whole list.
  Future<AdminProviderSummary?> _provider(String id) async {
    if (!_permissions.can(providerReadPermission)) return null;
    try {
      return (await _people.getAdminProvider(providerId: id)).data!.summary;
    } on Object {
      return null;
    }
  }
}
