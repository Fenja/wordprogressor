import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/connectivity_provider.dart';
import '../../features/settings/providers/settings_provider.dart';

/// Small chip indicating current sync state.
/// Shows nothing when offline-only mode is active.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final syncEnabled = ref.watch(syncEnabledProvider);

    if (!isLoggedIn || !syncEnabled) return const SizedBox.shrink();

    final onlineAsync = ref.watch(isOnlineProvider);

    return onlineAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (online) {
        final (icon, label, color) = online
            ? (Icons.cloud_done_outlined, 'Synchronisiert',
                Colors.green.shade600)
            : (Icons.cloud_off_outlined, 'Offline', Colors.orange.shade700);

        return Semantics(
          label: label,
          child: Chip(
            avatar: Icon(icon, size: 14, color: color),
            label: Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
        );
      },
    );
  }
}
