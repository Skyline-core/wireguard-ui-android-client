// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appLockedTitle => 'App Locked';

  @override
  String get appUnlockPrompt => 'Please authenticate to access WireGuard UI';

  @override
  String get appUnlockButton => 'Unlock';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionApp => 'Application';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSystem => 'System Default';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageEs => 'Spanish';

  @override
  String get settingsAppLockTitle => 'Biometric App Lock';

  @override
  String get settingsAppLockSubtitle =>
      'Require fingerprint, PIN, or Face ID when opening the app';

  @override
  String get settingsAppLockNotSupported =>
      'This device does not support or has no secure lock configured.';

  @override
  String get settingsAppLockAuthReason => 'Authenticate to enable app lock';

  @override
  String settingsAppLockError(String error) {
    return 'Error configuring biometrics: $error';
  }

  @override
  String get settingsChartPerPeerTitle => 'Show chart per peer';

  @override
  String get settingsChartPerPeerSubtitle =>
      'In Traffic, stacked bars per client (like the web panel). Disabled: aggregate graph by time.';

  @override
  String get authSessionNotEstablished => 'Session not established';

  @override
  String get authOfflineWarning => 'Offline, showing last known information.';

  @override
  String get authSessionExpired =>
      'Your WireGuard UI session expired. Please log in again.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabPeers => 'Peers';

  @override
  String get tabTraffic => 'Traffic';

  @override
  String get tabSettings => 'Settings';

  @override
  String shellOfflineWarning(int days) {
    return 'No connection to the server. Cached data; only «Log out» is available. Session expires after $days days of inactivity.';
  }

  @override
  String get shellUnappliedChanges =>
      'There are unapplied changes to the tunnel (like on the web). Tap Apply to update wg.conf on the server.';

  @override
  String get shellApplySuccess => 'Configuration applied on the server.';

  @override
  String get shellApplyFallbackError => 'Could not apply the configuration.';

  @override
  String get shellApplyBtn => 'Apply';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDesc =>
      'Automatic follows the device\'s light or dark mode.';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeAuto => 'Automatic';

  @override
  String get settingsSectionServer => 'Server';

  @override
  String get settingsWgInterface => 'WireGuard Interface';

  @override
  String get settingsTunnelState => 'Tunnel State';

  @override
  String get settingsStateActive => 'Active';

  @override
  String get settingsStateInactive => 'Inactive';

  @override
  String get settingsLiveMonitoring => 'Live Monitoring (logs & stats)';

  @override
  String get settingsLiveMonitoringDesc =>
      'Same option as the web panel: enables /api/system-logs, live traffic, and the Logs nav entry.';

  @override
  String get settingsSystemLogs => 'System Logs';

  @override
  String get settingsSectionApiClient => 'API Client';

  @override
  String get settingsServerOrigin => 'Server Origin';

  @override
  String get settingsApiPrefix => 'API (origin + base path)';

  @override
  String get settingsPasskeyOrigin => 'Passkey Origin (optional)';

  @override
  String get settingsNotDefined => 'Not defined';

  @override
  String get settingsChangeBasePath => 'Change base path';

  @override
  String get settingsChangeBasePathDesc =>
      'Domain or IP is not edited here; only the panel path.';

  @override
  String get settingsPushNotifications => 'Push Notifications';

  @override
  String get settingsPushNotificationsDesc =>
      'Peers and tunnel via FCM (server rate-limited)';

  @override
  String get settingsSectionSession => 'Session';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsUserPrefix => 'User: ';

  @override
  String get settingsDevelopedBy => 'Developed by Skyline';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonGenericError => 'Error';

  @override
  String get commonDash => '—';

  @override
  String get commonServerDnsParen => '(server)';

  @override
  String get loginAppTitle => 'WireGuard UI';

  @override
  String get loginSubtitle => 'Sign in to your panel';

  @override
  String get loginSnackUrlRequired => 'Enter the panel URL.';

  @override
  String get loginPanelUrlLabel => 'Panel URL';

  @override
  String get loginPanelUrlHint =>
      'https://example.net/wg or 192.168.1.5:51821/wg';

  @override
  String get loginPanelUrlHelper =>
      'IPv4/local host without a scheme defaults to http. For HTTPS use https:// (path, e.g. /wg, in the same URL).';

  @override
  String get loginPasskeyHttpsCheckboxTitle =>
      'Different HTTPS origin for passkeys';

  @override
  String get loginPasskeyHttpsCheckboxSubtitle =>
      'If you connect via IP/LAN but passkeys live on another public hostname.';

  @override
  String get loginPasskeyOriginLabel => 'Passkey origin (HTTPS)';

  @override
  String get loginPasskeyOriginHint => 'https://vpn.example.net';

  @override
  String get loginPasskeyOriginHelper =>
      'Same HTTPS base URL where you registered the passkey in the browser.';

  @override
  String get loginUsernameLabel => 'Username';

  @override
  String get loginUsernameHelper =>
      'Optional for passkeys with a discoverable key (no username)';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginRememberSession => 'Remember session';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginSubmitPasskey => 'Sign in with passkey';

  @override
  String get settingsSessionFallback => 'Session';

  @override
  String get settingsLiveMonitoringActivated => 'Live monitoring enabled.';

  @override
  String get settingsLiveMonitoringDeactivated => 'Live monitoring disabled.';

  @override
  String get settingsLiveMonitoringSaveFailed =>
      'Could not save (admin user?). Check your session.';

  @override
  String get settingsHeroInitialsFallback => 'WG';

  @override
  String get settingsFooterTagline => 'Flutter client · WireGuard UI';

  @override
  String get settingsPanelPathDialogTitle => 'Panel base path';

  @override
  String get settingsPanelPathServerReadonly => 'Server (read-only)';

  @override
  String get settingsPanelPathFieldLabel => 'Base path';

  @override
  String get settingsPanelPathFieldHint => 'e.g. /wg';

  @override
  String get settingsPanelPathHelper =>
      'It will be validated against the API before saving.';

  @override
  String get settingsPanelPathProbeFailed =>
      'This path does not respond to the API with your session.';

  @override
  String get settingsPanelPathRevertFailed =>
      'Could not restore the session with the new path. The path was reverted.';

  @override
  String get settingsPanelPathUpdated => 'Base path updated; data reloaded.';

  @override
  String get homeSubtitle => 'Control panel';

  @override
  String get homeOfflineNoCache =>
      'No cached data. Connect to the server at least once.';

  @override
  String get homeActiveInterface => 'ACTIVE INTERFACE';

  @override
  String get homeTunnelConnected => 'Connected';

  @override
  String get homeTunnelInactive => 'Inactive';

  @override
  String homeTunnelStatsLine(
      String sessionsLabel,
      int online,
      String downloadLabel,
      String downloadBytes,
      String uploadLabel,
      String uploadBytes) {
    return '$sessionsLabel · $online · $downloadLabel: $downloadBytes · $uploadLabel: $uploadBytes';
  }

  @override
  String get homeSessionsOnlineLabel => 'Online sessions';

  @override
  String get homeTrafficDownloadLabel => 'Download';

  @override
  String get homeTrafficUploadLabel => 'Upload';

  @override
  String get homeMiniPeersEnabled => 'enabled';

  @override
  String get homeNewClient => 'New client';

  @override
  String get homePeersHeading => 'PEERS';

  @override
  String get homeSeeAllPeers => 'See all';

  @override
  String get homeZipNoPeers => 'No peers to download.';

  @override
  String get homeZipReady => 'ZIP ready to save or share.';

  @override
  String get homeShareZipSubject => 'WireGuard configurations';

  @override
  String get peerSaveStateFailed => 'Could not save peer state on the server.';

  @override
  String get peerStatusOff => 'Off';

  @override
  String get peerStatusOnline => '● Online';

  @override
  String get peerStatusDisconnected => 'Disconnected';

  @override
  String get peerTraffic24hBadge => '24 h';

  @override
  String get peersOfflineNoCache => 'No cached data.';

  @override
  String get peersPageTitle => 'Peers';

  @override
  String get peersSubtitle => 'Registered clients';

  @override
  String get peersSearchHint => 'Search peer, IP…';

  @override
  String peersChipAll(int count) {
    return 'All · $count';
  }

  @override
  String peersChipWithTraffic(int count) {
    return 'With traffic · $count';
  }

  @override
  String peersChipNoTraffic(int count) {
    return 'No traffic · $count';
  }

  @override
  String peersChipEnabled(int count) {
    return 'Enabled · $count';
  }

  @override
  String peersChipDisabled(int count) {
    return 'Disabled · $count';
  }

  @override
  String get peerDetailFallbackTitle => 'Peer';

  @override
  String get peerDetailDeleteFailed =>
      'Could not delete the peer on the server.';

  @override
  String get peerToggleSaveFailed => 'Could not save state on the server.';

  @override
  String get peerQrHint => 'Scan from the WireGuard app on your device';

  @override
  String get peerSectionConfiguration => 'CONFIGURATION';

  @override
  String get peerRowAllowedIps => 'Allowed IPs';

  @override
  String get peerRowDns => 'DNS';

  @override
  String get peerRowEndpoint => 'Endpoint';

  @override
  String get peerDeleteTileTitle => 'Delete client';

  @override
  String get peerDeleteTileSubtitle =>
      'Revoke access (endpoint /remove-client)';

  @override
  String get peerDeleteConfirmTitle => 'Delete?';

  @override
  String get peerDeleteConfirmBody => 'This action cannot be undone.';

  @override
  String get newPeerTitle => 'New peer';

  @override
  String get newPeerNameLabel => 'Client name';

  @override
  String get newPeerIpOptionalLabel => 'Assigned IP (optional)';

  @override
  String get newPeerIpHint => '10.0.0.x · empty = first suggested';

  @override
  String get newPeerSuggestIp => 'Suggest IP (/api/suggest-client-ips)';

  @override
  String get newPeerNameRequired => 'Name required';

  @override
  String get newPeerSuggestIpFailed => 'Could not get suggested IP';

  @override
  String get newPeerSubmit => 'Create in wireguard-ui';

  @override
  String get newPeerApplyHint =>
      'After creating, tap Apply (banner or web) if the server does not auto-apply wg.conf.';

  @override
  String get trafficTitle => 'Traffic';

  @override
  String trafficUpdatedAge(int seconds) {
    return 'Updated · age ${seconds}s';
  }

  @override
  String get trafficRealtimeHeader => 'REAL-TIME SPEED';

  @override
  String get trafficDlShort => 'download';

  @override
  String get trafficUlShort => 'upload';

  @override
  String get trafficTab24h => '24h';

  @override
  String get trafficTab7d => '7 days';

  @override
  String get trafficTab30d => '30 days';

  @override
  String get trafficRangeSubtitle24h => 'last 24h (live estimate)';

  @override
  String get trafficRangeSubtitle7d => 'last 7 days (live estimate)';

  @override
  String get trafficRangeSubtitle30d => 'last 30 days (live estimate)';

  @override
  String get trafficBandwidthAggregate => 'Bandwidth · aggregate';

  @override
  String get trafficAxisStart => 'start';

  @override
  String get trafficAxisNow => 'now';

  @override
  String get trafficEmptyPeerBars => 'No per-peer data for this range.';

  @override
  String get trafficBandwidthPeers => 'Bandwidth';

  @override
  String get trafficLegendDownloadTop => 'Download (top)';

  @override
  String get trafficLegendUploadBottom => 'Upload (bottom)';

  @override
  String get trafficPeerPerspectiveNote =>
      'Peer view: download = server TX, upload = server RX.';

  @override
  String get trafficMetricDownload => 'Download';

  @override
  String get trafficMetricUpload => 'Upload';

  @override
  String get trafficMetricPeak => 'Peak';

  @override
  String get trafficMetricPeers => 'Peers';

  @override
  String get trafficRankingWindow => 'BY PEER (window)';

  @override
  String get trafficRankingKernel => 'BY PEER (kernel)';

  @override
  String get logsTitle => 'Logs';

  @override
  String get logsMonitoringDisabled =>
      'Live monitoring is disabled on the server (same as the web). Enable it in Settings → “Live monitoring (logs & stats)”.';

  @override
  String get logsSearchHint => 'Search logs…';

  @override
  String get logsFilterAll => 'All';

  @override
  String get logsLoadFailed =>
      'Could not load logs (403 or session). Enable monitoring in Settings or check permissions.';

  @override
  String get logsEmptyWithFilters =>
      'No lines to show with the current filters.';

  @override
  String get profileTitle => 'My account';

  @override
  String get profileSessionLoadError =>
      'Could not get the session user. Please sign in again.';

  @override
  String get profilePasswordStrengthNone => 'Strength: no new password';

  @override
  String get profilePasswordStrengthShort => 'Strength: too short';

  @override
  String get profilePasswordStrengthImprove => 'Strength: weak';

  @override
  String get profilePasswordStrengthMedium => 'Strength: medium';

  @override
  String get profilePasswordStrengthGood => 'Strength: good';

  @override
  String get profileSaveFailed => 'Could not save';

  @override
  String get profileRelogin => 'Please sign in again.';

  @override
  String get profileSavedOk => 'Changes saved.';

  @override
  String get profileSectionAccount => 'Your account details';

  @override
  String get profileSectionPasskeys => 'Passkeys';

  @override
  String get profileAccountHint =>
      'Only edit your own user. Changing password will log you out.';

  @override
  String get profileFieldDisplayName => 'DISPLAY NAME';

  @override
  String get profileFieldUsername => 'USERNAME';

  @override
  String get profileFieldEmail => 'EMAIL';

  @override
  String get profileFieldNewPassword => 'NEW PASSWORD';

  @override
  String get profileNewPasswordHint => 'Empty to keep current';

  @override
  String get profilePasswordShow => 'Show';

  @override
  String get profilePasswordHide => 'Hide';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profilePasskeysHintOn =>
      'Register passkeys on this device or rename/remove existing keys.';

  @override
  String get profilePasskeysHintOff =>
      'Passkeys are disabled in the server configuration. Enable them in the web panel (global settings) to register keys.';

  @override
  String get profileNoPasskeys => 'No passkeys on this account.';

  @override
  String get profilePasskeyRenameTooltip => 'Rename';

  @override
  String get profilePasskeyDeleteTooltip => 'Remove';

  @override
  String get profileAddPasskeyNameLabel => 'NAME (E.G. IPHONE, YUBIKEY)';

  @override
  String get profileAddPasskeyNameHint =>
      'Name (e.g. iPhone, MacBook, YubiKey)';

  @override
  String get profileAddPasskey => 'Add passkey';

  @override
  String get profileRemovePasskeyTitle => 'Remove passkey';

  @override
  String profileRemovePasskeyBody(String name) {
    return 'Remove \"$name\"? Sessions for this account will be invalidated.';
  }

  @override
  String get profileRenamePasskeyTitle => 'Rename passkey';

  @override
  String get profileRenamePasskeyFieldLabel => 'Name';

  @override
  String get profileRenamePasskeyFieldHint => 'e.g. iPhone, YubiKey';

  @override
  String get profilePasskeyRemoved => 'Passkey removed.';

  @override
  String get profileNameUpdated => 'Name updated.';

  @override
  String get profileEnterPasskeyName => 'Enter a name for this passkey.';

  @override
  String get profilePasskeyRegisterFailed => 'Could not register the passkey';

  @override
  String get profilePasskeyRegisteredOk => 'Passkey registered on this device.';

  @override
  String get profilePasskeyDuplicate =>
      'This key is already registered for your account.';

  @override
  String profilePasskeyDomainHint(String detail) {
    return 'Could not validate the passkey domain ($detail). Check “Passkey origin” in Settings if you use IP or another host.';
  }

  @override
  String get profilePasskeyDeviceUnsupported =>
      'This device cannot create passkeys.';
}
