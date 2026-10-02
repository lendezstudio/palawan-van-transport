# Palawan Van Transport & Travel Services — website concept

Static site (HTML/CSS/JS, no framework). The deployable site is in `site/`.

## Edit and build
- Page content: `src/pages/*.html`. Shared header, footer, FAQ and CTAs: `src/partials/`.
- Routes: `src/data/routes.json`. Each entry generates `site/transfers/<slug>/` from `src/templates/route.html`.
  Fill in `details` (pickup, dropoff, departures, travelTime, sharedFare, privateFare, luggage) once the business confirms them.
  A filled value appears under "Route at a glance". An empty value stays in the "Confirmed when you inquire" list.
- Contact details and settings: `src/data/site.json`.
- Rebuild: `powershell -ExecutionPolicy Bypass -File build.ps1`
- Preview: `powershell -ExecutionPolicy Bypass -File tools\serve.ps1 -Port 8765`, then open http://localhost:8765/

## Before going live
1. Set `siteUrl` in `src/data/site.json` to the real domain, then rebuild. It drives the canonical links, Open Graph URLs, sitemap and schema. It's currently a placeholder (`.example`).
2. Form: with no backend, "Send Travel Request" validates the form, then hands the request to WhatsApp or email with the details pre-filled.
   To collect submissions directly, put a form-service URL (e.g. Formspree) in `formEndpoint` and rebuild.
3. Confirm with the business: fares, schedules, pickup points, travel times, luggage policy, payment and cancellation rules, extra phone numbers, and permission to publish guest reviews and photos.
   Add verified testimonials where marked in `src/pages/index.html`.

## Image tools (Windows PowerShell, System.Drawing)
- `tools/process-images.ps1` — resizes the client photos in `Images/` into `site/assets/img/`
- `tools/make-brand.ps1` — transparent logo and emblem, favicons
- `tools/make-wordmark.ps1` — header wordmark cut from the full logo
- `tools/make-og.ps1` — 1200×630 social preview image
