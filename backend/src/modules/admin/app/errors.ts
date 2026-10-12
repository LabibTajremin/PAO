/** `DomainError` reasons of the admin module; only `adapter/http` maps them to API errors. */
export const AdminErrors = {
  /** No setting has the key. */
  SettingNotFound: 'admin.setting_not_found',
  /** The value does not match the setting's type. */
  SettingInvalid: 'admin.setting_invalid',
  /** No complaint has the id. */
  ComplaintNotFound: 'admin.complaint_not_found',
  /** The booking is unknown, or the caller is not its party in the reporting role. */
  BookingNotFound: 'admin.booking_not_found',
  /** Reason, description, photo list or resolution note break the rules. */
  ComplaintInvalid: 'admin.complaint_invalid',
  /** A photo is not the reporter's confirmed complaint photo. */
  PhotoInvalid: 'admin.photo_invalid',
  /** The assignee is not an active support agent or super admin. */
  AssigneeInvalid: 'admin.assignee_invalid',
  /** The complaint is already resolved. */
  AlreadyResolved: 'admin.complaint_already_resolved',
  /** No provider or customer has the id. */
  PersonNotFound: 'admin.person_not_found',
} as const;
