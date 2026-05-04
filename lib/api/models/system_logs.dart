/// One block from GET `/api/system-logs` (`sections`), same idea as web Logs page.
class SystemLogSectionVm {
  const SystemLogSectionVm({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  factory SystemLogSectionVm.fromJson(Map<String, dynamic> j) {
    final raw = j['Lines'] ?? j['lines'];
    final list = raw is List
        ? raw.map((e) => e.toString()).toList(growable: false)
        : <String>[];
    return SystemLogSectionVm(
      title: '${j['Title'] ?? j['title'] ?? ''}',
      lines: list,
    );
  }
}

class SystemLogsSnapshot {
  const SystemLogsSnapshot({
    required this.ifaceName,
    required this.sections,
    required this.logLines,
    required this.tailUnset,
  });

  final String ifaceName;
  final List<SystemLogSectionVm> sections;
  /// Tail of optional file when `WGUI_LOG_TAIL_PATH` is set (same key as API `log_lines`).
  final List<String> logLines;
  final bool tailUnset;

  factory SystemLogsSnapshot.fromJson(Map<String, dynamic> j) {
    final rawSections = j['sections'];
    final sections = rawSections is List
        ? rawSections
            .whereType<Map>()
            .map(
              (e) => SystemLogSectionVm.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <SystemLogSectionVm>[];

    final rawLines = j['log_lines'];
    final logLines = rawLines is List
        ? rawLines.map((e) => e.toString()).toList(growable: false)
        : <String>[];

    return SystemLogsSnapshot(
      ifaceName: '${j['iface_name'] ?? ''}',
      sections: sections,
      logLines: logLines,
      tailUnset: j['log_tail_unset'] == true,
    );
  }

  /// Lines like the web viewport: `[section title]` prefix + optional `[archivo]` tail file.
  List<String> get displayLines {
    final out = <String>[];
    for (final s in sections) {
      for (final line in s.lines) {
        out.add('[${s.title}] $line');
      }
    }
    if (tailUnset) {
      out.add(
        '[archivo] Sin archivo de tail configurado (variable WGUI_LOG_TAIL_PATH en el servidor).',
      );
    } else {
      for (final line in logLines) {
        out.add('[archivo] $line');
      }
    }
    return out;
  }
}
