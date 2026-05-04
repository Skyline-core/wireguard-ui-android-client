import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../api/models/client_models.dart';
import '../../api/wgu_repository.dart';
import '../../core/config/server_settings.dart';
import '../../core/format/formatters.dart';
import '../../core/session/auth_store.dart';
import '../../core/wg_apply_controller.dart';
import '../../core/theme/app_theme.dart';

class PeerDetailPage extends StatefulWidget {
  const PeerDetailPage({super.key, required this.clientId});

  final String clientId;

  @override
  State<PeerDetailPage> createState() => _PeerDetailPageState();
}

class _PeerDetailPageState extends State<PeerDetailPage> {
  bool _loading = true;
  String? _err;
  WgClientEnvelope? _envelope;
  PeerTrafficRow? _traffic;

  Future<void> _load() async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final r = WguRepository.fromContext(auth, cfg);
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final e = await r.fetchClientDetail(widget.clientId);
      final stats = await r.peerStatsMap();
      if (!mounted) return;
      setState(() {
        _envelope = e;
        _traffic = stats[e.client.publicKey];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = '$e';
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Uint8List? _pngBytes(String? dataUri) {
    if (dataUri == null || !dataUri.contains(',')) return null;
    try {
      return base64Decode(dataUri.split(',').last);
    } catch (_) {
      return null;
    }
  }

  Future<void> _delete() async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final r = WguRepository.fromContext(auth, cfg);
    try {
      final ok = await r.removeClient(widget.clientId);
      if (!mounted) return;
      await context.read<WgApplyController>().refreshFromServer(auth, cfg);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo borrar el peer en el servidor.',
            ),
          ),
        );
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _envelope;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          e?.client.name ?? 'Peer',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _err != null
              ? Center(child: Text(_err!))
              : e == null
                  ? const SizedBox.shrink()
                  : _buildBody(e),
    );
  }

  Widget _buildBody(WgClientEnvelope e) {
    final c = e.client;
    final ip = c.allocatedIps.isNotEmpty ? c.allocatedIps.first : '—';
    final png = _pngBytes(e.qrCode);

    final down = _traffic?.downloadBytes ?? 0;
    final up = _traffic?.uploadBytes ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.laptop_mac, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ip,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: c.enabled,
                onChanged: (v) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final auth = context.read<AuthStore>();
                  final cfg = context.read<ServerSettings>();
                  final wgApply = context.read<WgApplyController>();
                  final r = WguRepository.fromContext(auth, cfg);
                  try {
                    final ok = await r.setClientEnabled(c.id, v);
                    await wgApply.refreshFromServer(auth, cfg);
                    if (!mounted) return;
                    if (!ok) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se pudo guardar el estado en el servidor.',
                          ),
                        ),
                      );
                      await _load();
                      return;
                    }
                    await _load();
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                    await _load();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statTile(
                'Descarga',
                '↓ ${formatBytes(down)}',
                AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statTile(
                'Subida',
                '↑ ${formatBytes(up)}',
                AppColors.yellow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              if (png != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      Image.memory(png, width: 200, height: 200, fit: BoxFit.cover),
                )
              else
                SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: c.publicKey,
                    backgroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Escanea desde la app WireGuard en tu dispositivo',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CONFIGURACIÓN',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _rowTile('Allowed IPs', c.allowedIps.join(', ')),
        _rowTile('DNS', c.useServerDns ? '(servidor)' : '—'),
        _rowTile('Endpoint', c.endpoint.isEmpty ? '—' : c.endpoint),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppColors.red),
          title: const Text('Eliminar cliente',
              style: TextStyle(color: AppColors.red)),
          subtitle:
              const Text('Revoca acceso (endpoint /remove-client)'),
          onTap: () async {
            final sure = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('¿Eliminar?'),
                content: const Text('Esta acción no se puede deshacer.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );
            if (sure == true && mounted) await _delete();
          },
        ),
      ],
    );
  }

  Widget _statTile(String lbl, String val, Color c) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lbl.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: SizedBox(
          width: 180,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: AppColors.textSecondary),
            maxLines: 3,
          ),
        ),
      ),
    );
  }
}
