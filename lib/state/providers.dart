import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import '../data/mock/mock_family_repository.dart';
import '../data/repositories/family_repository.dart';
import '../models/family.dart';
import '../models/family_member.dart';
import '../models/field_definition.dart';
import '../models/user.dart';

final repositoryProvider = Provider<FamilyRepository>((ref) => throw UnimplementedError());
final currentUserProvider = StreamProvider<AppUser?>((ref) => ref.watch(repositoryProvider).watchCurrentUser());
final familiesProvider = StreamProvider<List<Family>>((ref) => ref.watch(repositoryProvider).watchFamiliesForCurrentUser());
final familyProvider = StreamProvider.family<Family?, String>((ref, id) => ref.watch(repositoryProvider).watchFamily(id));
final schemaProvider = StreamProvider.family<FieldSchema?, String>((ref, id) => ref.watch(repositoryProvider).watchSchema(id));
final membersProvider = StreamProvider.family<List<FamilyMember>, String>((ref, id) => ref.watch(repositoryProvider).watchMembers(id));
final invitesProvider = StreamProvider.family<List<String>, String>((ref, id) => ref.watch(repositoryProvider).watchPendingInvites(id));
Future<MockFamilyRepository> buildRepository() async { final r = MockFamilyRepository(); await r.init(); return r; }

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

