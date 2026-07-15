import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_tokens.dart';

class AppScaffold extends StatelessWidget { const AppScaffold({super.key, required this.title, required this.familyId, required this.child, this.actions = const []}); final String title; final String? familyId; final Widget child; final List<Widget> actions;
  @override Widget build(BuildContext context) { final wide = MediaQuery.sizeOf(context).width >= 900; final items = familyId == null ? <NavigationRailDestination>[] : const [NavigationRailDestination(icon: Icon(Icons.account_tree), label: Text('Tree')), NavigationRailDestination(icon: Icon(Icons.palette), label: Text('Appearance')), NavigationRailDestination(icon: Icon(Icons.group), label: Text('Collaborators'))];
    void go(int i) { if (familyId == null) return; context.go(['/family/$familyId/tree','/family/$familyId/settings/appearance','/family/$familyId/settings/collaborators'][i]); }
    final body = wide && items.isNotEmpty ? Row(children: [NavigationRail(selectedIndex: 0, onDestinationSelected: go, destinations: items), const VerticalDivider(width: 1), Expanded(child: child)]) : child;
    return Scaffold(appBar: AppBar(title: Text(title), actions: actions), body: body, bottomNavigationBar: !wide && items.isNotEmpty ? NavigationBar(selectedIndex: 0, onDestinationSelected: go, destinations: const [NavigationDestination(icon: Icon(Icons.account_tree), label: 'Tree'), NavigationDestination(icon: Icon(Icons.palette), label: 'Look'), NavigationDestination(icon: Icon(Icons.group), label: 'People')]) : null, floatingActionButtonLocation: FloatingActionButtonLocation.endFloat);
  }}
class SectionCard extends StatelessWidget { const SectionCard({super.key, required this.child}); final Widget child; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(DesignTokens.spacingUnit * 2), child: child)); }
