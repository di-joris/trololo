# Trello REST API — High-Level Overview

> Parsed from `trello-openapi.json` (OpenAPI 3.0.0, ~16k lines)

---

## At a Glance

| Metric | Value |
|---|---|
| **OpenAPI version** | 3.0.0 |
| **API title** | Trello REST API |
| **Base URL** | `https://api.trello.com/1` |
| **Total paths** | 187 |
| **Total operations** | 256 |
| **Schemas (models)** | 63 |

### Operations by HTTP Method

| Method | Count |
|---|---|
| GET | 125 |
| PUT | 51 |
| POST | 44 |
| DELETE | 36 |

---

## Authentication

Trello uses **two API-key query parameters** for authentication:

| Scheme | Type | Passed via | Query param |
|---|---|---|---|
| **APIKey** | `apiKey` | query string | `key` |
| **APIToken** | `apiKey` | query string | `token` |

Both are **required globally** on every request. There is no OAuth bearer token or header-based auth defined in this spec — all authentication is done by appending `key=...&token=...` to the query string of each API call.

---

## Main Resource Groups (18 groups)

Organized by the first path segment (`/resource/...`):

| Resource | Operations | GET | POST | PUT | DELETE |
|---|---|---|---|---|---|
| `/members` | 45 | 24 | 8 | 8 | 5 |
| `/cards` | 42 | 16 | 10 | 7 | 9 |
| `/boards` | 36 | 15 | 8 | 10 | 3 |
| `/organizations` | 26 | 11 | 4 | 4 | 7 |
| `/enterprises` | 21 | 13 | 1 | 5 | 2 |
| `/actions` | 16 | 11 | 1 | 2 | 2 |
| `/checklists` | 12 | 6 | 2 | 2 | 2 |
| `/lists` | 11 | 4 | 3 | 4 | 0 |
| `/notifications` | 11 | 8 | 1 | 2 | 0 |
| `/customFields` | 8 | 3 | 2 | 1 | 2 |
| `/tokens` | 8 | 4 | 1 | 1 | 2 |
| `/labels` | 5 | 1 | 1 | 2 | 1 |
| `/plugins` | 5 | 2 | 1 | 2 | 0 |
| `/webhooks` | 5 | 2 | 1 | 1 | 1 |
| `/search` | 2 | 2 | 0 | 0 | 0 |
| `/applications` | 1 | 1 | 0 | 0 | 0 |
| `/batch` | 1 | 1 | 0 | 0 | 0 |
| `/emoji` | 1 | 1 | 0 | 0 | 0 |

The **top 5 resources** (`members`, `cards`, `boards`, `organizations`, `enterprises`) account for **170 of 256 operations (66%)**.

---

## Most Complex Schemas

Complexity is measured by number of properties, nested objects, and `$ref` relationships to other schemas.

### Top 10 by Complexity

| # | Schema | Properties | Refs to other schemas | Nested objects | Notes |
|---|---|---|---|---|---|
| 1 | **Member** | 42 | 10 | 4 | The largest model — user profile, enterprise links, preferences, limits, boards, orgs |
| 2 | **Card** | 33 | 6 | 3 | Core Trello unit — badges, checklists, labels, attachments, cover, members, dates |
| 3 | **Board** | 26 | 5 | 1 | Workspace container — prefs, label names, limits, memberships, dates |
| 4 | **Enterprise** | 18 | 5 | 3 | Enterprise/admin management — admin list, org claims, audit logs |
| 5 | **Prefs** | 22 | 3 | 0 | Board preferences — backgrounds, permissions, voting, comments, invitations |
| 6 | **Organization** | 11 | 5 | 0 | Workspace/team — linked to boards, members, prefs, enterprise |
| 7 | **Action** | 8 | 2 | 4 | Audit trail — heavily nested data (display, entities, memberCreator) |
| 8 | **Notification** | 11 | 4 | 0 | User notifications — type, data, linked member/creator |
| 9 | **Attachment** | 11 | 3 | 0 | File/link attachments on cards |
| 10 | **PendingOrganizations** | 8 | 2 | 2 | Enterprise pending org invitations |

### Schema Categories (63 schemas total)

| Category | Count | Key schemas |
|---|---|---|
| **Member** | 5 | `Member`, `MemberFields`, `MemberPrefs`, `Membership`, `Memberships` |
| **Board** | 4 | `Board`, `BoardBackground`, `BoardFields`, `BoardStars` |
| **Card** | 3 | `Card`, `CardAging`, `CardFields` |
| **Organization** | 3 | `Organization`, `OrganizationFields`, `OrganizationPrefs` |
| **Notification** | 3 | `Notification`, `NotificationChannelSettings`, `NotificationFields` |
| **Plugin/Custom** | 7 | `CustomField`, `CustomFieldItems`, `Plugin`, `PluginData`, `PluginListing`, `CustomEmoji`, `CustomSticker` |
| **Auth/Webhook** | 4 | `Token`, `TokenFields`, `TokenPermission`, `Webhook` |
| **Action** | 2 | `Action`, `ActionFields` |
| **Checklist** | 2 | `CheckItem`, `Checklist` |
| **Label** | 1 | `Label` |
| **List** | 1 | `ListFields` (plus `TrelloList` in Other) |
| **Other/Infra** | 28 | `Error`, `TrelloID`, `Limits`, `Emoji`, `Export`, `Tag`, `Prefs`, etc. |

---

## Parameter Patterns

| Parameter location | Total occurrences |
|---|---|
| **Query string** | 489 |
| **Path** | 183 |

All 256 operations return **200** on success. Only 12 operations explicitly document `401`, `404`, or `default` error responses — most endpoints rely on implicit error handling.

---

## Key Observations

1. **Heavy read bias**: GET operations (125) outnumber write operations (131 combined POST/PUT/DELETE), but the split is fairly balanced, reflecting Trello's CRUD-heavy workflow nature.

2. **Query-string authentication**: Unlike most modern APIs that use `Authorization` headers, Trello passes credentials as query parameters (`key` and `token`). This is a notable security consideration since credentials can appear in server logs and browser history.

3. **Flat REST structure**: Most endpoints follow `/resource/{id}` or `/resource/{id}/sub-resource` patterns. There's no deep nesting beyond two levels.

4. **Sparse response documentation**: Only 12 of 256 operations define error responses — the spec mostly assumes success, making error handling reliant on runtime behavior rather than specification.

5. **Optional-heavy models**: Nearly all schema properties are optional (e.g., Member has 42 properties but 0 required), reflecting Trello's field-filtering approach where API consumers request specific fields via query parameters.

6. **`/members` is the richest surface**: With 45 operations it's the largest resource group, covering profile data, boards, cards, organizations, saved searches, custom stickers/emoji, and notification preferences.
