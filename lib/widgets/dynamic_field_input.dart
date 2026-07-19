import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/field_definition.dart';
import '../utils/persona_helper.dart';

class DynamicFieldInput extends StatelessWidget {
  const DynamicFieldInput({super.key, required this.field, required this.controller, this.allControllers});
  final FieldDefinition field;
  final TextEditingController controller;
  final Map<String, TextEditingController>? allControllers;

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      labelText: field.label,
      suffixIcon: field.sensitive ? const Icon(Icons.lock, size: 18) : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    if (field.type == 'enum') {
      return DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: decoration,
        items: (field.options ?? const []).map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) => controller.text = v ?? ''
      );
    }
    
    if (field.type == 'image') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(field.label, style: Theme.of(context).textTheme.titleMedium),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final hasImage = value.text.isNotEmpty;
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Upload Photo'),
                              onTap: () async {
                                Navigator.pop(context);
                                final picker = ImagePicker();
                                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                if (image != null) {
                                  final bytes = await image.readAsBytes();
                                  final base64String = base64Encode(bytes);
                                  final mimeType = image.mimeType ?? 'image/jpeg';
                                  controller.text = 'data:$mimeType;base64,$base64String';
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.face),
                              title: const Text('Choose Avatar Icon'),
                              onTap: () {
                                Navigator.pop(context);
                                final gender = allControllers?['gender']?.text ?? 'male';
                                final age = allControllers?['age']?.text ?? '30';
                                final personas = PersonaHelper.getAvailablePersonas(gender, age);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Select Avatar'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 48, crossAxisSpacing: 12, mainAxisSpacing: 12),
                                        itemCount: personas.length,
                                        itemBuilder: (context, index) {
                                          return InkWell(
                                            onTap: () {
                                              controller.text = personas[index];
                                              Navigator.pop(context);
                                            },
                                            child: Image.network(personas[index], fit: BoxFit.contain),
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      backgroundImage: hasImage ? NetworkImage(value.text) : null,
                      child: hasImage ? null : const Icon(Icons.add_a_photo, size: 28),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return TextFormField(
      controller: controller,
      maxLines: field.type == 'textarea' ? 4 : 1,
      keyboardType: ['number', 'phone'].contains(field.type) ? TextInputType.number : field.type == 'email' ? TextInputType.emailAddress : TextInputType.text,
      decoration: decoration,
      validator: (v) => field.mandatory && (v == null || v.trim().isEmpty) ? 'Required' : null
    );
  }
}
