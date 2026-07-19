class CustomLink {
  final String targetId;
  final String label;
  final bool isDotted;
  const CustomLink({required this.targetId, required this.label, this.isDotted = false});
  factory CustomLink.fromJson(Map<String, dynamic> json) => CustomLink(targetId: json['targetId'], label: json['label'], isDotted: json['isDotted'] ?? false);
  Map<String, dynamic> toJson() => {'targetId': targetId, 'label': label, 'isDotted': isDotted};
}

class MemberRelations {
  final String? fatherId;
  final String? motherId;
  final List<String> spouseIds;
  final List<String> childrenIds;
  final List<CustomLink> customLinks;
  const MemberRelations({this.fatherId, this.motherId, this.spouseIds = const [], this.childrenIds = const [], this.customLinks = const []});
  factory MemberRelations.fromJson(Map<String, dynamic> json) => MemberRelations(fatherId: json['fatherId'], motherId: json['motherId'], spouseIds: List<String>.from(json['spouseIds'] ?? const []), childrenIds: List<String>.from(json['childrenIds'] ?? const []), customLinks: (json['customLinks'] as List<dynamic>? ?? []).map((e) => CustomLink.fromJson(Map<String, dynamic>.from(e))).toList());
  Map<String, dynamic> toJson() => {'fatherId': fatherId, 'motherId': motherId, 'spouseIds': spouseIds, 'childrenIds': childrenIds, 'customLinks': customLinks.map((e) => e.toJson()).toList()};
  MemberRelations copyWith({String? fatherId, String? motherId, List<String>? spouseIds, List<String>? childrenIds, List<CustomLink>? customLinks}) => MemberRelations(fatherId: fatherId ?? this.fatherId, motherId: motherId ?? this.motherId, spouseIds: spouseIds ?? this.spouseIds, childrenIds: childrenIds ?? this.childrenIds, customLinks: customLinks ?? this.customLinks);
}
class FamilyMember {
  final String id;
  final String familyId;
  final int schemaVersion;
  final Map<String, dynamic> data;
  final String? photoMediaId;
  final MemberRelations relations;
  final String createdBy;
  final String lastEditedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FamilyMember({required this.id, required this.familyId, required this.schemaVersion, required this.data, this.photoMediaId, required this.relations, required this.createdBy, required this.lastEditedBy, required this.createdAt, required this.updatedAt});
  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(id: json['id'], familyId: json['familyId'], schemaVersion: json['schemaVersion'], data: Map<String, dynamic>.from(json['data']), photoMediaId: json['photoMediaId'], relations: MemberRelations.fromJson(Map<String, dynamic>.from(json['relations'])), createdBy: json['createdBy'], lastEditedBy: json['lastEditedBy'], createdAt: DateTime.parse(json['createdAt']), updatedAt: DateTime.parse(json['updatedAt']));
  Map<String, dynamic> toJson() => {'id': id, 'familyId': familyId, 'schemaVersion': schemaVersion, 'data': data, 'photoMediaId': photoMediaId, 'relations': relations.toJson(), 'createdBy': createdBy, 'lastEditedBy': lastEditedBy, 'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String()};
  FamilyMember copyWith({Map<String, dynamic>? data, String? photoMediaId, MemberRelations? relations, String? lastEditedBy, DateTime? updatedAt}) => FamilyMember(id: id, familyId: familyId, schemaVersion: schemaVersion, data: data ?? this.data, photoMediaId: photoMediaId ?? this.photoMediaId, relations: relations ?? this.relations, createdBy: createdBy, lastEditedBy: lastEditedBy ?? this.lastEditedBy, createdAt: createdAt, updatedAt: updatedAt ?? this.updatedAt);
}
