import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    (path: '/projects', label: 'Projekte', icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded),
    (path: '/deadlines', label: 'Deadlines', icon: Icons.event_outlined, activeIcon: Icons.event_rounded),
    (path: '/stats', label: 'Statistiken', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded),
    (path: '/settings', label: 'Einstellungen', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded),
  ];

  int _tabIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _tabIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          if (i != currentIndex) {
            context.go(_tabs[i].path);
          }
        },
        destinations: _tabs.map((tab) {
          return NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.activeIcon),
            label: tab.label,
            tooltip: tab.label,
          );
        }).toList(),
      ),
    );
  }
}