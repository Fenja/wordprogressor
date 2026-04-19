import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';

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
    _tabs.addListener(() => setState(() => _errorMsg = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Auth actions ────────────────────────────────────────────────────────────

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final auth = ref.read(authServiceProvider);
      if (_tabs.index == 0) {
        await auth.signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
      } else {
        await auth.registerWithEmail(_emailCtrl.text, _passwordCtrl.text);
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMsg = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMsg = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ref.read(authServiceProvider).signInWithApple();
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMsg = _friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Bitte zuerst E-Mail-Adresse eingeben.');
      return;
    }
    await ref.read(authServiceProvider).sendPasswordReset(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwort-Reset-E-Mail wurde gesendet.')),
      );
    }
  }

  // ── Error messages ──────────────────────────────────────────────────────────

  String _friendly(Object e) {
    if (e is AuthException) return e.message;
    final msg = e.toString();
    if (msg.contains('user-not-found') || msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'E-Mail oder Passwort ist falsch.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'Diese E-Mail-Adresse wird bereits verwendet.';
    }
    if (msg.contains('weak-password')) {
      return 'Das Passwort muss mindestens 6 Zeichen lang sein.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Keine Internetverbindung.';
    }
    if (msg.contains('cancelled') || msg.contains('canceled')) {
      return 'Anmeldung abgebrochen.';
    }
    if (msg.contains('sign_in_with_apple') || msg.contains('AuthorizationError')) {
      return 'Apple Sign-In ist auf diesem Gerät nicht verfügbar.';
    }
    return 'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appleAvailableAsync = ref.watch(appleSignInAvailableProvider);

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
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 28,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Social Sign-In ────────────────────────────────────────────────
            _GoogleButton(
              loading: _loading,
              onTap: _signInWithGoogle,
            ),
            const SizedBox(height: 10),

            // Apple: only shown when available
            appleAvailableAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (available) => available
                  ? _AppleButton(
                loading: _loading,
                onTap: _signInWithApple,
              )
                  : const SizedBox.shrink(),
            ),

            // ── Divider ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'oder mit E-Mail',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),

            // ── Email form ────────────────────────────────────────────────────
            Form(
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
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v?.contains('@') == true)
                        ? null
                        : 'Bitte eine gültige E-Mail-Adresse eingeben.',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        tooltip: _obscure
                            ? 'Passwort anzeigen'
                            : 'Passwort verbergen',
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitEmail(),
                    validator: (v) => (v != null && v.length >= 6)
                        ? null
                        : 'Mindestens 6 Zeichen.',
                  ),

                  // Error message
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMsg!,
                      style: TextStyle(
                          color: theme.colorScheme.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Submit
                  FilledButton(
                    onPressed: _loading ? null : _submitEmail,
                    child: _loading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : Text(_tabs.index == 0
                        ? 'Anmelden'
                        : 'Konto erstellen'),
                  ),

                  // Forgot password (only on login tab)
                  if (_tabs.index == 0)
                    TextButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: const Text('Passwort vergessen?'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Offline note
            Text(
              'WordProgressor funktioniert vollständig ohne Konto. '
                  'Ein Konto ist nur für die Synchronisation zwischen '
                  'mehreren Geräten erforderlich.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google Sign-In Button ─────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Mit Google anmelden',
      button: true,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor:
          isDark ? const Color(0xFF131314) : Colors.white,
          foregroundColor:
          isDark ? Colors.white : const Color(0xFF1F1F1F),
          side: BorderSide(
            color: isDark
                ? const Color(0xFF8E918F)
                : const Color(0xFF747775),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 'G' logo (SVG-like via custom paint or inline SVG)
            _GoogleLogo(size: 20),
            const SizedBox(width: 10),
            const Text(
              'Mit Google anmelden',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal Google 'G' logo drawn with Canvas.
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 2;
    final r = size.width / 2;

    // Clipping circle
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(c, c), radius: r)));

    // White background
    canvas.drawCircle(
        Offset(c, c), r, Paint()..color = Colors.white);

    // Four coloured arcs (simplified quadrant approach)
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.22;

    // Blue (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: Offset(c, c), radius: r * 0.62),
        -0.52, 1.04, false, paint);

    // Green (bottom-right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: Offset(c, c), radius: r * 0.62),
        0.52, 1.04, false, paint);

    // Yellow (bottom-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: Offset(c, c), radius: r * 0.62),
        1.57, 1.04, false, paint);

    // Red (top-left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: Offset(c, c), radius: r * 0.62),
        -1.57 - 0.52, 1.55, false, paint);

    // Horizontal bar (the crossbar of the G)
    paint
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(c, c - size.height * 0.11,
          r * 0.9, size.height * 0.22),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Apple Sign-In Button ──────────────────────────────────────────────────────

class _AppleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _AppleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Mit Apple anmelden',
      button: true,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apple_rounded,
              size: 22,
              color: isDark ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Mit Apple anmelden',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}