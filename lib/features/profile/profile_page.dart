import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/models/profile_models.dart';
import '../../api/wgu_repository.dart';
import '../../core/config/server_settings.dart';
import '../../core/session/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../../notifications/wgu_notifications.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _addPasskeyName = TextEditingController();

  String? _originalUsername;
  bool _admin = false;
  bool _obscurePassword = true;
  bool _loading = true;
  bool _saving = false;
  String? _loadErr;
  List<PasskeyItemVm> _passkeys = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _addPasskeyName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final un = auth.username;
    final r = WguRepository.fromContext(auth, cfg);
    setState(() {
      _loading = true;
      _loadErr = null;
    });
    try {
      var effectiveUser = un;
      final snap = await r.fetchProfilePasskeysSnapshot();
      if (snap.username.isNotEmpty &&
          (effectiveUser == null || effectiveUser.isEmpty)) {
        effectiveUser = snap.username;
        auth.syncSessionUsername(snap.username);
      }
      if (effectiveUser == null || effectiveUser.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _loadErr =
              'No se pudo obtener el usuario de la sesión. Vuelve a iniciar sesión.';
        });
        return;
      }
      final user = await r.fetchUser(effectiveUser);
      if (!mounted) return;
      setState(() {
        _originalUsername = user.username;
        _admin = user.admin;
        _displayName.text = user.displayName;
        _username.text = user.username;
        _email.text = user.email;
        _password.clear();
        _passkeys = snap.passkeys;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadErr = e.response?.data is Map
            ? '${(e.response!.data as Map)['message'] ?? e.message}'
            : (e.message ?? '$e');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadErr = '$e';
      });
    }
  }

  String _passwordStrengthHint() {
    final p = _password.text;
    if (p.isEmpty) return 'Fortaleza: sin contraseña nueva';
    if (p.length < 8) return 'Fortaleza: corta';
    var score = 0;
    if (RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[^a-zA-Z\d]').hasMatch(p)) score++;
    if (score >= 3 && p.length >= 12) return 'Fortaleza: buena';
    if (score >= 2) return 'Fortaleza: media';
    return 'Fortaleza: mejorable';
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final prev = _originalUsername;
    if (prev == null) return;
    final r = WguRepository.fromContext(auth, cfg);
    setState(() => _saving = true);
    try {
      final res = await r.updateUser(
        previousUsername: prev,
        username: _username.text.trim(),
        displayName: _displayName.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        admin: _admin,
      );
      if (!mounted) return;
      if (!res.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'No se pudo guardar')),
        );
        setState(() => _saving = false);
        return;
      }
      if (res.reauthenticate) {
        _password.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'Vuelve a iniciar sesión.'),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        await context.read<WguNotificationController>().prepareLogout(auth, cfg);
        await auth.logout(cfg);
        setState(() => _saving = false);
        return;
      }
      auth.syncSessionUsername(_username.text.trim());
      setState(() {
        _originalUsername = _username.text.trim();
        _password.clear();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados.')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final msg = e.response?.data is Map
          ? '${(e.response!.data as Map)['message'] ?? e.message}'
          : (e.message ?? '$e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _removePasskey(PasskeyItemVm pk) async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final un = auth.username;
    if (un == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar passkey'),
        content: Text(
          '¿Eliminar "${pk.name}"? '
          'Las sesiones de esta cuenta se invalidan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = WguRepository.fromContext(auth, cfg);
    final res = await r.passkeyRemove(
      username: un,
      credentialId: pk.credentialId,
    );
    if (!mounted) return;
    if (!res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Error')),
      );
      return;
    }
    if (res.reauthenticate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Vuelve a iniciar sesión.'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await context.read<WguNotificationController>().prepareLogout(auth, cfg);
      await auth.logout(cfg);
      return;
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passkey eliminada.')),
    );
  }

  Future<void> _renamePasskey(PasskeyItemVm pk) async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final un = auth.username;
    if (un == null) return;
    final ctrl = TextEditingController(text: pk.name);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar passkey'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'ej. iPhone, YubiKey',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (name.isEmpty) return;
    final r = WguRepository.fromContext(auth, cfg);
    final res = await r.passkeyRename(
      username: un,
      credentialId: pk.credentialId,
      name: name,
    );
    if (!mounted) return;
    if (!res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Error')),
      );
      return;
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nombre actualizado.')),
    );
  }

  void _snackAddPasskeyWeb() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Registrar passkeys usa WebAuthn en el navegador. '
          'Abre el panel web (Mi cuenta) para añadir una llave nueva.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Text(
          t.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      );

  Widget _card({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(children: _divide(children)),
        ),
      ),
    );
  }

  List<Widget> _divide(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        out.add(Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.05)));
      }
      out.add(items[i]);
    }
    return out;
  }

  InputDecoration _field(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.textMuted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<AuthStore>().offlineMode;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mi cuenta'),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: offline,
          child: _loading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : _loadErr != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _loadErr!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.red),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                    children: [
                      _sectionTitle('Datos de tu cuenta'),
                      _card(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Solo modifica tu propio usuario. Si cambias contraseña, '
                              'se cerrará la sesión.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _displayName,
                              textCapitalization: TextCapitalization.words,
                              decoration: _field('NOMBRE PARA MOSTRAR'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _username,
                              decoration: _field('NOMBRE DE USUARIO'),
                              autocorrect: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _field('CORREO ELECTRÓNICO'),
                              autocorrect: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              decoration: _field(
                                'NUEVA CONTRASEÑA',
                                hint: 'Vacío para mantener la actual',
                              ).copyWith(
                                suffixIcon: TextButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  child: Text(
                                    _obscurePassword ? 'Mostrar' : 'Ocultar',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _passwordStrengthHint(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _saving ? null : _saveProfile,
                                child: _saving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text('Guardar cambios'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _sectionTitle('Passkeys'),
                      _card(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Puedes registrar varias llaves y administrar sus nombres '
                              '(desde el navegador). Aquí puedes renombrar o quitar las ya registradas.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                          if (_passkeys.isEmpty)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                'No hay passkeys en esta cuenta.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          else
                            for (final pk in _passkeys)
                              ListTile(
                                title: Text(pk.name),
                                subtitle: Text(
                                  pk.fingerprint,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _renamePasskey(pk),
                                      tooltip: 'Renombrar',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: AppColors.red
                                            .withValues(alpha: 0.9),
                                      ),
                                      onPressed: () => _removePasskey(pk),
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                ),
                              ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _addPasskeyName,
                              decoration: _field(
                                'NOMBRE (EJ: IPHONE, YUBIKEY)',
                              ).copyWith(
                                hintText:
                                    'Nombre (ej: iPhone, MacBook, YubiKey)',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _snackAddPasskeyWeb,
                                child: const Text('Agregar passkey'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
        ),
      ),
    );
  }
}
