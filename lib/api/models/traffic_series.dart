import 'dashboard_stats.dart';

class TrafficBucketVm {
  const TrafficBucketVm({
    required this.rxAvgBps,
    required this.txAvgBps,
    required this.topPeerPubKey,
  });

  final double rxAvgBps;
  final double txAvgBps;
  final String topPeerPubKey;

  factory TrafficBucketVm.fromJson(Map<String, dynamic> j) => TrafficBucketVm(
        rxAvgBps: (j['rx_avg_bps'] as num?)?.toDouble() ?? 0,
        txAvgBps: (j['tx_avg_bps'] as num?)?.toDouble() ?? 0,
        topPeerPubKey: '${j['top_peer_public_key'] ?? ''}',
      );
}

class TrafficPeerTotalVm {
  const TrafficPeerTotalVm({
    required this.publicKey,
    required this.rxBytes,
    required this.txBytes,
  });

  final String publicKey;
  final int rxBytes;
  final int txBytes;

  factory TrafficPeerTotalVm.fromJson(Map<String, dynamic> j) =>
      TrafficPeerTotalVm(
        publicKey: '${j['public_key'] ?? ''}',
        rxBytes: (j['rx_bytes'] as num?)?.toInt() ?? 0,
        txBytes: (j['tx_bytes'] as num?)?.toInt() ?? 0,
      );
}

class TrafficSeriesResponseVm {
  const TrafficSeriesResponseVm({
    required this.range,
    required this.buckets,
    required this.peerTotals,
    required this.peerCurrentTotals,
    required this.rxRateNowBps,
    required this.txRateNowBps,
    required this.rxRateRecentMaxBps,
    required this.txRateRecentMaxBps,
    required this.peakPeerDownloadMbps,
    required this.totalRxBytes,
    required this.totalTxBytes,
    required this.updatedAgeSecs,
  });

  final String range;
  final List<TrafficBucketVm> buckets;
  /// Bytes per peer aggregated over the chart window (same source as web dashboard KPIs).
  final List<TrafficPeerTotalVm> peerTotals;
  final List<TrafficPeerTotalVm> peerCurrentTotals;
  /// Instant aggregate RX rate; JSON key `rx_rate_now_bps` but value is **bytes/s**.
  final double rxRateNowBps;
  /// Instant aggregate TX rate; JSON key `tx_rate_now_bps` but value is **bytes/s**.
  final double txRateNowBps;
  /// Rolling max RX (~60s window); JSON `rx_rate_recent_max_bps`, bytes/s (KPI subidas web).
  final double rxRateRecentMaxBps;
  /// Rolling max TX; JSON `tx_rate_recent_max_bps`, bytes/s (KPI descarga web).
  final double txRateRecentMaxBps;
  final double peakPeerDownloadMbps;
  final int totalRxBytes;
  final int totalTxBytes;
  final int updatedAgeSecs;

  /// Web dashboard "Descarga": Σ `peer_totals`.tx_bytes (server→peer in the series window).
  int get kpiDownloadSeriesBytes =>
      peerTotals.fold<int>(0, (s, p) => s + p.txBytes);

  /// Web dashboard "Subida": Σ `peer_totals`.rx_bytes (peer→server in the series window).
  int get kpiUploadSeriesBytes =>
      peerTotals.fold<int>(0, (s, p) => s + p.rxBytes);

  /// Home / Traffic KPI chips: window totals when [peerTotals] is non-empty, else kernel (+ optional dashboard snapshot).
  int resolvedDownloadKpi(DashboardStatsVm? dashboard) {
    if (peerTotals.isNotEmpty) return kpiDownloadSeriesBytes;
    return dashboard?.bytesTransmitted ?? totalTxBytes;
  }

  int resolvedUploadKpi(DashboardStatsVm? dashboard) {
    if (peerTotals.isNotEmpty) return kpiUploadSeriesBytes;
    return dashboard?.bytesReceived ?? totalRxBytes;
  }

  /// Per-peer byte totals for the selected [range] (`peer_totals`). Perspectiva peer: descarga = TX, subida = RX.
  (int downloadBytes, int uploadBytes) windowBytesForPeer(String publicKey) {
    for (final p in peerTotals) {
      if (p.publicKey == publicKey) {
        return (p.txBytes, p.rxBytes);
      }
    }
    return (0, 0);
  }

  /// Web `traffic.html` `applyKpiFrom24h`: peer download KPI uses server TX rolling peak (`fmtRateKbitPerSec(txBpsPeak)`).
  double get webTrafficKpiPeerDownloadBytesPerSec => txRateRecentMaxBps;

  /// Peer upload KPI uses server RX rolling peak (`fmtRateKbitPerSec(rxBpsPeak)`).
  double get webTrafficKpiPeerUploadBytesPerSec => rxRateRecentMaxBps;

  factory TrafficSeriesResponseVm.fromJson(Map<String, dynamic> j) {
    List<TrafficBucketVm> bs(String key) {
      final v = j[key];
      if (v is! List) return [];
      return v
          .whereType<Map<String, dynamic>>()
          .map(TrafficBucketVm.fromJson)
          .toList();
    }

    List<TrafficPeerTotalVm> pts(String key) {
      final v = j[key];
      if (v is! List) return [];
      return v
          .whereType<Map<String, dynamic>>()
          .map(TrafficPeerTotalVm.fromJson)
          .toList();
    }

    double recentOrNow(String recentKey, String nowKey) {
      if (!j.containsKey(recentKey)) {
        return (j[nowKey] as num?)?.toDouble() ?? 0;
      }
      return (j[recentKey] as num?)?.toDouble() ?? 0;
    }

    return TrafficSeriesResponseVm(
      range: '${j['range'] ?? '24h'}',
      buckets: bs('buckets'),
      peerTotals: pts('peer_totals'),
      peerCurrentTotals: pts('peer_current_totals'),
      rxRateNowBps: (j['rx_rate_now_bps'] as num?)?.toDouble() ?? 0,
      txRateNowBps: (j['tx_rate_now_bps'] as num?)?.toDouble() ?? 0,
      rxRateRecentMaxBps: recentOrNow('rx_rate_recent_max_bps', 'rx_rate_now_bps'),
      txRateRecentMaxBps: recentOrNow('tx_rate_recent_max_bps', 'tx_rate_now_bps'),
      peakPeerDownloadMbps:
          (j['peak_peer_download_mbps'] as num?)?.toDouble() ?? 0,
      totalRxBytes: (j['total_rx_bytes'] as num?)?.toInt() ?? 0,
      totalTxBytes: (j['total_tx_bytes'] as num?)?.toInt() ?? 0,
      updatedAgeSecs: (j['updated_age_secs'] as num?)?.toInt() ?? 0,
    );
  }
}

extension TrafficPeerTotalVmPerspective on TrafficPeerTotalVm {
  /// Peer perspective — matches web dashboard peer row ↓ column.
  int get downloadBytes => txBytes;
  /// Peer perspective — matches web dashboard peer row ↑ column.
  int get uploadBytes => rxBytes;
}
