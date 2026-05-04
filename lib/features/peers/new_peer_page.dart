import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/models/client_models.dart';
import '../../api/wgu_repository.dart';
import '../../core/config/server_settings.dart';
import '../../core/session/auth_store.dart';
import '../../core/wg_apply_controller.dart';
import '../../core/theme/app_theme.dart';
import 'peer_detail_page.dart';

class NewPeerPage extends StatefulWidget {
  const NewPeerPage({super.key});

  @override
  State<NewPeerPage> createState() => _NewPeerPageState();
}

class _NewPeerPageState extends State<NewPeerPage> {
  final _name = TextEditingController();
  final _ip = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _suggestIp() async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final r = WguRepository.fromContext(auth, cfg);
    try {
      final ips = await r.suggestIps();
      if (ips.isEmpty || !mounted) return;
      setState(() => _ip.text = ips.first);
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = '$e');
    }
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _err = 'Nombre requerido');
      return;
    }

    setState(() {
      _busy = true;
      _err = null;
    });
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final r = WguRepository.fromContext(auth, cfg);

    try {
      List<String> ips;
      if (_ip.text.trim().isNotEmpty) {
        ips = [_ip.text.trim()];
      } else {
        final s = await r.suggestIps();
        if (s.isEmpty) {
          setState(() {
            _err = 'No se pudo obtener IP sugerida';
            _busy = false;
          });
          return;
        }
        ips = [s.first];
      }

      final created = await r.createClient(
        WgClient.draftNew(name: name, allocatedIps: ips),
      );
      if (mounted && created != null) {
        await context.read<WgApplyController>().refreshFromServer(auth, cfg);
      }
      if (mounted && created != null) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PeerDetailPage(clientId: created.id),
          ),
        );
      }
    } catch (e) {
      setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Nuevo peer', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre del cliente'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ip,
            decoration: const InputDecoration(
              labelText: 'IP asignada (opcional)',
              hintText: '10.0.0.x · vacío = primera sugerida',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _suggestIp,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Sugerir IP (/api/suggest-client-ips)'),
            ),
          ),
          if (_err != null) Text(_err!, style: const TextStyle(color: AppColors.red)),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _busy ? null : _create,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Crear en wireguard-ui'),
          ),
          const SizedBox(height: 12),
          const Text(
            'After creating, tap Apply (banner or web) if the server does not auto-apply wg.conf.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
