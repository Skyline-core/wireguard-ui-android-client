import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/models/client_models.dart';
import '../../api/models/dashboard_stats.dart';
import '../../api/models/traffic_series.dart';
import '../../api/wgu_repository.dart';
import '../../core/config/server_settings.dart';
import '../../core/format/formatters.dart';
import '../../core/offline/offline_snapshot_store.dart';
import '../../core/session/auth_store.dart';
import '../../core/theme/app_theme.dart';

class TrafficPage extends StatefulWidget {
  const TrafficPage({super.key});

  @override
  State<TrafficPage> createState() => TrafficPageState();
}

class TrafficPageState extends State<TrafficPage> {
  String range = '24h';
  bool loading = true;
  String? err;
  TrafficSeriesResponseVm? vm;
  DashboardStatsVm? dash;
  List<WgClientEnvelope> peers = [];

  static const Duration _livePollInterval = Duration(seconds: 4);
  Timer? _livePollTimer;

  Future<void> refresh({bool silent = false}) => _load(silent: silent);

  Future<void> _load({bool silent = false}) async {
    final auth = context.read<AuthStore>();
    if (auth.offlineMode) {
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
          err = 'Sin datos en caché.';
        } else {
          err = null;
          vm = snap.traffic24h;
          peers = snap.clients;
          dash = snap.dashboard;
        }
      });
      return;
    }
    final cfg = context.read<ServerSettings>();
    final r = WguRepository.fromContext(auth, cfg);
    if (!silent) {
      setState(() {
        loading = true;
        err = null;
      });
    } else {
      setState(() => err = null);
    }
    try {
      final batch = await Future.wait([
        r.trafficSeries(range: range),
        r.fetchClients(),
        r.dashboardStats(),
      ]);
      if (!mounted) return;
      setState(() {
        vm = batch[0] as TrafficSeriesResponseVm;
        peers = batch[1] as List<WgClientEnvelope>;
        dash = batch[2] as DashboardStatsVm;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        err = '$e';
        loading = false;
      });
    }
  }

  Future<void> _pollLiveStats() async {
    if (!mounted || loading) return;
    if (context.read<AuthStore>().offlineMode) return;
    try {
      final auth = context.read<AuthStore>();
      final cfg = context.read<ServerSettings>();
      final r = WguRepository.fromContext(auth, cfg);
      final batch = await Future.wait([
        r.trafficSeries(range: range),
        r.dashboardStats(),
      ]);
      if (!mounted || loading) return;
      setState(() {
        vm = batch[0] as TrafficSeriesResponseVm;
        dash = batch[1] as DashboardStatsVm;
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(silent: false));
    _livePollTimer = Timer.periodic(_livePollInterval, (_) => _pollLiveStats());
  }

  @override
  void dispose() {
    _livePollTimer?.cancel();
    super.dispose();
  }

  String _resolveName(String pubkey) {
    for (final e in peers) {
      if (e.client.publicKey == pubkey) return e.client.name;
    }
    return pubkey.length > 8 ? pubkey.substring(0, 8) : pubkey;
  }

  String _rangeSubtitle() {
    switch (range) {
      case '7d':
        return 'últimos 7 días (estimado en vivo)';
      case '30d':
        return 'últimos 30 días (estimado en vivo)';
      default:
        return 'últimas 24h (estimado en vivo)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartPerPeer = context.watch<ServerSettings>().trafficChartPerPeer;
    final offline = context.watch<AuthStore>().offlineMode;
    final v = vm;
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
              if (context.mounted && ok) await _load(silent: true);
              return;
            }
            await _load(silent: true);
          },
          child: loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _header(context),
                    const SizedBox(height: 200),
                    const Center(child: CircularProgressIndicator.adaptive()),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    _header(context),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(err!, style: TextStyle(color: context.palette.red)),
                      ),
                    if (v != null) ...[
                      _liveCard(v),
                      _rangeTabs(offline),
                      chartPerPeer ? _barsPerPeer(v) : _barsAggregate(v),
                      _metrics(v),
                      _peerRanking(v),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tráfico',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: context.palette.textPrimary,
            ),
          ),
          Text(
            vm == null ? '…' : 'Actualizado · age ${vm!.updatedAgeSecs}s',
            style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _liveCard(TrafficSeriesResponseVm v) {
    final download = formatBitrateBitsPerSecFromBytesPerSec(
        v.webTrafficKpiPeerDownloadBytesPerSec);
    final upload = formatBitrateBitsPerSecFromBytesPerSec(
        v.webTrafficKpiPeerUploadBytesPerSec);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          gradient: context.palette.trafficLiveCardGradient,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: context.palette.green.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VELOCIDAD EN TIEMPO REAL',
              style: TextStyle(
                letterSpacing: 0.8,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.palette.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        download,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: context.palette.accent,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'descarga',
                        style:
                            TextStyle(fontSize: 11, color: context.palette.textMuted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        upload,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: context.palette.yellow,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'subida',
                        style:
                            TextStyle(fontSize: 11, color: context.palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeTabs(bool offline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _rng('24h', '24h', offline),
          const SizedBox(width: 8),
          _rng('7 días', '7d', offline),
          const SizedBox(width: 8),
          _rng('30 días', '30d', offline),
        ],
      ),
    );
  }

  Expanded _rng(String label, String key, bool offline) {
    final sel = range == key;
    return Expanded(
      child: Material(
        color: sel ? context.palette.accent.withValues(alpha: 0.14) : context.palette.surface2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: offline
              ? null
              : () {
                  range = key;
                  _load(silent: true);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                color: sel ? context.palette.accent : context.palette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Same idea as web aggregate chart: one bar per time bucket, height ∝ RXavg + TXavg (bytes/s).
  Widget _barsAggregate(TrafficSeriesResponseVm v) {
    final buckets = v.buckets;
    if (buckets.isEmpty) return const SizedBox.shrink();

    double maxB = 1;
    for (final b in buckets) {
      final m = [b.rxAvgBps, b.txAvgBps].fold<double>(0, (p, e) => p > e ? p : e);
      if (m > maxB) maxB = m;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.palette.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ancho de banda · agregado',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: context.palette.textPrimary,
              ),
            ),
            Text(
              _rangeSubtitle(),
              style: TextStyle(fontSize: 10, color: context.palette.textMuted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 76,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final b in buckets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          height: 72 *
                              (((b.rxAvgBps + b.txAvgBps) / (maxB * 2))
                                  .clamp(0.04, 1.0)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                context.palette.accent.withValues(alpha: 0.9),
                                context.palette.accent.withValues(alpha: 0.35),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('inicio',
                    style: TextStyle(fontSize: 9, color: context.palette.textMuted)),
                Text('ahora',
                    style: TextStyle(fontSize: 9, color: context.palette.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Matches web `traffic.html` `renderBandwidthChart`: one stacked column per peer (download↑ red, upload↓ yellow).
  Widget _barsPerPeer(TrafficSeriesResponseVm v) {
    final list =
        v.peerTotals.isNotEmpty ? v.peerTotals : v.peerCurrentTotals;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.palette.borderSubtle),
          ),
          child: Text(
            'Sin datos por peer para este rango.',
            style: TextStyle(color: context.palette.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    var maxB = 1.0;
    for (final p in list) {
      final d = p.downloadBytes.toDouble();
      final u = p.uploadBytes.toDouble();
      if (d > maxB) maxB = d;
      if (u > maxB) maxB = u;
    }

    const barAreaH = 200.0;
    const barW = 26.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.palette.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ancho de banda',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: context.palette.textPrimary,
              ),
            ),
            Text(
              _rangeSubtitle(),
              style: TextStyle(fontSize: 10, color: context.palette.textMuted),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: barAreaH + 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: context.palette.borderSubtle,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final p in list)
                        Padding(
                          padding: const EdgeInsets.only(left: 3, right: 3),
                          child: Tooltip(
                            message:
                                '${_resolveName(p.publicKey)}\n↓ ${formatBytes(p.downloadBytes)} · ↑ ${formatBytes(p.uploadBytes)}',
                            child: SizedBox(
                              width: barW,
                              height: barAreaH,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: barW,
                                      height: math.max(
                                        2.0,
                                        barAreaH *
                                            0.5 *
                                            (p.downloadBytes / maxB),
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.palette.red
                                            .withValues(alpha: 0.95),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: barW,
                                      height: math.max(
                                        2.0,
                                        barAreaH *
                                            0.5 *
                                            (p.uploadBytes / maxB),
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.palette.yellow,
                                        borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.palette.red.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Descarga (arriba)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.palette.yellow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Subida (abajo)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Perspectiva peer: descarga = TX del servidor, subida = RX del servidor.',
              style: TextStyle(
                fontSize: 9,
                fontStyle: FontStyle.italic,
                height: 1.35,
                color: context.palette.textMuted.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metrics(TrafficSeriesResponseVm v) {
    final dl = v.resolvedDownloadKpi(dash);
    final ul = v.resolvedUploadKpi(dash);
    final peerCount =
        v.peerTotals.isNotEmpty ? v.peerTotals.length : v.peerCurrentTotals.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SizedBox(
        height: 78,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _metricChip('Descarga', formatBytes(dl)),
            _metricChip('Subida', formatBytes(ul)),
            _metricChip('Pico', '${v.peakPeerDownloadMbps.toStringAsFixed(1)} Mb/s'),
            _metricChip('Peers', '$peerCount'),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(String lbl, String val) {
    return Container(
      width: 118,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: context.palette.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lbl,
            style: TextStyle(fontSize: 10, color: context.palette.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _peerRanking(TrafficSeriesResponseVm v) {
    final source =
        v.peerTotals.isNotEmpty ? v.peerTotals : v.peerCurrentTotals;
    final list = [...source]
      ..sort((a, b) =>
          ((b.rxBytes + b.txBytes) - (a.rxBytes + a.txBytes)));

    if (list.isEmpty) return const SizedBox.shrink();

    final topSum = list.first.rxBytes + list.first.txBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Text(
            v.peerTotals.isNotEmpty ? 'POR PEER (ventana)' : 'POR PEER (kernel)',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.palette.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  for (var i = 0; i < list.length.clamp(0, 14); i++)
                    _rankRow(
                      list[i],
                      i + 1,
                      topSum == 0
                          ? 0.08
                          : (list[i].rxBytes + list[i].txBytes) /
                              topSum,
                      i > 0,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rankRow(
      TrafficPeerTotalVm p, int rank, double frac, bool divider) {
    return Column(
      children: [
        if (divider)
          Divider(height: 1, thickness: 1, color: context.palette.borderSubtle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(width: 22, child: Text('$rank', style: TextStyle(color: context.palette.textMuted, fontWeight: FontWeight.bold))),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resolveName(p.publicKey),
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: frac.clamp(0.06, 1.0),
                        minHeight: 3,
                        color: context.palette.accent,
                        backgroundColor: context.palette.surface2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '↓ ${formatBytes(p.downloadBytes)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: context.palette.accent,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    '↑ ${formatBytes(p.uploadBytes)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.yellow,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
