# Trello REST API — High-Level Overview

**Spec version:** OpenAPI 3.0.0  
**Base URL:** `https://api.trello.com/1`  
**API title:** Trello REST API (v0.0.1)

---

## Endpoint Summary

| Metric | Count |
|--------|-------|
| **Total endpoints** | **256** |
| Unique paths | 187 |
| GET | 125 |
| PUT | 51 |
| POST | 44 |
| DELETE | 36 |

---

## Resource Groups (18 top-level resources)

| Resource | Path count | Description |
|----------|-----------|-------------|
| **cards** | 30 | Card CRUD, attachments, checklists, labels, members, stickers, actions |
| **boards** | 29 | Board CRUD, memberships, lists, cards, labels, custom fields, plugins |
| **members** | 27 | Member profiles, boards, cards, organizations, notifications, saved searches |
| **organizations** | 19 | Organization (workspace) CRUD, members, boards, tags, exports |
| **enterprises** | 19 | Enterprise admin, members, organizations, audit logs, tokens |
| **actions** | 12 | Action (activity) retrieval, reactions, related board/card/member lookups |
| **notifications** | 10 | Notification CRUD, read/unread status, channel settings |
| **lists** | 10 | List CRUD, cards within lists, archiving, moving |
| **checklists** | 7 | Checklist CRUD, check items |
| **tokens** | 5 | Token info, webhooks per token, revocation |
| **plugins** | 4 | Plugin details, compliance, membership, listings |
| **customFields** | 4 | Custom field definitions and options |
| **webhooks** | 3 | Webhook CRUD |
| **labels** | 3 | Label CRUD |
| **search** | 2 | Full-text search across boards/cards/members/organizations |
| **emoji** | 1 | Emoji listing |
| **batch** | 1 | Batch multiple GET requests |
| **applications** | 1 | Application compliance data |

---

## Authentication

Trello uses **query-parameter-based API key + token authentication**:

| Scheme | Type | Location | Parameter |
|--------|------|----------|-----------|
| `APIKey` | `apiKey` | query | `key` |
| `APIToken` | `apiKey` | query | `token` |

Both are required globally on every request. There is no OAuth bearer token or header-based auth — credentials are appended as `?key=...&token=...` query parameters.

---

## Schema Inventory

**Total schemas: 63** (including 14 enum types)

### Enum Schemas
`ActionFields`, `AttachmentFields`, `BlockedKey`, `BoardFields`, `CardAging`, `CardFields`, `Channel`, `Color`, `ListFields`, `MemberFields`, `NotificationFields`, `OrganizationFields`, `TokenFields`, `ViewFilter`

### Most Complex Schemas (by property count)

| Schema | Properties | Nested/Complex Fields | Referenced Schemas |
|--------|-----------|----------------------|-------------------|
| **Member** | 42 | 20 | `LimitsObject`, `MemberPrefs`, `TrelloID` |
| **Card** | 33 | 15 | `Checklist`, `Color`, `Label`, `Limits`, `TrelloID` |
| **Board** | 26 | 6 | `Limits`, `Prefs`, `TrelloID` |
| **Prefs** | 22 | — | *(inline — board preferences)* |
| **Enterprise** | 18 | 11 | *(enterprise-level admin data)* |
| **Organization** | 11 | 6 | *(workspace-level data)* |
| **Notification** | 11 | 5 | *(notification content + channel settings)* |
| **Attachment** | 11 | 4 | *(file attachment metadata)* |
| **Action** | 8 | 6 | *(activity log entries)* |
| **MemberPrefs** | 9 | — | *(member preference settings)* |

### Key Supporting Schemas

- **`TrelloID`** — String type alias used everywhere for entity IDs
- **`Limits` / `LimitsObject`** — Rate limit and quota structures referenced by Board, Card, Member
- **`Prefs`** — 22-property board preferences object (permissions, voting, backgrounds, card aging, etc.)
- **`MemberPrefs`** — Member-level preference settings
- **`Membership` / `Memberships`** — Board/org membership with roles
- **`CustomField` / `CustomFieldItems` / `CFValue`** — Custom field definitions and values
- **`Checklist` / `CheckItem`** — Checklist structures within cards
- **`Label`** — Color-coded labels
- **`Webhook`** — Webhook registration (URL, model ID, active status)

---

## Most Parameter-Heavy Endpoints

These endpoints accept the most query parameters, reflecting the API's flexible field-selection model:

| Params | Method | Path |
|--------|--------|------|
| 21 | GET | `/search` |
| 21 | GET | `/members/{id}` |
| 18 | POST | `/cards` |
| 18 | GET | `/cards/{id}` |
| 17 | PUT | `/cards/{id}` |
| 16 | POST | `/boards/` |
| 16 | GET | `/boards/{id}` |
| 15 | PUT | `/boards/{id}` |
| 15 | GET | `/notifications/{id}` |
| 14 | GET | `/enterprises/{id}` |

Many parameters are field-selection flags (e.g., `board_fields`, `card_fields`, `member_fields`) that let callers control which nested objects and fields are included in responses.

---

## Key Observations

1. **Read-heavy API** — 125 of 256 endpoints (49%) are GETs. The API is designed for consumption, with fine-grained field selection on most read endpoints.

2. **Flat resource model** — Resources are accessed by ID at the top level (`/cards/{id}`, `/boards/{id}`), with sub-resources as nested paths (`/boards/{id}/cards`, `/cards/{id}/checklists`).

3. **No PATCH methods** — The API uses PUT exclusively for updates (51 PUT endpoints, 0 PATCH).

4. **Highly optional schemas** — Most schema properties are optional, reflecting that Trello's API returns different fields depending on query parameters. The `Member` schema has 42 properties, almost all optional.

5. **Enterprise tier** — 19 enterprise endpoints indicate significant admin/governance surface (audit logs, SSO, domain management, organization preferences).

6. **Field-selection pattern** — Rather than separate "summary" vs "detail" endpoints, Trello uses `*_fields` query parameters to let callers specify exactly which fields to return.
