import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../api/models/client_models.dart';
import '../../api/models/dashboard_stats.dart';
import '../../api/models/traffic_series.dart';

/// Local JSON cache of the last known data when the server does not respond.
class OfflineSnapshotStore {
  OfflineSnapshotStore._();

  static const _fileName = 'wgui_offline_snapshot.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<Map<String, dynamic>?> _readRaw() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final txt = await f.readAsString();
      final j = jsonDecode(txt);
      if (j is Map<String, dynamic>) return j;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeRaw(Map<String, dynamic> data) async {
    try {
      final f = await _file();
      await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      debugPrint('[OfflineSnapshotStore] write failed: $e');
    }
  }

  static Future<void> clear() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Fusiona con lo ya guardado (no borra claves no enviadas).
  static Future<void> merge({
    String? username,
    Map<String, dynamic>? tunnel,
    DashboardStatsVm? dashboard,
    List<WgClientEnvelope>? clients,
    TrafficSeriesResponseVm? traffic24h,
    Map<String, PeerTrafficRow>? peerStats,
    TrafficSeriesResponseVm? peersSeries24h,
  }) async {
    final cur = await _readRaw() ?? <String, dynamic>{};
    if (username != null && username.isNotEmpty) cur['username'] = username;
    if (tunnel != null) cur['tunnel'] = tunnel;
    if (dashboard != null) cur['dashboard'] = _dashboardToMap(dashboard);
    if (clients != null) {
      cur['clients'] = clients.map(_envelopeToMap).toList();
    }
    if (traffic24h != null) cur['traffic24h'] = _trafficToMap(traffic24h);
    if (peerStats != null) {
      cur['peer_stats'] = peerStats.map((k, v) => MapEntry(k, {'rx': v.rx, 'tx': v.tx}));
    }
    if (peersSeries24h != null) {
      cur['peers_series_24h'] = _trafficToMap(peersSeries24h);
    }
    cur['saved_at'] = DateTime.now().toUtc().toIso8601String();
    await _writeRaw(cur);
  }

  static Future<OfflineSnapshotVm?> load() async {
    final raw = await _readRaw();
    if (raw == null) return null;
    try {
      final username = raw['username']?.toString();
      Map<String, dynamic>? tunnel;
      final t = raw['tunnel'];
      if (t is Map<String, dynamic>) tunnel = t;

      DashboardStatsVm? dash;
      final d = raw['dashboard'];
      if (d is Map<String, dynamic>) dash = DashboardStatsVm.fromJson(d);

      List<WgClientEnvelope> clients = [];
      final cl = raw['clients'];
      if (cl is List) {
        clients = cl
            .whereType<Map<String, dynamic>>()
            .map(WgClientEnvelope.fromFlexible)
            .toList();
      }

      TrafficSeriesResponseVm? traffic24h;
      final tr = raw['traffic24h'];
      if (tr is Map<String, dynamic>) traffic24h = TrafficSeriesResponseVm.fromJson(tr);

      Map<String, PeerTrafficRow> peerStats = {};
      final ps = raw['peer_stats'];
      if (ps is Map) {
        ps.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            peerStats['$k'] = PeerTrafficRow.fromJson(v);
          }
        });
      }

      TrafficSeriesResponseVm? peersSeries;
      final psr = raw['peers_series_24h'];
      if (psr is Map<String, dynamic>) peersSeries = TrafficSeriesResponseVm.fromJson(psr);

      return OfflineSnapshotVm(
        username: username,
        tunnel: tunnel,
        dashboard: dash,
        clients: clients,
        traffic24h: traffic24h,
        peerStats: peerStats,
        peersSeries24h: peersSeries,
      );
    } catch (e) {
      debugPrint('[OfflineSnapshotStore] parse: $e');
      return null;
    }
  }

  static Map<String, dynamic> _dashboardToMap(DashboardStatsVm d) => {
        'total_peers': d.totalPeers,
        'enabled_peers': d.enabledPeers,
        'online_sessions': d.onlineSessions,
        'bytes_received': d.bytesReceived,
        'bytes_transmitted': d.bytesTransmitted,
      };

  static Map<String, dynamic> _envelopeToMap(WgClientEnvelope e) {
    final c = e.client;
    return {
      'Client': {
        'id': c.id,
        'name': c.name,
        'public_key': c.publicKey,
        'private_key': c.privateKey,
        'preshared_key': c.presharedKey,
        'allocated_ips': c.allocatedIps,
        'allowed_ips': c.allowedIps,
        'extra_allowed_ips': c.extraAllowedIps,
        'endpoint': c.endpoint,
        'use_server_dns': c.useServerDns,
        'enabled': c.enabled,
        'email': c.email,
        'additional_notes': c.additionalNotes,
      },
      if (e.qrCode != null && e.qrCode!.isNotEmpty) 'QRCode': e.qrCode,
    };
  }

  static Map<String, dynamic> _trafficToMap(TrafficSeriesResponseVm v) => {
        'range': v.range,
        'buckets': v.buckets
            .map((b) => {
                  'rx_avg_bps': b.rxAvgBps,
                  'tx_avg_bps': b.txAvgBps,
                  'top_peer_public_key': b.topPeerPubKey,
                })
            .toList(),
        'peer_totals': v.peerTotals
            .map((p) => {
                  'public_key': p.publicKey,
                  'rx_bytes': p.rxBytes,
                  'tx_bytes': p.txBytes,
                })
            .toList(),
        'peer_current_totals': v.peerCurrentTotals
            .map((p) => {
                  'public_key': p.publicKey,
                  'rx_bytes': p.rxBytes,
                  'tx_bytes': p.txBytes,
                })
            .toList(),
        'rx_rate_now_bps': v.rxRateNowBps,
        'tx_rate_now_bps': v.txRateNowBps,
        'rx_rate_recent_max_bps': v.rxRateRecentMaxBps,
        'tx_rate_recent_max_bps': v.txRateRecentMaxBps,
        'peak_peer_download_mbps': v.peakPeerDownloadMbps,
        'total_rx_bytes': v.totalRxBytes,
        'total_tx_bytes': v.totalTxBytes,
        'updated_age_secs': v.updatedAgeSecs,
      };
}

class OfflineSnapshotVm {
  const OfflineSnapshotVm({
    required this.username,
    required this.tunnel,
    required this.dashboard,
    required this.clients,
    required this.traffic24h,
    required this.peerStats,
    required this.peersSeries24h,
  });

  final String? username;
  final Map<String, dynamic>? tunnel;
  final DashboardStatsVm? dashboard;
  final List<WgClientEnvelope> clients;
  final TrafficSeriesResponseVm? traffic24h;
  final Map<String, PeerTrafficRow> peerStats;
  final TrafficSeriesResponseVm? peersSeries24h;
}
