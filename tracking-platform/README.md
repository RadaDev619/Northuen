# Northuen Tracking Platform

This folder is a parallel Flutter + Node/Express tracking implementation for runner navigation and customer live tracking.

The existing project in this repo is Flutter + Spring Boot. This module does not replace it automatically; it provides the requested stack and can be integrated with the existing order lifecycle.

## Stack

- Mobile: Flutter
- Backend: Node.js / Express
- Database/realtime: Supabase Realtime
- Maps on mobile: Google Maps SDK for Android through `google_maps_flutter`
- Server-side Google APIs:
  - Routes API
  - Roads API
  - Places API (New)
  - Geocoding API

## Google API Key Split

Use separate restricted keys:

- Android mobile key:
  - Used by Flutter `google_maps_flutter`.
  - Restrict to Android app package and SHA-1.
  - Enable Maps SDK for Android.

- Server key:
  - Used only by the Node backend.
  - Restrict by server IP if possible.
  - Enable Routes API, Roads API, Places API (New), and Geocoding API.
  - Never ship this key in the mobile app.

Official references used:

- Flutter `google_maps_flutter`: https://pub.dev/packages/google_maps_flutter
- Routes API `computeRoutes`: https://developers.google.com/maps/documentation/routes/reference/rest/v2/TopLevel/computeRoutes
- Roads API Snap to Roads: https://developers.google.com/maps/documentation/roads/snap
- Places API (New) autocomplete: https://developers.google.com/maps/documentation/places/web-service/place-autocomplete

## Supabase Setup

Run:

```sql
-- tracking-platform/supabase/tracking_schema.sql
```

Tables:

- `runner_locations_latest`: one live row per order; this is the realtime subscription table.
- `runner_location_history`: raw and snapped GPS history for debugging/replay.
- `delivery_routes`: latest server-calculated encoded route, ETA, distance, and duration.

Realtime:

- `runner_locations_latest` and `delivery_routes` are added to `supabase_realtime` if the publication exists.
- The included RLS read policies are intentionally broad for MVP testing. Replace them with order membership policies before production.

## Backend Setup

```powershell
cd "C:\Users\a\Documents\New project\tracking-platform\backend"
copy .env.example .env
npm install
npm run dev
```

Configure `.env`:

```text
PORT=8082
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
GOOGLE_SERVER_API_KEY=your-server-restricted-google-key
TRACKING_ALLOWED_ORIGINS=*
```

Endpoints:

- `POST /api/tracking/locations`
  - Runner sends `orderId`, `runnerId`, `lat`, `lng`, `heading`, `speed`, `accuracy`, `timestamp`, and `status`.
  - Active statuses: `accepted`, `picked_up`, `on_the_way`.
  - Terminal statuses: `delivery_completed`, `delivered`, `cancelled`.

- `POST /api/tracking/routes`
  - Backend calls Google Routes API and stores route snapshots.
  - Mobile receives encoded polyline, ETA, distance, and duration.

- `GET /api/tracking/orders/:orderId`
  - Returns latest location and latest route snapshot.

- `GET /api/tracking/places/autocomplete?input=...&sessionToken=...`
  - Backend proxy to Places API (New).

- `GET /api/tracking/geocode?address=...`
  - Backend proxy to Geocoding API.

## Mobile Setup

```powershell
cd "C:\Users\a\Documents\New project\tracking-platform\mobile"
flutter pub get
flutter run --dart-define=TRACKING_API_BASE_URL=http://192.168.1.173:8082 `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key `
  --dart-define=GOOGLE_MAPS_API_KEY=your-android-restricted-google-maps-key
```

Build an APK:

```powershell
cd "C:\Users\a\Documents\New project\tracking-platform\mobile"
flutter build apk --release `
  --dart-define=TRACKING_API_BASE_URL=http://192.168.1.173:8082 `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key `
  --dart-define=GOOGLE_MAPS_API_KEY=your-android-restricted-google-maps-key
```

The checked-in default Google Maps key is the key you provided earlier. For production, use an Android-restricted key.

## Tracking Behavior

Runner:

- Requests foreground location permission.
- Watches GPS with `LocationAccuracy.bestForNavigation`.
- Sends location every 5 seconds or roughly every 8 meters.
- Sends heading, speed, accuracy, timestamp, and order id.
- Camera follows runner with heading and pitch for a navigation-like view.
- Backend rejects tracking updates unless the order status is active.

Customer:

- Subscribes to `runner_locations_latest` for the order.
- Subscribes to `delivery_routes` for route updates.
- Updates the runner marker and animates the camera as realtime updates arrive.
- Shows pickup, drop-off, blue route line, ETA, distance, and order status.
- Shows stale GPS warning if no update arrives for more than 30 seconds.

Backend route and snapping:

- Routes API calls happen server-side only.
- Roads API snapping is batched every 20 seconds when enough points are available.
- Raw GPS and snapped GPS are both stored.
- Route recalculation is throttled to roughly every 45 seconds unless `force=true`.

## Integration Notes

To connect this to the existing Northuen order system:

1. Use real `orderId` and `runnerId` from the authenticated app session.
2. Pass the actual order status into `RunnerNavigationScreen`.
3. Choose destination:
   - `accepted`: pickup point.
   - `picked_up` or `on_the_way`: drop-off point.
4. Call `/api/tracking/routes` when:
   - delivery starts,
   - runner picks up,
   - app detects off-route,
   - every 30-60 seconds during active tracking.
5. Lock down Supabase RLS so only the customer, runner, and admins for an order can read tracking rows.
