# Trello Checklist Endpoints

The Trello API exposes **17 endpoints** for managing checklists and their check items, organized into four groups.

---

## 1. Checklist CRUD (`/checklists`)

| Method | Path | Summary | Parameters |
|--------|------|---------|------------|
| **POST** | `/checklists` | Create a Checklist | `idCard` (query, **required**) — card to add the checklist to; `name` (query) — checklist name (1–16384 chars); `pos` (query) — `top`, `bottom`, or number; `idChecklistSource` (query) — ID of checklist to copy |
| **GET** | `/checklists/{id}` | Get a Checklist | `id` (path, **required**); `cards` (query) — `all`, `closed`, `none`, `open`, `visible`; `checkItems` (query) — `all` or `none`; `checkItem_fields` (query) — `all` or comma-separated list: `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember`; `fields` (query) — `all` or comma-separated checklist fields |
| **PUT** | `/checklists/{id}` | Update a Checklist | `id` (path, **required**); `name` (query) — new name (1–16384 chars); `pos` (query) — `top`, `bottom`, or number |
| **DELETE** | `/checklists/{id}` | Delete a Checklist | `id` (path, **required**) |

### Checklist field & relationship access

| Method | Path | Summary | Parameters |
|--------|------|---------|------------|
| **GET** | `/checklists/{id}/{field}` | Get field on a Checklist | `id` (path, **required**); `field` (path, **required**) |
| **PUT** | `/checklists/{id}/{field}` | Update field on a Checklist | `id` (path, **required**); `field` (path, **required**); `value` (query, **required**) — new value (1–16384 chars) |
| **GET** | `/checklists/{id}/board` | Get the Board the Checklist is on | `id` (path, **required**); `fields` (query) — `all` or comma-separated board fields |
| **GET** | `/checklists/{id}/cards` | Get the Card a Checklist is on | `id` (path, **required**) |

---

## 2. Check Items on a Checklist (`/checklists/{id}/checkItems`)

| Method | Path | Summary | Parameters |
|--------|------|---------|------------|
| **GET** | `/checklists/{id}/checkItems` | Get Checkitems on a Checklist | `id` (path, **required**); `filter` (query) — `all` or `none`; `fields` (query) — `all`, `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember` |
| **POST** | `/checklists/{id}/checkItems` | Create Checkitem on Checklist | `id` (path, **required**); `name` (query, **required**) — item name (1–16384 chars); `pos` (query) — `top`, `bottom`, or number; `checked` (query, boolean) — pre-check the item; `due` (query) — due date; `dueReminder` (query, number) — reminder; `idMember` (query) — assigned member ID |
| **GET** | `/checklists/{id}/checkItems/{idCheckItem}` | Get a Checkitem on a Checklist | `id` (path, **required**); `idCheckItem` (path, **required**); `fields` (query) — `all`, `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember` |
| **DELETE** | `/checklists/{id}/checkItems/{idCheckItem}` | Delete Checkitem from Checklist | `id` (path, **required**); `idCheckItem` (path, **required**) |

---

## 3. Checklists on Cards (`/cards/{id}/checklists`)

| Method | Path | Summary | Parameters |
|--------|------|---------|------------|
| **GET** | `/cards/{id}/checklists` | Get Checklists on a Card | `id` (path, **required**); `checkItems` (query) — `all` or `none`; `checkItem_fields` (query) — `all` or comma-separated: `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember`; `filter` (query) — `all` or `none`; `fields` (query) — `all` or comma-separated: `idBoard`, `idCard`, `name`, `pos` |
| **POST** | `/cards/{id}/checklists` | Create Checklist on a Card | `id` (path, **required**); `name` (query) — checklist name; `idChecklistSource` (query) — source checklist to copy; `pos` (query) — `top`, `bottom`, or number |
| **DELETE** | `/cards/{id}/checklists/{idChecklist}` | Delete a Checklist on a Card | `id` (path, **required**); `idChecklist` (path, **required**) |

### Update a check item via card context

| Method | Path | Summary | Parameters |
|--------|------|---------|------------|
| **PUT** | `/cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}` | Update Checkitem on Checklist on Card | `idCard` (path, **required**); `idChecklist` (path, **required**); `idCheckItem` (path, **required**); `pos` (query) — `top`, `bottom`, or positive float |

---

## 4. Checklists on Boards (`/boards/{id}/checklists`)

| Method | Path | Summary | Parameters |
|--------|------|---------|------------|
| **GET** | `/boards/{id}/checklists` | Get Checklists on a Board | `id` (path, **required**) — board ID |

---

## Summary by HTTP Method

| Method | Count |
|--------|-------|
| GET | 9 |
| POST | 3 |
| PUT | 3 |
| DELETE | 3 |
| **Total** | **18** |

> **Note:** The `PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}` endpoint is the only way to update a check item's position or state via the card context. For CRUD operations directly on check items, use the `/checklists/{id}/checkItems` endpoints.
