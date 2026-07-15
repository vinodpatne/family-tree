class FamilySettings {
  final String photoShape;
  final Map<String, String> genderColors;
  const FamilySettings({required this.photoShape, required this.genderColors});
  factory FamilySettings.fromJson(Map<String, dynamic> json) => FamilySettings(photoShape: json['photoShape'], genderColors: Map<String, String>.from(json['genderColors']));
  Map<String, dynamic> toJson() => {'photoShape': photoShape, 'genderColors': genderColors};
  FamilySettings copyWith({String? photoShape, Map<String, String>? genderColors}) => FamilySettings(photoShape: photoShape ?? this.photoShape, genderColors: genderColors ?? this.genderColors);
}
class Family {
  final String id;
  final String name;
  final String createdBy;
  final List<String> memberUserIds;
  final Map<String, String> roles;
  final FamilySettings settings;
  final String fieldSchemaId;
  const Family({required this.id, required this.name, required this.createdBy, required this.memberUserIds, required this.roles, required this.settings, required this.fieldSchemaId});
  factory Family.fromJson(Map<String, dynamic> json) => Family(id: json['id'], name: json['name'], createdBy: json['createdBy'], memberUserIds: List<String>.from(json['memberUserIds']), roles: Map<String, String>.from(json['roles']), settings: FamilySettings.fromJson(Map<String, dynamic>.from(json['settings'])), fieldSchemaId: json['fieldSchemaId']);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'createdBy': createdBy, 'memberUserIds': memberUserIds, 'roles': roles, 'settings': settings.toJson(), 'fieldSchemaId': fieldSchemaId};
  Family copyWith({String? name, List<String>? memberUserIds, Map<String, String>? roles, FamilySettings? settings, String? fieldSchemaId}) => Family(id: id, name: name ?? this.name, createdBy: createdBy, memberUserIds: memberUserIds ?? this.memberUserIds, roles: roles ?? this.roles, settings: settings ?? this.settings, fieldSchemaId: fieldSchemaId ?? this.fieldSchemaId);
}
