import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../models/family.dart';
import '../../models/family_member.dart';
import '../../models/field_definition.dart';
import '../../models/media_ref.dart';
import '../../models/user.dart';
import '../repositories/family_repository.dart';

class BackendUnavailableException implements Exception {
  final String message;
  BackendUnavailableException([this.message = 'Please try logging in after some time.']);
  @override
  String toString() => message;
}

class ApiFamilyRepository implements FamilyRepository {
  final String baseUrl;
  late Box _box;
  final _tick = StreamController<void>.broadcast();

  String? _jwtToken;
  AppUser? _currentUser;

  ApiFamilyRepository({this.baseUrl = 'http://localhost:8080'});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
      };

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('My Family Tree');
    _jwtToken = _box.get('jwtToken');
    final userMap = _box.get('currentUser');
    if (userMap != null) {
      _currentUser = AppUser.fromJson(Map<String, dynamic>.from(userMap));
    }
  }

  void _notify() => _tick.add(null);

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    yield _currentUser;
    yield* _tick.stream.map((_) => _currentUser);
  }

  @override
  Future<void> signInMock({required String role}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': '$role@example.com',
          'name': 'Mock ${role[0].toUpperCase()}${role.substring(1)}',
          'role': role,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['jwt'];
        _currentUser = AppUser.fromJson(Map<String, dynamic>.from(data['user']));
        await _box.put('jwtToken', _jwtToken);
        await _box.put('currentUser', data['user']);
        _notify();
      } else {
        await signOut();
        throw BackendUnavailableException();
      }
    } catch (e) {
      await signOut();
      throw BackendUnavailableException();
    }
  }

  @override
  Future<void> signInWithGoogle({String? idToken, String? email, String? name, String? avatarUrl, String? googleId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (idToken != null) 'idToken': idToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (googleId != null) 'googleId': googleId,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['jwt'];
        _currentUser = AppUser.fromJson(Map<String, dynamic>.from(data['user']));
        await _box.put('jwtToken', _jwtToken);
        await _box.put('currentUser', data['user']);
        _notify();
      } else {
        await signOut();
        throw BackendUnavailableException();
      }
    } catch (e) {
      await signOut();
      throw BackendUnavailableException();
    }
  }

  @override
  Future<void> switchActiveUserRole(String role) => signInMock(role: role);

  @override
  Future<void> signOut() async {
    _jwtToken = null;
    _currentUser = null;
    await _box.delete('jwtToken');
    await _box.delete('currentUser');
    _notify();
  }

  @override
  Stream<List<Family>> watchFamiliesForCurrentUser() async* {
    yield await _fetchFamilies();
    yield* _tick.stream.asyncMap((_) => _fetchFamilies());
  }

  Future<List<Family>> _fetchFamilies() async {
    if (_currentUser == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/families'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => Family.fromJson(Map<String, dynamic>.from(e))).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await signOut();
      }
    } catch (e) {
      debugPrint("Backend connection error: $e");
      await signOut();
    }
    return [];
  }

  @override
  Stream<Family?> watchFamily(String familyId) async* {
    yield await _fetchFamily(familyId);
    yield* _tick.stream.asyncMap((_) => _fetchFamily(familyId));
  }

  Future<Family?> _fetchFamily(String familyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/families/$familyId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return Family.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
      }
    } catch (e) {
      debugPrint("Error fetching family $familyId: $e");
    }
    return null;
  }

  @override
  Future<Family> createFamily(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/families'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final family = Family.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
      _notify();
      return family;
    }
    throw Exception('Failed to create family: ${response.body}');
  }

  @override
  Future<void> saveFamily(Family family) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/families/${family.id}/settings'),
      headers: _headers,
      body: jsonEncode(family.settings.toJson()),
    );
    if (response.statusCode == 200) {
      _notify();
    } else {
      throw Exception('Failed to save family settings: ${response.body}');
    }
  }

  @override
  Future<void> deleteFamily(String familyId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/families/$familyId'),
      headers: _headers,
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      _notify();
    } else {
      throw Exception('Failed to delete family: ${response.body}');
    }
  }

  @override
  Stream<FieldSchema?> watchSchema(String familyId) async* {
    yield await _fetchSchema(familyId);
    yield* _tick.stream.asyncMap((_) => _fetchSchema(familyId));
  }

  Future<FieldSchema?> _fetchSchema(String familyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/families/$familyId/schema'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return FieldSchema.fromJson(Map<String, dynamic>.from(jsonDecode(response.body)));
      }
    } catch (e) {
      debugPrint("Error fetching schema for family $familyId: $e");
    }
    return null;
  }

  @override
  Future<void> saveSchema(FieldSchema schema) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/families/${schema.familyId}/schema/fields'),
      headers: _headers,
      body: jsonEncode({
        'fields': schema.fields.map((e) => e.toJson()).toList(),
      }),
    );
    if (response.statusCode == 200) {
      _notify();
    } else {
      throw Exception('Failed to save schema: ${response.body}');
    }
  }

  @override
  Stream<List<FamilyMember>> watchMembers(String familyId) async* {
    yield await _fetchMembers(familyId);
    yield* _tick.stream.asyncMap((_) => _fetchMembers(familyId));
  }

  Future<List<FamilyMember>> _fetchMembers(String familyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/families/$familyId/members'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => FamilyMember.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (e) {
      debugPrint("Error fetching members for $familyId: $e");
    }
    return [];
  }

  @override
  Future<FamilyMember?> getMember(String memberId) async {
    // Look up from members endpoint or fetch family members
    return null;
  }

  @override
  Future<void> saveMember(FamilyMember member) async {
    // Check if member already exists on server by attempting update
    final patchBody = {
      'data': member.data,
      'relations': member.relations.toJson(),
      if (member.photoMediaId != null) 'photoBase64': member.photoMediaId,
    };

    var response = await http.patch(
      Uri.parse('$baseUrl/api/members/${member.id}'),
      headers: _headers,
      body: jsonEncode(patchBody),
    );

    if (response.statusCode == 404) {
      // Member doesn't exist yet -> POST create
      response = await http.post(
        Uri.parse('$baseUrl/api/families/${member.familyId}/members'),
        headers: _headers,
        body: jsonEncode({
          'data': member.data,
          'relations': member.relations.toJson(),
        }),
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      _notify();
    } else {
      throw Exception('Failed to save member: ${response.body}');
    }
  }

  @override
  Future<void> importMembers(String familyId, List<Map<String, dynamic>> membersBatch) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/families/$familyId/members/batch'),
      headers: _headers,
      body: jsonEncode(membersBatch),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to import members: ${response.body}');
    }
    _notify();
  }

  @override
  Future<void> deleteMember(String memberId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/members/$memberId'),
      headers: _headers,
    );
    if (response.statusCode == 204 || response.statusCode == 200) {
      _notify();
    } else {
      throw Exception('Failed to delete member: ${response.body}');
    }
  }

  @override
  Stream<List<MediaRef>> watchMedia(String memberId) async* {
    yield [];
  }

  @override
  Future<void> saveMedia(MediaRef media) async {}

  @override
  Stream<List<String>> watchPendingInvites(String familyId) async* {
    yield await _fetchInvites(familyId);
    yield* _tick.stream.asyncMap((_) => _fetchInvites(familyId));
  }

  Future<List<String>> _fetchInvites(String familyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/families/$familyId/invite'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint("Error fetching invites: $e");
    }
    return [];
  }

  @override
  Future<void> inviteCollaborator(String familyId, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/families/$familyId/invite'),
      headers: _headers,
      body: jsonEncode({'email': email, 'role': 'viewer'}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      _notify();
    } else {
      throw Exception('Failed to invite collaborator: ${response.body}');
    }
  }
}
