import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/report/domain/report_repository.dart';
import 'package:pao_customer/shared/uploads.dart';

/// [ReportRepository] on the PAO API.
class ApiReportRepository implements ReportRepository {
  /// Creates the repository; [uploader] defaults to the customer uploads.
  ApiReportRepository(Dio api, {MediaUploader? uploader})
    : _api = CustomerBookingsApi(api),
      _uploader = uploader ?? customerUploader(api);

  final CustomerBookingsApi _api;
  final MediaUploader _uploader;

  @override
  Future<String> uploadPhoto(Uint8List bytes) => _uploader.upload(
    UploadFile(bytes: bytes, purpose: UploadPurpose.complaintPhoto.value),
  );

  @override
  Future<String> report(String bookingId, ProblemReport report) async {
    final res = await _api.reportCustomerProblem(
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
