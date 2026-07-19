import 'package:flutter/material.dart'; import 'package:flutter_riverpod/flutter_riverpod.dart'; import 'package:go_router/go_router.dart'; import 'package:uuid/uuid.dart';
import '../../models/family_member.dart'; import '../../state/providers.dart'; import '../../widgets/dynamic_field_input.dart'; import '../../models/field_definition.dart';
class MemberEditFormScreen extends ConsumerStatefulWidget{ const MemberEditFormScreen({super.key,required this.familyId,this.memberId, this.initialFatherId, this.initialMotherId, this.initialSpouseId, this.initialChildId}); final String familyId; final String? memberId; final String? initialFatherId, initialMotherId, initialSpouseId, initialChildId; @override ConsumerState<MemberEditFormScreen> createState()=>_S();} 
class _S extends ConsumerState<MemberEditFormScreen>{ 
  final form=GlobalKey<FormState>(); 
  final ctrls=<String,TextEditingController>{}; 
  String? father,mother; 

  @override void initState(){
    super.initState(); 
    father = widget.initialFatherId; 
    mother = widget.initialMotherId;
  } 

  void _calculateAge() {
    final dob = ctrls['dob']?.text;
    if (dob != null && dob.isNotEmpty) {
      try {
        final date = DateTime.parse(dob);
        final now = DateTime.now();
        int age = now.year - date.year;
        if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
          age--;
        }
        ctrls['age']?.text = age.toString();
      } catch (_) {}
    }
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (email.isEmpty || !email.contains('@')) return;
              await ref.read(repositoryProvider).inviteCollaborator(widget.familyId, email);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invite sent to $email')));
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _addCustomField(BuildContext context, var schema) {
    String label = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Field'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Field Name (e.g. Hobbies)'),
          onChanged: (v) => label = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (label.trim().isEmpty) return;
              final key = label.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
              if (schema.fields.any((f) => f.key == key)) {
                Navigator.pop(context);
                return;
              }
              final newField = FieldDefinition(key: key, label: label.trim(), type: 'text');
              final newSchema = schema.copyWith(fields: [...schema.fields, newField], version: schema.version + 1);
              await ref.read(repositoryProvider).saveSchema(newSchema);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override Widget build(BuildContext context){ 
    final fam=ref.watch(familyProvider(widget.familyId)).valueOrNull; 
    final members=ref.watch(membersProvider(widget.familyId)).valueOrNull??[]; 
    final existing=members.where((m)=>m.id==widget.memberId).firstOrNull; 
    final schema=fam==null?null:ref.watch(schemaProvider(fam.fieldSchemaId)).valueOrNull; 
    
    if(fam==null||schema==null)return const Scaffold(body:Center(child:CircularProgressIndicator())); 
    
    for(final f in schema.fields){
      if(!ctrls.containsKey(f.key)) {
        final ctrl = TextEditingController(text: existing?.data[f.key]?.toString()??'');
        if (f.key == 'dob') ctrl.addListener(_calculateAge);
        if (f.key == 'gender') ctrl.addListener(() => setState(() {}));
        ctrls[f.key] = ctrl;
      }
    } 

    final fatherMember = members.where((m)=>m.id==father).firstOrNull; 
    final motherMember = members.where((m)=>m.id==mother).firstOrNull; 

    if (existing == null) {
      if (fatherMember != null) {
        if (ctrls['lastName']!.text.isEmpty) ctrls['lastName']!.text = fatherMember.data['lastName']?.toString() ?? '';
        if (ctrls['fatherFirstName']!.text.isEmpty) ctrls['fatherFirstName']!.text = fatherMember.data['firstName']?.toString() ?? '';
        if (ctrls['fatherLastName']!.text.isEmpty) ctrls['fatherLastName']!.text = fatherMember.data['lastName']?.toString() ?? '';
      }
      if (motherMember != null) {
        if (ctrls['motherFirstName']!.text.isEmpty) ctrls['motherFirstName']!.text = motherMember.data['firstName']?.toString() ?? '';
        if (ctrls['motherLastName']!.text.isEmpty) ctrls['motherLastName']!.text = motherMember.data['lastName']?.toString() ?? '';
      }
      if (widget.initialSpouseId != null) {
        final spouse = members.where((m) => m.id == widget.initialSpouseId).firstOrNull;
        if (spouse != null && ctrls['gender']!.text.isEmpty) {
          final sGender = spouse.data['gender']?.toString().toLowerCase();
          ctrls['gender']!.text = sGender == 'male' ? 'female' : sGender == 'female' ? 'male' : '';
        }
      }
      if (widget.initialChildId != null) {
        final child = members.where((m) => m.id == widget.initialChildId).firstOrNull;
        if (child != null && ctrls['gender']!.text.isEmpty) {
          if (child.relations.motherId != null && child.relations.fatherId == null) {
            ctrls['gender']!.text = 'male';
          } else if (child.relations.fatherId != null && child.relations.motherId == null) {
            ctrls['gender']!.text = 'female';
          }
        }
      }
    }

    final isFemale = ctrls['gender']?.text.toLowerCase() == 'female';

    Widget _buildSection(String title, List<Widget> children, {Widget? trailing}) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
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

    final photoField = schema.fields.firstWhere((f) => f.key == 'photo', orElse: () => schema.fields.first);
    final basicFields = schema.fields.where((f) => ['firstName', 'lastName', 'nickName', 'dob', 'age', 'gender'].contains(f.key));
    final maidenFields = schema.fields.where((f) => ['maidenFirstName', 'maidenLastName'].contains(f.key));
    final parentFields = schema.fields.where((f) => ['fatherFirstName', 'fatherLastName', 'motherFirstName', 'motherLastName'].contains(f.key));
    final otherFields = schema.fields.where((f) => !['photo', 'firstName', 'lastName', 'nickName', 'dob', 'age', 'gender', 'maidenFirstName', 'maidenLastName', 'fatherFirstName', 'fatherLastName', 'motherFirstName', 'motherLastName'].contains(f.key));

    return Scaffold(
      appBar:AppBar(
        title:Text(existing==null?'Add Member':(existing.data['firstName'] ?? 'Edit Member').toString()), 
        centerTitle: true, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/family/${widget.familyId}/tree'),
        ),
      ), 
      body:Form(
        key:form, 
        child:ListView(
          padding:const EdgeInsets.all(16), 
          children:[
            Center(child: DynamicFieldInput(field: photoField, controller: ctrls[photoField.key]!, allControllers: ctrls)),
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
            _buildSection('Personal Details', [
              for (final f in basicFields) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12), 
                  child: DynamicFieldInput(field: f, controller: ctrls[f.key]!, allControllers: ctrls)
                ),
              if (isFemale)
                for (final f in maidenFields) 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12), 
                    child: DynamicFieldInput(field: f, controller: ctrls[f.key]!, allControllers: ctrls)
                  ),
            ]),
            _buildSection('Parent Details', [
              for (final f in parentFields) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12), 
                  child: DynamicFieldInput(field: f, controller: ctrls[f.key]!, allControllers: ctrls)
                ),
            ]),
            _buildSection('Other Details', [
              for (final f in otherFields) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12), 
                  child: DynamicFieldInput(field: f, controller: ctrls[f.key]!, allControllers: ctrls)
                ),
            ], trailing: TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Field'),
              onPressed: () => _addCustomField(context, schema),
            )),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed:() async{ 
                  if(!form.currentState!.validate())return; 
                  final now=DateTime.now(); 
                  final id=existing?.id??const Uuid().v4(); 
                  final data={for(final e in ctrls.entries)e.key:e.value.text}; 
                  final spouseIds = List<String>.from(existing?.relations.spouseIds ?? []); 
                  if (widget.initialSpouseId != null && !spouseIds.contains(widget.initialSpouseId)) spouseIds.add(widget.initialSpouseId!); 
                  final childrenIds = List<String>.from(existing?.relations.childrenIds ?? []); 
                  if (widget.initialChildId != null && !childrenIds.contains(widget.initialChildId)) childrenIds.add(widget.initialChildId!); 
                  
                  // Age Validation
                  final currentAge = int.tryParse(ctrls['age']?.text ?? '');
                  if (currentAge != null) {
                    final parentAges = [
                      int.tryParse(fatherMember?.data['age']?.toString() ?? ''),
                      int.tryParse(motherMember?.data['age']?.toString() ?? '')
                    ];
                    for (final pa in parentAges) {
                      if (pa != null && currentAge >= pa) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Child's age cannot be greater than or equal to a Parent's age.")));
                        return;
                      }
                    }
                    for (final cid in childrenIds) {
                      final cMember = members.where((m) => m.id == cid).firstOrNull;
                      final cAge = int.tryParse(cMember?.data['age']?.toString() ?? '');
                      if (cAge != null && currentAge <= cAge) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parent's age cannot be less than or equal to a Child's age.")));
                        return;
                      }
                    }
                  }

                  final member=FamilyMember(id:id,familyId:widget.familyId,schemaVersion:schema.version,data:data,photoMediaId:null,relations:(existing?.relations??const MemberRelations()).copyWith(fatherId: father, motherId: mother, spouseIds: spouseIds, childrenIds: childrenIds),createdBy:'mock-owner-user',lastEditedBy:'mock-owner-user',createdAt:existing?.createdAt??now,updatedAt:now); 
                  await ref.read(repositoryProvider).saveMember(member); 
                  
                  if (widget.initialSpouseId != null) { 
                    final spouse = members.where((m)=>m.id==widget.initialSpouseId).firstOrNull; 
                    if (spouse != null) { 
                      final sIds = List<String>.from(spouse.relations.spouseIds); 
                      if (!sIds.contains(id)) { 
                        sIds.add(id); 
                        await ref.read(repositoryProvider).saveMember(spouse.copyWith(relations: spouse.relations.copyWith(spouseIds: sIds))); 
                      } 
                    } 
                  } 
                  if (widget.initialChildId != null) { 
                    final child = members.where((m)=>m.id==widget.initialChildId).firstOrNull; 
                    if (child != null) { 
                      final isMale = member.data['gender']?.toString().toLowerCase() == 'male'; 
                      await ref.read(repositoryProvider).saveMember(child.copyWith(relations: child.relations.copyWith(fatherId: isMale ? id : child.relations.fatherId, motherId: !isMale ? id : child.relations.motherId))); 
                    } 
                  } 
                  if(context.mounted)context.go('/family/${widget.familyId}/tree');
                }, 
                child:const Text('Save Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
              )
            )
          ]
        )
      )
    );
  }
}
extension FirstOrNull<E> on Iterable<E>{E? get firstOrNull=>isEmpty?null:first;}
