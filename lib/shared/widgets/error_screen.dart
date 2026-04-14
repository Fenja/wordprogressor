import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown by go_router's [errorBuilder] when:
///   - A route path does not match any defined route (404).
///   - A route builder throws an unhandled exception.
///
/// Provides a clear error message and a link back to the home route ('/').
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final is404 = error is GoException ||
        (error?.toString().contains('no routes') ?? false) ||
        (error?.toString().contains('404') ?? false);

    final title = is404 ? 'Seite nicht gefunden' : 'Etwas ist schiefgelaufen';
    final subtitle = is404
        ? 'Die angeforderte Seite existiert nicht.'
        : 'Ein unerwarteter Fehler ist aufgetreten.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('WordProgressor'),
        // No back button — this screen replaces the entire navigation stack.
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Text(
                is404 ? '🗺️' : '⚠️',
                style: const TextStyle(fontSize: 56),
                semanticsLabel: is404 ? 'Karte' : 'Warnung',
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              // Error detail (debug / non-404 only)
              if (!is404 && error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    error.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Home link
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Zur Startseite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}