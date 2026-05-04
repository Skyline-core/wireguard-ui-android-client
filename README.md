# wireguard-ui-android-client

Android **Flutter** client for **[WireGuard UI](https://github.com/Skyline-core/wireguard-ui/tree/master)** — the same backend that serves the web panel and JSON APIs. The app manages peers, traffic views, and server actions through authenticated HTTP (cookies + optional Passkeys), not by configuring WireGuard directly on the phone.

**Supported target:** **Android** (APK / AAB). This repository keeps only the `**android/`** Flutter platform; desktop and web targets are omitted on purpose.

---

## App features

### Authentication and server connection

- **Sign in** with username and password against your WireGuard UI deployment; optional **remember me** for session persistence.
- **Configurable panel URL** (scheme, host, port, and optional **base path** such as `/wg`) so the client matches your reverse proxy layout.
- **Passkeys (WebAuthn)** via Android **Credential Manager**: passwordless sign-in when the server and domain asset links are configured; optional **Passkey public origin (HTTPS)** when the credential was enrolled on a different origin than the API base URL.
- **Session restore** on cold start when cookies are still valid; **logout** clears the local session and push registration when enabled.

### Main shell and navigation

- **Bottom navigation** with four areas: **Home**, **Peers**, **Traffic**, and **Settings**, using **shared-axis** transitions between tabs.
- **Apply config** banner (when the server reports pending WireGuard changes): reminds you to apply `wg.conf` from the panel workflow, consistent with the web UI.
- **Offline mode**: if the device loses the server while the session is still valid, the app can show **cached** dashboard / peer / traffic snapshots (read-only). A **pull-to-refresh** gesture and **returning from background** attempt to **reconnect** immediately; a periodic retry still runs while offline.

### Home (dashboard)

- **Tunnel summary** (interface name, up/down state, online sessions, throughput hints).
- **Quick actions**: **New client** (peer), **Refresh**, **Download all configs** as a ZIP (share sheet).
- **Peer preview list** (subset of clients) with **24h traffic** hints when data is available, **open peer detail**, and **enable / disable** toggle when online.
- **Shortcuts** to search-focused **Peers** tab and **Profile** (when online).

### Peers

- **Searchable** client list with **filter chips** (all, traffic online/offline, enabled/disabled).
- **Open peer detail** for full fields, QR/config-related flows aligned with the API, and refresh after edits.
- **Create new peer** from the FAB (when online).

### Traffic

- **Traffic analytics** view: live KPI card, **range presets** (24h, 7d, 30d), aggregate or per-peer charts (depends on server settings), and **peer ranking** for the selected window.
- **Pull-to-refresh** to reload series and stats.

### Logs

- **System / tunnel logs** viewer when the server exposes log APIs and navigation hints allow it (same gating idea as the web UI).

### Settings and profile

- **Server / tunnel readouts** and links to **Profile** (display name, email, password, Passkeys management) and **Logs** when available.
- **Push notifications** toggle: registers or unregisters the device FCM token with the server (`/api/push/register` / `/api/push/unregister`) when Firebase is configured on both sides.
- **Realtime monitoring** toggle for admins (maps to server **realtime stats** / logs nav hints).
- **About / legal** and **sign out**; in offline mode, destructive settings remain blocked except where explicitly allowed (e.g. logout messaging per your server rules).

### Background behavior

- **Firebase Cloud Messaging** for server-driven alerts when enabled.
- **WorkManager / scheduler** hooks to align periodic server health checks with Android constraints (see `lib/background/`).

---

## System context (what you must run)

This project **does not replace** a WireGuard server. It talks to a **WireGuard UI** instance over the network. You need both of the following in your stack:


| Component              | Purpose                                                                                                                                                                    | Reference                                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **WireGuard UI**       | HTTP API, session auth, optional FCM push, Passkeys, and the same data model as the web UI. This Android app is built against that server.                                 | **[Skyline-core / wireguard-ui (master)](https://github.com/Skyline-core/wireguard-ui/tree/master)** |
| **WireGuard on Linux** | Kernel module and tools (`wg`, `wg-quick`, interfaces) that actually carry VPN traffic for your peers. WireGuard UI reads/writes `wg.conf` and applies config on the host. | **[wireguard.com](https://www.wireguard.com/)**                                                      |


Deploy WireGuard UI on a host where WireGuard is installed and configured as you would for the browser UI. Use **HTTPS** in production (Passkeys and cookies expect a secure origin). API route overview: upstream **WireGuard UI** `README.md` → **HTTP API reference**.

---

## Prerequisites

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (stable channel). This repo declares **Dart SDK `>=3.3.0 <4.0.0`** in `pubspec.yaml`; use a recent Flutter 3.24+ release unless you align the constraint.
- **Android toolchain:** Android SDK, platform tools, and an emulator **or** a physical device with **USB debugging** enabled.
- **JDK 17** (Gradle / Android Studio default) for command-line builds.

Check your environment:

```bash
flutter doctor -v
```

Fix any **Android licenses** or missing SDK components before building (`flutter doctor --android-licenses`).

---

## Initialize the project and fetch dependencies

From the repository root (directory that contains `pubspec.yaml`):

```bash
git clone https://github.com/Skyline-core/wireguard-ui-android-client.git
cd wireguard-ui-android-client
flutter pub get
```

### If the `android/` folder is missing or broken

Regenerate the Android host project without deleting `lib/`:

```bash
flutter create . --project-name wireguard_ui_client --org com.wireguardui --platforms=android
flutter pub get
```

Then open `android/app/src/main/AndroidManifest.xml` and confirm permissions (this tree includes `**POST_NOTIFICATIONS**` for Android 13+ where required).

---

## Run the app (debug)

List devices:

```bash
flutter devices
```

Run on the default Android device or emulator:

```bash
flutter run -d android
```

Or target a specific device id from `flutter devices`:

```bash
flutter run -d <device_id>
```

**Login:** point the app at the same **base URL** you use in the browser for WireGuard UI (scheme, host, optional port, and optional path prefix such as `/wg`). The server must be reachable from the phone or emulator (`10.0.2.2` maps to the host loopback from the **Android emulator** only).

---

## Build an APK

### Debug APK (quick local install)

```bash
flutter build apk --debug
```

Output: `**build/app/outputs/flutter-apk/app-debug.apk**`

### Release APK (distribution / testing)

```bash
flutter build apk --release
```

Output: `**build/app/outputs/flutter-apk/app-release.apk**`

Smaller per-CPU downloads:

```bash
flutter build apk --release --split-per-abi
```

Outputs under `**build/app/outputs/flutter-apk/**` with ABI suffixes (`app-armeabi-v7a-release.apk`, etc.).

### Play Store bundle (AAB)

```bash
flutter build appbundle --release
```

Output: `**build/app/outputs/bundle/release/app-release.aab**`

### Release signing

Release signing uses `**android/key.properties**` and a keystore file when present; otherwise the release build is still produced but signed with the **debug** keystore (not for Play upload or production Passkey SHA alignment). See **Release signing (keystore and `key.properties`)** below.

---

## Implementation notes (for developers)

- Shell UI with **shared-axis** tab transitions (`animations` package).
- **Cookie-based session** (Dio + persistent `cookie_jar`).
- `**WguRepository`** and Dart models aligned with WireGuard UI JSON.
- **Firebase Cloud Messaging** optional: register at `**/api/push/register`** from **Settings** when alerts are enabled. Requires `**google-services.json`** in `**android/app/**` and FCM configured on the **WireGuard UI** server (service account JSON — not the same file as the client).

---

## Release signing (keystore and `key.properties`)

Release builds use a **Java keystore** when Gradle finds `**android/key.properties`**. That file is **local only** (see `.gitignore`).

### Template

```bash
cp android/key.properties.example android/key.properties
```


| Property        | Meaning                                                              |
| --------------- | -------------------------------------------------------------------- |
| `storePassword` | Keystore file password.                                              |
| `keyPassword`   | Key entry password (often same as store).                            |
| `keyAlias`      | Must match the `**-alias**` used with `keytool` (example: `upload`). |
| `storeFile`     | Path **relative to `android/`** to the `.jks` / `.keystore` file.    |


### Generate a keystore

```bash
cd android
keytool -genkeypair -v \
  -storetype JKS \
  -keystore release-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 9125
```

Back up the keystore and passwords **outside** git.

### Build with signing

```bash
flutter build apk --release
flutter build appbundle --release
```

### Fingerprints (`signingReport`) and Passkeys

```bash
cd android && ./gradlew :app:signingReport
```

Use the **SHA-256** for the variant you install when configuring **Digital Asset Links** and `**WGUI_ANDROID_PASSKEY_SHA256`** on WireGuard UI.

---

## Passkeys (passwordless sign-in)

Uses **Android Credential Manager**. Requires **Digital Asset Links** on the panel host and matching WebAuthn settings on **WireGuard UI**. Server-side variables (`WGUI_ANDROID_PASSKEY_*`, `/.well-known/assetlinks.json`, `X-WGUI-WebAuthn-Public-Origin`) are documented in the **[WireGuard UI README](https://github.com/Skyline-core/wireguard-ui/blob/master/README.md)**.

Operational checklist:

1. Set `**WGUI_ANDROID_PASSKEY_SHA256`** on the server to the **SHA-256** cert fingerprint from `**signingReport`** for the **same** build you install (debug vs release differ).
2. Serve `**https://<your-panel-host>/.well-known/assetlinks.json`** at the **site HTTPS root** — not only under your panel base path (e.g. `/wg`). If the reverse proxy only forwards a subpath, add a dedicated rule for `/.well-known/`.
3. On login, **Passkey origin (HTTPS)** must match where the credential was created in the browser when it differs from the API base URL.
4. Prefer entering **Username** before **Sign in with passkey** for non-discoverable credentials.
5. After asset link changes: `**adb shell pm verify-app-links --re-verify <applicationId>`** (optional).

---

## Firebase (push)

1. In [Firebase Console](https://console.firebase.google.com/), add an Android app whose **package name** matches `**applicationId`** in `android/app/build.gradle.kts` (default: `**com.wireguardui.wireguard_ui_client**`).
2. Download `**google-services.json**` into `**android/app/**`. The Google Services Gradle plugin is applied only when that file exists.
3. On **WireGuard UI**, configure the Firebase **service account** JSON and `**FCM_CREDENTIALS_FILE`** / `**GOOGLE_APPLICATION_CREDENTIALS**` — that file is **not** `google-services.json`.

After install: sign in → **Settings** → enable **Push notifications** and grant permission on Android 13+. Sign-out calls `**/api/push/unregister`**.

---

## API mapping in this repo

- Endpoint constants: `**lib/api/backend_endpoints.dart**`
- Calls and models: `**lib/api/wgu_repository.dart**`

Default examples in code often assume HTTPS with a path prefix such as `**/wg**`; your deployment may differ — set **Base path** in the login / settings flow accordingly.

---

## License

**`LICENSE`**.