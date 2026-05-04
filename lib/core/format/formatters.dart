String formatBitrateBytesPerSec(double bytesPerSecond) {
  final bps = bytesPerSecond;
  if (bps < 1) return '—';
  if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
  final kb = bps / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB/s';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB/s';
}

/// Same math as web `templates/traffic.html` → `fmtRateKbitPerSec` ([bytesPerSecond] is bytes/s).
String formatBitrateBitsPerSecFromBytesPerSec(double bytesPerSecond) {
  final v = bytesPerSecond;
  if (!v.isFinite || v < 0) return '—';
  final kbps = (v * 8) / 1000;
  if (kbps < 1000) {
    final decimals = kbps >= 100 ? 0 : (kbps >= 10 ? 1 : 2);
    return '${kbps.toStringAsFixed(decimals)} Kb/s';
  }
  final mbps = kbps / 1000;
  if (mbps < 1000) {
    final decimals = mbps >= 100 ? 0 : (mbps >= 10 ? 1 : 2);
    return '${mbps.toStringAsFixed(decimals)} Mb/s';
  }
  final gbps = mbps / 1000;
  return '${gbps.toStringAsFixed(gbps >= 10 ? 1 : 2)} Gb/s';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(gb >= 10 ? 1 : 2)} GB';
}
