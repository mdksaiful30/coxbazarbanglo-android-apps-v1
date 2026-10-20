# Workspace UI refresh

Updated 19 October 2026.

Dashboard now has a workspace header, compact responsive metric cards, and a clear daily activity/balance panel. The occupied count is labelled as stays, matching the backend's checked-in booking count. No artificial trends or statistics were added.

Bookings now have a grouped filter surface, full-width cards, guest identity, explicit check-in/check-out rows and room badges. Search, server pagination, status filtering and opening bookings retain the existing callbacks.

Guests and Staff have identity cards with initials, contact details, roles and active-account status. Notifications have channel/delivery cards, destination, timestamps, delivery errors and the existing confirmed retry action. Audit trail has timeline-style event cards with entity, staff ID and time. Audit entities use the backend's `entity` field with the previous alternative as a fallback. Loaded-record counters describe the loaded records, not overall server totals. Existing edit/view/retry controls remain.

All room cards show right-hand artwork and the specific room name in English and Bengali beneath each image. Six bundled illustrations cover AC twin, non-AC twin, AC double/couple, non-AC double/couple, suite and waiting-room types. They are chosen from the supplied name/type/bed metadata and work offline. They are conceptual artwork, not photos or guarantees of the property's amenities. See ROOM-ARTWORK.md for the generation prompts and saved assets.

The existing full-week mobile calendar remains in place.

Validation: Flutter analysis and all 30 tests pass. New tests exercise populated pages at 320, 390 and 1280 logical pixels in both themes with enlarged text, verify the room-image mapping, confirm the actual audit entity field, and check that a notification retry still requires confirmation. Seven phone page previews were captured from the actual widgets with synthetic data and reviewed. Store screenshots were generated for the preceding UI refresh. The seven workspace previews include the latest bilingual room captions; image decoding is awaited before capture.

Latest signed upload bundle: releases/coxbazarbanglo-1.0.0-1-room-names.aab. Version 1.0.0+1 is retained as requested for the first upload. Android and production Flutter web outputs are rebuilt. Bundle signing, embedded room images, ZIP integrity, version/package, native alignment and bundletool validation are recorded in RELEASE-VERIFICATION.json. No physical-device or Play Console upload was performed.
