import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_reload_signal.dart';
import '../../core/config/server_settings.dart';
import '../../core/session/auth_store.dart';
import '../../core/session/session_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/wg_apply_controller.dart';
import '../../features/home/home_page.dart';
import '../../features/peers/peers_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/traffic/traffic_page.dart';
import '../../notifications/wgu_notifications.dart';
import '../../l10n/app_localizations.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _reconnectTimer;
  AuthStore? _authSub;
  bool _wasPaused = false;

  /// Refresh when switching tabs avoids stale data between Home and Peers.
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  final GlobalKey<PeersPageState> _peersKey = GlobalKey<PeersPageState>();
  final GlobalKey<TrafficPageState> _trafficKey = GlobalKey<TrafficPageState>();
  final GlobalKey<SettingsPageState> _settingsKey =
      GlobalKey<SettingsPageState>();
  AppReloadSignal? _reloadBus;

  /// Runs after the current frame. Does not refresh Settings: the path change originates there and
  /// calling `refresh` on that same route again triggers Provider disposed asserts.
  void _onApiReload() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _homeKey.currentState?.refresh();
      _peersKey.currentState?.refresh();
      _trafficKey.currentState?.refresh();
    });
  }

  void _syncReconnectTimer() {
    final auth = _authSub;
    if (auth == null || !mounted) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    if (!auth.offlineMode) return;
    _reconnectTimer = Timer.periodic(const Duration(seconds: 18), (_) {
      unawaited(_pollReconnect());
    });
  }

  Future<void> _afterServerReachableAgain() async {
    if (!mounted) return;
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final alerts = context.read<WguNotificationController>();
    if (alerts.enabled) {
      await alerts.setEnabled(auth, cfg, true);
    }
    if (!mounted) return;
    context.read<AppReloadSignal>().notifyReload();
    _homeKey.currentState?.refresh();
    _peersKey.currentState?.refresh();
    _trafficKey.currentState?.refresh();
    _settingsKey.currentState?.refresh();
  }

  Future<void> _pollReconnect() async {
    if (!mounted) return;
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    if (!auth.offlineMode) return;
    final ok = await auth.tryReconnect(cfg);
    if (!mounted || !ok) return;
    await _afterServerReachableAgain();
  }

  Future<void> _onAppResumedFromBackground() async {
    if (!mounted) return;
    final auth = context.read<AuthStore>();
    if (!auth.ready) return;
    final cfg = context.read<ServerSettings>();
    if (auth.offlineMode) {
      final ok = await auth.tryReconnect(cfg);
      if (!mounted || !ok) return;
      await _afterServerReachableAgain();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (_index) {
        case 0:
          _homeKey.currentState?.refresh();
          break;
        case 1:
          _peersKey.currentState?.refresh();
          break;
        case 2:
          _trafficKey.currentState?.refresh();
          break;
        case 3:
          _settingsKey.currentState?.refresh();
          break;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      unawaited(_onAppResumedFromBackground());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _reloadBus = context.read<AppReloadSignal>()..addListener(_onApiReload);
      final alerts = context.read<WguNotificationController>();
      final auth = context.read<AuthStore>();
      final cfg = context.read<ServerSettings>();
      _authSub = auth..addListener(_syncReconnectTimer);
      _syncReconnectTimer();

      if (alerts.enabled) {
        await alerts.setEnabled(auth, cfg, true);
      }

      _homeKey.currentState?.refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _authSub?.removeListener(_syncReconnectTimer);
    _reloadBus?.removeListener(_onApiReload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final titles = [loc.tabHome, loc.tabPeers, loc.tabTraffic, loc.tabSettings];

    final pages = [
      HomePage(key: _homeKey, onOpenPeers: () => _setTab(1)),
      PeersPage(key: _peersKey),
      TrafficPage(key: _trafficKey),
      SettingsPage(key: _settingsKey),
    ];

    return Scaffold(
      backgroundColor: context.palette.bg,
      // IndexedStack avoids sliding the entire Scaffold (header + lists) like PageView does — no black
      // gutter during gestures; tabs switch from the bottom nav only.
      body: IndexedStack(
        index: _index,
        sizing: StackFit.expand,
        children: [
          for (final p in pages)
            HeroMode(
              enabled: false,
              child: p,
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<AuthStore>(
            builder: (context, auth, _) {
              if (!auth.offlineMode) return const SizedBox.shrink();
              return Material(
                color: context.palette.red.withValues(alpha: 0.12),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 22, color: context.palette.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loc.shellOfflineWarning(SessionConstants.idleLogoutDays),
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: context.palette.red.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Consumer2<WgApplyController, AuthStore>(
            builder: (context, wg, auth, _) {
              if (auth.offlineMode || wg.needsApply != true) {
                return const SizedBox.shrink();
              }
              return Material(
                color: context.palette.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(12, 6, 12, 4),
                    child: Row(
                      children: [
                        Icon(Icons.engineering_outlined,
                            size: 22, color: context.palette.yellow),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loc.shellUnappliedChanges,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.25,
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: wg.applying
                              ? null
                              : () async {
                                  final auth = context.read<AuthStore>();
                                  final cfg =
                                      context.read<ServerSettings>();
                                  final ctrl =
                                      context.read<WgApplyController>();
                                  final ok =
                                      await ctrl.applyNow(auth, cfg);
                                  if (!context.mounted) return;
                                  if (ok) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(loc.shellApplySuccess),
                                      ),
                                    );
                                  } else {
                                    final msg = context
                                            .read<WgApplyController>()
                                            .lastError ??
                                        loc.shellApplyFallbackError;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(content: Text(msg)),
                                    );
                                  }
                                },
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: wg.applying
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.palette.accent,
                                  ),
                                )
                              : Text(loc.shellApplyBtn),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          NavigationBar(
            height: 72,
            backgroundColor: context.palette.surface,
            indicatorColor: context.palette.accent.withValues(alpha: 0.14),
            selectedIndex: _index,
            onDestinationSelected: (i) => _setTab(i),
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.grid_view_rounded,
                    color: _index == 0 ? context.palette.accent : context.palette.textMuted),
                label: titles[0],
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline,
                    color: _index == 1 ? context.palette.accent : context.palette.textMuted),
                label: titles[1],
              ),
              NavigationDestination(
                icon: Icon(Icons.show_chart_rounded,
                    color: _index == 2 ? context.palette.accent : context.palette.textMuted),
                label: titles[2],
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_input_antenna,
                    color: _index == 3 ? context.palette.accent : context.palette.textMuted),
                label: titles[3],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (i == 0) {
        _homeKey.currentState?.refresh(silent: true);
      } else if (i == 1) {
        _peersKey.currentState?.refresh(silent: true);
      } else if (i == 2) {
        _trafficKey.currentState?.refresh(silent: true);
      }
    });
  }
}
