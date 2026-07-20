import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/seed/seed_data.dart';
import '../../models/field_definition.dart';
import '../../state/providers.dart';

import '../../widgets/app_scaffold.dart';

class FieldSchemaSetupScreen extends ConsumerStatefulWidget {
  const FieldSchemaSetupScreen({super.key, required this.familyId});
  final String familyId;

  @override
  ConsumerState<FieldSchemaSetupScreen> createState() =>
      _FieldSchemaSetupScreenState();
}

class _FieldSchemaSetupScreenState
    extends ConsumerState<FieldSchemaSetupScreen> {
  final selected = <FieldDefinition>[];
  final _labelController = TextEditingController();
  String _selectedType = 'text';
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _addCustomField() {
    final text = _labelController.text.trim();
    if (text.isEmpty) return;

    final key = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    // Prevent duplicate keys
    final allKeys = {
      ...defaultFields().map((f) => f.key),
      ...selected.map((f) => f.key),
    };
    if (allKeys.contains(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A field with key "$key" already exists.')),
      );
      return;
    }

    setState(() {
      selected.add(FieldDefinition(
        key: key,
        label: text,
        type: _selectedType,
      ));
      _labelController.clear();
      _selectedType = 'text';
    });
  }

  Future<void> _handleSave() async {
    final fam = ref.read(familyProvider(widget.familyId)).valueOrNull;
    final schema = ref.read(schemaProvider(widget.familyId)).valueOrNull;
    if (fam == null || schema == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(repositoryProvider).saveSchema(
            FieldSchema(
              id: schema.id,
              familyId: widget.familyId,
              fields: [...defaultFields(), ...selected],
              version: schema.version + 1,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family tree fields updated successfully!'),
          ),
        );
        context.go('/family/${widget.familyId}/tree');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save schema: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fam = ref.watch(familyProvider(widget.familyId)).valueOrNull;
    final schema = ref.watch(schemaProvider(widget.familyId)).valueOrNull;
    
    if (schema != null && !_initialized) {
      _initialized = true;
      final defaultKeys = defaultFields().map((f) => f.key).toSet();
      selected.clear();
      selected.addAll(schema.fields.where((f) => !defaultKeys.contains(f.key)));
    }

    final sugg = suggestedFields();
    final theme = Theme.of(context);
    final isReady = fam != null && schema != null;

    return AppScaffold(
      title: 'Customize Family Fields',
      familyId: widget.familyId,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Text(
            'Customize Fields',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add or remove fields available for member profiles in this family tree.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // ── Locked defaults ──────────────────────────────
          Text(
            'Locked defaults',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in defaultFields())
                Chip(
                  avatar: Icon(Icons.lock, size: 16,
                      color: theme.colorScheme.primary),
                  label: Text(f.label),
                ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // ── Suggested fields ─────────────────────────────
          Text(
            'Suggested fields',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in sugg)
                FilterChip(
                  label: Text(
                      f.sensitive ? '${f.label} \u{1F512}' : f.label),
                  selected: selected.any((x) => x.key == f.key),
                  onSelected: (v) => setState(() => v
                      ? selected.add(f)
                      : selected.removeWhere((x) => x.key == f.key)),
                ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // ── Custom label ─────────────────────────────────
          Text(
            'Add Custom Field',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Field name (e.g. Hobbies, Caste, Qualification)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addCustomField(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedType,
                items: const [
                  'text',
                  'textarea',
                  'number',
                  'date',
                  'time',
                  'email',
                  'phone',
                  'enum',
                  'image',
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedType = v!),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addCustomField,
                icon: const Icon(Icons.add),
                tooltip: 'Add custom field',
              ),
            ],
          ),

          // ── Active Additional / Custom fields ─────────────────────
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Active Custom & Additional Fields (${selected.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click the remove button on any field to remove it from this tree.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in selected)
                  InputChip(
                    label: Text('${f.label} (${f.type})'),
                    deleteIcon: const Icon(Icons.cancel, size: 18),
                    onDeleted: () => setState(
                        () => selected.removeWhere((x) => x.key == f.key)),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // ── Save button ──────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: isReady && !_isSaving ? _handleSave : null,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

