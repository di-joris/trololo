---
name: openapi-parser
description: Parse, query, and generate code from OpenAPI (Swagger) specification files. Use when users (1) ask about REST API endpoints, schemas, parameters, or response types from an OpenAPI spec, (2) want to understand an API's surface area or list available endpoints, (3) need to generate models, API clients, or types from a spec, (4) reference files named openapi.json, swagger.yaml, *-openapi.json, or similar, (5) ask "what endpoints exist for X", "generate a model for Y schema", "what parameters does Z accept", or "what's not implemented yet", (6) want gap analysis between spec and existing code, or (7) need to resolve $ref chains or extract nested schema relationships. Provides jq-based extraction patterns for efficient large-spec navigation without loading full files into context.
---

# OpenAPI Parser

This skill helps you work with OpenAPI specification files — extracting information, answering questions about API surfaces, and generating code from schemas and endpoints.

## Why this skill exists

OpenAPI specs are often large (thousands of lines) and densely nested. Reading them raw is tedious. This skill gives you a systematic approach to navigating specs efficiently and translating them into useful artifacts like models, API clients, and documentation.

## Core capabilities

1. **Spec navigation** — Find endpoints, schemas, parameters, and response types quickly
2. **Schema extraction** — Pull out model definitions with their properties, types, and constraints
3. **Endpoint analysis** — Understand what an endpoint accepts and returns, including nested references
4. **Code generation** — Generate typed models, API client methods, and related code from the spec
5. **API surface overview** — Summarize what an API offers at a high level

## Working with OpenAPI specs

### Step 1: Locate and load the spec

Find the OpenAPI spec file in the project. Common locations and names:
- `openapi.json`, `openapi.yaml`, `swagger.json`, `swagger.yaml`
- `*-openapi.json`, `*-openapi.yaml`
- `api/`, `docs/`, `specs/` directories

Once found, determine the spec version (OpenAPI 3.x vs Swagger 2.0) by checking the top-level `openapi` or `swagger` field. This affects where schemas and other definitions live.

### Step 2: Understand the spec structure

OpenAPI 3.x specs have this high-level layout:

```
{
  "openapi": "3.x.x",
  "info": { ... },           // API metadata (title, version, description)
  "servers": [ ... ],        // Base URLs
  "paths": {                 // All endpoints
    "/resource/{id}": {
      "get": { ... },
      "post": { ... }
    }
  },
  "components": {
    "schemas": { ... },      // Data models / types
    "parameters": { ... },   // Reusable parameters
    "responses": { ... },    // Reusable responses
    "securitySchemes": { ... }
  }
}
```

Swagger 2.0 uses `definitions` instead of `components/schemas` and `basePath` instead of `servers`.

### Step 3: Use jq for efficient extraction

Don't read the entire spec into context when you only need specific parts. Use `jq` to extract exactly what you need:

**List all endpoint paths:**
```bash
jq -r '.paths | keys[]' spec.json
```

**List all endpoints with their HTTP methods:**
```bash
jq -r '.paths | to_entries[] | .key as $path | .value | to_entries[] | select(.key | test("get|post|put|patch|delete")) | "\(.key | ascii_upcase) \($path)"' spec.json
```

**Get a specific endpoint's definition:**
```bash
jq '.paths["/boards/{id}"].get' spec.json
```

**List all schema names:**
```bash
jq -r '.components.schemas // .definitions | keys[]' spec.json
```

**Get a specific schema:**
```bash
jq '.components.schemas["Board"] // .definitions["Board"]' spec.json
```

**Find endpoints that return a specific schema:**
```bash
jq -r '.paths | to_entries[] | .key as $path | .value | to_entries[] | select(.value.responses?["200"]?.content?["application/json"]?.schema?["$ref"]? // "" | test("Board")) | "\(.key | ascii_upcase) \($path)"' spec.json
```

**Get all parameters for an endpoint:**
```bash
jq '.paths["/boards/{id}"].get.parameters' spec.json
```

**Count endpoints by HTTP method:**
```bash
jq '[.paths | to_entries[] | .value | to_entries[] | select(.key | test("get|post|put|patch|delete")) | .key] | group_by(.) | map({method: .[0], count: length})' spec.json
```

**Find all endpoints under a path prefix:**
```bash
jq '.paths | to_entries[] | select(.key | startswith("/boards"))' spec.json
```

### Step 4: Resolve $ref references

OpenAPI specs use `$ref` extensively. A reference like `"$ref": "#/components/schemas/Board"` points to the `Board` schema in the same file. When you encounter a `$ref`:

1. Parse the reference path (everything after `#/`)
2. Navigate to that location in the spec
3. Extract the referenced definition

Use jq to resolve refs:
```bash
# Extract the ref target from a response
jq -r '.paths["/boards/{id}"].get.responses["200"].content["application/json"].schema["$ref"]' spec.json

# Then fetch the referenced schema (strip the #/ prefix)
jq '.components.schemas["Board"]' spec.json
```

For specs with deeply nested refs (schemas referencing other schemas), you may need to recursively resolve. Extract the top-level schema first, then follow any `$ref` fields within it.

### Step 5: Handle common patterns

**Array responses:** Many list endpoints return arrays. The schema will look like:
```json
{ "type": "array", "items": { "$ref": "#/components/schemas/Board" } }
```

**Inline schemas:** Some endpoints define schemas inline rather than referencing components. Extract these directly from the endpoint definition.

**allOf / oneOf / anyOf:** Composition keywords combine schemas. `allOf` means "all of these properties", `oneOf` means "exactly one of these", `anyOf` means "one or more of these".

**Nullable fields:** Check for `"nullable": true` (OpenAPI 3.0) or `"type": ["string", "null"]` (OpenAPI 3.1).

**Required vs optional:** The `required` array in a schema lists required property names. Properties not in this array are optional.

## Generating code from the spec

When generating code (models, API clients, types), follow these principles:

### Models / Types

1. **Read the schema** using jq to extract the specific component
2. **Map types** from OpenAPI to the target language:
   - `string` → `String` (Swift), `string` (TypeScript), `str` (Python), etc.
   - `integer` → `Int`, `number`, `int`
   - `number` → `Double`, `number`, `float`
   - `boolean` → `Bool`, `boolean`, `bool`
   - `array` → `[T]`, `T[]`, `List[T]`
   - `object` → nested struct/class/interface
   - `$ref` → reference to another model type
3. **Handle optionality** — properties not in the `required` array should be optional in the generated type
4. **Preserve naming** — use the property names from the schema, applying the target language's naming conventions (e.g., camelCase for Swift/JS, snake_case for Python/Ruby)
5. **Include format hints** — `format: "date-time"` → `Date`, `format: "email"` → validated string, `format: "uri"` → `URL`

### API client methods

1. **Read the endpoint** definition (path, method, parameters, request body, responses)
2. **Extract parameters** — separate path params, query params, headers, and request body
3. **Determine return type** — from the success response schema (usually 200 or 201)
4. **Generate the method** with:
   - Path parameter interpolation
   - Query parameter encoding
   - Request body serialization (for POST/PUT/PATCH)
   - Response deserialization to the appropriate model type
   - Error handling for non-success status codes

### Matching project conventions

Before generating code, examine the existing codebase for patterns:
- How are models structured? (structs vs classes, protocols/interfaces they conform to)
- How are API methods organized? (extensions, services, modules)
- What naming conventions are used?
- How is error handling done?
- What testing patterns exist?

Generate code that fits naturally into the existing codebase rather than introducing new patterns.

## Resolving deeply nested $ref chains

Many specs have schemas that reference other schemas. To generate complete code, you must resolve these chains. Use this systematic approach:

**Step 1: Get the top-level schema and list its refs:**
```bash
jq '[.components.schemas["Card"] | .. | .["$ref"]? // empty] | unique' spec.json
```

**Step 2: Extract all referenced schemas in one pass:**
```bash
# Get Card and all schemas it references
jq '{Card: .components.schemas["Card"], Label: .components.schemas["Label"], Checklist: .components.schemas["Checklist"]}' spec.json
```

**Step 3: For unknown ref depth, build a dependency graph:**
```bash
# For each schema, list what it references
jq '.components.schemas | to_entries[] | {schema: .key, refs: [.value | .. | .["$ref"]? // empty | split("/") | last] | unique}' spec.json
```

This tells you which schemas to generate first (those with no outbound refs) and which depend on others.

## Batch operations: generating multiple models at once

When the user asks to implement an entire resource (e.g., "add checklist support"), you need to generate models, endpoints, and tests for multiple related types. Follow this workflow:

1. **Identify all schemas for the resource:**
```bash
# Find schemas related to "checklist"
jq -r '.components.schemas | keys[] | select(test("checklist|checkitem|CheckItem|Checklist"; "i"))' spec.json
```

2. **Identify all endpoints for the resource:**
```bash
jq -r '.paths | to_entries[] | .key as $p | .value | to_entries[] | select(.key | test("get|post|put|patch|delete")) | "\(.key | ascii_upcase) \($p)"' spec.json | grep -i checklist
```

3. **Extract all schemas at once** (avoid repeated jq calls):
```bash
jq '{Checklist: .components.schemas["Checklist"], CheckItem: .components.schemas["CheckItem"]}' spec.json
```

4. **Generate models in dependency order** — models with no refs to other project models first, then those that reference them.

5. **Generate endpoints grouped by resource** — one file per resource (e.g., `ChecklistsAPI.swift`) with all related methods.

6. **Generate tests covering:** decoding (full, minimal, null fields), round-trip encode/decode, and endpoint URL/path verification.

## Gap analysis: spec vs implementation

When a project partially implements an API, help identify what's missing:

**List all implemented endpoints** (from existing code):
```bash
# Example for Swift: find all path strings in endpoint files
grep -r '"/[a-z]' Sources/*/Endpoints/ | grep -oE '"/[^"]+' | sort
```

**List all spec endpoints:**
```bash
jq -r '.paths | to_entries[] | .key as $p | .value | to_entries[] | select(.key | test("get|post|put|patch|delete")) | "\(.key | ascii_upcase) \($p)"' spec.json | sort
```

**Compare** to find unimplemented endpoints and prioritize by user need.

**List implemented vs available schemas:**
```bash
# Schemas in spec
jq -r '.components.schemas | keys[]' spec.json | sort > /tmp/spec_schemas.txt

# Models in code (example for Swift)
ls Sources/*/Models/*.swift | xargs -I{} basename {} .swift | sort > /tmp/code_models.txt

# Unimplemented schemas
comm -23 /tmp/spec_schemas.txt /tmp/code_models.txt
```

## Handling request bodies (POST/PUT/PATCH)

For write endpoints, extract the request body schema:

```bash
# Get the request body schema for a POST endpoint
jq '.paths["/cards"].post.requestBody.content["application/json"].schema' spec.json

# Or for form-encoded bodies
jq '.paths["/cards"].post.requestBody.content["application/x-www-form-urlencoded"].schema' spec.json

# Some APIs use query parameters for writes (e.g., Trello)
jq '[.paths["/cards"].post.parameters[] | select(.in == "query")]' spec.json
```

When generating write methods, include:
- All required parameters as non-optional method arguments
- Optional parameters with default nil/null values
- Request body encoding (JSON or form-encoded, matching the spec's content type)

## Tips for large specs

- **Don't load the whole file.** Use jq to extract only what you need. A 16,000-line spec consumed in full wastes context.
- **Start with an overview.** Count endpoints, list schemas, understand the API's domain before diving into specifics.
- **Group by resource.** Most REST APIs organize endpoints by resource (e.g., all `/boards/*` endpoints relate to boards). Work one resource at a time.
- **Check for patterns.** Many APIs follow consistent patterns — once you understand how one CRUD resource works, others likely follow the same structure.
- **Watch for auth.** Check `securitySchemes` and per-endpoint `security` to understand how authentication works (API keys, OAuth, bearer tokens, etc.).
- **Use parallel jq calls.** When you need multiple pieces of information (e.g., a schema AND its related endpoints), run multiple jq commands chained with `&&` in a single bash call rather than separate calls.
- **Cache schema extractions.** If you'll reference a schema multiple times, extract it once and store the result rather than re-querying the spec.
