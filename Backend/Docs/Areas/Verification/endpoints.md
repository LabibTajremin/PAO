# Verification area — endpoints

All in `VerificationControllers` (see [authorisation](../../Architecture/authorization.md)).
Errors map through `VerificationErrorMap` to the NestJS codes.

| Controller | Operation | Route | Attribute |
|---|---|---|---|
| `EnrolmentDocumentsController` | saveNid, saveSelfie, savePoliceClearance, saveSkillProof | `PUT /v1/provider/enrolment/{nid,selfie,police-clearance,skill-proof}` | `[Merchant(Permission = "provider:manage:own")]` |
| `EnrolmentDocumentsController` | submitEnrolment | `POST /v1/provider/enrolment/submit` | `[Merchant(Permission = "verification:submit")]` |
| `VerificationStatusController` | getVerificationStatus | `GET /v1/provider/verification` | `[Merchant(Permission = "provider:manage:own")]` |
| `VerificationReviewController` | queue, review, approve, reject | `/v1/admin/verifications…` | `[Admin(Permission = "verification:review")]` |
| `Level2SessionsController` | list, schedule (201), get, record result | `/v1/admin/level2-sessions…` | `[Admin(Permission = "level2:manage")]` |
