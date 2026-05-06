import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../background/server_health_scheduler.dart';
import '../../core/config/server_settings.dart';
import '../../core/session/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _panelUrl = TextEditingController();
  final _passkeyOrigin = TextEditingController();
  bool _remember = true;
  bool _busy = false;
  /// When true, show optional passkey public-origin override (HTTPS).
  bool _showPasskeyOrigin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cfg = context.read<ServerSettings>();
      _panelUrl.text = cfg.configuredPanelUrlDisplay;
      _passkeyOrigin.text = cfg.passkeyPublicOrigin;
      _showPasskeyOrigin = cfg.passkeyPublicOrigin.trim().isNotEmpty;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _panelUrl.dispose();
    _passkeyOrigin.dispose();
    super.dispose();
  }

  Future<void> _persistServerAndSubmit(
    Future<bool> Function(ServerSettings cfg) loginFn,
  ) async {
    if (_panelUrl.text.trim().isEmpty) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.loginSnackUrlRequired)),
        );
      }
      return;
    }
    setState(() => _busy = true);
    final cfg = context.read<ServerSettings>();
    await cfg.save(
      url: _panelUrl.text,
      path: '',
      passkeyPublicOrigin: _showPasskeyOrigin ? _passkeyOrigin.text : '',
    );
    await loginFn(cfg);
    if (!mounted) return;
    final ok = context.read<AuthStore>().ready;
    if (ok) {
      unawaited(ServerHealthScheduler.syncRegistration(true));
    }
    setState(() => _busy = false);
  }

  Future<void> _submitPassword() async {
    await _persistServerAndSubmit(
      (cfg) => context.read<AuthStore>().login(
            cfg,
            user: _user.text.trim(),
            password: _pass.text,
            remember: _remember,
          ),
    );
  }

  Future<void> _submitPasskey() async {
    await _persistServerAndSubmit(
      (cfg) {
        final u = _user.text.trim();
        return context.read<AuthStore>().loginWithPasskey(
              cfg,
              remember: _remember,
              usernameHint: u.isEmpty ? null : u,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final err = context.watch<AuthStore>().lastError;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.palette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Center(
              child: SvgPicture.asset(
                'assets/images/wireguard.svg',
                width: 108,
                height: 108,
                alignment: Alignment.center,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              loc.loginAppTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.loginSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textSecondary),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _panelUrl,
              style: TextStyle(color: context.palette.textPrimary),
              decoration: InputDecoration(
                labelText: loc.loginPanelUrlLabel,
                hintText: loc.loginPanelUrlHint,
                helperText: loc.loginPanelUrlHelper,
              ),
              keyboardType: TextInputType.url,
            ),
            CheckboxListTile(
              value: _showPasskeyOrigin,
              onChanged: _busy
                  ? null
                  : (v) {
                      setState(() {
                        _showPasskeyOrigin = v ?? false;
                        if (!_showPasskeyOrigin) {
                          _passkeyOrigin.clear();
                        }
                      });
                    },
              activeColor: context.palette.accent,
              checkColor: Colors.black,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                loc.loginPasskeyHttpsCheckboxTitle,
                style: TextStyle(fontSize: 14, color: context.palette.textSecondary),
              ),
              subtitle: Text(
                loc.loginPasskeyHttpsCheckboxSubtitle,
                style: TextStyle(fontSize: 11, color: context.palette.textMuted),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: TextField(
                  controller: _passkeyOrigin,
                  style: TextStyle(color: context.palette.textPrimary),
                  decoration: InputDecoration(
                    labelText: loc.loginPasskeyOriginLabel,
                    hintText: loc.loginPasskeyOriginHint,
                    helperText: loc.loginPasskeyOriginHelper,
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
              ),
              crossFadeState: _showPasskeyOrigin
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _user,
              style: TextStyle(color: context.palette.textPrimary),
              decoration: InputDecoration(
                labelText: loc.loginUsernameLabel,
                helperText: loc.loginUsernameHelper,
              ),
              textInputAction: TextInputAction.next,
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: true,
              style: TextStyle(color: context.palette.textPrimary),
              decoration: InputDecoration(labelText: loc.loginPasswordLabel),
              onSubmitted: (_) => _submitPassword(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _remember,
              onChanged: (v) => setState(() => _remember = v),
              activeThumbColor: context.palette.accent,
              title: Text(loc.loginRememberSession),
            ),
            if (err != null) ...[
              const SizedBox(height: 8),
              Text(err, style: TextStyle(color: context.palette.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : () => _submitPassword(),
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.loginSubmit),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _submitPasskey(),
              icon: Icon(Icons.key_outlined),
              label: Text(loc.loginSubmitPasskey),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.textPrimary,
                side: BorderSide(
                  color: context.palette.textMuted.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
