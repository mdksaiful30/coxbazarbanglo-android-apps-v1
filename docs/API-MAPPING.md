# API mapping

API base ends with `/api/v1`. Android emulator localhost is `10.0.2.2`; browser localhost is `127.0.0.1`. Credentials are exchanged for a revocable 30-day Sanctum token, stored with flutter_secure_storage where supported. Existing tokens are never forwarded when the operator changes server. Absolute pagination destinations are rejected.

| Screen | Endpoints |
|---|---|
| Access | POST auth/mobile/login, GET auth/me, POST auth/logout, forgot-password/reset-password |
| Account | GET/PATCH auth/preferences, PUT auth/password, GET/DELETE auth/devices |
| Dashboard | GET dashboard |
| Calendar / rooms | GET catalog, calendar, availability; PATCH rooms/{id} |
| Guests | GET/POST guests; PUT guests/{id} |
| Draft editor | POST booking-quotes, POST bookings, PATCH bookings/{id} |
| Approval/lifecycle | POST bookings/{id}/submit, approve, reject, return-for-correction, cancel, mark-no-show, check-in, check-out |
| Approved edit | PATCH bookings/{id}/approved-details |
| Amendments | POST bookings/{id}/amendments and booking-amendments/{id}/approve or reject |
| Finance | POST bookings/{id}/payments or credit-notes; POST payments/{id}/refunds or reverse |
| Documents | GET bookings/{id}/exports/pdf or jpg; POST bookings/{id}/attachments; GET attachments/{id}/download |
| Guest sharing | GET share-options/shares; POST bookings/{id}/share |
| Reservations | GET/POST room-blocks; POST room-blocks/{id}/release |
| Tariffs | GET tariffs and tariffs/{id}; POST clone/activate; PATCH tariffs/{id}/rates/{rateId} |
| Staff | GET/POST users; PUT users/{id} |
| Reports | GET reports and reports/export with start/end |
| Notifications | GET notifications; POST notifications/{id}/retry |
| Audit | GET audit-logs |

Money always stays in integer poisha in requests and responses. The finance form accepts BDT and converts it exactly to integer poisha; display formatting divides server amounts by 100. Booking input includes `+06:00`. SQL-style booking timestamps are already Dhaka-local; explicit-offset timestamps are converted to Dhaka for display. Calendar query end is exclusive. Quotes and availability are previews, revalidated at save/approval.

Mutation requests use an Idempotency-Key. The client retains the key for an uncertain network/server failure, and reuses it for an identical body during the same running session. Keys are not persisted across app restarts. After an interrupted app restart, inspect booking/payment history before submitting another action. There are no blind automatic retries. On 409 reload the record and review dates, allocation and version before continuing. The backend still enforces every role and lifecycle rule.

Files are downloaded as authenticated bytes, never as public token-bearing URLs. The share sheet uses a prepared file and a second user gesture (important for browser sharing and iPad positioning). Internal notes remain visible only to authenticated staff and are excluded by the guest-document API. Server shares target the saved booking guest only; PDF/JPG via server supports email, while WhatsApp uses text/approved templates.

Reference master setup (properties/buildings/floors/category master CRUD) remains in the Laravel administration/API. System, queue and audit infrastructure do not have arbitrary CRUD forms. No public guest registration, online payment gateway or staff push-notification service is added.
