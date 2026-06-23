# wireguard-ui-android-client

Android **Flutter** client for **[WireGuard UI](https://github.com/Skyline-core/wireguard-ui/tree/master)** — the same backend that serves the web panel and JSON APIs. The app manages peers, traffic views, and server actions through authenticated HTTP (cookies + optional Passkeys), not by configuring WireGuard directly on the phone.

**Supported target:** **Android** (APK / AAB). This repository keeps only the `**android/`** Flutter platform; desktop and web targets are omitted on purpose.

<img width="1344" height="2992" alt="Screenshot_1778322909" src="https://github.com/user-attachments/assets/34416da2-fc27-4b62-862b-e773a154f966" />
<img width="1344" height="2992" alt="Screenshot_1778322905" src="https://github.com/user-attachments/assets/2191bfc9-6cb3-4375-b067-8f4d00d6b057" />
<img width="1344" height="2992" alt="Screenshot_1778322902" src="https://github.com/user-attachments/assets/ea09835e-6c14-4633-8383-36d6354fd445" />
<img width="1344" height="2992" alt="Screenshot_1778322898" src="https://github.com/user-attachments/assets/d6a1d5c6-7c43-48ea-afd8-200671be200b" />


---

## App features

### Authentication and server connection

- **Sign in** with username and password against your WireGuard UI deployment; optional **remember me** for session persistence.
- **Configurable panel URL** (scheme, host, port, and optional **base path** such as `/wg`) so the client matches your reverse proxy layout.
- **Passkeys (WebAuthn)** via Android **Credential Manager**: passwordless sign-in when the server and domain asset links are configured; optional **Passkey public origin (HTTPS)** when the credential was enrolled on a different origin than the API base URL.
- **Session restore** on cold start when cookies are still valid; **logout** clears the local session and push registration when enabled.

### Main shell and navigation

- **Bottom navigation** with four areas: **Home**, **Peers**, **Traffic**, and **Settings**. Tabs use an `**IndexedStack`** so each screen stays mounted (no horizontal swipe); switching is instant from the bar.
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

- **Appearance (theme)** in **Settings** (labeled per current locale): choose **Light**, **Dark**, or **Automatic**. Automatic follows the device **system** light/dark setting. The choice is stored on the device and applies across the whole app after login.
- **Language** in **Settings → Application**: **System default**, **English**, or **Spanish** (Flutter **`gen-l10n`**; see **Localization (`gen-l10n`)** below).
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

## Continuous integration

GitHub Actions (**`.github/workflows/flutter_ci.yml`**) runs **`flutter pub get`**, **`flutter analyze --no-fatal-infos`**, and **`flutter test`** on pushes and pull requests to **`dev`**, **`main`**, and **`master`**.

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

- Shell: `**IndexedStack`** for the four main tabs; theme-aware chrome via `**ThemeExtension<AppPalette>**` in `**lib/core/theme/app_theme.dart`** (`buildAppLightTheme` / `buildAppDarkTheme`). UI colors use `**context.palette`** (not hard-coded dark-only constants). `**MaterialApp**` in `**lib/app.dart**` reads `**ThemeMode**` from `**ServerSettings**` (`**themePreference**`; SharedPreferences key `**wgui_theme_preference**` with values `**system**`, `**light**`, or `**dark**`).
- **Cookie-based session** (Dio + persistent `cookie_jar`).
- `**WguRepository`** and Dart models aligned with WireGuard UI JSON.
- **Firebase Cloud Messaging** optional: register at `**/api/push/register`** from **Settings** when alerts are enabled. Requires `**google-services.json`** in `**android/app/`** and FCM configured on the **WireGuard UI** server (service account JSON — not the same file as the client).

### Localization (`gen-l10n`)

The app ships **English** (`en`) and **Spanish** (`es`) UI strings via Flutter’s **`flutter_gen`** pipeline.

| Item | Location |
| ---- | -------- |
| Config | `**l10n.yaml**` — `arb-dir`, `template-arb-file`, `output-localization-file`, `output-dir` (generated Dart under `**lib/l10n/**`). |
| Source strings | `**lib/l10n/app_es.arb**` (template locale) and `**lib/l10n/app_en.arb**`. Prefer keeping keys and placeholders in sync in both files. |
| Generated API | `**lib/l10n/app_localizations.dart**` (+ `*_en.dart`, `*_es.dart`). Do not hand-edit the generated subclasses; rerun codegen after ARB edits. |

**Runtime wiring:** `**lib/app.dart**` registers `AppLocalizations.delegate`, `supportedLocales`, and sets `MaterialApp.locale` from `ServerSettings.localePreference`: **system** follows the OS, or a fixed **`en`** / **`es`**. Users change this under **Settings → Application → Language**.

**Workflow when adding or changing copy**

1. Add or edit the message key in **`app_es.arb`** and **`app_en.arb`** (use ICU placeholders and `@key` metadata for parameters, as in existing entries).
2. Regenerate Dart: `**flutter gen-l10n**` from the repo root (or rely on tooling that runs codegen after `flutter pub get` when **`flutter: generate: true`** is set in **`pubspec.yaml`**).
3. In widgets, resolve strings with **`AppLocalizations.of(context)!`** (never hard-code user-facing text in Dart for flows that already use l10n).

**Scopes covered:** login, shell (offline / apply banners, tab labels), home, peers, peer detail / new peer, traffic, logs, profile, settings (including dialogs, snackbars, and biometric app-lock strings where applicable).

### Biometric app lock (optional UX)

Users can enable a **biometric app lock** in Settings so reopening the app may require fingerprint, device PIN/pattern, or Face ID (`**lib/core/auth/app_lock_wrapper.dart**`, **`local_auth`**). This gates the Flutter shell only and does not replace server authentication.

---

## Release signing (keystore and `key.properties`)

Release builds use a **Java keystore** when Gradle finds **`android/key.properties`** (same directory as **`android/key.properties.example`**). That real file is **gitignored** — only the **`.example`** ships in the repo.

### Configure from `key.properties.example`

1. **Copy the template** (from the repo root):

   ```bash
   cp android/key.properties.example android/key.properties
   ```

2. **Create a keystore** (or reuse your Play/App signing keystore). The defaults in **`key.properties.example`** assume **alias `upload`** and **`release-keystore.jks`** sitting next to **`key.properties`** under **`android/`**:

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

   If you choose another **`-alias`** or **filename**, update **`key.properties`** to match (see below). Back up the **`.jks`** and passwords **outside** git.

3. **Edit `android/key.properties`** (never commit it). Replace the placeholders from the example with your real passwords and paths:

   | Property        | Meaning                                                                 |
   | --------------- | ----------------------------------------------------------------------- |
   | `storePassword` | Password for the **keystore file** (`-storepass` in `keytool` terms).   |
   | `keyPassword`   | Password for the **key entry** (often the same as `storePassword`).   |
   | `keyAlias`      | Must match **`keytool -alias …`** (template default: **`upload`**).     |
   | `storeFile`     | Path to the **`.jks` / `.keystore` relative to the `android/` folder. |

   Example after filling in (passwords are illustrative only):

   ```properties
   storePassword=your-keystore-password
   keyPassword=your-key-password
   keyAlias=upload
   storeFile=release-keystore.jks
   ```

   If the keystore lives elsewhere, adjust **`storeFile`**: e.g. **`upload/upload.jks`** means **`android/upload/upload.jks`**. Gradle resolves this from the **`android/`** project directory (see **`android/app/build.gradle.kts`**).

4. **Verify** Gradle picks up signing: **`cd android && ./gradlew :app:signingReport`** — the **release** config should show your certificate (not only the debug key).

5. **Build** signed artifacts from the repo root:

   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

Without **`android/key.properties`**, **`flutter build … --release`** still runs but signs with the **debug** keystore — fine for local tests, **not** for Play upload or matching production **`WGUI_ANDROID_PASSKEY_SHA256`**.

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

1. In [Firebase Console](https://console.firebase.google.com/), add an Android app whose **package name** matches `**applicationId`** in `android/app/build.gradle.kts` (default: `**com.wireguardui.wireguard_ui_client`**).
2. Download `**google-services.json`** into `**android/app/**`. The Google Services Gradle plugin is applied only when that file exists — this file is **only for the Flutter/Android build**. The WireGuard UI **server never reads it**.

### Server: service account JSON (FCM from the backend)

WireGuard UI needs a **Firebase / Google Cloud service account key** (`"type": "service_account"` in the JSON):

1. In the **same** Firebase project: **Project settings** (gear) → **Service accounts**.
2. **Generate new private key** (under Firebase Admin SDK). Save the downloaded **`.json`** on the WireGuard UI host (e.g. `/etc/wireguard-ui/firebase-service-account.json`), `chmod 600`, readable by the process user.
3. Set **`FCM_CREDENTIALS_FILE`** (or **`GOOGLE_APPLICATION_CREDENTIALS`**) to that path. Full checklist, API enablement, and troubleshooting: **[WireGuard UI README — Firebase Cloud Messaging (FCM)](https://github.com/Skyline-core/wireguard-ui/blob/master/README.md#firebase-cloud-messaging-fcm)**.

After install: sign in → **Settings** → enable **Push notifications** and grant permission on Android 13+. Sign-out calls `**/api/push/unregister`**.

---

## API mapping in this repo

- Endpoint constants: `**lib/api/backend_endpoints.dart`**
- Calls and models: `**lib/api/wgu_repository.dart`**

Default examples in code often assume HTTPS with a path prefix such as `**/wg**`; your deployment may differ — set **Base path** in the login / settings flow accordingly.

---

## License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0). Read the full terms here: **[LICENSE** (branch `main` on GitHub)](https://github.com/Skyline-core/wireguard-ui-android-client/blob/main/LICENSE). The same file is at the repo root as `[LICENSE](LICENSE)` when you clone the project.
