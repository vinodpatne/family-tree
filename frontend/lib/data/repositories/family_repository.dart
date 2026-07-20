import '../../models/family.dart';
import '../../models/family_member.dart';
import '../../models/field_definition.dart';
import '../../models/media_ref.dart';
import '../../models/user.dart';

abstract class FamilyRepository {
  Future<void> init();
  Stream<AppUser?> watchCurrentUser();
  Future<void> signInMock({required String role});
  Future<void> signInWithGoogle({String? idToken, String? email, String? name, String? avatarUrl, String? googleId});
  Future<void> signOut();
  Future<void> switchActiveUserRole(String role);
  Stream<List<Family>> watchFamiliesForCurrentUser();
  Stream<Family?> watchFamily(String familyId);
  Future<Family> createFamily(String name);
  Future<void> saveFamily(Family family);
  Stream<FieldSchema?> watchSchema(String familyId);
  Future<void> saveSchema(FieldSchema schema);
  Stream<List<FamilyMember>> watchMembers(String familyId);
  Future<FamilyMember?> getMember(String memberId);
  Future<void> saveMember(FamilyMember member);
  Future<void> deleteMember(String memberId);
  Stream<List<MediaRef>> watchMedia(String memberId);
  Future<void> saveMedia(MediaRef media);
  Stream<List<String>> watchPendingInvites(String familyId);
  Future<void> inviteCollaborator(String familyId, String email);
}
