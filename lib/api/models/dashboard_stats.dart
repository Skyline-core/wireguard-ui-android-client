class DashboardStatsVm {
  const DashboardStatsVm({
    required this.totalPeers,
    required this.enabledPeers,
    required this.onlineSessions,
    required this.bytesReceived,
    required this.bytesTransmitted,
  });

  final int totalPeers;
  final int enabledPeers;
  final int onlineSessions;
  final int bytesReceived;
  final int bytesTransmitted;

  factory DashboardStatsVm.fromJson(Map<String, dynamic> j) {
    int i(String k) {
      final v = j[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    int i64(String k) {
      final v = j[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    return DashboardStatsVm(
      totalPeers: i('total_peers'),
      enabledPeers: i('enabled_peers'),
      onlineSessions: i('online_sessions'),
      bytesReceived: i64('bytes_received'),
      bytesTransmitted: i64('bytes_transmitted'),
    );
  }
}
