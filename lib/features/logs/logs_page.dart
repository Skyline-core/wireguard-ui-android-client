import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/models/system_logs.dart';
import '../../api/wgu_repository.dart';
import '../../core/config/server_settings.dart';
import '../../core/session/auth_store.dart';
import '../../core/theme/app_theme.dart';

/// Rough syslog-ish level for tint + chips (aligned with web `detectLevel`, sin falsos
/// positivos tipo **STDERR** → substring `ERR`).
String _logLevelBucket(String text) {
  final t = text.toUpperCase();
  if (_mentionsSeverity(t, [
        ' ERROR ',
        'ERROR:',
        ' FAILED ',
        'FAILURE',
        ' FATAL ',
        'DENIED',
        'CRITICAL',
        'EMERG',
      ]) ||
      t.contains('ERROR[') ||
      t.endsWith(' ERROR')) {
    return 'ERROR';
  }
  if (_mentionsSeverity(t, ['WARN', 'WARNING', ' RETRY'])) return 'WARN';
  if (_mentionsSeverity(t, [
        ' INFO ',
        'INFO:',
        'HANDSHAKE',
        'NOTICE',
        ' ACTIVE ',
      ]) ||
      t.contains('INFORMATION')) {
    return 'INFO';
  }
  return 'ALL';
}

bool _mentionsSeverity(String upper, List<String> needles) {
  for (final n in needles) {
    if (upper.contains(n)) return true;
  }
  return false;
}

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final _filter = TextEditingController();
  String lvl = 'all';
  SystemLogsSnapshot? snap;
  String? err;
  bool loading = true;
  /// Server `realtime_stats_enabled` false → API returns 403; same gate as web Logs link.
  bool monitoringDisabled = false;

  Future<void> _load() async {
    final r = WguRepository.fromContext(
      context.read<AuthStore>(),
      context.read<ServerSettings>(),
    );
    setState(() {
      loading = true;
      err = null;
      monitoringDisabled = false;
    });
    try {
      final hints = await r.uiNavHints();
      if (!mounted) return;
      final live = hints?['show_logs_nav'] == true;
      if (!live) {
        setState(() {
          snap = null;
          loading = false;
          monitoringDisabled = true;
        });
        return;
      }

      final logs = await r.systemLogs();
      if (!mounted) return;
      if (logs == null) {
        setState(() {
          snap = null;
          err =
              'No se pudieron cargar los logs (403 o sesión). Activa el monitoreo en Ajustes o revisa permisos.';
          loading = false;
        });
        return;
      }
      setState(() {
        snap = logs;
        err = null;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _filter.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  bool _lineMatchesFilter(String line) {
    if (lvl == 'all') return true;
    return _logLevelBucket(line) == lvl;
  }

  @override
  Widget build(BuildContext context) {
    final lines = snap?.displayLines ?? <String>[];

    Iterable<String> visible = lines;
    final q = _filter.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      visible = visible.where((l) => l.toLowerCase().contains(q));
    }
    if (lvl != 'all') {
      visible = visible.where(_lineMatchesFilter);
    }
    final visibleList = visible.toList();

    const chipKeys = ['all', 'INFO', 'WARN', 'ERROR'];

    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: AppBar(title: const Text('Logs')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (monitoringDisabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.palette.yellow.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.palette.yellow.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'El monitoreo en vivo está desactivado en el servidor (igual que en la web). '
                  'Actívalo en Ajustes → «Monitoreo en vivo (logs y estadísticas)».',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _filter,
              enabled: !monitoringDisabled || snap != null,
              decoration: InputDecoration(
                hintText: 'Buscar en logs…',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: context.palette.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chipKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final k = chipKeys[i];
                final sel = lvl == k;
                return ChoiceChip(
                  selected: sel,
                  label: Text(k == 'all' ? 'Todos' : k),
                  selectedColor: context.palette.accent.withValues(alpha: 0.15),
                  onSelected: (_) => setState(() => lvl = k),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          if (err != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(err!, style: TextStyle(color: context.palette.yellow)),
            ),
          Expanded(
            child: RefreshIndicator(
              color: context.palette.accent,
              onRefresh: _load,
              child: loading
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : !monitoringDisabled && snap != null && visibleList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 48),
                            Center(
                              child: Text(
                                'No hay líneas que mostrar con los filtros actuales.',
                                style: TextStyle(color: context.palette.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: visibleList.length,
                          itemBuilder: (context, i) => _line(visibleList[i]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String raw) {
    final bucket = _logLevelBucket(raw);
    final (tag, label) = switch (bucket) {
      'ERROR' => (context.palette.red, 'ERR'),
      'WARN' => (context.palette.yellow, 'WRN'),
      'INFO' => (context.palette.green, 'INF'),
      _ => (context.palette.textMuted, '···'),
    };

    final time = raw.length > 10 ? raw.substring(0, 10) : raw;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: context.palette.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: tag.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: tag,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              raw,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.35,
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
