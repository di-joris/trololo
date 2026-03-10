# Trello Checklist Endpoints

The Trello OpenAPI spec (`trello-openapi.json`) defines **17 endpoints** for managing checklists, organized into four groups: standalone checklist CRUD, check-item management, board/card-level checklist operations, and field-level access.

---

## 1. Standalone Checklist Endpoints (`/checklists/...`)

### `POST /checklists` — Create a Checklist
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `idCard` | query | ✅ | string | The ID of the Card to add the checklist to |
| `name` | query | | string | Checklist name (1–16384 chars) |
| `pos` | query | | string | Position: `top`, `bottom`, or a positive number |
| `idChecklistSource` | query | | string | ID of a checklist to copy from |

### `GET /checklists/{id}` — Get a Checklist
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `cards` | query | | string | `all`, `closed`, `none`, `open`, `visible` |
| `checkItems` | query | | string | `all` or `none` |
| `checkItem_fields` | query | | string | `all` or comma-separated: `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember` |
| `fields` | query | | string | `all` or comma-separated checklist fields |

### `PUT /checklists/{id}` — Update a Checklist
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `name` | query | | string | New checklist name (1–16384 chars) |
| `pos` | query | | string | Position: `top`, `bottom`, or a positive number |

### `DELETE /checklists/{id}` — Delete a Checklist
No parameters (aside from the `{id}` path segment).

---

## 2. Checklist Check-Item Endpoints (`/checklists/{id}/checkItems/...`)

### `GET /checklists/{id}/checkItems` — Get Checkitems on a Checklist
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `filter` | query | | string | `all` or `none` |
| `fields` | query | | string | `all`, `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember` |

### `POST /checklists/{id}/checkItems` — Create Checkitem on Checklist
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `name` | query | ✅ | string | Check-item name (1–16384 chars) |
| `pos` | query | | string | Position: `top`, `bottom`, or a positive number |
| `checked` | query | | boolean | Whether the item starts checked |
| `due` | query | | string | A due date for the check-item |
| `dueReminder` | query | | number | Due-date reminder offset |
| `idMember` | query | | string | ID of a member to assign |

### `GET /checklists/{id}/checkItems/{idCheckItem}` — Get a Checkitem on a Checklist
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `fields` | query | | string | `all`, `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember` |

### `DELETE /checklists/{id}/checkItems/{idCheckItem}` — Delete Checkitem from Checklist
No parameters (aside from the path segments).

---

## 3. Checklist Relationship Endpoints

### `GET /checklists/{id}/board` — Get the Board the Checklist is on
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `id` | path | ✅ | string | ID of the checklist |
| `fields` | query | | string | `all` or comma-separated board fields |

### `GET /checklists/{id}/cards` — Get the Card a Checklist is on
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `id` | path | ✅ | string | ID of the checklist |

---

## 4. Checklist Field-Level Endpoints (`/checklists/{id}/{field}`)

### `GET /checklists/{id}/{field}` — Get field on a Checklist
No query parameters. The `{field}` path segment selects which field to return.

### `PUT /checklists/{id}/{field}` — Update field on a Checklist
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `value` | query | ✅ | string | The new value for the field (1–16384 chars for name) |

---

## 5. Board-Level Checklist Endpoint

### `GET /boards/{id}/checklists` — Get Checklists on a Board
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `id` | path | ✅ | string | The ID of the board |

---

## 6. Card-Level Checklist Endpoints

### `GET /cards/{id}/checklists` — Get Checklists on a Card
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `id` | path | ✅ | string | The ID of the Card |
| `checkItems` | query | | string | `all` or `none` |
| `checkItem_fields` | query | | string | `all` or comma-separated: `name`, `nameData`, `pos`, `state`, `type`, `due`, `dueReminder`, `idMember` |
| `filter` | query | | string | `all` or `none` |
| `fields` | query | | string | `all` or comma-separated: `idBoard`, `idCard`, `name`, `pos` |

### `POST /cards/{id}/checklists` — Create Checklist on a Card
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `id` | path | ✅ | string | The ID of the Card |
| `name` | query | | string | The name of the checklist |
| `idChecklistSource` | query | | string | ID of a source checklist to copy |
| `pos` | query | | string | Position: `top`, `bottom`, or a positive number |

### `DELETE /cards/{id}/checklists/{idChecklist}` — Delete a Checklist on a Card
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `id` | path | ✅ | string | The ID of the Card |
| `idChecklist` | path | ✅ | string | The ID of the checklist to delete |

### `PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}` — Update Checkitem on Checklist on Card
| Parameter | In | Required | Type | Description |
|---|---|---|---|---|
| `idCard` | path | ✅ | string | The ID of the Card |
| `idChecklist` | path | ✅ | string | The ID of the checklist |
| `idCheckItem` | path | ✅ | string | The ID of the check-item to update |
| `pos` | query | | string | `top`, `bottom`, or a positive float |

---

## Summary Table

| # | Method | Path | Summary |
|---|--------|------|---------|
| 1 | `POST` | `/checklists` | Create a Checklist |
| 2 | `GET` | `/checklists/{id}` | Get a Checklist |
| 3 | `PUT` | `/checklists/{id}` | Update a Checklist |
| 4 | `DELETE` | `/checklists/{id}` | Delete a Checklist |
| 5 | `GET` | `/checklists/{id}/checkItems` | Get Checkitems on a Checklist |
| 6 | `POST` | `/checklists/{id}/checkItems` | Create Checkitem on Checklist |
| 7 | `GET` | `/checklists/{id}/checkItems/{idCheckItem}` | Get a Checkitem |
| 8 | `DELETE` | `/checklists/{id}/checkItems/{idCheckItem}` | Delete Checkitem from Checklist |
| 9 | `GET` | `/checklists/{id}/board` | Get Board for Checklist |
| 10 | `GET` | `/checklists/{id}/cards` | Get Card for Checklist |
| 11 | `GET` | `/checklists/{id}/{field}` | Get field on a Checklist |
| 12 | `PUT` | `/checklists/{id}/{field}` | Update field on a Checklist |
| 13 | `GET` | `/boards/{id}/checklists` | Get Checklists on a Board |
| 14 | `GET` | `/cards/{id}/checklists` | Get Checklists on a Card |
| 15 | `POST` | `/cards/{id}/checklists` | Create Checklist on a Card |
| 16 | `DELETE` | `/cards/{id}/checklists/{idChecklist}` | Delete Checklist on a Card |
| 17 | `PUT` | `/cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}` | Update Checkitem on Card |
