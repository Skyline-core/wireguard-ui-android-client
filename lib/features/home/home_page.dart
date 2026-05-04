import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../api/models/client_models.dart';
import '../../api/models/dashboard_stats.dart';
import '../../api/models/traffic_series.dart';
import '../../api/wgu_repository.dart';
import '../../core/config/server_settings.dart';
import '../../core/offline/offline_snapshot_store.dart';
import '../../core/wg_apply_controller.dart';
import '../../core/format/formatters.dart';
import '../../core/network/format_network_error.dart';
import '../../core/session/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../profile/profile_page.dart';
import '../peers/new_peer_page.dart';
import '../peers/peer_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpenPeers});

  final VoidCallback onOpenPeers;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool loading = true;
  bool _busyDownloadZip = false;
  String? err;
  Map<String, dynamic>? tunnel;
  DashboardStatsVm? stats;
  TrafficSeriesResponseVm? traffic;
  List<WgClientEnvelope> clients = [];

  /// Peers shown on Home; the rest live under the Peers tab.
  static const int _maxHomePeers = 5;

  /// Align with server `trafficSampleInterval` (4s) and web dashboard polling when realtime is on.
  static const Duration _livePollInterval = Duration(seconds: 4);
  Timer? _livePollTimer;

  Future<void> refresh() async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();

    if (auth.offlineMode) {
      setState(() {
        loading = true;
        err = null;
      });
      final snap = await OfflineSnapshotStore.load();
      if (!mounted) return;
      setState(() {
        loading = false;
        if (snap == null) {
          err = 'Sin datos en caché. Conecta al menos una vez con el servidor.';
        } else {
          err = null;
          tunnel = snap.tunnel;
          stats = snap.dashboard;
          clients = snap.clients;
          traffic = snap.traffic24h;
        }
      });
      return;
    }

    setState(() {
      loading = true;
      err = null;
    });
    try {
      final r = WguRepository.fromContext(auth, cfg);
      // Traffic series is slower; load tunnel + stats + peers first so the UI unlocks quickly.
      final batch = await Future.wait([
        r.tunnelStatus(),
        r.dashboardStats(),
        r.fetchClients(),
      ]);
      if (!mounted) return;
      setState(() {
        tunnel = batch[0] as Map<String, dynamic>;
        stats = batch[1] as DashboardStatsVm;
        clients = batch[2] as List<WgClientEnvelope>;
        loading = false;
      });
      final series = await r.trafficSeries(range: '24h');
      if (!mounted) return;
      setState(() {
        traffic = series;
      });
      await OfflineSnapshotStore.merge(
        username: auth.username,
        tunnel: tunnel,
        dashboard: stats,
        clients: clients,
        traffic24h: traffic,
      );
    } catch (e) {
      if (!mounted) return;
      final authAfter = context.read<AuthStore>();
      if (authAfter.offlineMode) {
        final snap = await OfflineSnapshotStore.load();
        if (!mounted) return;
        setState(() {
          loading = false;
          if (snap != null) {
            err = null;
            tunnel = snap.tunnel;
            stats = snap.dashboard;
            clients = snap.clients;
            traffic = snap.traffic24h;
          } else {
            err = formatNetworkError(e);
          }
        });
        return;
      }
      setState(() {
        err = formatNetworkError(e);
        loading = false;
      });
    } finally {
      if (mounted) {
        await context.read<WgApplyController>().refreshFromServer(auth, cfg);
      }
    }
  }

  /// Lightweight poll for hero card + estado (no peer list, no full-screen loading).
  Future<void> _pollLiveStats() async {
    if (!mounted || loading) return;
    if (context.read<AuthStore>().offlineMode) return;
    try {
      final auth = context.read<AuthStore>();
      final cfg = context.read<ServerSettings>();
      final r = WguRepository.fromContext(auth, cfg);
      final batch = await Future.wait([
        r.tunnelStatus(),
        r.dashboardStats(),
        r.trafficSeries(range: '24h'),
      ]);
      if (!mounted || loading) return;
      setState(() {
        tunnel = batch[0] as Map<String, dynamic>;
        stats = batch[1] as DashboardStatsVm;
        traffic = batch[2] as TrafficSeriesResponseVm;
      });
    } catch (_) {
      // Keep last good snapshot; full refresh / pull-to-refresh surfaces errors.
    }
  }

  @override
  void initState() {
    super.initState();
    _livePollTimer = Timer.periodic(_livePollInterval, (_) => _pollLiveStats());
  }

  @override
  void dispose() {
    _livePollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<AuthStore>().offlineMode;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            if (context.read<AuthStore>().offlineMode) {
              final ok = await context
                  .read<AuthStore>()
                  .tryReconnect(context.read<ServerSettings>());
              if (context.mounted && ok) await refresh();
              return;
            }
            await refresh();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header(context, offline)),
              if (err != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(err!, style: const TextStyle(color: AppColors.red)),
                  ),
                ),
              if (loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else ...[
                SliverToBoxAdapter(child: _heroCard()),
                SliverToBoxAdapter(child: _actions(context, offline)),
                SliverToBoxAdapter(child: _peerSectionHeader(context, offline)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final subset = clients.length <= _maxHomePeers
                          ? clients
                          : clients.sublist(0, _maxHomePeers);
                      if (i >= subset.length) return null;
                      final e = subset[i];
                      final (d24, u24) = traffic
                              ?.windowBytesForPeer(e.client.publicKey) ??
                          (0, 0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OpenContainer<bool?>(
                          transitionDuration:
                              const Duration(milliseconds: 420),
                          transitionType: ContainerTransitionType.fade,
                          closedColor: AppColors.surface,
                          openColor: AppColors.bg,
                          closedElevation: 0,
                          openElevation: 0,
                          closedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          openShape: const RoundedRectangleBorder(),
                          onClosed: (_) {
                            if (mounted) refresh();
                          },
                          tappable: false,
                          closedBuilder: (context, openContainer) {
                            return PeerPreviewTile(
                              envelope: e,
                              onChanged: refresh,
                              show24hTraffic: traffic != null,
                              traffic24hDown: d24,
                              traffic24hUp: u24,
                              readOnly: offline,
                              onTap: offline ? () {} : openContainer,
                            );
                          },
                          openBuilder: (context, _) {
                            return PeerDetailPage(clientId: e.client.id);
                          },
                        ),
                      );
                    },
                    childCount: clients.isEmpty
                        ? 0
                        : (clients.length < _maxHomePeers
                            ? clients.length
                            : _maxHomePeers),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool offline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WireGuard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Panel de control',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: offline ? null : widget.onOpenPeers,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: AppColors.textSecondary),
            onPressed: offline
                ? null
                : () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    final iface = tunnel?['iface_name']?.toString() ?? 'wg0';
    final up = tunnel?['tunnel_running'] == true;
    final online = stats?.onlineSessions ?? 0;
    final enabled = stats?.enabledPeers ?? 0;
    final downloadAcum = traffic != null
        ? traffic!.resolvedDownloadKpi(stats)
        : (stats?.bytesTransmitted ?? 0);
    final uploadAcum = traffic != null
        ? traffic!.resolvedUploadKpi(stats)
        : (stats?.bytesReceived ?? 0);
    // Same as web `traffic.html` KPI rates: rolling max TX/RX (~60s), bit/s — see `TrafficSeriesResponseVm.webTrafficKpi*`.
    final clientDownloadBps = traffic?.webTrafficKpiPeerDownloadBytesPerSec ?? 0;
    final clientUploadBps = traffic?.webTrafficKpiPeerUploadBytesPerSec ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.heroVpn,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'INTERFAZ ACTIVA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        up ? 'Conectado' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: up ? AppColors.green : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              iface,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sesiones en línea · $online · Descarga: ${formatBytes(downloadAcum)} · Subida: ${formatBytes(uploadAcum)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.accent,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    '$enabled',
                    'habilitados',
                    AppColors.green,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
                Expanded(
                  child: _miniStat(
                    '↓ ${formatBitrateBitsPerSecFromBytesPerSec(clientDownloadBps)}',
                    'descarga',
                    AppColors.accent,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
                Expanded(
                  child: _miniStat(
                    '↑ ${formatBitrateBitsPerSecFromBytesPerSec(clientUploadBps)}',
                    'subida',
                    AppColors.yellow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String val, String lbl, Color c) {
    return Column(
      children: [
        Text(
          val,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          lbl.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context, bool offline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OpenContainer<bool?>(
              transitionDuration: const Duration(milliseconds: 420),
              transitionType: ContainerTransitionType.fade,
              closedColor: AppColors.accent,
              openColor: AppColors.bg,
              closedElevation: 0,
              openElevation: 0,
              closedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              openShape: const RoundedRectangleBorder(),
              onClosed: (_) {
                if (mounted) refresh();
              },
              tappable: false,
              closedBuilder: (context, openContainer) {
                return FilledButton.icon(
                  onPressed: offline ? null : openContainer,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nuevo cliente'),
                );
              },
              openBuilder: (context, _) => const NewPeerPage(),
            ),
          ),
          const SizedBox(width: 10),
          _squareIconBtn(
            Icons.refresh_rounded,
            offline ? null : refresh,
          ),
          const SizedBox(width: 10),
          _squareIconBtn(
            Icons.downloading_rounded,
            offline ? null : _downloadAllConfigsZip,
            loading: _busyDownloadZip,
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAllConfigsZip() async {
    if (_busyDownloadZip || !mounted) return;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay peers para descargar.')),
      );
      return;
    }
    setState(() => _busyDownloadZip = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = WguRepository.fromContext(
        context.read<AuthStore>(),
        context.read<ServerSettings>(),
      );
      final bytes = await r.downloadAllPeersAsZip(clients);
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'wireguard-peers-$ts.zip',
              mimeType: 'application/zip',
            ),
          ],
          subject: 'Configuraciones WireGuard',
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('ZIP listo para guardar o compartir.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(formatNetworkError(e))),
      );
    } finally {
      if (mounted) setState(() => _busyDownloadZip = false);
    }
  }

  Widget _squareIconBtn(
    IconData icon,
    VoidCallback? onTap, {
    bool loading = false,
  }) {
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: (loading || onTap == null) ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 52,
          height: 52,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              : Icon(icon, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _peerSectionHeader(BuildContext context, bool offline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          const Text(
            'PEERS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: offline ? null : widget.onOpenPeers,
            child: const Text(
              'Ver todos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PeerPreviewTile extends StatelessWidget {
  const PeerPreviewTile({
    super.key,
    required this.envelope,
    required this.onTap,
    required this.onChanged,
    this.onlineHint,
    this.show24hTraffic = false,
    this.traffic24hDown = 0,
    this.traffic24hUp = 0,
    this.readOnly = false,
  });

  final WgClientEnvelope envelope;
  final VoidCallback onTap;
  final Future<void> Function() onChanged;
  /// When true (e.g. offline cache mode), taps and the enabled switch are disabled.
  final bool readOnly;
  final bool? onlineHint;
  /// When true, show traffic totals from `peer_totals` (same [range] as the series request, e.g. 24h).
  final bool show24hTraffic;
  final int traffic24hDown;
  final int traffic24hUp;

  @override
  Widget build(BuildContext context) {
    final c = envelope.client;
    final ip = c.allocatedIps.isNotEmpty ? c.allocatedIps.first : '—';
    final online = onlineHint ?? c.enabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: readOnly ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _avatarFor(c.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ip,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      online ? '● Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: online
                            ? AppColors.green
                            : AppColors.textMuted,
                      ),
                    ),
                    if (show24hTraffic) ...[
                      const SizedBox(height: 4),
                      const Text(
                        '24 h',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 0.3,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '↓${formatBytes(traffic24hDown)} · ↑${formatBytes(traffic24hUp)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 8),
                Switch(
                  value: c.enabled,
                  onChanged: readOnly
                      ? null
                      : (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final repo = WguRepository.fromContext(
                      context.read<AuthStore>(),
                      context.read<ServerSettings>(),
                    );
                    try {
                      final ok = await repo.setClientEnabled(c.id, v);
                      if (!context.mounted) return;
                      if (!ok) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se pudo guardar el estado del peer en el servidor.',
                            ),
                          ),
                        );
                        await onChanged();
                        return;
                      }
                      await onChanged();
                    } catch (e) {
                      if (!context.mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(formatNetworkError(e))),
                      );
                      await onChanged();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFor(String name) {
    final hue = name.hashCode.abs() % 360;
    final color = HSLColor.fromAHSL(1, hue.toDouble(), 0.35, 0.55).toColor();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.devices, color: color, size: 20),
    );
  }
}
