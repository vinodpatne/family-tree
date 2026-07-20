# Family Tree App

A full-stack Family Tree application with a Flutter frontend and a Spring Boot + PostgreSQL backend.

## 📁 Project Structure

```
family-tree/
├── frontend/          # Flutter cross-platform client
│   ├── lib/           # Dart source code
│   ├── web/           # Web assets & persona icons
│   ├── pubspec.yaml   # Flutter dependencies
│   └── ...
├── backend/           # Spring Boot REST API
│   ├── src/main/java/com/familytree/
│   │   ├── config/        # Security, CORS, WebSocket configs
│   │   ├── controller/    # REST endpoints
│   │   ├── entity/        # JPA entities (PostgreSQL + JSONB)
│   │   ├── repository/    # Spring Data JPA repositories
│   │   ├── security/      # JWT service & auth filter
│   │   ├── service/       # Business logic
│   │   └── exception/     # Global error handling
│   ├── src/main/resources/
│   │   ├── application.yml
│   │   └── db/migration/  # Flyway SQL migrations
│   └── pom.xml
└── README.md
```

---

## ✨ Frontend Features
- **Dynamic Interactive Family Tree:** Pannable, zoomable DAG canvas visualizing the entire family.
- **Smart Auto-Population Engine:** Context-aware adding logic (e.g., adding a child to a married female auto-sets parents).
- **Custom Labeled & Dotted Links:** Overlay custom relationship links with optional dotted paths.
- **Collapsible Subtrees:** Expand/collapse branches with smooth canvas updates.
- **Intelligent Member Form:** Auto-calculates age from DOB, conditional maiden names, mandatory field enforcement.
- **Dynamic Persona Icons:** Auto-assigned based on age, gender, and profession.
- **Premium UI:** Custom-designed cards, smooth modals, centralized design tokens.
- **Collaborator Invites:** Invite family members by email from their profile.

## 🛠️ Backend Features
- **Spring Boot 3.x + Java 21** REST API.
- **PostgreSQL with JSONB** columns for maximum flexibility (member data, relations, settings, schema fields all stored as JSON).
- **JWT Authentication:** Stateless auth with Bearer tokens.
- **Photo Upload:** Base64-encoded images stored in DB, capped at **100 KB**.
- **Flyway Migrations:** Automated schema creation and seed data.
- **WebSocket (STOMP):** Real-time collaboration notifications on `/topic/family/{familyId}`.
- **Audit Logging:** Every mutation is tracked with before/after snapshots.
- **Global Exception Handling:** Structured JSON error responses.

---

## 🚀 Getting Started

### Prerequisites
- **Frontend:** Flutter SDK (≥ 3.4.0)
- **Backend:** Java 21, Maven, PostgreSQL

### Database Setup
```sql
CREATE USER family_tree_app_user WITH ENCRYPTED PASSWORD 'family_tree';
CREATE DATABASE family_tree_app_db WITH OWNER family_tree_app_user;
```

### Run Backend
```bash
cd backend
mvn clean spring-boot:run
```
Flyway will automatically create the `family_tree` schema, tables, and seed data on first run.

### Run Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome
flutter run -d edge
flutter run -d windows

flutter run -d edge --web-port=4000 --web-browser-flag="--user-data-dir=%LOCALAPPDATA%\Microsoft\Edge\FlutterDevProfile"

```

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Mock login → returns JWT |
| GET | `/api/families` | List user's families |
| POST | `/api/families` | Create a new family |
| GET | `/api/families/{id}` | Get family details |
| PUT | `/api/families/{id}/settings` | Update family settings |
| GET | `/api/families/{id}/schema` | Get field schema |
| PUT | `/api/families/{id}/schema/fields` | Update schema fields |
| GET | `/api/families/{id}/members` | List family members |
| POST | `/api/families/{id}/members` | Create a member |
| PATCH | `/api/members/{id}` | Update a member |
| DELETE | `/api/members/{id}` | Delete a member |
| POST | `/api/members/{id}/photo` | Upload photo (max 100KB) |
| GET | `/api/media/{id}` | Get photo |
| GET | `/api/families/{id}/invite` | List pending invites |
| POST | `/api/families/{id}/invite` | Send invite |

---

## 🔐 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NEXT_PUBLIC_GOOGLE_CLIENT_ID` | Google OAuth 2 Client ID for Frontend & Backend | `589984283666-lfqpl9j3tvl9ianh5tnmk67pq6umnnp9.apps.googleusercontent.com` |
| `JWT_SECRET` | Secret key for JWT signing | dev default (change in prod!) |
| PostgreSQL | Configured in `application.yml` | `localhost:5432/family_tree_app_db` |

---

## What is mocked
- Google OAuth is stubbed — use `POST /api/auth/login` with any email.
- No real email sending for invites.
