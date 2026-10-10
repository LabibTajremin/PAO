import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/jobs/domain/jobs_repository.dart';
import 'package:pao_partner/shared/uploads.dart';

/// [JobsRepository] and [ReportRepository] on the PAO API.
class ApiJobsRepository implements JobsRepository, ReportRepository {
  /// Creates the repository.
  ApiJobsRepository(this._dio) : _api = ProviderJobsApi(_dio);

  final Dio _dio;
  final ProviderJobsApi _api;

  @override
  Future<Paged<BookingSummary>> list(JobsTab tab, {String? cursor}) async {
    final res = await _api.listProviderJobs(tab: tab.name, cursor: cursor);
    return Paged(res.data!.items, res.data!.nextCursor);
  }

  @override
  Future<Booking> job(String id) async =>
      (await _api.getProviderJob(bookingId: id)).data!;

  @override
  Future<Receipt> receipt(String id) async =>
      (await _api.getProviderReceipt(bookingId: id)).data!;

  @override
  Future<String> uploadPhoto(Uint8List bytes) => providerUploader(_dio).upload(
    UploadFile(bytes: bytes, purpose: UploadPurpose.complaintPhoto.value),
  );

  @override
  Future<String> report(String bookingId, ProblemReport report) async {
    final res = await _api.reportProviderProblem(
      bookingId: bookingId,
      complaintInput: ComplaintInput(
        reason: report.reason,
        description: report.description,
        photoMediaIds: report.photoIds.isEmpty ? null : report.photoIds,
      ),
    );
    return res.data!.ticketNumber;
  }
}
