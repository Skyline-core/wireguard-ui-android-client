import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (ok) {
      setState(() => realtimeLogsEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Monitoreo en vivo activado.'
                : 'Monitoreo en vivo desactivado.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar (¿usuario administrador?). Revisa la sesión.',
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
    final user = auth.username ?? 'Sesión';
    final offline = auth.offlineMode;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
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
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                            child: Text(
                              'Ajustes',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _hero(context, user, cfg.originNormalized),
                          _sectionTitle('Servidor'),
                          _card(children: [
                            _tile(Icons.dns, 'Interfaz WireGuard',
                                tunnel?['iface_name']?.toString() ?? '—'),
                            _tile(
                                Icons.shield_outlined,
                                'Estado del túnel',
                                tunnel?['tunnel_running'] == true
                                    ? 'Activo'
                                    : 'Inactivo'),
                            SwitchListTile(
                              secondary: Icon(
                                Icons.podcasts_outlined,
                                color: AppColors.accent.withValues(alpha: 0.9),
                              ),
                              title: const Text(
                                  'Monitoreo en vivo (logs y estadísticas)'),
                              subtitle: const Text(
                                'Misma opción que en la web: habilita /api/system-logs, actualización de tráfico en vivo y la entrada Logs en el panel.',
                                style: TextStyle(fontSize: 11),
                              ),
                              value: realtimeLogsEnabled ?? false,
                              onChanged: loading || savingRealtime
                                  ? null
                                  : (v) => _setRealtimeLogs(v),
                              activeThumbColor: AppColors.accent,
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
                                      AppColors.accent.withValues(alpha: 0.9)),
                              title: const Text('Logs del sistema'),
                              subtitle: const Text('/api/system-logs'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const LogsPage()),
                              ),
                            ),
                          ]),
                          _sectionTitle('Cliente API'),
                          _card(children: [
                            ListTile(
                              leading: const Icon(Icons.link,
                                  color: AppColors.accent),
                              title: const Text('Origen del servidor'),
                              subtitle: Text(
                                cfg.originNormalized,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.http,
                                  color: AppColors.accent),
                              title: const Text('API (origen + base path)'),
                              subtitle: Text(
                                cfg.apiPrefix,
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 11),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.key_outlined,
                                  color: AppColors.accent.withValues(alpha: 0.85)),
                              title: const Text('Origen passkey (opcional)'),
                              subtitle: Text(
                                cfg.passkeyPublicOrigin.trim().isEmpty
                                    ? 'No definido'
                                    : cfg.passkeyPublicOrigin,
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.edit_outlined),
                              title: const Text('Cambiar base path'),
                              subtitle: const Text(
                                'El dominio o IP no se edita aquí; solo la ruta del panel.',
                                style: TextStyle(fontSize: 11),
                              ),
                              onTap: () => _editBasePathDialog(context),
                            ),
                          ]),
                          _sectionTitle('Aplicación'),
                          _card(children: [
                            SwitchListTile(
                              value: cfg.trafficChartPerPeer,
                              onChanged: (v) => cfg.setTrafficChartPerPeer(v),
                              activeThumbColor: AppColors.accent,
                              title: const Text('Mostrar gráfica por peer'),
                              subtitle: const Text(
                                'En Tráfico, barras apiladas por cliente (como el panel web). Desactivado: gráfica agregada por tiempo.',
                                style: TextStyle(fontSize: 11),
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
                              activeThumbColor: AppColors.accent,
                              secondary: Icon(Icons.notifications_active_outlined,
                                  color:
                                      AppColors.yellow.withValues(alpha: 0.9)),
                              title: const Text('Notificaciones push'),
                              subtitle: const Text(
                                'Peers y túnel vía FCM (el servidor limita la frecuencia)',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    _sectionTitle('Sesión'),
                    _card(children: [
                      ListTile(
                        leading: Icon(Icons.logout,
                            color: AppColors.red.withValues(alpha: 0.9)),
                        title: const Text('Cerrar sesión'),
                        subtitle: Text('Usuario: $user'),
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
                          'Desarrollado por Skyline',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                AppColors.accent.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(28, 8, 28, 0),
                      child: Text(
                        'v0.1050325b',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(28, 14, 28, 28),
                      child: Text(
                        'Cliente Flutter · WireGuard UI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
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
                const Color(0xFF1A1A2E),
                AppColors.surface,
              ]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
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
                      gradient: const LinearGradient(
                        colors: [AppColors.accentStrong, AppColors.accent],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials.length >= 2
                          ? initials.substring(0, 2).toUpperCase()
                          : (initials.isEmpty ? 'WG' : initials.toUpperCase()),
                      style: const TextStyle(
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
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(host,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color:
                          AppColors.textSecondary.withValues(alpha: 0.85)),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      );

  Widget _card({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(children: divide(children)),
        ),
      ),
    );
  }

  List<Widget> divide(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        out.add(Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.05)));
      }
      out.add(items[i]);
    }
    return out;
  }

  Widget _tile(IconData icon, String title, String sub) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(sub.isEmpty ? '—' : sub),
    );
  }

  Future<void> _editBasePathDialog(BuildContext context) async {
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
                title: const Text('Base path del panel'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Servidor (solo lectura)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        cfg.originNormalized,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pathCtrl,
                        enabled: !busy,
                        decoration: InputDecoration(
                          labelText: 'Base path',
                          hintText: 'ej. /wg',
                          helperText:
                              'Se validará contra la API antes de guardar.',
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
                    child: const Text('Cancelar'),
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
                                err =
                                    'Este path no responde a la API con tu sesión.';
                                busy = false;
                              });
                              return;
                            }
                            // Do not call setLocal after validation — closing the dialog immediately
                            // avoids rebuilding the TextField while the route is tearing down
                            // (“controller disposed”, Provider asserts).
                            Navigator.pop(ctx, pathCtrl.text.trim());
                          },
                    child: const Text('Guardar'),
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
        const SnackBar(
          content: Text(
            'No se pudo restablecer la sesión con el nuevo path. Se revirtió el path.',
          ),
        ),
      );
      return;
    }
    await wg.refreshFromServer(auth, cfg);
    if (!mounted) return;
    unawaited(ServerHealthScheduler.syncRegistration(auth.ready));

    // Primero esta pantalla (evita "dirty widget in wrong scope" mezclando setState con reload).
    await _load();
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      reload.notifyReload();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Base path actualizado; datos recargados.'),
        ),
      );
    });
  }
}
