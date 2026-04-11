import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../settings/providers/settings_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      if (_tabs.index == 0) {
        await auth.signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await auth.registerWithEmail(
            _emailCtrl.text.trim(), _passwordCtrl.text);
      }

      // Mark as logged in
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(syncEnabledProvider.notifier).state = true;

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMsg = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password')) {
      return 'E-Mail oder Passwort falsch.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'Diese E-Mail-Adresse wird bereits verwendet.';
    }
    if (raw.contains('weak-password')) {
      return 'Das Passwort muss mindestens 6 Zeichen lang sein.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Keine Internetverbindung.';
    }
    return 'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konto'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Anmelden'),
            Tab(text: 'Registrieren'),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'E-Mail-Adresse',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: (v) => (v?.contains('@') == true)
                    ? null
                    : 'Bitte eine gültige E-Mail-Adresse eingeben.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    tooltip: _obscure ? 'Passwort anzeigen' : 'Passwort verbergen',
                  ),
                ),
                obscureText: _obscure,
                validator: (v) => (v != null && v.length >= 6)
                    ? null
                    : 'Mindestens 6 Zeichen.',
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMsg!,
                  style: TextStyle(
                      color: theme.colorScheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        _tabs.index == 0 ? 'Anmelden' : 'Konto erstellen'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'WordProgressor funktioniert vollständig ohne Konto. Ein Konto ist nur für die Synchronisation zwischen mehreren Geräten erforderlich.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
