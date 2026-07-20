import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/user_avatar.dart';

class FamilyListScreen extends ConsumerStatefulWidget {
  const FamilyListScreen({super.key});

  @override
  ConsumerState<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends ConsumerState<FamilyListScreen> {
  String _selectedRole = 'owner';

  @override
  Widget build(BuildContext context) {
    final families = ref.watch(familiesProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return AppScaffold(
      title: 'Your Families',
      familyId: null,
      actions: [
        DropdownButton<String>(
          value: _selectedRole,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'owner', child: Text('Role: Owner')),
            DropdownMenuItem(value: 'editor', child: Text('Role: Editor')),
            DropdownMenuItem(value: 'viewer', child: Text('Role: Viewer')),
          ],
          onChanged: (v) {
            if (v != null && v != _selectedRole) {
              setState(() => _selectedRole = v);
              ref.read(repositoryProvider).switchActiveUserRole(v);
            }
          },
        ),
        const SizedBox(width: 8),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/family/new'),
        icon: const Icon(Icons.add),
        label: const Text('Create Family'),
      ),
      child: families.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No families found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Create your first family tree to get started.'),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.go('/family/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Family'),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (currentUser != null) ...[
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: UserAvatar(user: currentUser, radius: 24),
                        title: Text(
                          currentUser.name.isNotEmpty ? currentUser.name : 'Logged In User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(currentUser.email),
                        trailing: TextButton.icon(
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Logout'),
                          onPressed: () async {
                            await ref.read(repositoryProvider).signOut();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ),
                    ),
                  ],
                  Text(
                    'Select a Family',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  for (final f in list)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.family_restroom),
                        ),
                        title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${f.memberUserIds.length} collaborators'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Family'),
                                    content: Text('Are you sure you want to delete ${f.name}? This action cannot be undone.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await ref.read(repositoryProvider).deleteFamily(f.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                                    }
                                  }
                                }
                              },
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => context.go('/family/${f.id}/tree'),
                      ),
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading families: $e')),
      ),
    );
  }
}
