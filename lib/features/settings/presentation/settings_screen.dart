import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/sync_service.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final syncEnabled = ref.watch(syncEnabledProvider);
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (user) => ListView(
          children: [
            // ── Account ───────────────────────────────────────────────────────
            _SectionHeader(label: 'Konto'),
            if (user != null)
              _AccountTile(user: user, ref: ref)
            else
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Anmelden / Konto erstellen'),
                subtitle: const Text(
                    'Mit Google, Apple oder E-Mail'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/auth'),
              ),

            const Divider(),

            // ── Sync ──────────────────────────────────────────────────────────
            _SectionHeader(label: 'Synchronisation'),
            SwitchListTile(
              secondary: const Icon(Icons.sync_rounded),
              title: const Text('Firebase-Synchronisation'),
              subtitle: Text(user != null
                  ? 'Daten werden in der Cloud gespeichert'
                  : 'Anmeldung erforderlich'),
              value: syncEnabled && user != null,
              onChanged: user != null
                  ? (v) =>
              ref.read(syncEnabledProvider.notifier).state = v
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Jetzt synchronisieren'),
              enabled: syncEnabled && user != null,
              onTap: syncEnabled && user != null
                  ? () => _triggerSync(context, ref)
                  : null,
            ),

            const Divider(),

            // ── Appearance ────────────────────────────────────────────────────
            _SectionHeader(label: 'Darstellung'),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('Farbschema'),
              trailing: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined, size: 16),
                      tooltip: 'Hell'),
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined, size: 16),
                      tooltip: 'System'),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined, size: 16),
                      tooltip: 'Dunkel'),
                ],
                selected: {themeMode},
                onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).state = s.first,
                style: const ButtonStyle(
                    visualDensity: VisualDensity.compact),
              ),
            ),

            const Divider(),

            // ── Notifications ─────────────────────────────────────────────────
            _SectionHeader(label: 'Benachrichtigungen'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Deadline-Erinnerungen'),
              subtitle: const Text('Wird 3 Tage vor Ablauf erinnert'),
              value: notificationsEnabled,
              onChanged: (v) =>
              ref.read(notificationsEnabledProvider.notifier).state = v,
            ),

            const Divider(),

            // ── Achievements ──────────────────────────────────────────────────
            _SectionHeader(label: 'Achievements'),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Meine Achievements'),
              subtitle: const Text('Fortschritt und freigeschaltete Abzeichen'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/achievements'),
            ),

            const Divider(),

            // ── About ─────────────────────────────────────────────────────────
            _SectionHeader(label: 'Über die App'),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('WordProgressor'),
              subtitle: Text('Version 1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Open-Source-Lizenzen'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'WordProgressor',
                applicationVersion: '1.0.0',
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerSync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Synchronisation gestartet…'),
        duration: Duration(seconds: 2),
      ),
    );
    final result = await ref.read(syncServiceProvider).sync();
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(result.message),
        duration: const Duration(seconds: 3),
      ));
    }
  }
}

// ── Account tile ──────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final User user;
  final WidgetRef ref;
  const _AccountTile({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine which sign-in provider the user used
    final providers = user.providerData.map((p) => p.providerId).toList();
    final providerLabel = providers.contains('google.com')
        ? 'Google'
        : providers.contains('apple.com')
        ? 'Apple'
        : 'E-Mail';
    final providerIcon = providers.contains('google.com')
        ? Icons.g_mobiledata_rounded
        : providers.contains('apple.com')
        ? Icons.apple_rounded
        : Icons.email_outlined;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoURL != null
            ? NetworkImage(user.photoURL!)
            : null,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: user.photoURL == null
            ? Text(
          (user.displayName?.isNotEmpty == true
              ? user.displayName![0]
              : user.email?[0] ?? '?')
              .toUpperCase(),
          style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600),
        )
            : null,
      ),
      title: Text(user.displayName ?? user.email ?? 'Angemeldet',
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Row(
        children: [
          Icon(providerIcon, size: 13,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('Über $providerLabel',
              style: const TextStyle(fontSize: 12)),
        ],
      ),
      trailing: TextButton(
        onPressed: () => _confirmSignOut(context),
        child: const Text('Abmelden'),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abmelden?'),
        content: const Text(
            'Lokale Daten bleiben erhalten. Die Cloud-Synchronisation '
                'wird deaktiviert bis zur nächsten Anmeldung.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Abmelden')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      ref.read(syncEnabledProvider.notifier).state = false;
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}