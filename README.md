# lucos_auth_scopes

An issuer-agnostic **scope vocabulary** for lucOS authorisation — the central, neutral list of valid scope strings, consumed at build-time by `lucos_aithne` and `lucos_creds`.

See `lucos_aithne` ADR-0001 §7 for the design rationale (a dedicated repo, published as a docker image, consumed at build-time — no runtime polling).

## What this is (and isn't)

This repo holds **`scopes.yaml`**: the authoritative set of scope strings that may be granted to a principal. **The file *is* the allowlist** — a scope is valid *iff* it appears here. There is nothing else to validate against; membership in this set is the whole check.

It defines only the **vocabulary**. The other two concerns live elsewhere (ADR-0001 §6):

- **Grant** — "principal P is granted scope S in environment E" — lives in `lucos_aithne` (default-deny, human-gated, per-env, revocable).
- **Enforcement** — "does this scope permit *this* action?" — lives in each **backend**. Only the owning service knows what a scope permits; aithne makes a scoped *assertion*, the backend makes the *decision*.

## File format

A flat YAML list of strings:

```yaml
scopes:
  - render-ui
  - eolas:read
  - photos:write
```

That's it — a flat list, not a map. Grouping by service was considered and rejected: a capability often spans services, so a service-keyed structure mis-models it (see "Naming" below).

## Naming convention

A scope is either **`domain:capability`** or, for genuinely estate-wide capabilities, a **bare** string.

- **`domain`** is the *resource / capability area*, **not** the owning service. It exists to keep the same capability word from colliding across areas (`photos:read` vs `contacts:read`). It is often coincident with the sole-home service (`eolas`, `media-metadata`) but is **not** required to be the full `lucos_configy` system code.
- **`capability`** — prefer a small, consistent estate-wide verb set (`read`, `write`, `delete`) for generic CRUD, so "what can principal P do?" reads consistently. Use a domain-specific verb only where a generic one would genuinely mislead (e.g. a hypothetical append-only `:add`, where the generic `:write` would overstate the capability).
- **Bare scopes** are for capabilities that are genuinely cross-cutting — held estate-wide by a principal that needs them everywhere, with a uniform contract on every service. Current examples:
  - `render-ui` — dev-only: GET-render any service's UI (e.g. `lucos-ux` page snapshots).
  - `webhook` — deliver an event notification to any service's `/webhooks` (held by `lucos_loganne`). Bundled deliberately: the sole holder needs it estate-wide, so per-service scopes would add no least-privilege value and would *silently fail-closed* delivery to any newly-added service until re-granted. Safe precisely because `/webhooks` is a uniform, narrow, accept-202-enqueue contract everywhere.

### No wildcard scopes

There is no `full` / catch-all / `*` scope. Least-privilege means a principal carries the **explicit set** of capabilities it needs; "everything" must be visible in the grant, never hidden behind a wildcard — that is exactly what makes "what can P do?" a single auditable answer.

## How a grant references scopes

A credential carries a **set** of scopes. In `lucos_creds` linked credentials this is a comma-separated list after the key: `key|scope1,scope2`. A grant is therefore a **subset** of this vocabulary.

## Versioning

The **docker image tag is the version** (semver, for free from the publish flow). There is no in-file version field — it would only duplicate the tag and drift.

## Consuming the vocabulary

Pull it in at build-time; there is no runtime layer:

```dockerfile
COPY --from=lucas42/lucos_auth_scopes:<version> /scopes.yaml ./scopes.yaml
```

## Changing the vocabulary

- **Build-time coupled** — a change takes effect only after a rebuild + redeploy of `lucos_aithne` and `lucos_creds`. This is deliberate: vocabulary changes are rare and should be.
- **Default-deny** — add a scope only when a *real consumer needs it*. Never add one speculatively.
- **lucas42 approval required** on every change (this repo carries its own PR-approval policy for exactly this reason).
