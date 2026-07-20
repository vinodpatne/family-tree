import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/auth/login_screen.dart';
import 'screens/family/create_family_screen.dart';
import 'screens/family/family_list_screen.dart';
import 'screens/family/field_schema_setup_screen.dart';
import 'screens/member/member_edit_form_screen.dart';
import 'screens/member/photo_zoom_viewer.dart';
import 'screens/settings/appearance_settings_screen.dart';
import 'screens/settings/collaborators_screen.dart';
import 'screens/tree/tree_canvas_screen.dart';
import 'state/providers.dart';
import 'theme/app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final u = ref.read(currentUserProvider).valueOrNull;
      debugPrint("REDIRECT: user = $u, path = ${state.matchedLocation}");
      return u == null && state.matchedLocation != '/login' ? '/login' : null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const FamilyListScreen()),
      GoRoute(path: '/family/new', builder: (_, __) => const CreateFamilyScreen()),
      GoRoute(path: '/family/:fid/schema', builder: (_, s) => FieldSchemaSetupScreen(familyId: s.pathParameters['fid']!)),
      GoRoute(path: '/family/:fid/tree', builder: (_, s) => TreeCanvasScreen(familyId: s.pathParameters['fid']!)),
      GoRoute(path: '/family/:fid/member/new', builder: (_, s) => MemberEditFormScreen(familyId: s.pathParameters['fid']!, initialFatherId: s.uri.queryParameters['fatherId'], initialMotherId: s.uri.queryParameters['motherId'], initialSpouseId: s.uri.queryParameters['spouseId'], initialChildId: s.uri.queryParameters['childId'])),
      GoRoute(path: '/family/:fid/member/:mid', builder: (_, s) => MemberEditFormScreen(familyId: s.pathParameters['fid']!, memberId: s.pathParameters['mid'])),
      GoRoute(path: '/photo', builder: (_, s) => PhotoZoomViewer(imageUrl: s.uri.queryParameters['url'] ?? '')),
      GoRoute(path: '/family/:fid/settings/appearance', builder: (_, s) => AppearanceSettingsScreen(familyId: s.pathParameters['fid']!)),
      GoRoute(path: '/family/:fid/settings/collaborators', builder: (_, s) => CollaboratorsScreen(familyId: s.pathParameters['fid']!)),
    ],
  );
});

class FamilyTreeApp extends ConsumerWidget {
  const FamilyTreeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Family Tree',
      theme: buildAppTheme(isDark: false),
      darkTheme: buildAppTheme(isDark: true),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}
