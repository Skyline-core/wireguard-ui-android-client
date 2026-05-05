import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/models/client_models.dart';
import '../../api/models/traffic_series.dart';
import '../../api/wgu_repository.dart';
import '../../core/config/server_settings.dart';
import '../../core/offline/offline_snapshot_store.dart';
import '../../core/wg_apply_controller.dart';
import '../../core/session/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_page.dart';
import 'new_peer_page.dart';
import 'peer_detail_page.dart';

class PeersPage extends StatefulWidget {
  const PeersPage({super.key});

  @override
  PeersPageState createState() => PeersPageState();
}

class PeersPageState extends State<PeersPage>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  String _filter = 'all';
  bool _loading = true;
  String? _err;
  List<WgClientEnvelope> _list = [];
  Map<String, PeerTrafficRow> _stats = {};
  TrafficSeriesResponseVm? _series24h;

  late final AnimationController _fabEnterController;
  late final Animation<double> _fabScaleAnim;
  late final Animation<Offset> _fabSlideAnim;

  /// Reloads client list and peer stats (also when this tab is selected).
  /// When [silent] is true, keeps the list visible while fetching (tab swipe / pull-to-refresh).
  Future<void> refresh({bool silent = false}) async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final r = WguRepository.fromContext(auth, cfg);

    if (auth.offlineMode) {
      if (!silent) {
        setState(() {
          _loading = true;
          _err = null;
        });
      } else {
        setState(() => _err = null);
      }
      final snap = await OfflineSnapshotStore.load();
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (snap == null) {
          _err = 'Sin datos en caché.';
        } else {
          _err = null;
          _list = snap.clients;
          _stats = snap.peerStats;
          _series24h = snap.peersSeries24h;
        }
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _err = null;
      });
    } else {
      setState(() => _err = null);
    }
    try {
      final batch = await Future.wait([
        r.fetchClients(),
        r.peerStatsMap(),
      ]);
      final clients = batch[0] as List<WgClientEnvelope>;
      final stats = batch[1] as Map<String, PeerTrafficRow>;
      if (!mounted) return;
      setState(() {
        _list = clients;
        _stats = stats;
        _loading = false;
      });
      TrafficSeriesResponseVm? seriesVm;
      try {
        final series = await r.trafficSeries(range: '24h');
        seriesVm = series;
        if (!mounted) return;
        setState(() => _series24h = series);
      } catch (_) {
        // Keep the last traffic series snapshot if the request keeps failing (list already loaded).
      }
      await OfflineSnapshotStore.merge(
        username: auth.username,
        clients: clients,
        peerStats: stats,
        peersSeries24h: seriesVm ?? _series24h,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = '$e';
        _loading = false;
      });
    } finally {
      if (mounted) {
        await context.read<WgApplyController>().refreshFromServer(auth, cfg);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _fabEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabEnterController,
      curve: Curves.easeOutBack,
    );
    _fabSlideAnim = Tween<Offset>(
      begin: const Offset(0.4, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fabEnterController,
        curve: Curves.easeOutCubic,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fabEnterController.forward();
    });
  }

  @override
  void dispose() {
    _fabEnterController.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final baseRows = _list.where((e) {
      final c = e.client;
      final ip = c.allocatedIps.join(' ');
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) || ip.toLowerCase().contains(q);
    }).toList();

    bool hasTraffic(WgClientEnvelope e) {
      final row = _stats[e.client.publicKey];
      return ((row?.rx ?? 0) + (row?.tx ?? 0)) > 0;
    }

    final onlineApprox = baseRows.where((e) {
      return e.client.enabled && hasTraffic(e);
    }).length;

    final enabledCount =
        baseRows.where((e) => e.client.enabled).length;
    final disabledCount = baseRows.length - enabledCount;

    var rows = List<WgClientEnvelope>.from(baseRows);
    switch (_filter) {
      case 'on':
        rows = rows
            .where((e) => e.client.enabled && hasTraffic(e))
            .toList();
        break;
      case 'off':
        rows = rows
            .where(
              (e) => !e.client.enabled || !hasTraffic(e),
            )
            .toList();
        break;
      case 'enabled_only':
        rows = rows.where((e) => e.client.enabled).toList();
        break;
      case 'disabled_only':
        rows = rows.where((e) => !e.client.enabled).toList();
        break;
      default:
        break;
    }

    final offline = context.watch<AuthStore>().offlineMode;

    return Scaffold(
      backgroundColor: context.palette.bg,
      floatingActionButton: offline
          ? null
          : SlideTransition(
              position: _fabSlideAnim,
              child: ScaleTransition(
                scale: _fabScaleAnim,
                alignment: Alignment.center,
                child: OpenContainer<bool?>(
                  transitionDuration: const Duration(milliseconds: 420),
                  transitionType: ContainerTransitionType.fade,
                  closedColor: context.palette.accent,
                  openColor: context.palette.bg,
                  closedElevation: 6,
                  openElevation: 0,
                  closedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  openShape: const RoundedRectangleBorder(),
                  onClosed: (_) {
                    if (mounted) refresh(silent: true);
                  },
                  tappable: false,
                  closedBuilder: (context, openContainer) {
                    return SizedBox(
                      width: 56,
                      height: 56,
                      child: FloatingActionButton(
                        heroTag: 'peers-fab-new-peer',
                        onPressed: openContainer,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.add_rounded, size: 28),
                      ),
                    );
                  },
                  openBuilder: (context, _) => const NewPeerPage(),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peers',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: context.palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Clientes registrados',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: context.palette.textSecondary),
                    onPressed: offline ? null : () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                enabled: !offline,
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Buscar peer, IP…',
                  prefixIcon:
                      Icon(Icons.search, color: context.palette.textMuted),
                  filled: true,
                  fillColor: context.palette.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide:
                        BorderSide(color: context.palette.borderSubtle),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip('Todos · ${baseRows.length}', 'all', offline: offline),
                  _chip('Con tráfico · $onlineApprox', 'on', offline: offline),
                  _chip(
                    'Sin tráfico · ${(baseRows.length - onlineApprox).clamp(0, 9999)}',
                    'off',
                    offline: offline,
                  ),
                  _chip('Habilitados · $enabledCount', 'enabled_only',
                      offline: offline),
                  _chip('Deshabilitados · $disabledCount', 'disabled_only',
                      offline: offline),
                ],
              ),
            ),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_err!, style: TextStyle(color: context.palette.red)),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : RefreshIndicator(
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
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final e = rows[i];
                          final c = e.client;
                          final vpnConnected =
                              c.enabled &&
                                  (_stats[c.publicKey]?.connected == true);
                          final (d24, u24) =
                              _series24h?.windowBytesForPeer(c.publicKey) ??
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
                                return PeerPreviewTile(
                                  envelope: e,
                                  onChanged: () => refresh(silent: true),
                                  onTap: offline ? () {} : openContainer,
                                  readOnly: offline,
                                  onlineHint: vpnConnected,
                                  show24hTraffic: _series24h != null,
                                  traffic24hDown: d24,
                                  traffic24hUp: u24,
                                );
                              },
                              openBuilder: (context, _) {
                                return PeerDetailPage(clientId: c.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String key, {required bool offline}) {
    final sel = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected:
            offline ? null : (_) => setState(() => _filter = key),
        selectedColor: context.palette.accent.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: sel ? context.palette.accent : context.palette.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
