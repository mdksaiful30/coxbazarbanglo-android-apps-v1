# Full-week mobile booking calendar

Updated 19 October 2026. The mobile calendar now fits all seven days across the phone screen. Each room has a compact row, with a current-day highlight and separate Available, Booked, Pending and Blocked indicators. Tapping a cell opens a scrollable detail sheet with the full room/date information, guest, booking reference, status and stay dates, plus a button to open the booking. Empty and maintenance-block cells also provide details. Larger screens keep the existing weekly text table.

Analysis and all 21 tests pass. Tests check every date column fits within 320, 390 and 540-pixel phone widths with 1.6x text scaling; booking and maintenance detail sheets; week navigation; malformed date handling; and the tablet table. The updated phone preview was captured from real widgets with synthetic data and inspected. The screenshot ZIP was refreshed.

Latest signed bundle: releases/coxbazarbanglo-1.0.0-1-weekly-calendar.aab. Version remains 1.0.0+1 as requested for the first upload. Signature, matching upload certificate, ZIP integrity, embedded branding, package/version values and bundletool validation passed. Flutter web was rebuilt. No physical-device or Play Console test was performed.
