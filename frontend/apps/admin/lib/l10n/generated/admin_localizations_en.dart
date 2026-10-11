// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AdminL10nEn extends AdminL10n {
  AdminL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PAO Admin';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navVerification => 'Verification';

  @override
  String get navLevel2 => 'Level 2 sessions';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get navProviders => 'Providers';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navComplaints => 'Complaints';

  @override
  String get navSettings => 'Settings';

  @override
  String get loginTitle => 'Sign in to PAO Admin';

  @override
  String get loginEmail => 'Work email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginEnrolBody =>
      'First sign-in: add this key to your authenticator app.';

  @override
  String get loginCodeBody =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get loginBack => 'Use another account';

  @override
  String get passwordTitle => 'Choose a new password';

  @override
  String get passwordBody =>
      'Replace the temporary password from your invitation before you continue.';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordNew => 'New password (at least 12 characters)';

  @override
  String get passwordRepeat => 'Repeat the new password';

  @override
  String get passwordTooShort =>
      'The new password needs at least 12 characters.';

  @override
  String get passwordMismatch => 'The two new passwords are not the same.';

  @override
  String get reasonLabel => 'Reason';

  @override
  String reasonTooShort(int count) {
    return 'Write at least $count characters.';
  }

  @override
  String get formRequired => 'Fill this in.';

  @override
  String formTooLong(String max) {
    return 'Keep it to $max characters or fewer.';
  }

  @override
  String get formWhole => 'Enter a whole number.';

  @override
  String get formNumber => 'Enter a number.';

  @override
  String formAtLeast(String min) {
    return 'Enter $min or more.';
  }

  @override
  String formRange(String min, String max) {
    return 'Enter a number from $min to $max.';
  }

  @override
  String get formMoney => 'Enter an amount in taka, such as 500 or 499.50.';

  @override
  String get formEmail => 'Enter a valid email address.';

  @override
  String get formSaved => 'Saved.';

  @override
  String get dashTitle => 'Dashboard';

  @override
  String dashUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get dashRefresh => 'Refresh';

  @override
  String get dashPendingVerifications => 'Pending verifications';

  @override
  String get dashOpenComplaints => 'Open complaints';

  @override
  String get dashCompletionRate => 'Completion rate';

  @override
  String get dashBookings => 'Bookings in this period';

  @override
  String get dashActiveProviders => 'Active providers';

  @override
  String get dashBookingsPerDay => 'Bookings per day';

  @override
  String get dashLegendTotal => 'All bookings';

  @override
  String get dashLegendCompleted => 'Completed';

  @override
  String dashDayTip(String day, String total, String completed) {
    return '$day: $total bookings, $completed completed';
  }

  @override
  String get dashNoBookings => 'No bookings in this period yet.';

  @override
  String get dashProvidersByStatus => 'Providers by status';

  @override
  String get dashProvidersByLevel => 'Providers by level';

  @override
  String get dashNoProviders => 'No providers yet.';

  @override
  String get dashStatusPending => 'Pending';

  @override
  String get dashStatusActive => 'Active';

  @override
  String get dashStatusSuspended => 'Suspended';

  @override
  String get dashStatusBanned => 'Banned';

  @override
  String get dashLevel0 => 'Level 0 · Registered';

  @override
  String get dashLevel1 => 'Level 1 · Verified';

  @override
  String get dashLevel2 => 'Level 2 · PAO Verified Pro';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String catalogVersion(String version) {
    return 'Version $version';
  }

  @override
  String get catalogEmptyTitle => 'No categories yet';

  @override
  String get catalogEmptyBody =>
      'Add a category, then the services customers can book in it.';

  @override
  String get catalogNewCategory => 'New category';

  @override
  String get catalogEditCategory => 'Edit category';

  @override
  String catalogCategoryLine(String other, String order, String count) {
    return '$other · order $order · $count services';
  }

  @override
  String get catalogNewService => 'New service';

  @override
  String get catalogServiceTitle => 'Service';

  @override
  String get catalogBack => 'Back to catalog';

  @override
  String get catalogPublished => 'Published';

  @override
  String get catalogHidden => 'Hidden';

  @override
  String get catalogPublishedSwitch => 'Published';

  @override
  String get catalogPublishedHint => 'Customers see it in the apps.';

  @override
  String get catalogName => 'Name';

  @override
  String get catalogDescription => 'Description';

  @override
  String catalogInEnglish(String label) {
    return '$label (English)';
  }

  @override
  String catalogInBangla(String label) {
    return '$label (Bangla)';
  }

  @override
  String get catalogIconKey => 'Icon key';

  @override
  String get catalogPickIcon => 'Pick a known icon';

  @override
  String get catalogSortOrder => 'Sort order';

  @override
  String get catalogAddRow => 'Add';

  @override
  String get catalogRemoveRow => 'Remove';

  @override
  String get catalogServiceDetails => 'Service details';

  @override
  String get catalogCategory => 'Category';

  @override
  String get catalogModel => 'Service model';

  @override
  String get catalogLevel => 'Required level';

  @override
  String get catalogRadius => 'Search radius (metres)';

  @override
  String get catalogRadiusHint => 'From 500 to 50000';

  @override
  String get catalogWomenOnly => 'Women providers only';

  @override
  String get catalogWomenOnlyHint => 'Requests go only to women providers.';

  @override
  String get catalogRequiresLevel2 => 'Requires Level 2';

  @override
  String get catalogRequiresLevel2Hint =>
      'Providers pass an in-person skill check first.';

  @override
  String get catalogChecklistItem => 'Checklist item';

  @override
  String get catalogModelOnDemand => 'On-demand visit';

  @override
  String get catalogModelDuration => 'Duration hire';

  @override
  String get catalogModelListing => 'Listing';

  @override
  String get catalogModelPartner => 'Partner referral';

  @override
  String get catalogUnitJob => 'per job';

  @override
  String get catalogUnitUnit => 'per unit';

  @override
  String get catalogUnitHour => 'per hour';

  @override
  String get catalogUnitDay => 'per day';

  @override
  String get catalogSubServices => 'Sub-services';

  @override
  String get catalogNoSubServices =>
      'No sub-services yet. Add one so customers can book this service.';

  @override
  String get catalogNewSubService => 'New sub-service';

  @override
  String get catalogEditSub => 'Edit sub-service';

  @override
  String catalogMaxLine(String count) {
    return 'up to $count';
  }

  @override
  String get catalogInclusion => 'Included';

  @override
  String get catalogExclusion => 'Not included';

  @override
  String get catalogUnit => 'Priced';

  @override
  String get catalogMaxQuantity => 'Most per booking';

  @override
  String get catalogMaxQuantityHint => 'Leave empty for no limit';

  @override
  String get catalogFirstPrice => 'Price';

  @override
  String get catalogPrices => 'Prices';

  @override
  String catalogPricesOf(String name) {
    return 'Prices of $name';
  }

  @override
  String get catalogPriceNote =>
      'A new price applies to bookings made from now on. Earlier bookings keep the price they were made at.';

  @override
  String catalogNewPrice(String unit) {
    return 'New price ($unit)';
  }

  @override
  String get catalogSetPrice => 'Set new price';

  @override
  String get catalogPriceChanged => 'Price updated.';

  @override
  String get catalogPriceHistory => 'Price history';

  @override
  String get catalogNoPrices => 'No prices recorded yet.';

  @override
  String catalogPriceSince(String when, String admin) {
    return 'From $when · by $admin';
  }

  @override
  String get catalogCurrentPrice => 'Current';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTabSettings => 'Platform settings';

  @override
  String get settingsTabAdmins => 'Admin users';

  @override
  String get settingsTabRoles => 'Roles';

  @override
  String get settingsTabAudit => 'Audit log';

  @override
  String get settingsEmpty => 'No settings yet';

  @override
  String get settingsSearch => 'Search settings';

  @override
  String settingsUpdatedAt(String when) {
    return 'Changed $when';
  }

  @override
  String get settingsEdit => 'Change setting';

  @override
  String get settingsValue => 'Value';

  @override
  String get settingsOn => 'On';

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsShape => 'Map shape';

  @override
  String get settingsBadShape => 'Paste a GeoJSON object with a \"type\".';

  @override
  String get settingsApplyNow =>
      'The change applies right away and is recorded in the audit log.';

  @override
  String get settingsRoleCustomer => 'Customer';

  @override
  String get settingsRoleProvider => 'Provider';

  @override
  String get settingsRoleVerifier => 'Verifier';

  @override
  String get settingsRoleCatalogManager => 'Catalog manager';

  @override
  String get settingsRoleSupportAgent => 'Support agent';

  @override
  String get settingsRoleSuperAdmin => 'Super admin';

  @override
  String get adminsInvite => 'Invite admin';

  @override
  String get adminsSendInvite => 'Send invite';

  @override
  String get adminsEmpty => 'No admin users yet';

  @override
  String get adminsEmail => 'Work email';

  @override
  String get adminsName => 'Full name';

  @override
  String get adminsNameShort => 'Write at least 2 characters.';

  @override
  String get adminsRoles => 'Roles';

  @override
  String get adminsPickRole => 'Pick at least one role.';

  @override
  String get adminsInvitedTitle => 'Invitation created';

  @override
  String adminsInvitedBody(String name) {
    return 'Give this temporary password to $name privately. It is shown only once; they replace it and set up 2FA when they first sign in.';
  }

  @override
  String get adminsCopy => 'Copy password';

  @override
  String get adminsCopied => 'Copied.';

  @override
  String get adminsDone => 'Done';

  @override
  String get adminsNeverSignedIn => 'Has not signed in yet';

  @override
  String adminsLastSignIn(String when) {
    return 'Last signed in $when';
  }

  @override
  String get adminsActive => 'Active';

  @override
  String get adminsInactive => 'Deactivated';

  @override
  String get adminsTotpOn => '2FA set up';

  @override
  String get adminsTotpOff => '2FA pending';

  @override
  String get adminsEdit => 'Change roles or access';

  @override
  String get adminsActiveSwitch => 'Can sign in';

  @override
  String get adminsActiveHint =>
      'Turning this off ends their sessions at once.';

  @override
  String adminsDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get adminsDeactivateBody =>
      'They are signed out everywhere now and cannot sign in until reactivated.';

  @override
  String get adminsDeactivate => 'Deactivate';

  @override
  String get rolesEmpty => 'No roles found';

  @override
  String get rolesApplyNow =>
      'Role changes apply immediately to everyone who holds the role.';

  @override
  String rolesCounts(String permissions, String screens) {
    return '$permissions permissions · $screens screens';
  }

  @override
  String get rolesEdit => 'Edit role';

  @override
  String get rolesPermissions => 'Permissions';

  @override
  String get rolesScreens => 'Screens';

  @override
  String rolesConfirmTitle(String role) {
    return 'Apply the changes to $role?';
  }

  @override
  String get rolesApply => 'Apply now';

  @override
  String get rolesSaved => 'Role updated.';

  @override
  String get auditWhen => 'When';

  @override
  String get auditActor => 'Who';

  @override
  String get auditRole => 'Role';

  @override
  String get auditAction => 'Action';

  @override
  String get auditSubject => 'Subject';

  @override
  String get auditReason => 'Reason';

  @override
  String get auditBefore => 'Before';

  @override
  String get auditAfter => 'After';

  @override
  String get auditSystem => 'System';

  @override
  String get auditEmpty => 'No audit entries match';

  @override
  String get auditActorId => 'Actor ID';

  @override
  String get auditActorInvalid => 'Paste a full account ID.';

  @override
  String get auditActionHint => 'Action, e.g. catalog.price_changed';

  @override
  String get auditSubjectId => 'Subject ID';

  @override
  String get auditAnyDate => 'Any date';

  @override
  String get auditApply => 'Apply';

  @override
  String get auditClear => 'Clear';
}
