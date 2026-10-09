import 'package:pao_api/src/model/account.dart';
import 'package:pao_api/src/model/account_status_change.dart';
import 'package:pao_api/src/model/address.dart';
import 'package:pao_api/src/model/address_input.dart';
import 'package:pao_api/src/model/address_list.dart';
import 'package:pao_api/src/model/admin_customer_detail.dart';
import 'package:pao_api/src/model/admin_customer_list.dart';
import 'package:pao_api/src/model/admin_customer_summary.dart';
import 'package:pao_api/src/model/admin_login_challenge.dart';
import 'package:pao_api/src/model/admin_login_request.dart';
import 'package:pao_api/src/model/admin_password_change.dart';
import 'package:pao_api/src/model/admin_provider_detail.dart';
import 'package:pao_api/src/model/admin_provider_list.dart';
import 'package:pao_api/src/model/admin_provider_summary.dart';
import 'package:pao_api/src/model/admin_totp_request.dart';
import 'package:pao_api/src/model/admin_user.dart';
import 'package:pao_api/src/model/admin_user_invite.dart';
import 'package:pao_api/src/model/admin_user_invited.dart';
import 'package:pao_api/src/model/admin_user_list.dart';
import 'package:pao_api/src/model/admin_user_update.dart';
import 'package:pao_api/src/model/audit_entry.dart';
import 'package:pao_api/src/model/audit_list.dart';
import 'package:pao_api/src/model/booking.dart';
import 'package:pao_api/src/model/booking_address.dart';
import 'package:pao_api/src/model/booking_create.dart';
import 'package:pao_api/src/model/booking_item.dart';
import 'package:pao_api/src/model/booking_item_input.dart';
import 'package:pao_api/src/model/booking_list.dart';
import 'package:pao_api/src/model/booking_party.dart';
import 'package:pao_api/src/model/booking_summary.dart';
import 'package:pao_api/src/model/catalog_search_results.dart';
import 'package:pao_api/src/model/catalog_tree.dart';
import 'package:pao_api/src/model/category.dart';
import 'package:pao_api/src/model/category_input.dart';
import 'package:pao_api/src/model/code_of_conduct_input.dart';
import 'package:pao_api/src/model/complaint.dart';
import 'package:pao_api/src/model/complaint_assign_input.dart';
import 'package:pao_api/src/model/complaint_comment.dart';
import 'package:pao_api/src/model/complaint_comment_input.dart';
import 'package:pao_api/src/model/complaint_input.dart';
import 'package:pao_api/src/model/complaint_list.dart';
import 'package:pao_api/src/model/complaint_resolve_input.dart';
import 'package:pao_api/src/model/complete_input.dart';
import 'package:pao_api/src/model/customer_cancel_input.dart';
import 'package:pao_api/src/model/customer_profile.dart';
import 'package:pao_api/src/model/customer_profile_update.dart';
import 'package:pao_api/src/model/dashboard.dart';
import 'package:pao_api/src/model/dashboard_bookings_per_day_inner.dart';
import 'package:pao_api/src/model/delete_account_request.dart';
import 'package:pao_api/src/model/device_token_input.dart';
import 'package:pao_api/src/model/earnings_job.dart';
import 'package:pao_api/src/model/earnings_job_list.dart';
import 'package:pao_api/src/model/earnings_summary.dart';
import 'package:pao_api/src/model/earnings_summary_buckets_inner.dart';
import 'package:pao_api/src/model/emergency_contact_input.dart';
import 'package:pao_api/src/model/emergency_contact_verify_input.dart';
import 'package:pao_api/src/model/enrolment_status.dart';
import 'package:pao_api/src/model/enrolment_status_steps_inner.dart';
import 'package:pao_api/src/model/error_body.dart';
import 'package:pao_api/src/model/error_response.dart';
import 'package:pao_api/src/model/extras_decision_input.dart';
import 'package:pao_api/src/model/extras_input.dart';
import 'package:pao_api/src/model/extras_proposal.dart';
import 'package:pao_api/src/model/heartbeat_input.dart';
import 'package:pao_api/src/model/level2_info.dart';
import 'package:pao_api/src/model/level2_result_input.dart';
import 'package:pao_api/src/model/level2_result_input_checklist_inner.dart';
import 'package:pao_api/src/model/level2_session.dart';
import 'package:pao_api/src/model/level2_session_checklist_inner.dart';
import 'package:pao_api/src/model/level2_session_input.dart';
import 'package:pao_api/src/model/level2_session_list.dart';
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/logout_request.dart';
import 'package:pao_api/src/model/media_object.dart';
import 'package:pao_api/src/model/my_permissions.dart';
import 'package:pao_api/src/model/nearby_providers.dart';
import 'package:pao_api/src/model/nid_input.dart';
import 'package:pao_api/src/model/notification.dart';
import 'package:pao_api/src/model/notification_list.dart';
import 'package:pao_api/src/model/otp_request.dart';
import 'package:pao_api/src/model/otp_request_accepted.dart';
import 'package:pao_api/src/model/otp_verify_request.dart';
import 'package:pao_api/src/model/personal_info_input.dart';
import 'package:pao_api/src/model/point.dart';
import 'package:pao_api/src/model/police_clearance_input.dart';
import 'package:pao_api/src/model/presence_state.dart';
import 'package:pao_api/src/model/price_history.dart';
import 'package:pao_api/src/model/price_input.dart';
import 'package:pao_api/src/model/price_summary.dart';
import 'package:pao_api/src/model/price_version.dart';
import 'package:pao_api/src/model/provider_cancel_input.dart';
import 'package:pao_api/src/model/provider_card.dart';
import 'package:pao_api/src/model/provider_profile.dart';
import 'package:pao_api/src/model/provider_profile_update.dart';
import 'package:pao_api/src/model/provider_public_profile.dart';
import 'package:pao_api/src/model/rating_breakdown.dart';
import 'package:pao_api/src/model/receipt.dart';
import 'package:pao_api/src/model/refresh_request.dart';
import 'package:pao_api/src/model/reject_input.dart';
import 'package:pao_api/src/model/review.dart';
import 'package:pao_api/src/model/review_document.dart';
import 'package:pao_api/src/model/review_input.dart';
import 'package:pao_api/src/model/review_item.dart';
import 'package:pao_api/src/model/review_list.dart';
import 'package:pao_api/src/model/role_definition.dart';
import 'package:pao_api/src/model/role_list.dart';
import 'package:pao_api/src/model/role_update.dart';
import 'package:pao_api/src/model/selfie_input.dart';
import 'package:pao_api/src/model/service.dart';
import 'package:pao_api/src/model/service_area_check.dart';
import 'package:pao_api/src/model/service_area_input.dart';
import 'package:pao_api/src/model/service_input.dart';
import 'package:pao_api/src/model/service_ref.dart';
import 'package:pao_api/src/model/services_input.dart';
import 'package:pao_api/src/model/setting.dart';
import 'package:pao_api/src/model/setting_list.dart';
import 'package:pao_api/src/model/setting_update.dart';
import 'package:pao_api/src/model/skill_proof_input.dart';
import 'package:pao_api/src/model/start_code.dart';
import 'package:pao_api/src/model/status_reason.dart';
import 'package:pao_api/src/model/sub_service.dart';
import 'package:pao_api/src/model/sub_service_input.dart';
import 'package:pao_api/src/model/timeline_entry.dart';
import 'package:pao_api/src/model/token_pair.dart';
import 'package:pao_api/src/model/totp_enrolment.dart';
import 'package:pao_api/src/model/upload_request.dart';
import 'package:pao_api/src/model/upload_ticket.dart';
import 'package:pao_api/src/model/verification_item.dart';
import 'package:pao_api/src/model/verification_queue.dart';
import 'package:pao_api/src/model/verification_queue_item.dart';
import 'package:pao_api/src/model/verification_review.dart';
import 'package:pao_api/src/model/verification_review_profile.dart';
import 'package:pao_api/src/model/verification_status.dart';
import 'package:pao_api/src/model/view_url.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(
  dynamic value,
  String targetType, {
  bool growable = true,
}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'Account':
      return Account.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AccountStatus':
    case 'AccountStatusChange':
      return AccountStatusChange.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Address':
      return Address.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AddressInput':
      return AddressInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AddressLabel':
    case 'AddressList':
      return AddressList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminCustomerDetail':
      return AdminCustomerDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminCustomerList':
      return AdminCustomerList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminCustomerSummary':
      return AdminCustomerSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminLoginChallenge':
      return AdminLoginChallenge.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminLoginRequest':
      return AdminLoginRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminPasswordChange':
      return AdminPasswordChange.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminProviderDetail':
      return AdminProviderDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminProviderList':
      return AdminProviderList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminProviderSummary':
      return AdminProviderSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminRole':
    case 'AdminTotpRequest':
      return AdminTotpRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUser':
      return AdminUser.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminUserInvite':
      return AdminUserInvite.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUserInvited':
      return AdminUserInvited.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUserList':
      return AdminUserList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUserUpdate':
      return AdminUserUpdate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AppKind':
    case 'AuditEntry':
      return AuditEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AuditList':
      return AuditList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Badge':
    case 'Booking':
      return Booking.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'BookingAddress':
      return BookingAddress.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'BookingCreate':
      return BookingCreate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'BookingItem':
      return BookingItem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'BookingItemInput':
      return BookingItemInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'BookingList':
      return BookingList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'BookingParty':
      return BookingParty.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'BookingStatus':
    case 'BookingSummary':
      return BookingSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CatalogSearchResults':
      return CatalogSearchResults.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CatalogTree':
      return CatalogTree.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Category':
      return Category.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CategoryInput':
      return CategoryInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CodeOfConductInput':
      return CodeOfConductInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Complaint':
      return Complaint.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ComplaintAssignInput':
      return ComplaintAssignInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ComplaintComment':
      return ComplaintComment.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ComplaintCommentInput':
      return ComplaintCommentInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ComplaintInput':
      return ComplaintInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ComplaintList':
      return ComplaintList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ComplaintReason':
    case 'ComplaintResolveInput':
      return ComplaintResolveInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ComplaintStatus':
    case 'CompleteInput':
      return CompleteInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerCancelInput':
      return CustomerCancelInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerProfile':
      return CustomerProfile.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CustomerProfileUpdate':
      return CustomerProfileUpdate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Dashboard':
      return Dashboard.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DashboardBookingsPerDayInner':
      return DashboardBookingsPerDayInner.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'DeleteAccountRequest':
      return DeleteAccountRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DeviceTokenInput':
      return DeviceTokenInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EarningsJob':
      return EarningsJob.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'EarningsJobList':
      return EarningsJobList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EarningsPeriod':
    case 'EarningsSummary':
      return EarningsSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EarningsSummaryBucketsInner':
      return EarningsSummaryBucketsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EmergencyContactInput':
      return EmergencyContactInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EmergencyContactVerifyInput':
      return EmergencyContactVerifyInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EnrolmentStatus':
      return EnrolmentStatus.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EnrolmentStatusStepsInner':
      return EnrolmentStatusStepsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EnrolmentStep':
    case 'ErrorBody':
      return ErrorBody.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ErrorCode':
    case 'ErrorResponse':
      return ErrorResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExtrasDecisionInput':
      return ExtrasDecisionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExtrasInput':
      return ExtrasInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ExtrasProposal':
      return ExtrasProposal.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Gender':
    case 'HeartbeatInput':
      return HeartbeatInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ItemStatus':
    case 'ItemType':
    case 'Language':
    case 'Level2Info':
      return Level2Info.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Level2Result':
    case 'Level2ResultInput':
      return Level2ResultInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Level2ResultInputChecklistInner':
      return Level2ResultInputChecklistInner.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'Level2Session':
      return Level2Session.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Level2SessionChecklistInner':
      return Level2SessionChecklistInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Level2SessionInput':
      return Level2SessionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Level2SessionList':
      return Level2SessionList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LocalizedText':
      return LocalizedText.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LogoutRequest':
      return LogoutRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MediaObject':
      return MediaObject.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MyPermissions':
      return MyPermissions.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'NearbyProviders':
      return NearbyProviders.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'NidInput':
      return NidInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Notification':
      return Notification.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'NotificationList':
      return NotificationList.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OtpPurpose':
    case 'OtpRequest':
      return OtpRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'OtpRequestAccepted':
      return OtpRequestAccepted.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OtpVerifyRequest':
      return OtpVerifyRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PersonalInfoInput':
      return PersonalInfoInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Platform':
    case 'Point':
      return Point.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PoliceClearanceInput':
      return PoliceClearanceInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PresenceState':
      return PresenceState.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PriceHistory':
      return PriceHistory.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PriceInput':
      return PriceInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PriceSummary':
      return PriceSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PriceUnit':
    case 'PriceVersion':
      return PriceVersion.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProviderCancelInput':
      return ProviderCancelInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProviderCard':
      return ProviderCard.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProviderProfile':
      return ProviderProfile.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProviderProfileUpdate':
      return ProviderProfileUpdate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProviderPublicProfile':
      return ProviderPublicProfile.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RatingBreakdown':
      return RatingBreakdown.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Receipt':
      return Receipt.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RefreshRequest':
      return RefreshRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RejectInput':
      return RejectInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Review':
      return Review.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReviewDocument':
      return ReviewDocument.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReviewInput':
      return ReviewInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReviewItem':
      return ReviewItem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReviewList':
      return ReviewList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ReviewTag':
    case 'Role':
    case 'RoleDefinition':
      return RoleDefinition.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RoleList':
      return RoleList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RoleUpdate':
      return RoleUpdate.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SelfieInput':
      return SelfieInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Service':
      return Service.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ServiceAreaCheck':
      return ServiceAreaCheck.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ServiceAreaInput':
      return ServiceAreaInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ServiceInput':
      return ServiceInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ServiceModel':
    case 'ServiceRef':
      return ServiceRef.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ServicesInput':
      return ServicesInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Setting':
      return Setting.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SettingList':
      return SettingList.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SettingUpdate':
      return SettingUpdate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SkillProofInput':
      return SkillProofInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StartCode':
      return StartCode.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'StatusReason':
      return StatusReason.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SubService':
      return SubService.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SubServiceInput':
      return SubServiceInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TimelineEntry':
      return TimelineEntry.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Timing':
    case 'TokenPair':
      return TokenPair.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TotpEnrolment':
      return TotpEnrolment.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'UploadPurpose':
    case 'UploadRequest':
      return UploadRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'UploadTicket':
      return UploadTicket.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VerificationItem':
      return VerificationItem.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VerificationQueue':
      return VerificationQueue.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VerificationQueueItem':
      return VerificationQueueItem.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VerificationReview':
      return VerificationReview.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VerificationReviewProfile':
      return VerificationReviewProfile.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VerificationStatus':
      return VerificationStatus.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ViewUrl':
      return ViewUrl.fromJson(value as Map<String, dynamic>) as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toList(growable: growable)
            as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toSet()
            as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
          value.keys as Iterable<String>,
          value.values.map(
            (dynamic v) => deserialize<BaseType, BaseType>(
              v,
              targetType,
              growable: growable,
            ),
          ),
        ) as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
