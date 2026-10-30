# Merchant area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Use case | Kind | Notes |
|---|---|---|---|
| `Enrolment` | `GetEnrolment` | query | nine steps; skill proof optional; nothing saved means every step open |
| `Enrolment` | `SavePersonalStep`, `SaveServicesStep`, `SaveAreaStep`, `SaveCodeOfConductStep` | command | AGE_REQUIREMENT (18 on the Dhaka date), SERVICE_UNAVAILABLE, VALIDATION_FAILED; saving services takes the merchant offline |
| `Enrolment` | `SaveEmergencyContactStep`, `VerifyEmergencyContact` | command | a one-time code to the guarantor through Identity; a failed send rolls back; OTP_INVALID, RATE_LIMITED, EMERGENCY_CONTACT_MISSING |
| `Profile` | `GetMerchantProfile`, `UpdateMerchantProfile`, `GetMerchantPublicProfile` | query/command | own profile with presence and badge; bio, language and own avatar; customers see only verified, active merchants |
| `Presence` | `GoOnline`, `SendHeartbeat`, `GoOffline`, `ReapLostPresence` | command | NOT_VERIFIED, SERVICE_AREA_MISSING, OFFLINE; the reaper backs the `provider.reap_lost_presence` job |
| `PerfSeed` | `AddPerfMerchant` | command | `migrate perf-seed N`: a Level 1 electrician written straight to the schemas and put online |
