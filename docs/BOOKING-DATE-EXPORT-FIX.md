# Booking date and Flutter export fixes — 20 October 2026

New bookings and draft edits reject arrivals before the current date in Asia/Dhaka, regardless of role. Old drafts cannot be submitted or approved once their arrival day has passed. Today is allowed even if the chosen arrival time has already passed. Existing approved stay history remains editable through the established administrator workflow.

The Laravel booking form and Flutter date picker disable past arrival days. The server enforces the rule independently of browser/device controls. The Laravel form resets an old room-search date when starting a new booking.

Flutter Generate PDF and Generate JPG fetch the authenticated guest-confirmation data and generate real files locally. Server-side Chromium is no longer required for these two Flutter buttons. Bundled fonts preserve Bengali shaping. Use Save PDF/Save JPG to choose the destination, or Share prepared file to share the generated document. The output retains the existing booking/payment-summary meaning and confirmation/provisional warnings; it is not a separate payment receipt.

## Live Laravel deployment

Upload `app/Services/BookingService.php` and the complete `public/build/` folder from the deployment ZIP. Preserve the folder structure relative to your Laravel project. If the domain document root is `public_html`, place the contents of `public/build/` in `public_html/build/`, and place the service file in the Laravel project outside the document root. `resources/js/App.vue` is included as source for future builds.

Run `php artisan optimize:clear` from the Laravel project directory. No database migration is required. Keep the existing `.env` and signing credentials unchanged.

Install the new Flutter app release to receive the app-side fixes. Laravel file upload alone cannot update an already installed app. No changes have been uploaded to the live server or Play Console automatically.

## Validation

Laravel: 52 tests passed, including past-day rejection for admin/staff-admin, UTC-to-Dhaka midnight boundaries, today's arrival acceptance, and stale draft submission/approval rejection. Production Vue build passed. Flutter tests cover disabled date selection, valid PDF/JPEG signatures, Bengali rendering, and both generation buttons offering Save/Share.
