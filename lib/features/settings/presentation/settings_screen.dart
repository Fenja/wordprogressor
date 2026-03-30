import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final syncEnabled = ref.watch(syncEnabledProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          // Account section
          _SectionHeader(label: 'Konto'),
          if (isLoggedIn)
            _AccountTile(ref: ref)
          else
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Anmelden / Konto erstellen'),
              subtitle: const Text('Für Cloud-Synchronisation'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showAuthDialog(context, ref),
            ),

          const Divider(),

          // Sync
          _SectionHeader(label: 'Synchronisation'),
          SwitchListTile(
            secondary: const Icon(Icons.sync_rounded),
            title: const Text('Firebase-Synchronisation'),
            subtitle: Text(
              isLoggedIn
                  ? 'Daten werden in der Cloud gespeichert'
                  : 'Anmeldung erforderlich',
            ),
            value: syncEnabled && isLoggedIn,
            onChanged: isLoggedIn
                ? (v) => ref
                .read(syncEnabledProvider.notifier)
                .state = v
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Jetzt synchronisieren'),
            enabled: syncEnabled && isLoggedIn,
            onTap: syncEnabled && isLoggedIn
                ? () => _triggerSync(context, ref)
                : null,
          ),

          const Divider(),

          // Appearance
          _SectionHeader(label: 'Darstellung'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Farbschema'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined, size: 16),
                  tooltip: 'Hell',
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined, size: 16),
                  tooltip: 'System',
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 16),
                  tooltip: 'Dunkel',
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) => ref
                  .read(themeModeProvider.notifier)
                  .state = s.first,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),

          const Divider(),

          // Notifications
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

          // Accessibility
          _SectionHeader(label: 'Barrierefreiheit'),
          ListTile(
            leading: const Icon(Icons.accessibility_new_rounded),
            title: const Text('Systemeinstellungen verwenden'),
            subtitle: const Text(
                'Schriftgröße und Kontrast folgen den Systemeinstellungen'),
          ),

          const Divider(),

          // About
          _SectionHeader(label: 'Über die App'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('WordProgressor'),
            subtitle: const Text('Version 1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Datenschutzerklärung'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () {},
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
    );
  }

  void _showAuthDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konto erstellen oder anmelden'),
        content: const Text(
          'Mit einem Konto kannst du deine Projekte auf mehreren Geräten synchronisieren. Die App funktioniert auch vollständig ohne Konto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Launch Firebase Auth UI
            },
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
  }

  void _triggerSync(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Synchronisation gestartet…'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: call SyncService
  }
}

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

class _AccountTile extends StatelessWidget {
  final WidgetRef ref;
  const _AccountTile({required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.person_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: const Text('Angemeldet'),
      subtitle: const Text('nutzer@beispiel.de'),
      trailing: TextButton(
        onPressed: () {
          ref.read(isLoggedInProvider.notifier).state = false;
        },
        child: const Text('Abmelden'),
      ),
    );
  }
}