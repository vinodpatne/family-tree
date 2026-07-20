import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/family.dart';
import '../../models/family_member.dart';
import '../../models/field_definition.dart';
import '../../models/media_ref.dart';
import '../../models/user.dart';
import '../repositories/family_repository.dart';
import 'seed_data.dart';

class LocalFamilyRepository implements FamilyRepository {
  late Box _box;
  final _tick = StreamController<void>.broadcast();
  final _uuid = const Uuid();
  @override Future<void> init() async { await Hive.initFlutter(); _box = await Hive.openBox('family_tree_seed_v1'); if (!_box.containsKey('seeded')) { final s = seedStore(); for (final e in s.entries) { await _box.put(e.key, e.value); } await _box.put('seeded', true); } }
  void _notify() => _tick.add(null);
  T _read<T>(String key, T fallback) => (_box.get(key) as T?) ?? fallback;
  @override Stream<AppUser?> watchCurrentUser() async* { yield _user(); yield* _tick.stream.map((_) => _user()); }
  AppUser? _user() { final role = _box.get('role', defaultValue: 'owner'); final id = role == 'editor' ? seedEditorId : role == 'viewer' ? seedViewerId : seedUserId; return _box.get('signedIn', defaultValue: false) ? AppUser(id: id, email: '$role@example.com', name: 'User ${role[0].toUpperCase()}${role.substring(1)}', avatarUrl: 'https://i.pravatar.cc/100?u=$id') : null; }
  @override Future<void> signInMock({required String role}) async { await _box.put('role', role); await _box.put('signedIn', true); _notify(); }
  @override Future<void> signInWithGoogle({String? idToken, String? email, String? name, String? avatarUrl, String? googleId}) async { await signInMock(role: 'owner'); }
  @override Future<void> switchActiveUserRole(String role) => signInMock(role: role);
  @override Future<void> signOut() async { await _box.put('signedIn', false); _notify(); }
  @override Stream<List<Family>> watchFamiliesForCurrentUser() async* { List<Family> read() => _read<Map>('families', {}).values.map((e) => Family.fromJson(Map<String, dynamic>.from(e))).toList(); yield read(); yield* _tick.stream.map((_) => read()); }
  @override Stream<Family?> watchFamily(String familyId) async* { Family? read() { final e = _read<Map>('families', {})[familyId]; return e == null ? null : Family.fromJson(Map<String, dynamic>.from(e)); } yield read(); yield* _tick.stream.map((_) => read()); }
  @override Future<Family> createFamily(String name) async { final user = _user()!; final fid = _uuid.v4(); final sid = _uuid.v4(); final fam = Family(id: fid, name: name, createdBy: user.id, memberUserIds: [user.id], roles: {user.id: 'owner'}, settings: FamilySettings(photoShape: 'circle', genderColors: const {'male':'#2E86DE','female':'#E84393','other':'#8E44AD'}), fieldSchemaId: sid); final families = Map.of(_read<Map>('families', {})); families[fid] = fam.toJson(); await _box.put('families', families); await saveSchema(FieldSchema(id: sid, familyId: fid, fields: defaultFields(), version: 1)); _notify(); return fam; }
  @override Future<void> saveFamily(Family family) async { final m = Map.of(_read<Map>('families', {})); m[family.id] = family.toJson(); await _box.put('families', m); _notify(); }
  @override Stream<FieldSchema?> watchSchema(String familyId) async* { FieldSchema? read() { final schemas = _read<Map>('schemas', {}); for (final e in schemas.values) { final s = FieldSchema.fromJson(Map<String, dynamic>.from(e)); if (s.familyId == familyId) return s; } return null; } yield read(); yield* _tick.stream.map((_) => read()); }
  @override Future<void> saveSchema(FieldSchema schema) async { final m = Map.of(_read<Map>('schemas', {})); m[schema.id] = schema.toJson(); await _box.put('schemas', m); _notify(); }
  @override Stream<List<FamilyMember>> watchMembers(String familyId) async* { List<FamilyMember> read() => _read<Map>('members', {}).values.map((e) => FamilyMember.fromJson(Map<String, dynamic>.from(e))).where((m) => m.familyId == familyId).toList(); yield read(); yield* _tick.stream.map((_) => read()); }
  @override Future<FamilyMember?> getMember(String memberId) async { final all = _read<Map>('members', {}); final e = all[memberId]; return e == null ? null : FamilyMember.fromJson(Map<String, dynamic>.from(e)); }
  @override Future<void> saveMember(FamilyMember member) async { final m = Map.of(_read<Map>('members', {})); m[member.id] = member.toJson(); await _box.put('members', m); _notify(); }
  @override Future<void> deleteMember(String memberId) async { final m = Map.of(_read<Map>('members', {})); m.remove(memberId); await _box.put('members', m); _notify(); }
  @override Stream<List<MediaRef>> watchMedia(String memberId) async* { yield []; }
  @override Future<void> saveMedia(MediaRef media) async {}
  @override Stream<List<String>> watchPendingInvites(String familyId) async* { yield []; }
  @override Future<void> inviteCollaborator(String familyId, String email) async {}
}
