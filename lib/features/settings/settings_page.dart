import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import '../../l10n/app_localizations.dart';

import '../../background/server_health_scheduler.dart';
import '../../core/config/server_settings.dart';
import '../../core/session/auth_store.dart';
import '../../core/app_reload_signal.dart';
import '../../core/wg_apply_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../api/wgu_repository.dart';
import '../../core/offline/offline_snapshot_store.dart';
import '../../notifications/wgu_notifications.dart';
import '../logs/logs_page.dart';
import '../profile/profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? tunnel;
  bool loading = false;
  /// Mirrors server `realtime_stats_enabled` / `show_logs_nav` (logs + live stats API).
  bool? realtimeLogsEnabled;
  bool savingRealtime = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final auth = context.read<AuthStore>();
    if (auth.offlineMode) {
      setState(() => loading = true);
      final snap = await OfflineSnapshotStore.load();
      if (!mounted) return;
      setState(() {
        tunnel = snap?.tunnel;
        realtimeLogsEnabled = null;
        loading = false;
      });
      return;
    }
    final r = WguRepository.fromContext(
      auth,
      context.read<ServerSettings>(),
    );
    setState(() => loading = true);
    try {
      final t = await r.tunnelStatus();
      final hints = await r.uiNavHints();
      if (!mounted) return;
      setState(() {
        tunnel = t;
        realtimeLogsEnabled = hints?['show_logs_nav'] == true;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _setRealtimeLogs(bool enabled) async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final r = WguRepository.fromContext(auth, cfg);
    setState(() => savingRealtime = true);
    final ok = await r.setRealtimeStatsEnabled(enabled);
    if (!mounted) return;
    setState(() => savingRealtime = false);
    final loc = AppLocalizations.of(context)!;
    if (ok) {
      setState(() => realtimeLogsEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? loc.settingsLiveMonitoringActivated
                : loc.settingsLiveMonitoringDeactivated,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.settingsLiveMonitoringSaveFailed,
          ),
        ),
      );
      if (!mounted) return;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<ServerSettings>();
    final alerts = context.watch<WguNotificationController>();
    final auth = context.watch<AuthStore>();
    final loc = AppLocalizations.of(context)!;
    final user = auth.username ?? loc.settingsSessionFallback;
    final offline = auth.offlineMode;

    return Scaffold(
      backgroundColor: context.palette.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RefreshIndicator(
                color: context.palette.accent,
                onRefresh: () async {
                  if (offline) {
                    final ok = await auth.tryReconnect(cfg);
                    if (context.mounted && ok) await _load();
                    return;
                  }
                  await _load();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    AbsorbPointer(
                      absorbing: offline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                            child: Text(
                              loc.settingsTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: context.palette.textPrimary,
                              ),
                            ),
                          ),
                          _hero(context, user, cfg.originNormalized),
                          _sectionTitle(loc.settingsSectionAppearance),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Material(
                              color: context.palette.surface,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.settingsTheme,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: context.palette.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      loc.settingsThemeDesc,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.palette.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SegmentedButton<AppThemePreference>(
                                      segments: [
                                        ButtonSegment(
                                          value: AppThemePreference.light,
                                          icon: Icon(Icons.light_mode_outlined,
                                              size: 18,
                                              color: context.palette.textSecondary),
                                          label: Text(loc.settingsThemeLight),
                                        ),
                                        ButtonSegment(
                                          value: AppThemePreference.dark,
                                          icon: Icon(Icons.dark_mode_outlined,
                                              size: 18,
                                              color: context.palette.textSecondary),
                                          label: Text(loc.settingsThemeDark),
                                        ),
                                        ButtonSegment(
                                          value: AppThemePreference.system,
                                          icon: Icon(
                                              Icons.brightness_auto_outlined,
                                              size: 18,
                                              color: context.palette.textSecondary),
                                          label: Text(loc.settingsThemeAuto),
                                        ),
                                      ],
                                      selected: {cfg.themePreference},
                                      onSelectionChanged: (s) {
                                        if (s.isEmpty) return;
                                        cfg.setThemePreference(s.first);
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      loc.settingsLanguageTitle,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: context.palette.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SegmentedButton<AppLocalePreference>(
                                      segments: [
                                        ButtonSegment(
                                          value: AppLocalePreference.system,
                                          label: Text(loc.settingsLanguageSystem),
                                        ),
                                        ButtonSegment(
                                          value: AppLocalePreference.en,
                                          label: Text(loc.settingsLanguageEn),
                                        ),
                                        ButtonSegment(
                                          value: AppLocalePreference.es,
                                          label: Text(loc.settingsLanguageEs),
                                        ),
                                      ],
                                      selected: {cfg.localePreference},
                                      onSelectionChanged: (s) {
                                        if (s.isEmpty) return;
                                        cfg.setLocalePreference(s.first);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _sectionTitle(loc.settingsSectionServer),
                          _card(context, children: [
                            _tile(Icons.dns, loc.settingsWgInterface,
                                tunnel?['iface_name']?.toString() ??
                                    loc.commonDash),
                            _tile(
                                Icons.shield_outlined,
                                loc.settingsTunnelState,
                                tunnel?['tunnel_running'] == true
                                    ? loc.settingsStateActive
                                    : loc.settingsStateInactive),
                            SwitchListTile(
                              secondary: Icon(
                                Icons.podcasts_outlined,
                                color: context.palette.accent.withValues(alpha: 0.9),
                              ),
                              title: Text(loc.settingsLiveMonitoring),
                              subtitle: Text(
                                loc.settingsLiveMonitoringDesc,
                                style: TextStyle(fontSize: 11),
                              ),
                              value: realtimeLogsEnabled ?? false,
                              onChanged: loading || savingRealtime
                                  ? null
                                  : (v) => _setRealtimeLogs(v),
                              activeThumbColor: context.palette.accent,
                            ),
                            if (savingRealtime)
                              const Padding(
                                padding: EdgeInsets.only(
                                    left: 16, right: 16, bottom: 8),
                                child:
                                    LinearProgressIndicator(minHeight: 2),
                              ),
                            ListTile(
                              leading: Icon(Icons.terminal,
                                  color:
                                      context.palette.accent.withValues(alpha: 0.9)),
                              title: Text(loc.settingsSystemLogs),
                              subtitle: const Text('/api/system-logs'),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const LogsPage()),
                              ),
                            ),
                          ]),
                          _sectionTitle(loc.settingsSectionApiClient),
                          _card(context, children: [
                            ListTile(
                              leading: Icon(Icons.link,
                                  color: context.palette.accent),
                              title: Text(loc.settingsServerOrigin),
                              subtitle: Text(
                                cfg.originNormalized,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: context.palette.textSecondary,
                                ),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.http,
                                  color: context.palette.accent),
                              title: Text(loc.settingsApiPrefix),
                              subtitle: Text(
                                cfg.apiPrefix,
                                style: TextStyle(
                                    fontFamily: 'monospace', fontSize: 11),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.key_outlined,
                                  color: context.palette.accent.withValues(alpha: 0.85)),
                              title: Text(loc.settingsPasskeyOrigin),
                              subtitle: Text(
                                cfg.passkeyPublicOrigin.trim().isEmpty
                                    ? loc.settingsNotDefined
                                    : cfg.passkeyPublicOrigin,
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: context.palette.textSecondary,
                                ),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text(loc.settingsChangeBasePath),
                              subtitle: Text(
                                loc.settingsChangeBasePathDesc,
                                style: TextStyle(fontSize: 11),
                              ),
                              onTap: () => _editBasePathDialog(context),
                            ),
                          ]),
                          _sectionTitle(loc.settingsSectionApp),
                          _card(context, children: [
                            SwitchListTile(
                              value: cfg.appLockEnabled,
                              onChanged: (v) async {
                                if (v) {
                                  final auth = LocalAuthentication();
                                  final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                                  if (!canCheck) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(loc.settingsAppLockNotSupported)),
                                    );
                                    return;
                                  }
                                  try {
                                    final didAuth = await auth.authenticate(
                                      localizedReason: loc.settingsAppLockAuthReason,
                                    );
                                    if (didAuth) {
                                      await cfg.setAppLockEnabled(true);
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              loc.settingsAppLockError('$e'))),
                                    );
                                  }
                                } else {
                                  await cfg.setAppLockEnabled(false);
                                }
                              },
                              activeThumbColor: context.palette.accent,
                              secondary: Icon(Icons.fingerprint, color: context.palette.accent.withValues(alpha: 0.9)),
                              title: Text(loc.settingsAppLockTitle),
                              subtitle: Text(
                                loc.settingsAppLockSubtitle,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            SwitchListTile(
                              value: cfg.trafficChartPerPeer,
                              onChanged: (v) => cfg.setTrafficChartPerPeer(v),
                              activeThumbColor: context.palette.accent,
                              title: Text(loc.settingsChartPerPeerTitle),
                              subtitle: Text(
                                loc.settingsChartPerPeerSubtitle,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            SwitchListTile(
                              value: alerts.enabled,
                              onChanged: (v) {
                                alerts.setEnabled(
                                  context.read<AuthStore>(),
                                  cfg,
                                  v,
                                );
                              },
                              activeThumbColor: context.palette.accent,
                              secondary: Icon(Icons.notifications_active_outlined,
                                  color:
                                      context.palette.yellow.withValues(alpha: 0.9)),
                              title: Text(loc.settingsPushNotifications),
                              subtitle: Text(
                                loc.settingsPushNotificationsDesc,
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    _sectionTitle(loc.settingsSectionSession),
                    _card(context, children: [
                      ListTile(
                        leading: Icon(Icons.logout,
                            color: context.palette.red.withValues(alpha: 0.9)),
                        title: Text(loc.settingsLogout),
                        subtitle: Text('${loc.settingsUserPrefix}$user'),
                        onTap: () async {
                          final a = context.read<AuthStore>();
                          await context
                              .read<WguNotificationController>()
                              .prepareLogout(a, cfg);
                          await a.logout(cfg);
                          if (context.mounted) {
                            context.read<WgApplyController>().reset();
                          }
                        },
                      ),
                    ]),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final u = Uri.parse(
                            'https://github.com/Skyline-core/wireguard-ui-android-client',
                          );
                          await launchUrl(
                            u,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Text(
                          loc.settingsDevelopedBy,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.palette.accent,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                context.palette.accent.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                      child: Text(
                        'v0.1050325b',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.textMuted,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
                      child: Text(
                        loc.settingsFooterTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11, color: context.palette.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, String initials, String host) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const ProfilePage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                context.palette.heroBannerTop,
                context.palette.surface,
              ]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.palette.accent.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [context.palette.accentStrong, context.palette.accent],
                      ),
                    ),
                    alignment: Alignment.center,
                      child: Text(
                        initials.length >= 2
                          ? initials.substring(0, 2).toUpperCase()
                          : (initials.isEmpty
                              ? loc.settingsHeroInitialsFallback
                              : initials.toUpperCase()),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(initials,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(host,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.palette.accent)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color:
                          context.palette.textSecondary.withValues(alpha: 0.85)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Text(
          t.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 11,
            color: context.palette.textMuted,
          ),
        ),
      );

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(children: divide(context, children)),
        ),
      ),
    );
  }

  List<Widget> divide(BuildContext context, List<Widget> items) {
    final line = context.palette.borderSubtle;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        out.add(Divider(height: 1, thickness: 1, color: line));
      }
      out.add(items[i]);
    }
    return out;
  }

  Widget _tile(IconData icon, String title, String sub) {
    final loc = AppLocalizations.of(context)!;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(sub.isEmpty ? loc.commonDash : sub),
    );
  }

  Future<void> _editBasePathDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final cfg = context.read<ServerSettings>();
    final auth = context.read<AuthStore>();
    final pathCtrl = TextEditingController(text: cfg.basePath);
    String? err;
    var busy = false;

    String? acceptedPath;
    try {
      if (!context.mounted) return;
      acceptedPath = await showDialog<String?>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                title: Text(loc.settingsPanelPathDialogTitle),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        loc.settingsPanelPathServerReadonly,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        cfg.originNormalized,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: context.palette.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pathCtrl,
                        enabled: !busy,
                        decoration: InputDecoration(
                          labelText: loc.settingsPanelPathFieldLabel,
                          hintText: loc.settingsPanelPathFieldHint,
                          helperText: loc.settingsPanelPathHelper,
                          errorText: err,
                        ),
                        autocorrect: false,
                      ),
                      if (busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: busy ? null : () => Navigator.pop(ctx, null),
                    child: Text(loc.commonCancel),
                  ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            setLocal(() {
                              err = null;
                              busy = true;
                            });
                            final ok = await WguRepository.probePanelBasePath(
                              auth: auth,
                              cfg: cfg,
                              proposedPath: pathCtrl.text,
                            );
                            if (!ctx.mounted) return;
                            if (!ok) {
                              setLocal(() {
                                err = loc.settingsPanelPathProbeFailed;
                                busy = false;
                              });
                              return;
                            }
                            // Do not call setLocal after validation — closing the dialog immediately
                            // avoids rebuilding the TextField while the route is tearing down
                            // (“controller disposed”, Provider asserts).
                            Navigator.pop(ctx, pathCtrl.text.trim());
                          },
                    child: Text(loc.commonSave),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      pathCtrl.dispose();
    }

    if (acceptedPath != null && context.mounted) {
      await _applyNewBasePath(context, acceptedPath);
    }
  }

  /// [proposedPath] must match what the user entered (controller was disposed; pass before dispose).
  Future<void> _applyNewBasePath(
    BuildContext context,
    String proposedPath,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final cfg = context.read<ServerSettings>();
    final auth = context.read<AuthStore>();
    final wg = context.read<WgApplyController>();
    final reload = context.read<AppReloadSignal>();
    final oldPath = cfg.basePath;

    await cfg.savePathOnly(proposedPath);
    await auth.bootstrap(cfg);
    if (!context.mounted) return;
    if (!auth.ready) {
      unawaited(ServerHealthScheduler.syncRegistration(false));
      await cfg.savePathOnly(oldPath);
      await auth.bootstrap(cfg);
      if (!context.mounted) return;
      unawaited(ServerHealthScheduler.syncRegistration(auth.ready));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.settingsPanelPathRevertFailed,
          ),
        ),
      );
      return;
    }
    await wg.refreshFromServer(auth, cfg);
    if (!mounted) return;
    unawaited(ServerHealthScheduler.syncRegistration(auth.ready));

    // First this screen (avoids "dirty widget in wrong scope" by mixing setState with reload).
    await _load();
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      reload.notifyReload();
      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.settingsPanelPathUpdated),
        ),
      );
    });
  }
}
