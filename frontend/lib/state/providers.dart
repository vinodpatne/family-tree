import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:hive_flutter/hive_flutter.dart';
import '../data/api/api_family_repository.dart';
import '../data/repositories/family_repository.dart';
import '../models/family.dart';
import '../models/family_member.dart';
import '../models/field_definition.dart';
import '../models/user.dart';

final repositoryProvider = Provider<FamilyRepository>((ref) => throw UnimplementedError());
final currentUserProvider = StreamProvider<AppUser?>((ref) => ref.watch(repositoryProvider).watchCurrentUser());
final familiesProvider = StreamProvider<List<Family>>((ref) => ref.watch(repositoryProvider).watchFamiliesForCurrentUser());
final familyProvider = StreamProvider.family<Family?, String>((ref, id) => ref.watch(repositoryProvider).watchFamily(id));
final schemaProvider = StreamProvider.family<FieldSchema?, String>((ref, familyId) => ref.watch(repositoryProvider).watchSchema(familyId));
final membersProvider = StreamProvider.family<List<FamilyMember>, String>((ref, id) => ref.watch(repositoryProvider).watchMembers(id));
final invitesProvider = StreamProvider.family<List<String>, String>((ref, id) => ref.watch(repositoryProvider).watchPendingInvites(id));

Future<FamilyRepository> buildRepository() async {
  final apiRepo = ApiFamilyRepository(baseUrl: 'http://localhost:8080');
  await apiRepo.init();
  return apiRepo;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  static const String _key = 'theme_mode';

  Future<void> _loadSavedTheme() async {
    try {
      final box = await Hive.openBox('theme_preferences');
      final saved = box.get(_key) as String?;
      if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'system') {
        state = ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = await Hive.openBox('theme_preferences');
      if (mode == ThemeMode.dark) {
        await box.put(_key, 'dark');
      } else if (mode == ThemeMode.light) {
        await box.put(_key, 'light');
      } else {
        await box.put(_key, 'system');
      }
    } catch (_) {}
  }
}

