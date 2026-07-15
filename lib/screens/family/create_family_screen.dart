import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
class CreateFamilyScreen extends ConsumerStatefulWidget { const CreateFamilyScreen({super.key}); @override ConsumerState<CreateFamilyScreen> createState() => _S(); } class _S extends ConsumerState<CreateFamilyScreen> { final c = TextEditingController(); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Create Family')), body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [TextField(controller: c, decoration: const InputDecoration(labelText: 'Family name')), const SizedBox(height: 16), FilledButton(onPressed: () async { final f = await ref.read(repositoryProvider).createFamily(c.text.trim().isEmpty ? 'New Family' : c.text.trim()); if (context.mounted) context.go('/family/${f.id}/schema'); }, child: const Text('Continue to field setup'))]))); }
