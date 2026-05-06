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
import '../../l10n/app_localizations.dart';
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
  /// Live kernel map from [`WguRepository.peerStatsMap`] — includes [PeerTrafficRow.connected].
  Map<String, PeerTrafficRow> peerStats = {};

  /// Peers shown on Home; the rest live under the Peers tab.
  static const int _maxHomePeers = 5;

  /// Align with server `trafficSampleInterval` (4s) and web dashboard polling when realtime is on.
  static const Duration _livePollInterval = Duration(seconds: 4);
  Timer? _livePollTimer;

  /// When [silent] is true (tab switch, pull-to-refresh), keeps showing existing content while fetching.
  Future<void> refresh({bool silent = false}) async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();

    if (auth.offlineMode) {
      final loc = AppLocalizations.of(context)!;
      if (!silent) {
        setState(() {
          loading = true;
          err = null;
        });
      } else {
        setState(() => err = null);
      }
      final snap = await OfflineSnapshotStore.load();
      if (!mounted) return;
      setState(() {
        loading = false;
        if (snap == null) {
          err = loc.homeOfflineNoCache;
        } else {
          err = null;
          tunnel = snap.tunnel;
          stats = snap.dashboard;
          clients = snap.clients;
          traffic = snap.traffic24h;
          peerStats = snap.peerStats;
        }
      });
      return;
    }

    if (!silent) {
      setState(() {
        loading = true;
        err = null;
      });
    } else {
      setState(() => err = null);
    }

    try {
      final r = WguRepository.fromContext(auth, cfg);
      // Traffic series is slower; load tunnel + stats + peers first so the UI unlocks quickly.
      final batch = await Future.wait([
        r.tunnelStatus(),
        r.dashboardStats(),
        r.fetchClients(),
        r.peerStatsMap(),
      ]);
      if (!mounted) return;
      setState(() {
        tunnel = batch[0] as Map<String, dynamic>;
        stats = batch[1] as DashboardStatsVm;
        clients = batch[2] as List<WgClientEnvelope>;
        peerStats = batch[3] as Map<String, PeerTrafficRow>;
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
        peerStats: peerStats,
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
            peerStats = snap.peerStats;
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
        r.peerStatsMap(),
      ]);
      if (!mounted || loading) return;
      setState(() {
        tunnel = batch[0] as Map<String, dynamic>;
        stats = batch[1] as DashboardStatsVm;
        traffic = batch[2] as TrafficSeriesResponseVm;
        peerStats = batch[3] as Map<String, PeerTrafficRow>;
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
      backgroundColor: context.palette.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.palette.accent,
          onRefresh: () async {
              if (context.read<AuthStore>().offlineMode) {
                final ok = await context
                    .read<AuthStore>()
                    .tryReconnect(context.read<ServerSettings>());
              if (context.mounted && ok) await refresh(silent: true);
                return;
              }
              await refresh(silent: true);
            },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header(context, offline)),
              if (err != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(err!, style: TextStyle(color: context.palette.red)),
                  ),
                ),
              if (loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else ...[
                SliverToBoxAdapter(child: _heroCard(context)),
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
                          closedColor: context.palette.surface,
                          openColor: context.palette.bg,
                          closedElevation: 0,
                          openElevation: 0,
                          closedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          openShape: const RoundedRectangleBorder(),
                          onClosed: (_) {
                            if (mounted) refresh(silent: true);
                          },
                          tappable: false,
                          closedBuilder: (context, openContainer) {
                            final st = peerStats[e.client.publicKey];
                            final vpnOn = e.client.enabled && (st?.connected == true);
                            return PeerPreviewTile(
                              envelope: e,
                              onChanged: () => refresh(silent: true),
                              show24hTraffic: traffic != null,
                              traffic24hDown: d24,
                              traffic24hUp: u24,
                              readOnly: offline,
                              onTap: offline ? () {} : openContainer,
                              onlineHint: vpnOn,
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
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WireGuard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.homeSubtitle,
                  style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: context.palette.textSecondary),
            onPressed: offline ? null : widget.onOpenPeers,
          ),
          IconButton(
            icon: Icon(Icons.account_circle_outlined,
                color: context.palette.textSecondary),
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

  Widget _heroCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
          gradient: context.palette.heroVpn,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.palette.accent.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  loc.homeActiveInterface,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: context.palette.accent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.palette.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.palette.green.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.palette.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        up ? loc.homeTunnelConnected : loc.homeTunnelInactive,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: up ? context.palette.green : context.palette.textMuted,
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.homeTunnelStatsLine(
                loc.homeSessionsOnlineLabel,
                online,
                loc.homeTrafficDownloadLabel,
                formatBytes(downloadAcum),
                loc.homeTrafficUploadLabel,
                formatBytes(uploadAcum),
              ),
              style: TextStyle(
                fontSize: 13,
                color: context.palette.accent,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    '$enabled',
                    loc.homeMiniPeersEnabled,
                    context.palette.green,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: context.palette.borderSubtle,
                ),
                Expanded(
                  child: _miniStat(
                    '↓ ${formatBitrateBitsPerSecFromBytesPerSec(clientDownloadBps)}',
                    loc.trafficDlShort,
                    context.palette.accent,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: context.palette.borderSubtle,
                ),
                Expanded(
                  child: _miniStat(
                    '↑ ${formatBitrateBitsPerSecFromBytesPerSec(clientUploadBps)}',
                    loc.trafficUlShort,
                    context.palette.yellow,
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
          style: TextStyle(
            fontSize: 10,
            color: context.palette.textMuted,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context, bool offline) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OpenContainer<bool?>(
              transitionDuration: const Duration(milliseconds: 420),
              transitionType: ContainerTransitionType.fade,
              closedColor: context.palette.accent,
              openColor: context.palette.bg,
              closedElevation: 0,
              openElevation: 0,
              closedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              openShape: const RoundedRectangleBorder(),
              onClosed: (_) {
                if (mounted) refresh(silent: true);
              },
              tappable: false,
              closedBuilder: (context, openContainer) {
                return FilledButton.icon(
                  onPressed: offline ? null : openContainer,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: context.palette.accent,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                  ),
                  icon: Icon(Icons.add, size: 20),
                  label: Text(loc.homeNewClient),
                );
              },
              openBuilder: (context, _) => const NewPeerPage(),
            ),
          ),
          const SizedBox(width: 10),
          _squareIconBtn(
            Icons.refresh_rounded,
            offline ? null : () => refresh(silent: true),
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
    final loc = AppLocalizations.of(context)!;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.homeZipNoPeers)),
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
          subject: loc.homeShareZipSubject,
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(loc.homeZipReady)),
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
      color: context.palette.surface2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: (loading || onTap == null) ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 52,
          height: 52,
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.palette.accent,
                  ),
                )
              : Icon(icon, color: context.palette.textSecondary),
        ),
      ),
    );
  }

  Widget _peerSectionHeader(BuildContext context, bool offline) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          Text(
            loc.homePeersHeading,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.palette.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: offline ? null : widget.onOpenPeers,
            child: Text(
              loc.homeSeeAllPeers,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.palette.accent,
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
  /// When [client.enabled] is true, whether the peer has a **recent WireGuard handshake** (VPN connected), from `/api/wg-peer-stats` `connected`.
  final bool? onlineHint;
  /// When true, show traffic totals from `peer_totals` (same [range] as the series request, e.g. 24h).
  final bool show24hTraffic;
  final int traffic24hDown;
  final int traffic24hUp;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = envelope.client;
    final ip = c.allocatedIps.isNotEmpty ? c.allocatedIps.first : loc.commonDash;
    final vpnOn = c.enabled && (onlineHint == true);
    String statusText;
    Color statusColor;
    if (!c.enabled) {
      statusText = loc.peerStatusOff;
      statusColor = context.palette.textMuted;
    } else if (vpnOn) {
      statusText = loc.peerStatusOnline;
      statusColor = context.palette.green;
    } else {
      statusText = loc.peerStatusDisconnected;
      statusColor = context.palette.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: readOnly ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _avatarFor(c.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: context.palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.88,
                      alignment: Alignment.topCenter,
                      child: Switch(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: c.enabled,
                        onChanged: readOnly
                            ? null
                            : (v) async {
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                final repo = WguRepository.fromContext(
                                  context.read<AuthStore>(),
                                  context.read<ServerSettings>(),
                                );
                                try {
                                  final ok =
                                      await repo.setClientEnabled(c.id, v);
                                  if (!context.mounted) return;
                                  if (!ok) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          loc.peerSaveStateFailed,
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
                                    SnackBar(
                                        content:
                                            Text(formatNetworkError(e))),
                                  );
                                  await onChanged();
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ip,
                  maxLines: 3,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.28,
                    color: context.palette.textSecondary,
                    fontFamily: 'monospace',
                    letterSpacing: -0.2,
                  ),
                ),
                if (show24hTraffic) ...[
                  const SizedBox(height: 7),
                  Text(
                    loc.peerTraffic24hBadge,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.35,
                      color: context.palette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '↓ ${formatBytes(traffic24hDown)}   ·   ↑ ${formatBytes(traffic24hUp)}',
                    maxLines: 2,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      color: context.palette.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.devices, color: color, size: 20),
    );
  }
}
