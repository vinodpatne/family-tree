import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/field_definition.dart';
import '../utils/persona_helper.dart';

/// A custom TextInputFormatter that auto-formats date input as YYYY-MM-DD
/// while the user types only digits.
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract only digits from the new value
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 8 digits (YYYYMMDD)
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      // Insert dash after 4th and 6th digit
      if (i == 3 && limited.length > 4) buffer.write('-');
      if (i == 5 && limited.length > 6) buffer.write('-');
    }

    final formatted = buffer.toString();
    // Place cursor at end
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DynamicFieldInput extends StatefulWidget {
  const DynamicFieldInput({
    super.key,
    required this.field,
    required this.controller,
    this.allControllers,
  });

  final FieldDefinition field;
  final TextEditingController controller;
  final Map<String, TextEditingController>? allControllers;

  @override
  State<DynamicFieldInput> createState() => _DynamicFieldInputState();
}

class _DynamicFieldInputState extends State<DynamicFieldInput> {
  bool get _isDateField =>
      widget.field.type == 'date' || widget.field.key == 'dob';

  bool get _isAgeField => widget.field.key == 'age';

  /// Whether the age field should be read-only (DOB has a valid date entered)
  bool get _isAgeReadOnly {
    if (!_isAgeField) return false;
    final dobCtrl = widget.allControllers?['dob'];
    if (dobCtrl == null) return false;
    final dobText = dobCtrl.text.trim();
    if (dobText.isEmpty) return false;
    // Only lock if DOB is a complete, valid date
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dobText)) return false;
    final parsed = DateTime.tryParse(dobText);
    return parsed != null && !parsed.isAfter(DateTime.now());
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    DateTime initial = DateTime(1990, 1, 1);
    if (widget.controller.text.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(widget.controller.text.trim());
      if (parsed != null && !parsed.isAfter(now)) {
        initial = parsed;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1850),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select ${widget.field.label}',
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      widget.controller.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = widget.field;
    final controller = widget.controller;

    Widget? suffixIcon;
    if (_isDateField) {
      suffixIcon = IconButton(
        icon: const Icon(Icons.calendar_month, size: 20),
        tooltip: 'Select date',
        onPressed: () => _selectDate(context),
      );
    } else if (field.sensitive) {
      suffixIcon = const Icon(Icons.lock, size: 18);
    }

    String? helperText;
    if (_isDateField) {
      helperText = 'Format: YYYY-MM-DD';
    } else if (field.type == 'phone') {
      helperText = 'Enter 10-digit mobile number';
    }

    final decoration = InputDecoration(
      labelText: field.label,
      suffixIcon: suffixIcon,
      helperText: helperText,
      filled: true,
      fillColor:
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    // Read-only decoration for locked age field
    final ageReadOnly = _isAgeReadOnly;
    final ageDecoration = ageReadOnly
        ? decoration.copyWith(
            helperText: 'Auto-calculated from Date of Birth',
            suffixIcon: const Icon(Icons.lock_outline, size: 18),
          )
        : decoration;

    if (field.type == 'enum') {
      return DropdownButtonFormField<String>(
        initialValue: controller.text.isEmpty ? null : controller.text,
        decoration: decoration,
        items: (field.options ?? const [])
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) => controller.text = v ?? '',
        validator: (v) {
          if (field.mandatory && (v == null || v.trim().isEmpty)) {
            return 'Required';
          }
          return null;
        },
      );
    }

    if (field.type == 'image') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(field.label, style: theme.textTheme.titleMedium),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([
                controller,
                if (widget.allControllers?.containsKey('gender') == true) widget.allControllers!['gender']!,
                if (widget.allControllers?.containsKey('age') == true) widget.allControllers!['age']!,
                if (widget.allControllers?.containsKey('profession') == true) widget.allControllers!['profession']!,
              ]),
              builder: (context, child) {
                final hasUploadedImage = controller.text.isNotEmpty && !controller.text.contains('/personas/');
                
                String displayUrl = controller.text;
                if (!hasUploadedImage) {
                  final gender = widget.allControllers?['gender']?.text ?? 'male';
                  final age = widget.allControllers?['age']?.text ?? '30';
                  final profession = widget.allControllers?['profession']?.text ?? 'developer';
                  displayUrl = PersonaHelper.getDynamicPersonaUrl(gender, age, profession);
                }

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
                                final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery);
                                if (image != null) {
                                  final bytes = await image.readAsBytes();
                                  final base64String = base64Encode(bytes);
                                  final mimeType =
                                      image.mimeType ?? 'image/jpeg';
                                  controller.text =
                                      'data:$mimeType;base64,$base64String';
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.face),
                              title: const Text('Choose Avatar Icon'),
                              onTap: () {
                                Navigator.pop(context);
                                final gender =
                                    widget.allControllers?['gender']?.text ??
                                        'male';
                                final age =
                                    widget.allControllers?['age']?.text ?? '30';
                                final personas =
                                    PersonaHelper.getAvailablePersonas(
                                        gender, age);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Select Avatar'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 48,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: personas.length,
                                        itemBuilder: (context, index) {
                                          return InkWell(
                                            onTap: () {
                                              controller.text =
                                                  personas[index];
                                              Navigator.pop(context);
                                            },
                                            child: Image.network(
                                              personas[index],
                                              fit: BoxFit.contain,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
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
                      border: Border.all(color: theme.primaryColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: displayUrl.isNotEmpty ? NetworkImage(displayUrl) : null,
                      child: displayUrl.isNotEmpty
                          ? null
                          : const Icon(Icons.add_a_photo, size: 28),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Input formatters & keyboard types based on field key / type
    final formatters = <TextInputFormatter>[];
    TextInputType keyboardType = TextInputType.text;

    if (_isAgeField || field.type == 'number') {
      keyboardType = TextInputType.number;
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      if (_isAgeField) {
        formatters.add(LengthLimitingTextInputFormatter(3)); // max "110"
      }
    } else if (field.type == 'email') {
      keyboardType = TextInputType.emailAddress;
      formatters.add(FilteringTextInputFormatter.deny(RegExp(r'\s')));
    } else if (field.type == 'phone') {
      keyboardType = TextInputType.phone;
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      formatters.add(LengthLimitingTextInputFormatter(10));
    } else if (_isDateField) {
      keyboardType = TextInputType.number;
      formatters.add(_DateInputFormatter());
    }

    return TextFormField(
      controller: controller,
      maxLines: field.type == 'textarea' ? 4 : 1,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      readOnly: _isAgeField && ageReadOnly,
      decoration: _isAgeField ? ageDecoration : decoration,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) {
        final val = v?.trim() ?? '';
        if (field.mandatory && val.isEmpty) {
          return '${field.label} is required';
        }
        if (val.isEmpty) return null;

        // Age Validation (0 to 110)
        if (_isAgeField) {
          final ageVal = int.tryParse(val);
          if (ageVal == null || ageVal < 0 || ageVal > 110) {
            return 'Age must be between 0 and 110';
          }
        }

        // Generic Number Validation
        if (field.type == 'number' && !_isAgeField) {
          final numVal = num.tryParse(val);
          if (numVal == null) {
            return 'Enter a valid number';
          }
        }

        // Date Validation (No Future Dates)
        if (_isDateField) {
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(val)) {
            return 'Enter date in YYYY-MM-DD format';
          }
          final parsed = DateTime.tryParse(val);
          if (parsed == null) {
            return 'Enter a valid date';
          }
          final today = DateTime.now();
          final todayEnd =
              DateTime(today.year, today.month, today.day, 23, 59, 59);
          if (parsed.isAfter(todayEnd)) {
            return 'Future dates are not allowed';
          }
        }

        // Email Validation
        if (field.type == 'email') {
          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
              .hasMatch(val)) {
            return 'Enter a valid email address';
          }
        }

        // Phone Validation — exactly 10 digits
        if (field.type == 'phone') {
          final digits = val.replaceAll(RegExp(r'\D'), '');
          if (digits.length != 10) {
            return 'Mobile number must be exactly 10 digits';
          }
        }

        // Name Fields Validation
        if (field.key.contains('Name')) {
          if (!RegExp(r"^[a-zA-Z\s\-\'\.]+$").hasMatch(val)) {
            return 'Name contains invalid characters';
          }
        }

        return null;
      },
    );
  }
}
