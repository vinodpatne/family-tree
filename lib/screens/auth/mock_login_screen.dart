import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
class MockLoginScreen extends ConsumerWidget { const MockLoginScreen({super.key}); @override Widget build(BuildContext context, WidgetRef ref) => Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Card(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.family_restroom, size: 72), Text('Family Tree Prototype', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 24), FilledButton.icon(icon: const Icon(Icons.login), label: const Text('Continue with Google'), onPressed: () async { await ref.read(repositoryProvider).signInMock(role: 'owner'); if (context.mounted) context.go('/'); }), const Text('Mock sign-in only — no OAuth request is made.')])))))); }
