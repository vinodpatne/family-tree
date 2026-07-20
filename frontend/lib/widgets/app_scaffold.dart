import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../state/providers.dart';
import '../theme/design_tokens.dart';
import 'user_avatar.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.familyId,
    required this.child,
    this.actions = const [],
    this.floatingActionButton,
    this.showBackButton,
  });

  final String title;
  final String? familyId;
  final Widget child;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final bool? showBackButton;

  void _showUserInfoDialog(BuildContext context, WidgetRef ref, AppUser currentUser) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(user: currentUser, radius: 36),
            const SizedBox(height: 16),
            Text(
              currentUser.name.isNotEmpty ? currentUser.name : 'User',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              currentUser.email,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: const Text('Switch Family'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(dialogContext);
                context.go('/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create New Family'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(dialogContext);
                context.go('/family/new');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(dialogContext);
                await ref.read(repositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final families = ref.watch(familiesProvider).valueOrNull ?? [];
    
    int selectedIndex = 0;
    try {
      final path = GoRouterState.of(context).uri.path;
      if (path.contains('/schema')) {
        selectedIndex = 1;
      } else if (path.contains('/settings/appearance')) {
        selectedIndex = 2;
      } else if (path.contains('/settings/collaborators')) {
        selectedIndex = 3;
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
              icon: Tooltip(message: 'Fields', child: Icon(Icons.tune)),
              label: Text('Fields'),
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
        '/family/$familyId/schema',
        '/family/$familyId/settings/appearance',
        '/family/$familyId/settings/collaborators'
      ][i]);
    }

    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final body = wide && items.length >= 2
        ? Row(children: [
            Container(
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
                      message: 'Toggle theme (${themeMode.name})',
                      child: Switch(
                        value: isDark,
                        onChanged: (val) {
                          ref.read(themeModeProvider.notifier).setThemeMode(
                                val ? ThemeMode.dark : ThemeMode.light,
                              );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ])
        : child;

    final canPop = showBackButton ?? (GoRouterState.of(context).uri.path != '/' && GoRouterState.of(context).uri.path != '/family/$familyId/tree');

    final leadingWidget = Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (familyId != null) {
                  context.go('/family/$familyId/tree');
                } else {
                  context.go('/');
                }
              },
            ),
          Padding(
            padding: EdgeInsets.only(left: canPop ? 0.0 : 12.0, right: 8.0),
            child: UserAvatar(
              user: currentUser,
              radius: 18,
              onTap: currentUser == null
                  ? null
                  : () => _showUserInfoDialog(context, ref, currentUser),
            ),
          ),
        ],
      ),
    );

    // Title / Family Switcher
    Widget titleWidget;
    if (familyId != null && families.isNotEmpty) {
      final currentFamExists = families.any((f) => f.id == familyId);
      titleWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentFamExists ? familyId : null,
            hint: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
            isDense: true,
            borderRadius: BorderRadius.circular(16),
            items: [
              for (final f in families)
                DropdownMenuItem<String>(
                  value: f.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        f.id == familyId ? Icons.check_circle : Icons.family_restroom,
                        size: 18,
                        color: f.id == familyId ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        f.name,
                        style: TextStyle(
                          fontWeight: f.id == familyId ? FontWeight.bold : FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              const DropdownMenuItem<String>(
                value: '__all__',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list_alt, size: 18),
                    SizedBox(width: 8),
                    Text('All Families'),
                  ],
                ),
              ),
              const DropdownMenuItem<String>(
                value: '__new__',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Create New Family'),
                  ],
                ),
              ),
            ],
            onChanged: (val) {
              if (val == null || val == familyId) return;
              if (val == '__all__') {
                context.go('/');
              } else if (val == '__new__') {
                context.go('/family/new');
              } else {
                context.go('/family/$val/tree');
              }
            },
          ),
        ),
      );
    } else {
      titleWidget = Text(title);
    }

    return Scaffold(
      appBar: AppBar(
        leading: leadingWidget,
        leadingWidth: canPop ? 96.0 : 56.0,
        title: titleWidget,
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: !wide && items.length >= 2
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: go,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.account_tree), label: 'Tree'),
                NavigationDestination(icon: Icon(Icons.tune), label: 'Fields'),
                NavigationDestination(icon: Icon(Icons.palette), label: 'Look'),
                NavigationDestination(icon: Icon(Icons.group), label: 'People'),
              ],
            )
          : null,
      floatingActionButton: floatingActionButton,
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
