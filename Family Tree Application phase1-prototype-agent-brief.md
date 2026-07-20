# PHASE 1 — Family Tree App: Interactive Prototype
### Agent Build Brief

> **How to use this file:** Paste this entire document as the initial task for your coding agent (e.g., Claude Code). Once the agent completes the initial build, give it plain follow-up messages for UI/look-and-feel changes — see Section 8 ("Change Request Protocol") for how those should be handled.
> **Pairs with:** `phase2-backend-agent-brief.md` (do not build that yet — this phase must be approved first, since its data contracts and locked visual design become Phase 2's binding input).

---

## 1. Role & Mission

You are an autonomous coding agent. Your task is to build a **fully interactive, click-through prototype** of a cross-platform Family Tree application. This prototype:
- Uses **mock/local data only** — no real backend, no real Google login, no real database.
- Must look, feel, and behave like the finished product, so the user can evaluate it and request UI/style changes iteratively.
- Must be architected so that swapping the mock data layer for a real backend later (Phase 2) requires **no changes to any screen/widget** — only a new implementation of one repository interface.

Read this entire brief before writing any code.

---

## 2. Locked Technical Decisions

| Concern | Decision | Why |
|---|---|---|
| Framework | **Flutter** (latest stable 3.x) | One codebase → Android, iOS, tablet, Windows, macOS, Web |
| State management | **Riverpod** | Clean DI; trivial to swap mock repository for real one in Phase 2 |
| Routing | **go_router** | Deep-linkable screens, works identically across platforms |
| Local mock persistence | **Hive** | Lightweight embedded store so mock data survives app restarts; works on mobile, desktop, and web |
| Photo zoom viewer | **photo_view** package | Pinch-to-zoom / scroll-to-zoom out of the box |
| Image selection (mock) | **image_picker** (mobile) / **file_picker** (desktop/web) | Platform-appropriate photo selection without a real upload backend |
| UUIDs | **uuid** package (v4) | Every member/family/media record gets a UUID at creation, matching the eventual MongoDB `_id` scheme |

Platform setup commands to run once:
```bash
flutter config --enable-windows-desktop --enable-macos-desktop
flutter create family_tree_app
```

---

## 3. Ground-Truth Data Model

Define these as plain Dart classes with `toJson`/`fromJson` (or use `freezed` + `json_serializable` if you prefer — your choice, but keep the JSON shape below **exact**, since Phase 2's REST API will mirror it field-for-field).

```dart
// lib/models/user.dart
class AppUser {
  final String id;            // uuid
  final String email;
  final String name;
  final String? avatarUrl;
}

// lib/models/family.dart
class Family {
  final String id;            // uuid
  final String name;
  final String createdBy;     // user id
  final List<String> memberUserIds;
  final Map<String, String> roles;   // userId -> "owner" | "editor" | "viewer"
  final FamilySettings settings;
  final String fieldSchemaId;
}

class FamilySettings {
  final String photoShape;    // "circle" | "square" | "rounded-square" | "hexagon"
  final Map<String, String> genderColors; // "male"/"female"/"other" -> hex color
}

// lib/models/field_definition.dart
class FieldDefinition {
  final String key;           // e.g. "firstName"
  final String label;         // e.g. "First Name"
  final String type;          // "text" | "textarea" | "number" | "date" | "time" | "email" | "phone" | "enum" | "image"
  final bool mandatory;
  final bool isDefault;       // true for the 9 locked default fields
  final bool sensitive;       // true = show lock icon, hide-by-default in views
  final List<String>? options; // for type == "enum"
}

class FieldSchema {
  final String id;            // uuid
  final String familyId;
  final List<FieldDefinition> fields;
  final int version;
}

// lib/models/family_member.dart
class FamilyMember {
  final String id;            // uuid — THE canonical linking id
  final String familyId;
  final int schemaVersion;
  final Map<String, dynamic> data;   // dynamic field values, keyed by FieldDefinition.key
  final String? photoMediaId;        // uuid, links to MediaRef
  final MemberRelations relations;
  final String createdBy;
  final String lastEditedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MemberRelations {
  final String? fatherId;     // uuid or null
  final String? motherId;
  final List<String> spouseIds;
  final List<String> childrenIds;
}

// lib/models/media_ref.dart
class MediaRef {
  final String id;            // uuid
  final String memberId;
  final String localPath;     // Phase 1 only: local file path or base64 blob
  final String mimeType;
}
```

**Default fields (locked, always present, in this order):** `photo`, `firstName` (mandatory), `lastName`, `dob`, `gender`, `fatherFirstName`, `fatherLastName`, `motherFirstName`, `motherLastName`.

**Suggested fields (offered as a checklist during family setup, none selected by default):** `email`, `profession`, `placeOfBirth`, `timeOfBirth`, `hobby`, `dod` (date of death), `netWorth` (sensitive), `residenceArea`, `residenceAddress` (sensitive), `mobile` (sensitive), `caste`, `religion`, `gotra`, `naadi`, `height`, `weight`.

**Custom fields:** user can also type a brand-new label + pick a type — this appends a new `FieldDefinition` with `isDefault: false, isCustom: true`.

---

## 4. Explicit Non-Goals for This Phase

Do **not** build these now — they are Phase 2 concerns. Stub them convincingly instead:
- Real Google OAuth → show a "Sign in with Google" button that, on tap, instantly logs in as a hardcoded mock user (no real auth call).
- Real MongoDB / network calls → all data lives in Hive on-device.
- Real multi-device realtime sync → simulate collaboration with a small "Switch active user" dev-menu dropdown (Owner / Editor / Viewer) so the user can see how permissions and an activity/audit feed *look*, without real concurrency.
- Real file storage → store photo bytes as a local file path or base64 string in the mock repository.

---

## 5. Design Token System (this is your lever for "look and feel" requests)

Centralize every visual decision so future style change-requests are one-file edits:

```dart
// lib/theme/design_tokens.dart
class DesignTokens {
  static const primaryColor = Color(0xFF2E86DE);
  static const genderBorderColors = {
    'male': Color(0xFF2E86DE),
    'female': Color(0xFFE84393),
    'other': Color(0xFF8E44AD),
  };
  static const defaultPhotoShape = 'circle'; // circle | square | rounded-square | hexagon
  static const avatarBorderWidth = 3.0;
  static const spacingUnit = 8.0;
  static const radiusSmall = 8.0;
  static const radiusMedium = 16.0;
  // typography scale, elevation, etc. — add as needed, but keep everything HERE
}
```
Build `lib/theme/app_theme.dart` (`ThemeData`) entirely from these tokens. Every widget must read colors/shapes/spacing from tokens or from `Family.settings` — never hardcode a color or radius inline in a screen file.

---

## 6. Screens & Required Behavior

### P0 — Required for prototype approval
1. **Mock Sign-In** — "Continue with Google" button → instant mock login.
2. **Family List / Create Family** — list families the mock user belongs to; "+ Create Family" flow.
3. **Field Schema Setup** (shown once per new family) — default 9 fields shown as locked/checked; suggested fields as a multi-select chip list; "+ Add custom field" (label + type picker); "Continue" persists the `FieldSchema`.
4. **Tree Canvas** — pannable/zoomable node-link diagram. Each node = `MemberAvatar` (shape from settings, gender-colored border, greyscale + thin ring if `dod` is set). Tap empty canvas area → "+ Add member". Search bar with autocomplete that centers the tree on a match.
5. **Member Profile (view)** — shows populated fields per current schema, respects `sensitive` fields (blurred/hidden behind a tap-to-reveal), tapping the photo opens the zoom viewer.
6. **Member Edit Form** — dynamically rendered input per `FieldDefinition.type`; enforces `mandatory`; father/mother name fields offer a simple autocomplete against existing members in the family (exact/substring match is enough for Phase 1) with a "Link as parent?" confirm chip that sets `relations.fatherId`/`motherId` when confirmed.
7. **Photo Zoom Viewer** — full-screen, pinch/scroll zoom, swipe to dismiss.
8. **Appearance Settings** — live picker for `photoShape` (4 options, shown as preview thumbnails) and each gender's border color (color picker) — changes should reflect on the Tree Canvas immediately.
9. **Collaborators (mocked)** — list of family members with role badges; "Invite" opens a form that just adds a fake pending-invite row (no email actually sent).

### P1 — Nice-to-have if time permits (do not block delivery on these)
- Simple timeline view (members plotted by birth year).
- Basic "how are X and Y related" path display using the `relations` graph (BFS).
- Printable/exportable tree image (share sheet with a rendered PNG of the canvas).

---

## 7. Mock Data Seed

On first launch, seed Hive with one sample family, 3 generations (8–10 members), a couple of marriages, at least one member with `dod` set, and placeholder avatar images (use `https://i.pravatar.cc/300?u={uuid}` or local bundled placeholder assets — your call) so the tree renders meaningfully with no user input.

---

## 8. Change Request Protocol

After the initial build, the user will send short, plain-language UI/style requests. Handle them like this:

| Request pattern | Where you make the change |
|---|---|
| Color / shape / spacing / border-width tweak | `design_tokens.dart` only |
| "Change default photo shape to X" | `DesignTokens.defaultPhotoShape` + `FamilySettings` initial value |
| Add/rename/reorder a field | `FieldDefinition` seed list + schema setup screen |
| Rearrange a screen's layout | The specific screen file only — do not touch unrelated screens |
| New screen / feature | Confirm it's additive (doesn't break P0 flows) before building |

After each change: rebuild, verify no errors on at least web + one other target, and reply with a short summary (what changed, which file) — not a full re-explanation of the app.

---

## 9. Project Structure

```
lib/
  main.dart
  app.dart
  theme/
    design_tokens.dart
    app_theme.dart
  models/
    user.dart  family.dart  field_definition.dart  family_member.dart  media_ref.dart
  data/
    mock/mock_family_repository.dart
    mock/seed_data.dart
    repositories/family_repository.dart      // abstract interface — Phase 2 implements this for real
  state/
    providers.dart
  screens/
    auth/mock_login_screen.dart
    family/family_list_screen.dart
    family/create_family_screen.dart
    family/field_schema_setup_screen.dart
    tree/tree_canvas_screen.dart
    tree/widgets/member_avatar.dart
    tree/widgets/tree_edge_painter.dart
    member/member_profile_screen.dart
    member/member_edit_form_screen.dart
    member/photo_zoom_viewer.dart
    settings/appearance_settings_screen.dart
    settings/collaborators_screen.dart
  widgets/
    dynamic_field_input.dart
    app_scaffold.dart
```

The `FamilyRepository` abstract interface is the single most important file in this project — every screen must talk to data only through it, never directly to Hive.

---

## 10. Definition of Done

- [ ] Runs cleanly via `flutter run -d chrome`, `-d windows` (or `-d macos`), and an Android/iOS simulator.
- [ ] Responsive: usable at phone width (<600dp), tablet (600–1024dp), and desktop (>1024dp) — side-nav on wide screens, bottom-nav on phones.
- [ ] All P0 screens implemented and navigable end-to-end.
- [ ] Mock data persists across app restarts (Hive).
- [ ] Gender border colors and photo shape both change live from Appearance Settings and are reflected on the Tree Canvas.
- [ ] Tapping any avatar opens the pinch-zoom viewer.
- [ ] A short `README.md` explains what's mocked, what isn't, and how to run each target platform.
