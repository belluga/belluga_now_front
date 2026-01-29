# Route Paths Migration Guide
**Version:** 1.0

## 1. Purpose
This guide summarizes the route path and domain-scope changes introduced by the route refactor. It is intentionally minimal: it lists what changed so an AI (or dev) can update client calls and integrations quickly.

## 2. Core Rule: Domain Scope First
Routes are now **domain-scoped**, and **domain scope is not the same as auth scope**.

- **Main domain** serves **Landlord** routes only.
- **Tenant subdomain or tenant custom domain** serves **Tenant** + **Account** routes only.

If a route is not registered for the current domain, it **does not exist** (404), even if the path matches.

## 3. Route Families (Final Structure)
### 3.1 Landlord (Main Domain)
- **Landlord Admin:** `/admin/api/v1/...`
- **Landlord Public:** `/api/v1/...` (minimal, e.g. `/api/v1/environment`)

### 3.2 Tenant (Tenant Domains)
- **Tenant Admin:** `/admin/api/v1/...`
- **Tenant Public (Non-Admin):** `/api/v1/...`

### 3.3 Account (Tenant Domains)
- **Account Admin (account-scoped):** `/api/v1/accounts/{account_slug}/...`

Account routes are already admin and do **not** move under `/admin`.

## 4. Path Changes (Old -> New)
### 4.1 Tenant Admin Endpoints
All tenant admin resources previously under `/api/v1/...` are now under:

```
/admin/api/v1/...
```

Examples:
- `/api/v1/account_profiles` -> `/admin/api/v1/account_profiles`
- `/api/v1/accounts` -> `/admin/api/v1/accounts`
- `/api/v1/organizations` -> `/admin/api/v1/organizations`
- `/api/v1/roles` -> `/admin/api/v1/roles`
- `/api/v1/users` -> `/admin/api/v1/users`

### 4.2 Tenant Public Endpoints
Tenant public endpoints remain **under `/api/v1/...`**, but now **only exist on tenant domains**.

Examples:
- `/api/v1/agenda` (tenant domain only)
- `/api/v1/events` (tenant domain only)

### 4.3 Landlord Public Endpoint
Landlord public endpoint is now explicit and **main-domain only**:

- `/api/v1/environment` (main domain only)

### 4.4 Account Admin Endpoints
Account admin stays the same:

```
/api/v1/accounts/{account_slug}/...
```

## 5. Access Rules (Auth Scope)
Auth/abilities still apply as before, but with domain + path in place:

- **Landlord user:** can access landlord + tenant-admin + tenant-public + account routes (abilities still required).
- **Account user:** can access tenant-public + account routes only (abilities still required).

## 6. Migration Checklist (Quick)
1. If endpoint is tenant-admin, **prepend `/admin`** and ensure you are calling on a tenant domain.
2. If endpoint is tenant-public, **keep `/api/v1`** but ensure you are on a tenant domain (not main).
3. If endpoint is landlord-public, **use main domain** `/api/v1/...`.
4. If endpoint is account-admin, **keep `/api/v1/accounts/{account_slug}/...`** (tenant domain).
