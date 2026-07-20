import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../models/family_member.dart';
import '../../models/field_definition.dart';
import '../../state/providers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dynamic_field_input.dart';

class MemberEditFormScreen extends ConsumerStatefulWidget {
  const MemberEditFormScreen({
    super.key,
    required this.familyId,
    this.memberId,
    this.initialFatherId,
    this.initialMotherId,
    this.initialSpouseId,
    this.initialChildId,
  });

  final String familyId;
  final String? memberId;
  final String? initialFatherId,
      initialMotherId,
      initialSpouseId,
      initialChildId;

  @override
  ConsumerState<MemberEditFormScreen> createState() => _S();
}

class _S extends ConsumerState<MemberEditFormScreen> {
  final form = GlobalKey<FormState>();
  final ctrls = <String, TextEditingController>{};
  String? father, mother;
  String _lastAutoPopulatedLastName = '';

  @override
  void initState() {
    super.initState();
    father = widget.initialFatherId;
    mother = widget.initialMotherId;
  }

  void _onLastNameChanged() {
    final currentLastName = ctrls['lastName']?.text ?? '';
    final fatherCtrl = ctrls['fatherLastName'];
    final motherCtrl = ctrls['motherLastName'];

    if (fatherCtrl != null) {
      if (fatherCtrl.text.isEmpty ||
          fatherCtrl.text == _lastAutoPopulatedLastName) {
        fatherCtrl.text = currentLastName;
      }
    }
    if (motherCtrl != null) {
      if (motherCtrl.text.isEmpty ||
          motherCtrl.text == _lastAutoPopulatedLastName) {
        motherCtrl.text = currentLastName;
      }
    }
    _lastAutoPopulatedLastName = currentLastName;
  }

  void _calculateAge() {
    final dob = ctrls['dob']?.text.trim() ?? '';
    if (dob.isEmpty) {
      // DOB cleared — unlock age field and clear auto-calculated value
      if (mounted) setState(() {});
      return;
    }
    // Only calculate when we have a complete date (YYYY-MM-DD)
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob)) {
      if (mounted) setState(() {});
      return;
    }
    try {
      final date = DateTime.parse(dob);
      final now = DateTime.now();
      if (date.isAfter(now)) return; // Don't calculate for future dates
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      if (age >= 0 && age <= 150) {
        ctrls['age']?.text = age.toString();
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _inviteMember(BuildContext context) {
    String email = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite to Collaborate'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Email Address'),
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => email = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (email.isEmpty || !email.contains('@')) return;
              await ref
                  .read(repositoryProvider)
                  .inviteCollaborator(widget.familyId, email);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invite sent to $email')),
                );
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _addCustomField(BuildContext context, FieldSchema schema) {
    final labelController = TextEditingController();
    String selectedType = 'text';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Custom Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Field Name (e.g. Hobbies, Caste, Qualification)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Data Type',
                  border: OutlineInputBorder(),
                ),
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
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final label = labelController.text.trim();
                if (label.isEmpty) return;
                final key =
                    label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                if (schema.fields.any((f) => f.key == key)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Field with key "$key" already exists.')),
                  );
                  return;
                }
                final newField = FieldDefinition(
                  key: key,
                  label: label,
                  type: selectedType,
                );
                final newSchema = FieldSchema(
                  id: schema.id,
                  familyId: schema.familyId,
                  fields: [...schema.fields, newField],
                  version: schema.version + 1,
                );
                await ref.read(repositoryProvider).saveSchema(newSchema);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add Field'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fam = ref.watch(familyProvider(widget.familyId)).valueOrNull;
    final members =
        ref.watch(membersProvider(widget.familyId)).valueOrNull ?? [];
    final existing =
        members.where((m) => m.id == widget.memberId).firstOrNull;
    final schema = fam == null
        ? null
        : ref.watch(schemaProvider(widget.familyId)).valueOrNull;

    if (fam == null || schema == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    for (final f in schema.fields) {
      if (!ctrls.containsKey(f.key)) {
        final ctrl = TextEditingController(
            text: existing?.data[f.key]?.toString() ?? '');
        if (f.key == 'dob') ctrl.addListener(_calculateAge);
        if (f.key == 'gender') ctrl.addListener(() => setState(() {}));
        if (f.key == 'lastName') ctrl.addListener(_onLastNameChanged);
        ctrls[f.key] = ctrl;
      }
    }

    final fatherMember = members.where((m) => m.id == father).firstOrNull;
    final motherMember = members.where((m) => m.id == mother).firstOrNull;

    if (existing == null) {
      if (fatherMember != null) {
        if (ctrls['lastName']!.text.isEmpty) {
          ctrls['lastName']!.text =
              fatherMember.data['lastName']?.toString() ?? '';
        }
        if (ctrls['fatherFirstName']!.text.isEmpty) {
          ctrls['fatherFirstName']!.text =
              fatherMember.data['firstName']?.toString() ?? '';
        }
        if (ctrls['fatherLastName']!.text.isEmpty) {
          ctrls['fatherLastName']!.text =
              fatherMember.data['lastName']?.toString() ?? '';
        }
      }
      if (motherMember != null) {
        if (ctrls['motherFirstName']!.text.isEmpty) {
          ctrls['motherFirstName']!.text =
              motherMember.data['firstName']?.toString() ?? '';
        }
        if (ctrls['motherLastName']!.text.isEmpty) {
          ctrls['motherLastName']!.text =
              motherMember.data['lastName']?.toString() ?? '';
        }
      }
      if (widget.initialSpouseId != null) {
        final spouse = members
            .where((m) => m.id == widget.initialSpouseId)
            .firstOrNull;
        if (spouse != null && ctrls['gender']!.text.isEmpty) {
          final sGender = spouse.data['gender']?.toString().toLowerCase();
          ctrls['gender']!.text =
              sGender == 'male' ? 'female' : sGender == 'female' ? 'male' : '';
        }
      }
      if (widget.initialChildId != null) {
        final child =
            members.where((m) => m.id == widget.initialChildId).firstOrNull;
        if (child != null && ctrls['gender']!.text.isEmpty) {
          if (child.relations.motherId != null &&
              child.relations.fatherId == null) {
            ctrls['gender']!.text = 'male';
          } else if (child.relations.fatherId != null &&
              child.relations.motherId == null) {
            ctrls['gender']!.text = 'female';
          }
        }
      }

      // Default auto-populate father & mother last name if member last name is present
      if (ctrls['lastName']!.text.isNotEmpty) {
        if (ctrls['fatherLastName']!.text.isEmpty) {
          ctrls['fatherLastName']!.text = ctrls['lastName']!.text;
        }
        if (ctrls['motherLastName']!.text.isEmpty) {
          ctrls['motherLastName']!.text = ctrls['lastName']!.text;
        }
      }
    }

    final isFemale = ctrls['gender']?.text.toLowerCase() == 'female';

    Widget buildSection(String title, List<Widget> children,
        {Widget? trailing}) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );
    }

    final photoField = schema.fields.firstWhere((f) => f.key == 'photo',
        orElse: () => schema.fields.first);
    final basicFields = schema.fields.where((f) =>
        ['firstName', 'lastName', 'nickName', 'dob', 'age', 'gender']
            .contains(f.key));
    final maidenFields = schema.fields.where(
        (f) => ['maidenFirstName', 'maidenLastName'].contains(f.key));
    final parentFields = schema.fields.where((f) => [
          'fatherFirstName',
          'fatherLastName',
          'motherFirstName',
          'motherLastName'
        ].contains(f.key));
    final otherFields = schema.fields.where((f) => ![
          'photo',
          'firstName',
          'lastName',
          'nickName',
          'dob',
          'age',
          'gender',
          'maidenFirstName',
          'maidenLastName',
          'fatherFirstName',
          'fatherLastName',
          'motherFirstName',
          'motherLastName'
        ].contains(f.key));

    return AppScaffold(
      title: existing == null
          ? 'Add New Member'
          : 'Edit Member: ${existing.data['firstName'] ?? ''}',
      familyId: widget.familyId,
      showBackButton: true,
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Page Title Header
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null
                        ? 'Add New Family Member'
                        : 'Edit Member Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    existing == null
                        ? 'Fill out member information and family relationships.'
                        : 'Update information for ${existing.data['firstName'] ?? 'this member'}.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Center(
              child: DynamicFieldInput(
                field: photoField,
                controller: ctrls[photoField.key]!,
                allControllers: ctrls,
              ),
            ),
            if (existing != null) ...[
              const SizedBox(height: 16),
              Center(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.mail, size: 18),
                  label: const Text('Invite to Collaborate'),
                  onPressed: () => _inviteMember(context),
                ),
              ),
            ],
            const SizedBox(height: 24),
            buildSection('Personal Details', [
              for (final f in basicFields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DynamicFieldInput(
                    field: f,
                    controller: ctrls[f.key]!,
                    allControllers: ctrls,
                  ),
                ),
              if (isFemale)
                for (final f in maidenFields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DynamicFieldInput(
                      field: f,
                      controller: ctrls[f.key]!,
                      allControllers: ctrls,
                    ),
                  ),
            ]),
            buildSection('Parent Details', [
              for (final f in parentFields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DynamicFieldInput(
                    field: f,
                    controller: ctrls[f.key]!,
                    allControllers: ctrls,
                  ),
                ),
            ]),
            buildSection(
              'Other Details',
              [
                for (final f in otherFields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DynamicFieldInput(
                      field: f,
                      controller: ctrls[f.key]!,
                      allControllers: ctrls,
                    ),
                  ),
              ],
              trailing: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Field'),
                onPressed: () => _addCustomField(context, schema),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  final now = DateTime.now();
                  final id = existing?.id ?? const Uuid().v4();
                  final data = {
                    for (final e in ctrls.entries) e.key: e.value.text
                  };
                  final spouseIds = List<String>.from(
                      existing?.relations.spouseIds ?? []);
                  if (widget.initialSpouseId != null &&
                      !spouseIds.contains(widget.initialSpouseId)) {
                    spouseIds.add(widget.initialSpouseId!);
                  }
                  final childrenIds = List<String>.from(
                      existing?.relations.childrenIds ?? []);
                  if (widget.initialChildId != null &&
                      !childrenIds.contains(widget.initialChildId)) {
                    childrenIds.add(widget.initialChildId!);
                  }

                  // Age Validation vs Parents / Children
                  final currentAge =
                      int.tryParse(ctrls['age']?.text ?? '');
                  if (currentAge != null) {
                    final parentAges = [
                      int.tryParse(
                          fatherMember?.data['age']?.toString() ?? ''),
                      int.tryParse(
                          motherMember?.data['age']?.toString() ?? '')
                    ];
                    for (final pa in parentAges) {
                      if (pa != null && currentAge >= pa) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Child's age cannot be greater than or equal to a Parent's age."),
                          ),
                        );
                        return;
                      }
                    }
                    for (final cid in childrenIds) {
                      final cMember = members
                          .where((m) => m.id == cid)
                          .firstOrNull;
                      final cAge = int.tryParse(
                          cMember?.data['age']?.toString() ?? '');
                      if (cAge != null && currentAge <= cAge) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Parent's age cannot be less than or equal to a Child's age."),
                          ),
                        );
                        return;
                      }
                    }
                  }

                  final member = FamilyMember(
                    id: id,
                    familyId: widget.familyId,
                    schemaVersion: schema.version,
                    data: data,
                    photoMediaId: null,
                    relations: (existing?.relations ??
                            const MemberRelations())
                        .copyWith(
                      fatherId: father,
                      motherId: mother,
                      spouseIds: spouseIds,
                      childrenIds: childrenIds,
                    ),
                    createdBy: 'mock-owner-user',
                    lastEditedBy: 'mock-owner-user',
                    createdAt: existing?.createdAt ?? now,
                    updatedAt: now,
                  );
                  await ref.read(repositoryProvider).saveMember(member);

                  if (widget.initialSpouseId != null) {
                    final spouse = members
                        .where((m) => m.id == widget.initialSpouseId)
                        .firstOrNull;
                    if (spouse != null) {
                      final sIds = List<String>.from(spouse.relations.spouseIds);
                      if (!sIds.contains(id)) {
                        sIds.add(id);
                        await ref.read(repositoryProvider).saveMember(
                              spouse.copyWith(
                                relations: spouse.relations
                                    .copyWith(spouseIds: sIds),
                              ),
                            );
                      }
                    }
                  }
                  if (widget.initialChildId != null) {
                    final child = members
                        .where((m) => m.id == widget.initialChildId)
                        .firstOrNull;
                    if (child != null) {
                      final isMale =
                          member.data['gender']?.toString().toLowerCase() ==
                              'male';
                      await ref.read(repositoryProvider).saveMember(
                            child.copyWith(
                              relations: child.relations.copyWith(
                                fatherId: isMale
                                    ? id
                                    : child.relations.fatherId,
                                motherId: !isMale
                                    ? id
                                    : child.relations.motherId,
                              ),
                            ),
                          );
                    }
                  }
                  if (context.mounted) {
                    context.go('/family/${widget.familyId}/tree');
                  }
                },
                child: const Text(
                  'Save Member',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
