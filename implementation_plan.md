# Implementation Plan: Background Execution & Ads

Support background FTP server execution using a foreground service and integrate Native Ads for monetization.

## User Review Required

> [!IMPORTANT]
> **Background Service**: On Android, this requires a persistent notification. I will implement a foreground service so the FTP server keeps running when the app is minimized.
> **Native Ads**: I will use AdMob test IDs for now. You will need to replace them with your real unit IDs in `lib/helpers/ad_helper.dart`.

## Proposed Changes

### [Fix] UI Polish
#### [MODIFY] [pulse_animation.dart](file:///home/syarif/Documents/p-flutter/wifi-ftp-integration/lib/widgets/pulse_animation.dart)
- Isolated the pulse effect in a fixed-size container to prevent "pushing" other UI elements.

---

### [Component] Background Service
#### [NEW] [background_service.dart](file:///home/syarif/Documents/p-flutter/wifi-ftp-integration/lib/services/background_service.dart)
- Initialize `flutter_background_service`.
- Handle the FTP server lifecycle within the service isolate.
- Communicate with the UI via the service instance.

#### [MODIFY] [main.dart](file:///home/syarif/Documents/p-flutter/wifi-ftp-integration/lib/main.dart)
- Initialize the background service on startup.

#### [MODIFY] [ftp_provider.dart](file:///home/syarif/Documents/p-flutter/wifi-ftp-integration/lib/providers/ftp_provider.dart)
- Update to toggle the background service instead of starting the server directly in the UI isolate.

---

### [Component] Monetization
#### [NEW] [ad_helper.dart](file:///home/syarif/Documents/p-flutter/wifi-ftp-integration/lib/helpers/ad_helper.dart)
- Manage AdMob unit IDs and helper methods for loading native ads.

#### [NEW] [native_ad_card.dart](file:///home/syarif/Documents/p-flutter/wifi-ftp-integration/lib/widgets/native_ad_card.dart)
- A reusable glassmorphic card to display Native Ads.

#### [MODIFY] [connection_screen.dart](file:///home/syarif/Documents/p-flutter/wifi-ftp-integration/lib/screens/connection/connection_screen.dart)
- Inject the native ad card into the dashboard.

## Verification Plan

### Automated Tests
- `flutter pub get` (Done)
- Monitor logs for background service initialization.

### Manual Verification
- Start FTP server, minimize app, and check if FileZilla can still connect.
- Check the dashboard for the Native Ad placeholder.
- Verify the START button pulse effect doesn't move the storage card below it.
