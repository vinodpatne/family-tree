import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/providers.dart';
import '../theme/design_tokens.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.familyId,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String? familyId;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    
    int selectedIndex = 0;
    try {
      final path = GoRouterState.of(context).uri.path;
      if (path.contains('/settings/appearance')) {
        selectedIndex = 1;
      } else if (path.contains('/settings/collaborators')) {
        selectedIndex = 2;
      }
    } catch (_) {}

    final items = familyId == null
        ? <NavigationRailDestination>[]
        : const [
            NavigationRailDestination(
              icon: Tooltip(message: 'Tree', child: Icon(Icons.account_tree)),
              label: Text('Tree'),
            ),
            NavigationRailDestination(
              icon: Tooltip(message: 'Appearance', child: Icon(Icons.palette)),
              label: Text('Appearance'),
            ),
            NavigationRailDestination(
              icon: Tooltip(message: 'Collaborators', child: Icon(Icons.group)),
              label: Text('Collaborators'),
            ),
          ];

    void go(int i) {
      if (familyId == null) return;
      context.go([
        '/family/$familyId/tree',
        '/family/$familyId/settings/appearance',
        '/family/$familyId/settings/collaborators'
      ][i]);
    }

    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    
    final leftNav = Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: go,
              destinations: items,
              backgroundColor: Colors.transparent,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Tooltip(
              message: 'Toggle Dark/Light Mode',
              child: Switch(
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).state =
                      val ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),
          ),
        ],
      ),
    );

    final body = wide && items.isNotEmpty
        ? Row(children: [
            leftNav,
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ])
        : child;

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
      bottomNavigationBar: !wide && items.isNotEmpty
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: go,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.account_tree), label: 'Tree'),
                NavigationDestination(icon: Icon(Icons.palette), label: 'Look'),
                NavigationDestination(icon: Icon(Icons.group), label: 'People'),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingUnit * 2),
          child: child,
        ),
      );
}
