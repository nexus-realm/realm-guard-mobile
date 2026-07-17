# SYNC_MAPPING.md — VaultDoc ↔ drift projection

> The **durable wire format** for CRDT sync (P3.3). Cross-device and forward-compatible:
> **field ids, kind codes, and value tags must never be renumbered or reused.**
> Keep in sync with `lib/core/sync/*` and `realm-guard-core` `VaultDoc`.

## Model

- **Source of truth = the CRDT** (`VaultDoc<Ciphertext>` in `realm-guard-core`), persisted as opaque bytes.
- **drift = a read projection** (option B): the local SQLCipher DB is rebuilt from the doc, never the other way around. Writes go doc-first, then reproject.
- Each **entry** = one row of one v1 table (`profiles` / `credentials` / `totps`).
- Each **field** = one LWW register, keyed by a stable `FieldId` (`u16`).
- Field **values** are per-entry encrypted (`crdt_encrypt_field`, key derived from `vaultKey` + `entryId`) → the server only ever sees ciphertext.

## Identity — `syncId`

- Every projected table has a `syncId BLOB(16) UNIQUE` column ⇔ the CRDT `EntryId`.
- Schema v4→v5 migration adds it and backfills existing rows with `randomblob(16)`; new rows get one via `clientDefault` (`generateSyncId`) until the CRDT write path (P3.3c) supplies the `EntryId` explicitly.
- The local autoincrement `id` (PK) stays **local-only** — it is never synced; joins across devices go through `syncId`.

## `kind` — `FieldId(0)` (shared)

Routes an entry to its table. Encoded as an integer value.

| code | kind |
|------|------|
| 0 | profile |
| 1 | credential |
| 2 | totp |

An entry with no `kind`, or an unknown `kind`, is **ignored** by the projection (forward-compat).

## FieldId ranges

Profile `1–19`, credential `20–39`, totp `40–59`.

| FieldId | Profile (kind 0) | value type |
|--------:|------------------|------------|
| 1 | name | text |
| 2 | emails | text (JSON array) |
| 3 | usernames | text (JSON array) |
| 4 | phoneNumbers | text (JSON array) |
| 5 | color | int |
| 6 | note | text |
| 7 | createdAt | int (epoch ms) |

| FieldId | Credential (kind 1) | value type |
|--------:|---------------------|------------|
| 20 | title | text |
| 21 | username | text |
| 22 | password | text |
| 23 | uri | text |
| 24 | notes | text |
| 25 | customFields | text (JSON) |
| 26 | favorite | bool |
| 27 | profileId | **uuid** (referenced profile's `syncId`) |
| 28 | createdAt | int (epoch ms) |

| FieldId | Totp (kind 2) | value type |
|--------:|---------------|------------|
| 40 | label | text |
| 41 | account | text |
| 42 | secret | text (Base32) |
| 43 | digits | int |
| 44 | period | int |
| 45 | algorithm | text |
| 46 | profileId | **uuid** (referenced profile's `syncId`) |
| 47 | favorite | bool |
| 48 | createdAt | int (epoch ms) |

## Value codec (tagged `[tag][payload]`)

Defined in `lib/core/sync/field_value.dart` (`FieldValue`).

| tag | type | payload |
|-----|------|---------|
| 0 | null | (empty) |
| 1 | text | UTF-8 |
| 2 | int | i64 little-endian (8 bytes) |
| 3 | bool | 1 byte (0/1) |
| 4 | uuid | 16 bytes |

- `null` (tag 0) means an **explicit clear**, distinct from *never set* (which is simply not emitted). The projection's encoders **omit** null optionals; an explicit clear is a deliberate `NullValue`, decided by the differential write path (P3.3c).

## Foreign keys

`profileId` travels as the referenced profile's `syncId` (**uuid**), not the local int. The projection resolves uuid→local int on read; if the referenced profile is absent locally, `profileId` → `null` until it arrives.

## Synced vs local-only

- **Synced:** every field above, **including `favorite` and `createdAt`**.
- **Local-only:** `id` (↔ `EntryId` via `syncId`), `updatedAt` (derived = projection time).

## Deletion

A delete is `remove_entry` (add-wins tombstone) in the CRDT. The entry then drops out of `entry_ids()`, so the projection removes the corresponding drift row.

## Code map

| File | Role |
|------|------|
| `lib/core/sync/field_value.dart` | tagged value codec (`FieldValue`) |
| `lib/core/sync/vault_fields.dart` | `VaultKind` + `FieldId` constants + row→field-map encoders (`VaultFieldMap`) |
| `lib/core/sync/crdt_ffi.dart` | `CrdtFfi` interface + `FrbCrdtFfi` (over generated FFI) — testable seam |
| `lib/core/sync/vault_projection.dart` | `VaultProjection.decode` (doc→rows), `VaultDocWriter.putFields` (fields→doc, encrypt + HLC) |

> **Not yet wired to the live `VaultRepository`.** Rerouting writes through the CRDT and reprojecting reads, plus migrating existing v1 rows into the doc, is **P3.3c**.
