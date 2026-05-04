import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';

/// Compact widget that shows the current auth state.
///
/// When signed in: avatar initial + display name / email.
/// When signed out: "Anmelden"-link.
///
/// [compact] = true → single avatar icon only (for tight spaces like the
/// mobile app bar). [compact] = false → avatar + name text (for the sidebar).
class UserStatusBadge extends ConsumerWidget {
  final bool compact;
  const UserStatusBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      loading: () => const SizedBox(width: 32, height: 32,
          child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) => user != null
          ? _SignedInBadge(user: user, compact: compact)
          : _SignedOutButton(compact: compact),
    );
  }
}

// ── Signed-in badge ───────────────────────────────────────────────────────────

class _SignedInBadge extends StatelessWidget {
  final User user;
  final bool compact;
  const _SignedInBadge({required this.user, required this.compact});

  String get _displayName {
    if (user.displayName?.isNotEmpty == true) return user.displayName!;
    if (user.email?.isNotEmpty == true) {
      // Show only the part before @
      return user.email!.split('@').first;
    }
    return 'Nutzer';
  }

  String get _initial => _displayName[0].toUpperCase();

  String get _providerLabel {
    final ids = user.providerData.map((p) => p.providerId).toList();
    if (ids.contains('google.com')) return 'Google';
    if (ids.contains('apple.com'))  return 'Apple';
    return 'E-Mail';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final avatar = Semantics(
      label: 'Angemeldet als $_displayName',
      child: CircleAvatar(
        radius: 15,
        backgroundImage:
        user.photoURL != null ? NetworkImage(user.photoURL!) : null,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: user.photoURL == null
            ? Text(
          _initial,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        )
            : null,
      ),
    );

    if (compact) {
      return Tooltip(
        message: '$_displayName · $_providerLabel',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/settings'),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: avatar,
          ),
        ),
      );
    }

    // Full version: avatar + name + provider
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.push('/settings'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'via $_providerLabel',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Signed-out button ─────────────────────────────────────────────────────────

class _SignedOutButton extends StatelessWidget {
  final bool compact;
  const _SignedOutButton({required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return Tooltip(
        message: 'Anmelden',
        child: IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          iconSize: 22,
          onPressed: () => context.push('/auth'),
          tooltip: 'Anmelden',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/auth'),
        icon: const Icon(Icons.person_outline_rounded, size: 16),
        label: const Text('Anmelden'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 13),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
    );
  }
}