import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_api/pao_api.dart';

/// Who filed a complaint.
String reporterLabel(AdminL10n t, ComplaintReporterRoleEnum role) =>
    switch (role) {
      ComplaintReporterRoleEnum.customer => t.complaintsByCustomer,
      ComplaintReporterRoleEnum.provider => t.complaintsByProvider,
    };

/// An admin as the signed-in admin [me] knows them: "You", a short ID, or
/// nobody when [id] is null.
String adminLabel(AdminL10n t, String? id, String me) {
  if (id == null) return t.complaintsUnassigned;
  if (id == me) return t.complaintsYou;
  return t.complaintsAgent(id.length > 8 ? id.substring(0, 8) : id);
}
