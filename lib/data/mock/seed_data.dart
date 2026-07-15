import 'package:uuid/uuid.dart';
import '../../models/family.dart';
import '../../models/family_member.dart';
import '../../models/field_definition.dart';
import '../../theme/design_tokens.dart';

const mockUserId = 'mock-owner-user';
const mockEditorId = 'mock-editor-user';
const mockViewerId = 'mock-viewer-user';

String colorHex(int value) => '#${value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

List<FieldDefinition> defaultFields() => const [
  FieldDefinition(key: 'photo', label: 'Photo', type: 'image', isDefault: true),
  FieldDefinition(key: 'firstName', label: 'First Name', type: 'text', mandatory: true, isDefault: true),
  FieldDefinition(key: 'lastName', label: 'Last Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'dob', label: 'Date of Birth', type: 'date', isDefault: true),
  FieldDefinition(key: 'gender', label: 'Gender', type: 'enum', isDefault: true, options: ['male', 'female', 'other']),
  FieldDefinition(key: 'fatherFirstName', label: 'Father First Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'fatherLastName', label: 'Father Last Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'motherFirstName', label: 'Mother First Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'motherLastName', label: 'Mother Last Name', type: 'text', isDefault: true),
];

List<FieldDefinition> suggestedFields() => const [
  FieldDefinition(key: 'email', label: 'Email', type: 'email'), FieldDefinition(key: 'profession', label: 'Profession', type: 'text'), FieldDefinition(key: 'placeOfBirth', label: 'Place of Birth', type: 'text'), FieldDefinition(key: 'timeOfBirth', label: 'Time of Birth', type: 'time'), FieldDefinition(key: 'hobby', label: 'Hobby', type: 'textarea'), FieldDefinition(key: 'dod', label: 'Date of Death', type: 'date'), FieldDefinition(key: 'netWorth', label: 'Net Worth', type: 'number', sensitive: true), FieldDefinition(key: 'residenceArea', label: 'Residence Area', type: 'text'), FieldDefinition(key: 'residenceAddress', label: 'Residence Address', type: 'textarea', sensitive: true), FieldDefinition(key: 'mobile', label: 'Mobile', type: 'phone', sensitive: true), FieldDefinition(key: 'caste', label: 'Caste', type: 'text'), FieldDefinition(key: 'religion', label: 'Religion', type: 'text'), FieldDefinition(key: 'gotra', label: 'Gotra', type: 'text'), FieldDefinition(key: 'naadi', label: 'Naadi', type: 'text'), FieldDefinition(key: 'height', label: 'Height', type: 'number'), FieldDefinition(key: 'weight', label: 'Weight', type: 'number'),
];

Map<String, dynamic> seedStore() {
  final uuid = const Uuid(); final familyId = uuid.v4(); final schemaId = uuid.v4(); final now = DateTime.now();
  final settings = FamilySettings(photoShape: DesignTokens.defaultPhotoShape, genderColors: DesignTokens.genderBorderColors.map((k, v) => MapEntry(k, colorHex(v.value))));
  final family = Family(id: familyId, name: 'The Riveras', createdBy: mockUserId, memberUserIds: const [mockUserId, mockEditorId, mockViewerId], roles: const {mockUserId: 'owner', mockEditorId: 'editor', mockViewerId: 'viewer'}, settings: settings, fieldSchemaId: schemaId);
  final ids = List.generate(9, (_) => uuid.v4());
  FamilyMember m(int i, String f, String l, String g, String dob, {String? dod, String? father, String? mother, List<String> spouses = const [], List<String> children = const []}) => FamilyMember(id: ids[i], familyId: familyId, schemaVersion: 1, data: {'photo': 'https://i.pravatar.cc/300?u=${ids[i]}', 'firstName': f, 'lastName': l, 'gender': g, 'dob': dob, if (dod != null) 'dod': dod, 'profession': 'Community builder', 'mobile': '+1 555 010${i + 1}'}, relations: MemberRelations(fatherId: father, motherId: mother, spouseIds: spouses, childrenIds: children), createdBy: mockUserId, lastEditedBy: mockUserId, createdAt: now, updatedAt: now);
  final members = [
    m(0, 'George', 'Rivera', 'male', '1940-04-12', dod: '2018-09-01', spouses: [ids[1]], children: [ids[2], ids[3]]), m(1, 'Elena', 'Rivera', 'female', '1944-07-03', spouses: [ids[0]], children: [ids[2], ids[3]]),
    m(2, 'Marco', 'Rivera', 'male', '1968-02-11', father: ids[0], mother: ids[1], spouses: [ids[4]], children: [ids[5], ids[6]]), m(3, 'Sofia', 'Patel', 'female', '1971-10-22', father: ids[0], mother: ids[1]),
    m(4, 'Asha', 'Rivera', 'female', '1970-06-19', spouses: [ids[2]], children: [ids[5], ids[6]]), m(5, 'Lina', 'Rivera', 'female', '1995-01-08', father: ids[2], mother: ids[4], spouses: [ids[7]], children: [ids[8]]),
    m(6, 'Noah', 'Rivera', 'male', '1999-12-30', father: ids[2], mother: ids[4]), m(7, 'Sam', 'Chen', 'other', '1993-03-15', spouses: [ids[5]], children: [ids[8]]), m(8, 'Maya', 'Chen-Rivera', 'female', '2021-08-05', father: ids[7], mother: ids[5]),
  ];
  final schema = FieldSchema(id: schemaId, familyId: familyId, fields: [...defaultFields(), ...suggestedFields().where((f) => ['profession','mobile','dod'].contains(f.key))], version: 1);
  return {'families': {family.id: family.toJson()}, 'schemas': {schema.id: schema.toJson()}, 'members': {for (final x in members) x.id: x.toJson()}, 'invites': {family.id: ['pending-cousin@example.com']}};
}
