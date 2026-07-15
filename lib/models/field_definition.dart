class FieldDefinition {
  final String key;
  final String label;
  final String type;
  final bool mandatory;
  final bool isDefault;
  final bool sensitive;
  final List<String>? options;
  const FieldDefinition({required this.key, required this.label, required this.type, this.mandatory = false, this.isDefault = false, this.sensitive = false, this.options});
  factory FieldDefinition.fromJson(Map<String, dynamic> json) => FieldDefinition(key: json['key'], label: json['label'], type: json['type'], mandatory: json['mandatory'] ?? false, isDefault: json['isDefault'] ?? false, sensitive: json['sensitive'] ?? false, options: json['options'] == null ? null : List<String>.from(json['options']));
  Map<String, dynamic> toJson() => {'key': key, 'label': label, 'type': type, 'mandatory': mandatory, 'isDefault': isDefault, 'sensitive': sensitive, 'options': options};
}
class FieldSchema {
  final String id;
  final String familyId;
  final List<FieldDefinition> fields;
  final int version;
  const FieldSchema({required this.id, required this.familyId, required this.fields, required this.version});
  factory FieldSchema.fromJson(Map<String, dynamic> json) => FieldSchema(id: json['id'], familyId: json['familyId'], fields: (json['fields'] as List).map((e) => FieldDefinition.fromJson(Map<String, dynamic>.from(e))).toList(), version: json['version']);
  Map<String, dynamic> toJson() => {'id': id, 'familyId': familyId, 'fields': fields.map((e) => e.toJson()).toList(), 'version': version};
}
