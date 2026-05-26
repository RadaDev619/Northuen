# Northuen Deployment

## Backend

The backend is a Spring Boot service that uses Flyway migrations and validates the schema on startup.

Required environment variables:

```text
PORT=8081
DATABASE_URL=jdbc:postgresql://<host>:<port>/<database>?sslmode=require
DATABASE_USERNAME=<username>
DATABASE_PASSWORD=<password>
DB_MAX_POOL_SIZE=2
DB_MIN_IDLE=0
DB_CONNECTION_TIMEOUT_MS=30000
DB_IDLE_TIMEOUT_MS=300000
DB_MAX_LIFETIME_MS=900000
JWT_SECRET=<at-least-32-bytes>
JWT_EXPIRATION_MS=86400000
ALLOWED_ORIGIN_PATTERNS=https://your-app-domain.com,http://localhost:*
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS_PER_MINUTE=120
ADMIN_EMAIL=admin@northuen.bt
ADMIN_PASSWORD=<strong-password>
DEMO_DATA_ENABLED=false
```

Run locally with Docker:

```powershell
docker compose up --build
```

## Render Deployment

This repo includes `render.yaml`, based on Render Blueprints. Render’s docs describe Blueprint files as `render.yaml` files in the repository root that define services and environment variables.

1. Push the project to GitHub.
2. In Render, create a new Blueprint from the GitHub repo.
3. Set the `sync: false` secret values when Render prompts:
   - `DATABASE_URL`
   - `DATABASE_USERNAME`
   - `DATABASE_PASSWORD`
   - `JWT_SECRET`
   - `ADMIN_EMAIL`
   - `ADMIN_PASSWORD`
   - `ADMIN_PHONE`
4. Deploy.
5. Copy the Render service URL, for example `https://northuen-backend.onrender.com`.
6. Build Flutter with that URL:

```powershell
cd northuen_app
flutter build apk --release --dart-define=API_BASE_URL=https://your-render-service.onrender.com
```

If Supabase reports `MaxClientsInSessionMode`, Render is still using Supabase session mode, usually port `5432`. Use the transaction pooler on port `6543` and keep `DB_MAX_POOL_SIZE=2` for pilot. For transaction pooling, a safe JDBC URL is:

```text
jdbc:postgresql://aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=require&prepareThreshold=0
```

Swagger:

```text
http://localhost:8081/swagger-ui.html
```

## Supabase

1. Create a Supabase project.
2. Use the Supabase pooled PostgreSQL JDBC URL in `DATABASE_URL`.
3. Create a public/private storage bucket for product and vendor images.
4. Store uploaded image URLs in `vendors.image_url` and `products.image_url`.

The backend owns order, payment, delivery, and settlement writes. Flutter must call REST APIs and must not write critical marketplace state directly to Supabase.

## Flutter

Build web:

```powershell
cd northuen_app
flutter build web --dart-define=API_BASE_URL=https://your-api-domain.com
```

Run mobile:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081
```
