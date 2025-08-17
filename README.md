# BudgetIQ

Expense management platform with a clean **3-service** backend and an **Angular 19** PWA frontend.

* **API Gateway** (`Spring Cloud Gateway`) – single public entrypoint, JWT check, routing & rate-limits
* **Core Service** (`Spring Boot + JPA + Flyway + PostgreSQL`) – business logic (users/orgs, categories, expenses, budgets, recurring, reports)
* **AI Service** (`Spring Boot`) – AI categorization, insights, OCR (stateless)
* **Web App** (`Angular 19 + Angular Material + CoreUX theme`) – PWA, offline queue, charts

---

## 🧭 Monorepo Layout

```
budgetiq/
├─ budgetiq-backend/
│  ├─ settings.gradle.kts
│  ├─ build.gradle.kts
│  ├─ gradle/libs.versions.toml
│  ├─ common/
│  │  ├─ security/           # JwtService, JwtFilter, SecurityConfig
│  │  └─ web/                # GlobalExceptionHandler, paging DTOs, OpenAPI cfg
│  ├─ api-gateway/           # 8080
│  ├─ core-service/          # 8081 (Postgres + Flyway)
│  └─ ai-service/            # 8082 (stateless)
└─ budgetiq-ui/
   ├─ package.json
   ├─ apps/web/              # Angular app (PWA)
   └─ libs/
      ├─ ui-core/            # CoreUX themes/components (macOS/Minimal Zen)
      ├─ feature-auth/
      ├─ feature-ledger/
      ├─ feature-budgets/
      ├─ feature-reports/
      └─ data-access/        # API clients, models, interceptors
```

---

## 🚀 Quick Start (Local Dev)

### 0) Prerequisites

* **Java 21**, **Node 20+**, **pnpm** (or npm), **Docker** & **Docker Compose**

### 1) Infra (DB, cache, object storage)

From `budgetiq-backend/` run:

```bash
docker compose -f docker-compose.dev.yml up -d
```

`docker-compose.dev.yml` should provide:

* **Postgres** (port `5432`), DB: `budgetiq` / user: `budgetiq` / pass: `budgetiq`
* **Redis** (port `6379`)
* **MinIO** (ports `9000/9001`) with bucket `receipts`

> Create an access key/secret for MinIO and a `receipts` bucket (MinIO console on `:9001`).

### 2) Backend – run all three services

From `budgetiq-backend/`:

```bash
# build once
./gradlew clean build

# terminals (or use IntelliJ run configs):
./gradlew :api-gateway:bootRun      # http://localhost:8080
./gradlew :core-service:bootRun     # http://localhost:8081
./gradlew :ai-service:bootRun       # http://localhost:8082
```

### 3) Frontend – Angular app

From `budgetiq-ui/`:

```bash
pnpm install   # or npm i
pnpm start     # or ng serve
# http://localhost:4200
```

> The UI talks to **gateway** at `http://localhost:8080`.

---

## ⚙️ Configuration

### Backend environment (suggested)

Create a `.env.local` (or export env vars) for **core-service**:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/budgetiq
SPRING_DATASOURCE_USERNAME=budgetiq
SPRING_DATASOURCE_PASSWORD=budgetiq

JWT_ISSUER=budgetiq
JWT_PUBLIC_KEY=... # or HS secret if using HMAC
JWT_PRIVATE_KEY=... # for RSA (core issues tokens if desired)

MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=receipts
```

For **api-gateway** (verifies JWT and routes):

```
GATEWAY_JWT_PUBLIC_KEY=... # same key pair public used by verifier
RATE_LIMIT_ENABLED=true
```

For **ai-service**:

```
OPENAI_API_KEY=...           # optional when enabling LLM
AI_FEATURES_ENABLED=false    # flip true when ready
OCR_PROVIDER=tesseract|vision
```

### Frontend environment (Angular)

`budgetiq-ui/apps/web/src/environments/environment.ts`:

```ts
export const environment = {
  production: false,
  apiBaseUrl: 'http://localhost:8080', // gateway
};
```

---

## 🔐 Security Overview

* **JWT access + refresh** tokens (stateless)
* Gateway validates JWT; injects `X-Org-Id`, `X-User-Id` headers to services
* **RBAC**: `OWNER`, `ADMIN`, `USER`, `READONLY`
* Multi-tenant: all Core queries filtered by `org_id`
* Rate-limits at gateway; CORS locked to UI origin in staging/prod

---

## 🗃️ Database & Migrations

* PostgreSQL with **Flyway** migrations in `core-service/src/main/resources/db/migration/`
* **V1**: `org`, `usr`
* **V2**: `category`, `tag`, `expense`, `expense_tag` + indexes
* **V3**: `budget`, `recurring_rule` + scheduler support

On `core-service` startup, Flyway runs automatically.

---

## 📡 API Contracts (Core highlights via Gateway)

> Base via gateway: `http://localhost:8080`

**Auth**

* `POST /api/auth/register` – creates org + owner user
* `POST /api/auth/login` – returns access & refresh tokens
* `POST /api/auth/refresh`
* `GET /api/me`

**Ledger**

* `GET /api/categories`
* `POST /api/categories`
* `GET /api/expenses?from=&to=&categoryId=&q=&page=&size=`
* `POST /api/expenses`
* `PATCH /api/expenses/{id}` / `DELETE /api/expenses/{id}`
* `POST /api/expenses/{id}/receipt` – multipart → MinIO/S3

**Budgets & Reports**

* `POST /api/budgets` / `GET /api/budgets?periodKey=YYYY-MM`
* `GET /reports/summary?from=&to=`
* `GET /reports/category-breakdown?periodKey=YYYY-MM`
* `GET /reports/export.csv`

**AI**

* `POST /ai/categorize`
* `GET /ai/insights?periodKey=YYYY-MM`
* `POST /ai/ocr` (multipart)

> Add `/v1` prefix when contracts are stable.

---

## 🖥️ Frontend Structure (Angular 19)

* `feature-auth`: login/register/guards, token interceptor (refresh handling)
* `feature-ledger`: expenses list (virtual scroll), add/edit, filters, receipt upload
* `feature-budgets`: create/edit budgets, utilization view, threshold warnings
* `feature-reports`: charts (line/pie) and CSV export button
* `ui-core`: CoreUX styles (Minimal Zen/macOS), cards, dialogs, inputs
* `data-access`: typed models, API clients, error & auth interceptors
* **PWA**: offline add queue (IndexedDB) + background sync

Run:

```bash
pnpm test
pnpm build
```

---

## 🧩 Development Phases & Acceptance

### Phase 0 — Foundations (Day 1–2)

* Repos scaffolded, CI builds green, infra up, `/actuator/health` OK
  **AC**: Gateway route to Core/AI health endpoints; Angular shell loads & shows “System Online”.

### Phase 1 — Identity & Security (Week 1)

* Flyway V1, `/api/auth/*`, `/api/me`, JWT in gateway + services, Angular auth flow
  **AC**: Register → Login → `/api/me` from UI via gateway; refresh token works.

### Phase 2 — Ledger MVP (Week 2)

* Categories, expenses CRUD, filters/paging, receipt upload to MinIO
  **AC**: CRUD works end-to-end; pagination correct; receipt link opens via signed URL.

### Phase 3 — Budgets, Recurring, Reports (Week 3)

* Budgets & utilization, recurring engine, summary & category breakdown, CSV export
  **AC**: Recurring creates entries exactly once on schedule; CSV opens in Excel.

### Phases 4–5 — AI & PWA (Weeks 4–6)

* AI service stubs → rules → LLM/OCR behind flags; insights on dashboard
* PWA offline add & background sync; budget threshold alerts
  **AC**: AI categorization falls back to rules; offline add syncs without dupes; alerts trigger reliably.

### Phase 6 — SaaS Readiness (Weeks 7–8)

* Roles/org invites, (optional) reimbursements, billing integration, observability dashboards, hardening
  **AC**: Feature flags per plan; SLO dashboards; load tests meet p95 goals.

---

## ✅ Testing

* **Unit**: services, validators, mappers (MapStruct)
* **Integration**: Spring `@DataJpaTest` + Testcontainers (Postgres/Redis/MinIO)
* **E2E**: Playwright (UI → gateway → services). Happy path: login → add expense → list → export
* **Perf**: k6/JMeter (1k r/min reads, 200 r/min writes baseline)
* **Security**: JWT tamper/expiry tests; org isolation tests (no cross-org data)

---

## 📊 Observability

* **Actuator**: health/info/metrics
* **OpenTelemetry**: traces from gateway → core/ai
* **Prometheus**: HTTP latency, error rate, DB timings
* **Logs**: JSON w/ correlation IDs (request → service chain)

---

## 🧱 Build Commands

**Backend**

```bash
./gradlew clean build            # build all modules
./gradlew :api-gateway:bootRun
./gradlew :core-service:bootRun
./gradlew :ai-service:bootRun
```

**Frontend**

```bash
pnpm i
pnpm start          # dev
pnpm test
pnpm build
```

---

## 🔁 Environments

* **local**: Docker compose (Postgres/Redis/MinIO), services on 8080/8081/8082, Angular 4200
* **staging**: single VM or k8s; managed Postgres; S3; HTTPS; CORS limited to UI domain
* **prod**: separate VPC; autoscale gateway/services; managed Postgres; S3; CDN for UI

---

## 🧰 Troubleshooting

* **`Directory does not contain a Gradle build`** → run `gradle init` at module root or check `settings.gradle.kts` includes your modules.
* **`java { toolchain } unresolved`** → ensure `plugins { java }` applied and Gradle ≥ 8.
* **CORS errors in UI** → set CORS in gateway for `http://localhost:4200` (dev).
* **MinIO auth errors** → confirm access/secret & bucket name; regenerate pre-signed URL.
* **JWT invalid at gateway** → sync keys (issuer, audience, alg), check clock skew.

---

## 📝 License

Choose an open-source license (MIT/Apache-2.0) or keep proprietary. Add a `LICENSE` file accordingly.

---

## 🙌 Contributing (Internal)

* Branch naming: `feature/*`, `fix/*`, `chore/*`
* PR checklist: tests, docs updated, feature flags for non-GA features, OpenAPI updated
* Code style: Spotless (BE) & ESLint/Prettier (FE) must pass in CI

---

### Appendix A — Example `docker-compose.dev.yml` (backend)

```yaml
version: "3.8"
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: budgetiq
      POSTGRES_PASSWORD: budgetiq
      POSTGRES_DB: budgetiq
    ports: [ "5432:5432" ]
  redis:
    image: redis:7
    ports: [ "6379:6379" ]
  minio:
    image: quay.io/minio/minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - ./_data/minio:/data
```
