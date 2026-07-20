import 'package:uuid/uuid.dart';
import '../../models/family.dart';
import '../../models/family_member.dart';
import '../../models/field_definition.dart';

const seedUserId = 'seed-owner-user';
const seedEditorId = 'seed-editor-user';
const seedViewerId = 'seed-viewer-user';

String colorHex(int value) => '#${value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

List<FieldDefinition> defaultFields() => const [
  FieldDefinition(key: 'photo', label: 'Photo', type: 'image', isDefault: true),
  FieldDefinition(key: 'firstName', label: 'First Name', type: 'text', mandatory: true, isDefault: true),
  FieldDefinition(key: 'lastName', label: 'Last Name', type: 'text', mandatory: true, isDefault: true),
  FieldDefinition(key: 'nickName', label: 'Nick Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'dob', label: 'Date of Birth', type: 'date', isDefault: true),
  FieldDefinition(key: 'age', label: 'Age', type: 'number', isDefault: true),
  FieldDefinition(key: 'gender', label: 'Gender', type: 'enum', isDefault: true, options: ['male', 'female', 'other']),
  FieldDefinition(key: 'maidenFirstName', label: 'Maternal First Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'maidenLastName', label: 'Maternal Last Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'fatherFirstName', label: 'Father First Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'fatherLastName', label: 'Father Last Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'motherFirstName', label: 'Mother First Name', type: 'text', isDefault: true),
  FieldDefinition(key: 'motherLastName', label: 'Mother Last Name', type: 'text', isDefault: true),
];

List<FieldDefinition> suggestedFields() => const [
  FieldDefinition(key: 'email', label: 'Email', type: 'email'),
  FieldDefinition(key: 'profession', label: 'Profession', type: 'text'),
  FieldDefinition(key: 'placeOfBirth', label: 'Place of Birth', type: 'text'),
  FieldDefinition(key: 'timeOfBirth', label: 'Time of Birth', type: 'time'),
  FieldDefinition(key: 'hobby', label: 'Hobby', type: 'text'),
  FieldDefinition(key: 'dod', label: 'Date of Death', type: 'date'),
  FieldDefinition(key: 'netWorth', label: 'Net Worth', type: 'number', sensitive: true),
  FieldDefinition(key: 'residenceArea', label: 'Residence Area', type: 'text'),
  FieldDefinition(key: 'residenceAddress', label: 'Residence Address', type: 'textarea', sensitive: true),
  FieldDefinition(key: 'mobile', label: 'Mobile', type: 'phone', sensitive: true),
  FieldDefinition(key: 'caste', label: 'Caste', type: 'text'),
  FieldDefinition(key: 'religion', label: 'Religion', type: 'text'),
  FieldDefinition(key: 'gotra', label: 'Gotra', type: 'text'),
  FieldDefinition(key: 'naadi', label: 'Naadi', type: 'text'),
  FieldDefinition(key: 'height', label: 'Height (cm)', type: 'number'),
  FieldDefinition(key: 'weight', label: 'Weight (kg)', type: 'number'),
];

Map<String, Map<String, dynamic>> seedStore() {
  const uuid = Uuid();
  final famId = uuid.v4();
  final schemaId = uuid.v4();
  final m1 = uuid.v4();
  final m2 = uuid.v4();
  final m3 = uuid.v4();
  final m4 = uuid.v4();

  final family = Family(
    id: famId,
    name: 'Sample Family',
    createdBy: seedUserId,
    memberUserIds: [seedUserId, seedEditorId, seedViewerId],
    roles: {seedUserId: 'owner', seedEditorId: 'editor', seedViewerId: 'viewer'},
    settings: const FamilySettings(
      photoShape: 'circle',
      genderColors: {
        'male': '#2E86DE',
        'female': '#E84393',
        'other': '#8E44AD',
      },
    ),
    fieldSchemaId: schemaId,
  );

  final schema = FieldSchema(id: schemaId, familyId: famId, fields: [...defaultFields(), ...suggestedFields()], version: 1);

  final members = [
    FamilyMember(id: m1, familyId: famId, schemaVersion: 1, data: {'firstName': 'Ramchandra', 'lastName': 'Patne', 'gender': 'male', 'dob': '1950-01-01', 'profession': 'Farmer'}, relations: MemberRelations(childrenIds: [m3]), createdBy: seedUserId, lastEditedBy: seedUserId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    FamilyMember(id: m2, familyId: famId, schemaVersion: 1, data: {'firstName': 'Saraswati', 'lastName': 'Patne', 'gender': 'female', 'dob': '1955-05-05', 'profession': 'Teacher'}, relations: MemberRelations(spouseIds: [m1], childrenIds: [m3]), createdBy: seedUserId, lastEditedBy: seedUserId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    FamilyMember(id: m3, familyId: famId, schemaVersion: 1, data: {'firstName': 'Vinod', 'lastName': 'Patne', 'gender': 'male', 'dob': '1980-08-15', 'profession': 'Engineer'}, relations: MemberRelations(fatherId: m1, motherId: m2, childrenIds: [m4]), createdBy: seedUserId, lastEditedBy: seedUserId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    FamilyMember(id: m4, familyId: famId, schemaVersion: 1, data: {'firstName': 'Aarav', 'lastName': 'Patne', 'gender': 'male', 'dob': '2010-10-10'}, relations: MemberRelations(fatherId: m3), createdBy: seedUserId, lastEditedBy: seedUserId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];

  return {
    'families': {famId: family.toJson()},
    'schemas': {schemaId: schema.toJson()},
    'members': {for (final m in members) m.id: m.toJson()},
  };
}
