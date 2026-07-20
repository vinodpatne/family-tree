# PHASE 2 — Family Tree App: Backend Build
### Agent Build Brief

> **How to use this file:** Paste this entire document as the task for your coding agent once Phase 1's prototype has been reviewed and its UI/data model are approved. This brief is self-contained — the agent does not need the Phase 1 project open, but should treat the Dart model shapes below as fixed contracts, not suggestions.
> **Pairs with:** `phase1-prototype-agent-brief.md` (source of truth for the data model and UX this API must serve).

---

## 1. Role & Mission

You are an autonomous coding agent. Your task is to build the **production backend** for the Family Tree application: a Java Spring Boot REST + WebSocket API backed by MongoDB, with schema/index/seed management via Flyway, real Google OAuth login, real photo storage, and role-based multi-user collaboration.

Read this entire brief before writing any code. Treat Section 3 (data contracts) as binding — every DTO field name must match exactly what's listed, since a Flutter client built against these exact shapes already exists.

---

## 2. Locked Technical Decisions

| Concern | Decision |
|---|---|
| Language / runtime | Java 21 LTS, Spring Boot 3.x |
| Web layer | Spring Web (MVC, servlet-based — simpler ops than WebFlux, and fine at this scale) |
| Persistence | Spring Data MongoDB |
| Auth | Spring Security + OAuth2 Client (Google), backend issues its own short-lived JWT after Google login succeeds |
| Realtime collaboration | Spring WebSocket + STOMP, one topic per family: `/topic/family/{familyId}` |
| Photo storage | MongoDB **GridFS** via `GridFsTemplate` (keeps everything in one datastore; swap for S3 later only if photo volume becomes a real cost/perf concern) |
| Schema/index/seed migrations | **Flyway with MongoDB Native Connectors** (see Section 6 — read the caveats, this is a newer Flyway capability) |
| Validation | Jakarta Bean Validation (`@NotBlank`, custom validator for `mandatory` dynamic fields) |
| Build tool | Maven |

---

## 3. Data Contracts (must match the Flutter prototype exactly)

### 3.1 MongoDB collections
```
users
families
field_definition_templates      // NEW vs. the per-family field_definitions — see 3.2
field_definitions               // one per family, cloned from the template at family creation
family_members
media                           // GridFS file metadata lives here alongside gridfs chunks/files buckets
invitations
audit_log
```

### 3.2 Why a template collection
The original design had `field_definitions` keyed 1:1 with `families`. To make "default + suggested fields" a manageable, versionable thing instead of copy-pasted JSON in every family, this phase introduces **one global `field_definition_templates` document** (seeded by Flyway — see Section 6.4) containing the 9 default + 16 suggested field definitions. `FieldSchemaService.createDefaultSchemaForFamily(familyId)` clones this template into a new `field_definitions` document whenever a family is created. Families can then freely add custom fields on top without touching the template.

### 3.3 Document shapes (Java, `@Document` classes)

```java
@Document("family_members")
public class FamilyMemberDocument {
    @Id private String id;                 // UUID string, matches Flutter FamilyMember.id
    private String familyId;
    private int schemaVersion;
    private Map<String, Object> data;       // dynamic field values
    private String photoMediaId;
    private MemberRelations relations;      // { fatherId, motherId, spouseIds[], childrenIds[] }
    private String createdBy;
    private String lastEditedBy;
    private Instant createdAt;
    private Instant updatedAt;
}
```
Mirror the remaining documents (`UserDocument`, `FamilyDocument`, `FieldDefinitionDocument`, `InvitationDocument`, `AuditLogEntry`) directly from Section 3 of the original design doc / Section 3 of the Phase 1 brief — field names must match 1:1, only the language changes (Dart → Java).

### 3.4 Repository → Endpoint contract table
This is the exact mapping the Flutter app's real `FamilyRepository` implementation (its Phase-3 integration task, not built here) will call. Build these endpoints to satisfy it:

| Prototype repository method | Real endpoint |
|---|---|
| `signInWithGoogle()` | `POST /api/auth/google` (body: Google ID token → returns `{ jwt, user }`) |
| `getFamilies()` | `GET /api/families` |
| `createFamily(name)` | `POST /api/families` |
| `getFieldSchema(familyId)` | `GET /api/families/{familyId}/schema` |
| `updateFieldSchema(familyId, fields)` | `PUT /api/families/{familyId}/schema/fields` |
| `getMembers(familyId)` | `GET /api/families/{familyId}/members` |
| `createMember(familyId, member)` | `POST /api/families/{familyId}/members` |
| `updateMember(memberId, patch)` | `PATCH /api/members/{memberId}` |
| `deleteMember(memberId)` | `DELETE /api/members/{memberId}` |
| `uploadPhoto(memberId, bytes)` | `POST /api/members/{memberId}/photo` (multipart) |
| `getPhoto(mediaId)` | `GET /api/media/{mediaId}` (streams GridFS bytes) |
| `inviteUser(familyId, email, role)` | `POST /api/families/{familyId}/invite` |
| `updateSettings(familyId, settings)` | `PUT /api/families/{familyId}/settings` |
| `subscribeToFamilyUpdates(familyId)` | `CONNECT /ws` then `SUBSCRIBE /topic/family/{familyId}` |

Example bodies:
```json
// POST /api/families/{familyId}/members
{
  "data": { "firstName": "Ravi", "lastName": "Rao", "dob": "1975-03-12", "gender": "male" },
  "relations": { "fatherId": null, "motherId": null, "spouseIds": [], "childrenIds": [] }
}
// → 201 Created
{
  "id": "b3f1...-uuid",
  "familyId": "...", "schemaVersion": 3,
  "data": { "...": "..." },
  "photoMediaId": null,
  "relations": { "...": "..." },
  "createdBy": "...", "lastEditedBy": "...",
  "createdAt": "2026-07-15T10:00:00Z", "updatedAt": "2026-07-15T10:00:00Z"
}
```

---

## 4. Package Structure

```
src/main/java/com/familytree/
  FamilyTreeApplication.java
  config/       SecurityConfig.java  WebSocketConfig.java  MongoIndexConfig.java  CorsConfig.java
  security/     GoogleOAuth2UserService.java  JwtService.java  JwtAuthFilter.java
  controller/   AuthController  FamilyController  FieldSchemaController  MemberController  MediaController  InvitationController
  service/      FamilyService  MemberService  FieldSchemaService  MediaService  InvitationService  RelationshipGraphService  AuditService
  repository/   UserRepository  FamilyRepository  FamilyMemberRepository  FieldDefinitionRepository  FieldDefinitionTemplateRepository  MediaMetaRepository  InvitationRepository  AuditLogRepository
  document/     (the @Document classes from 3.3)
  dto/          request/  response/
  ws/           FamilyCollabController.java   (STOMP @MessageMapping handlers)
  exception/    GlobalExceptionHandler.java
src/main/resources/
  application.yml
  db/migration/mongodb/
    V1__create_collections_and_indexes.js
    V2__seed_field_definition_template.js
  db/migration/mongodb-dev/            // dev/staging only — never point prod's flyway.locations here
    V3__seed_demo_family.js
flyway.toml
pom.xml
docker-compose.yml
```

`RelationshipGraphService` and `AuditService` are stubbed with a single working method each in this phase (BFS shortest-path between two member IDs; append-only audit write on every mutation) — they exist now so the Phase-1 "relationship path finder" and "activity feed" stretch ideas have a real backend to call into later.

---

## 5. Security

- Register Google as an OAuth2 client (`spring.security.oauth2.client.registration.google.client-id` / `client-secret` in `application.yml`, values from environment variables — never hardcoded).
- Flow: Flutter app gets a Google ID token client-side → sends it to `POST /api/auth/google` → `GoogleOAuth2UserService` verifies it against Google's tokeninfo endpoint → look up/create `UserDocument` → issue an app-level JWT (short-lived, e.g. 1 hour, plus a refresh token) → all subsequent requests carry `Authorization: Bearer <jwt>`, validated by `JwtAuthFilter`.
- Authorization is **family-scoped**, not global: every family-nested endpoint must check the caller's `roles[userId]` on that specific family (`owner` > `editor` > `viewer`) via `@PreAuthorize` + a custom `PermissionEvaluator`, not just "is logged in."
- Fields marked `sensitive: true` in the schema (net worth, address, mobile) — encrypt at rest with a field-level AES-GCM converter (Spring Data MongoDB `@ValueConverter` or a custom `MongoConverter`) using a key from a secrets manager / env var, not committed to source.
- Every mutating call writes one `AuditLogEntry` (who, what changed, before/after diff, timestamp) — this powers the "who changed what" transparency feature from the original design.

---

## 6. MongoDB Schema & Flyway Migrations

### 6.1 What's confirmed and current (verified July 2026)
Flyway (Redgate), from v11 onward, ships a **Native Connectors** engine that connects to MongoDB without going through JDBC. Two migration file types are supported, and — per Flyway's own docs — **cannot be mixed within one project**:
- **`.js`** — executed via `mongosh` (must be installed where Flyway runs); **not transactional**.
- **`.json`** — executed directly via the MongoDB API; **does support transactions**, but its exact required schema wasn't something this brief could verify with confidence — check Flyway's current MongoDB migration reference before committing to it. This brief uses `.js` throughout, since that's just standard mongosh syntax and is verifiable.

Flyway's own documentation describes MongoDB support as **"foundational"** (i.e., newer and still evolving) as of its 2026 release notes — some things aren't supported yet (e.g., locking the schema history table), and property/config names may shift between versions. **Before implementing, confirm current syntax at:**
- https://documentation.red-gate.com/fd/mongodb-341246448.html
- https://documentation.red-gate.com/flyway/reference/tutorials/tutorial-using-native-connectors-to-connect-to-mongodb

### 6.2 `flyway.toml` (starting point — verify keys against your installed Flyway version)
```toml
[environments.mongodb]
url = "mongodb://localhost:27017/familytree"
user = "flyway_migrator"
password = "${FLYWAY_MONGO_PASSWORD}"

[flyway]
environment = "mongodb"
locations = ["filesystem:./src/main/resources/db/migration/mongodb"]
```

### 6.3 `V1__create_collections_and_indexes.js`
```javascript
db.createCollection("users");
db.users.createIndex({ googleId: 1 }, { unique: true });
db.users.createIndex({ email: 1 }, { unique: true });

db.createCollection("families");
db.families.createIndex({ createdBy: 1 });

db.createCollection("field_definition_templates");

db.createCollection("field_definitions");
db.field_definitions.createIndex({ familyId: 1 }, { unique: true });

db.createCollection("family_members");
db.family_members.createIndex({ familyId: 1 });
db.family_members.createIndex({ familyId: 1, "data.firstName": 1, "data.lastName": 1 });

db.createCollection("media");
db.media.createIndex({ memberId: 1 });

db.createCollection("invitations");
db.invitations.createIndex({ token: 1 }, { unique: true });
db.invitations.createIndex({ invitedEmail: 1, familyId: 1 });

db.createCollection("audit_log");
db.audit_log.createIndex({ familyId: 1, timestamp: -1 });
```

### 6.4 `V2__seed_field_definition_template.js`
```javascript
db.field_definition_templates.insertOne({
  _id: "default-template-v1",
  version: 1,
  fields: [
    { key: "photo", label: "Photo", type: "image", mandatory: false, isDefault: true },
    { key: "firstName", label: "First Name", type: "text", mandatory: true, isDefault: true },
    { key: "lastName", label: "Last Name", type: "text", mandatory: false, isDefault: true },
    { key: "dob", label: "Date of Birth", type: "date", mandatory: false, isDefault: true },
    { key: "gender", label: "Gender", type: "enum", options: ["male", "female", "other"], mandatory: false, isDefault: true },
    { key: "fatherFirstName", label: "Father First Name", type: "text", isDefault: true },
    { key: "fatherLastName", label: "Father Last Name", type: "text", isDefault: true },
    { key: "motherFirstName", label: "Mother First Name", type: "text", isDefault: true },
    { key: "motherLastName", label: "Mother Last Name", type: "text", isDefault: true },
    { key: "email", label: "Email", type: "email", suggested: true },
    { key: "profession", label: "Profession", type: "text", suggested: true },
    { key: "placeOfBirth", label: "Place of Birth", type: "text", suggested: true },
    { key: "timeOfBirth", label: "Time of Birth", type: "time", suggested: true },
    { key: "hobby", label: "Hobby", type: "text", suggested: true },
    { key: "dod", label: "Date of Death", type: "date", suggested: true },
    { key: "netWorth", label: "Net Worth", type: "number", suggested: true, sensitive: true },
    { key: "residenceArea", label: "Residence Area", type: "text", suggested: true },
    { key: "residenceAddress", label: "Residence Address", type: "textarea", suggested: true, sensitive: true },
    { key: "mobile", label: "Mobile", type: "phone", suggested: true, sensitive: true },
    { key: "caste", label: "Caste", type: "text", suggested: true },
    { key: "religion", label: "Religion", type: "text", suggested: true },
    { key: "gotra", label: "Gotra", type: "text", suggested: true },
    { key: "naadi", label: "Naadi", type: "text", suggested: true },
    { key: "height", label: "Height (cm)", type: "number", suggested: true },
    { key: "weight", label: "Weight (kg)", type: "number", suggested: true }
  ]
});
```

### 6.5 How migrations get run — two options
**Option A — In-application startup (matches "executed from application"):**
```java
@Component
public class MongoMigrationRunner implements CommandLineRunner {

    @Value("${spring.data.mongodb.uri}")
    private String mongoUri;

    @Override
    public void run(String... args) {
        Map<String, String> config = new HashMap<>();
        config.put("flyway.environment", "mongodb");
        config.put("flyway.url", mongoUri);
        config.put("flyway.locations", "classpath:db/migration/mongodb");
        // TODO: confirm exact property keys against your installed Flyway version —
        // Native Connectors for MongoDB is a "foundational" (evolving) feature as of 2026.

        Flyway.configure().configuration(config).load().migrate();
    }
}
```
Maven dependency (artifact name likely `flyway-database-mongodb` following Flyway's per-database module convention — confirm exact name/version for your Flyway release):
```xml
<dependency>
  <groupId>org.flywaydb</groupId>
  <artifactId>flyway-core</artifactId>
</dependency>
<!-- <dependency><groupId>org.flywaydb</groupId><artifactId>flyway-database-mongodb</artifactId></dependency> -->
```

**Option B — External pipeline step (more battle-tested; use if Option A causes friction):** run the official Docker image as a one-shot container before the app starts.
```yaml
# docker-compose.yml
services:
  mongo:
    image: mongo:7
    ports: ["27017:27017"]
    volumes: ["mongo_data:/data/db"]

  flyway-migrate:
    image: redgate/flyway:12-mongo   # confirm current tag on Docker Hub
    depends_on: [mongo]
    volumes:
      - ./src/main/resources/db/migration/mongodb:/flyway/sql
      - ./flyway.toml:/flyway/conf/flyway.toml
    command: -configFiles=/flyway/conf/flyway.toml migrate

  app:
    build: .
    depends_on:
      mongo: { condition: service_started }
      flyway-migrate: { condition: service_completed_successfully }
    ports: ["8080:8080"]
    environment:
      SPRING_DATA_MONGODB_URI: mongodb://mongo:27017/familytree

volumes:
  mongo_data:
```

### 6.6 If Flyway's Mongo support proves too limiting
Mongock — the tool most Spring/Mongo teams have historically reached for here — is **now in maintenance mode and reaches end-of-life at the end of 2026**; its own maintainers direct new projects to its successor, **Flamingock**, which carries the same code-first `@ChangeUnit` model forward. If Flyway's foundational Mongo support blocks you (e.g., you need code-first migrations with dependency injection, or transactional guarantees the `.js` path doesn't give you), evaluate Flamingock rather than adopting Mongock fresh.

---

## 7. Realtime Collaboration

- `WebSocketConfig` registers a STOMP endpoint at `/ws` (with SockJS fallback) and a simple broker on `/topic`.
- On any successful member/schema mutation, the relevant service publishes to `/topic/family/{familyId}` with a small patch payload: `{ "type": "member.updated", "memberId": "...", "byUser": "...", "at": "..." }`.
- Clients (the Flutter app, in its later integration phase) subscribe per open family screen and merge patches into local state — this is what makes multi-user editing feel live without polling.

---

## 8. Testing & Definition of Done

- [ ] Fresh `docker-compose up` brings up Mongo, runs all Flyway migrations cleanly, and starts the app with zero manual steps.
- [ ] All endpoints in the Section 3.4 table implemented and return the documented shapes.
- [ ] Google OAuth login round-trip works end-to-end (real Google account → app JWT issued).
- [ ] Role-based authorization verified with an integration test per role (owner/editor/viewer) attempting a forbidden action and getting a 403.
- [ ] Photo upload → GridFS store → `GET /api/media/{id}` streams the same bytes back.
- [ ] Two WebSocket clients subscribed to the same family both receive a patch event when a third client edits a member.
- [ ] Sensitive fields are encrypted in the raw MongoDB documents (verify by inspecting the collection directly, not just through the API).
- [ ] Indexes from `V1` exist (`db.<collection>.getIndexes()`).
- [ ] `README.md` documents environment variables needed (`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `FLYWAY_MONGO_PASSWORD`, JWT signing key, field-encryption key) and how to run locally.

---

## 9. Explicit Scope Boundary

This phase delivers the **backend only**. Wiring the Phase 1 Flutter prototype's `FamilyRepository` interface to call these real endpoints (replacing `MockFamilyRepository`) is a natural follow-on task, but is out of scope here unless requested separately.
