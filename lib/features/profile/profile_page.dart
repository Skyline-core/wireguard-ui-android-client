import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/exceptions.dart' as pkex;
import 'package:provider/provider.dart';

import '../../api/models/profile_models.dart';
import '../../api/wgu_repository.dart';
import '../../core/auth/passkey_options.dart';
import '../../core/config/server_settings.dart';
import '../../core/session/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../../notifications/wgu_notifications.dart';
import '../../l10n/app_localizations.dart';

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
  bool _registeringPasskey = false;
  String? _loadErr;
  List<PasskeyItemVm> _passkeys = [];
  /// Mirrors server global setting (Passkeys disabled → no registration API).
  bool _passkeysEnabled = true;

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
              AppLocalizations.of(context)!.profileSessionLoadError;
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
        _passkeysEnabled = snap.passkeysEnabled;
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

  String _passwordStrengthHint(AppLocalizations loc) {
    final p = _password.text;
    if (p.isEmpty) return loc.profilePasswordStrengthNone;
    if (p.length < 8) return loc.profilePasswordStrengthShort;
    var score = 0;
    if (RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[^a-zA-Z\d]').hasMatch(p)) score++;
    if (score >= 3 && p.length >= 12) return loc.profilePasswordStrengthGood;
    if (score >= 2) return loc.profilePasswordStrengthMedium;
    return loc.profilePasswordStrengthImprove;
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
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? loc.profileSaveFailed)),
        );
        setState(() => _saving = false);
        return;
      }
      if (res.reauthenticate) {
        _password.clear();
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? loc.profileRelogin),
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
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.profileSavedOk)),
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
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.profileRemovePasskeyTitle),
        content: Text(
          loc.profileRemovePasskeyBody(pk.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.palette.red),
            child: Text(loc.commonDelete),
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
        SnackBar(content: Text(res.message ?? loc.commonGenericError)),
      );
      return;
    }
    if (res.reauthenticate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? loc.profileRelogin),
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
      SnackBar(content: Text(loc.profilePasskeyRemoved)),
    );
  }

  Future<void> _renamePasskey(PasskeyItemVm pk) async {
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final un = auth.username;
    if (un == null) return;
    final ctrl = TextEditingController(text: pk.name);
    final loc = AppLocalizations.of(context)!;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.profileRenamePasskeyTitle),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: loc.profileRenamePasskeyFieldLabel,
            hintText: loc.profileRenamePasskeyFieldHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.commonSave),
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
        SnackBar(content: Text(res.message ?? loc.commonGenericError)),
      );
      return;
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.profileNameUpdated)),
    );
  }

  Future<void> _addPasskeyNative() async {
    if (!_passkeysEnabled || _registeringPasskey) return;
    final loc = AppLocalizations.of(context)!;
    final name = _addPasskeyName.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.profileEnterPasskeyName)),
      );
      return;
    }
    final auth = context.read<AuthStore>();
    final cfg = context.read<ServerSettings>();
    final un = auth.username;
    if (un == null) return;

    setState(() => _registeringPasskey = true);
    try {
      final r = WguRepository.fromContext(auth, cfg);
      final beginMap = await r.passkeyRegisterBegin(username: un, cfg: cfg);
      final req = parsePasskeyRegisterBeginOptions(beginMap);
      final reg = await PasskeyAuthenticator().register(req);
      final body = Map<String, dynamic>.from(reg.toJson());
      body['credential_name'] = name;
      final res = await r.passkeyRegisterFinish(
        username: un,
        cfg: cfg,
        webauthnBody: body,
      );
      if (!mounted) return;
      if (!res.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.message ?? loc.profilePasskeyRegisterFailed)),
        );
        return;
      }
      _addPasskeyName.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.profilePasskeyRegisteredOk)),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on pkex.PasskeyAuthCancelledException {
      if (!mounted) return;
    } on pkex.ExcludeCredentialsCanNotBeRegisteredException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.profilePasskeyDuplicate),
        ),
      );
    } on pkex.DomainNotAssociatedException catch (e) {
      if (!mounted) return;
      final hintLoc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hintLoc.profilePasskeyDomainHint(e.message ?? ''),
          ),
        ),
      );
    } on pkex.DeviceNotSupportedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.profilePasskeyDeviceUnsupported)),
      );
    } on pkex.AuthenticatorException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? '${(e.response!.data as Map)['message'] ?? e.message}'
          : (e.message ?? '$e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _registeringPasskey = false);
    }
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Text(
          t.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 11,
            color: context.palette.textMuted,
          ),
        ),
      );

  Widget _card({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: context.palette.surface,
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
            color: context.palette.borderSubtle));
      }
      out.add(items[i]);
    }
    return out;
  }

  InputDecoration _field(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: context.palette.textMuted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final offline = context.watch<AuthStore>().offlineMode;
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: AppBar(
        title: Text(loc.profileTitle),
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
                            style: TextStyle(color: context.palette.red),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: Text(loc.commonRetry),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                    children: [
                      _sectionTitle(loc.profileSectionAccount),
                      _card(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              loc.profileAccountHint,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: context.palette.textSecondary
                                    .withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _displayName,
                              textCapitalization: TextCapitalization.words,
                              decoration: _field(loc.profileFieldDisplayName),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _username,
                              decoration: _field(loc.profileFieldUsername),
                              autocorrect: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _field(loc.profileFieldEmail),
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
                                loc.profileFieldNewPassword,
                                hint: loc.profileNewPasswordHint,
                              ).copyWith(
                                suffixIcon: TextButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  child: Text(
                                    _obscurePassword
                                        ? loc.profilePasswordShow
                                        : loc.profilePasswordHide,
                                    style: TextStyle(fontSize: 13),
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
                                _passwordStrengthHint(loc),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.palette.textMuted,
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
                                    : Text(loc.profileSaveChanges),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _sectionTitle(loc.profileSectionPasskeys),
                      _card(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              _passkeysEnabled
                                  ? loc.profilePasskeysHintOn
                                  : loc.profilePasskeysHintOff,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: context.palette.textSecondary
                                    .withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                          if (_passkeys.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                loc.profileNoPasskeys,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.palette.textMuted,
                                ),
                              ),
                            )
                          else
                            for (final pk in _passkeys)
                              ListTile(
                                title: Text(pk.name),
                                subtitle: Text(
                                  pk.fingerprint,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined),
                                      onPressed: _passkeysEnabled
                                          ? () => _renamePasskey(pk)
                                          : null,
                                      tooltip: loc.profilePasskeyRenameTooltip,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: context.palette.red
                                            .withValues(alpha: 0.9),
                                      ),
                                      onPressed: _passkeysEnabled
                                          ? () => _removePasskey(pk)
                                          : null,
                                      tooltip: loc.profilePasskeyDeleteTooltip,
                                    ),
                                  ],
                                ),
                              ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _addPasskeyName,
                              enabled: _passkeysEnabled && !_registeringPasskey,
                              decoration: _field(
                                loc.profileAddPasskeyNameLabel,
                              ).copyWith(
                                hintText: loc.profileAddPasskeyNameHint,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: (!_passkeysEnabled ||
                                        _registeringPasskey)
                                    ? null
                                    : _addPasskeyNative,
                                child: _registeringPasskey
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(loc.profileAddPasskey),
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
