# OpenAPI Structure Quick Reference

## OpenAPI 3.x vs Swagger 2.0

| Feature | OpenAPI 3.x | Swagger 2.0 |
|---------|------------|-------------|
| Version field | `openapi: "3.x.x"` | `swagger: "2.0"` |
| Schemas location | `components.schemas` | `definitions` |
| Parameters location | `components.parameters` | `parameters` (top-level) |
| Request body | `requestBody` (separate from parameters) | `in: body` parameter |
| Base URL | `servers[].url` | `host` + `basePath` + `schemes` |
| Content types | `content` object with media types | `consumes` / `produces` |
| Security | `components.securitySchemes` | `securityDefinitions` |

## OpenAPI Type System

### Primitive Types

| OpenAPI Type | Format | Description |
|-------------|--------|-------------|
| `string` | — | Plain string |
| `string` | `date` | ISO 8601 date (YYYY-MM-DD) |
| `string` | `date-time` | ISO 8601 datetime |
| `string` | `email` | Email address |
| `string` | `uri` | URI/URL |
| `string` | `uuid` | UUID |
| `string` | `binary` | Binary data |
| `string` | `byte` | Base64 encoded |
| `integer` | `int32` | 32-bit integer |
| `integer` | `int64` | 64-bit integer |
| `number` | `float` | Float |
| `number` | `double` | Double |
| `boolean` | — | Boolean |

### Complex Types

```json
// Object
{
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "age": { "type": "integer" }
  },
  "required": ["name"]
}

// Array
{
  "type": "array",
  "items": { "$ref": "#/components/schemas/Item" }
}

// Enum
{
  "type": "string",
  "enum": ["active", "inactive", "pending"]
}

// Composition
{
  "allOf": [
    { "$ref": "#/components/schemas/Base" },
    { "type": "object", "properties": { "extra": { "type": "string" } } }
  ]
}
```

## Common jq Patterns for OpenAPI

### Navigation
```bash
# API info
jq '.info' spec.json

# All paths
jq '.paths | keys[]' spec.json

# All schemas
jq '.components.schemas | keys[]' spec.json
jq '.definitions | keys[]' swagger.json  # Swagger 2.0

# Server URLs
jq '.servers[].url' spec.json
jq '"\(.schemes[0])://\(.host)\(.basePath)"' swagger.json  # Swagger 2.0
```

### Endpoint Analysis
```bash
# Full endpoint definition
jq '.paths["/path"].get' spec.json

# Parameters only
jq '.paths["/path"].get.parameters' spec.json

# Path parameters only
jq '[.paths["/path"].get.parameters[] | select(.in == "path")]' spec.json

# Query parameters only  
jq '[.paths["/path"].get.parameters[] | select(.in == "query")]' spec.json

# Required parameters
jq '[.paths["/path"].get.parameters[] | select(.required == true)]' spec.json

# Response schema
jq '.paths["/path"].get.responses["200"].content["application/json"].schema' spec.json

# Operation ID
jq '.paths["/path"].get.operationId' spec.json
```

### Schema Analysis
```bash
# Full schema
jq '.components.schemas["Name"]' spec.json

# Property names
jq '.components.schemas["Name"].properties | keys[]' spec.json

# Required fields
jq '.components.schemas["Name"].required' spec.json

# Property types
jq '.components.schemas["Name"].properties | to_entries[] | "\(.key): \(.value.type // .value["$ref"])"' spec.json
```

### Bulk Operations
```bash
# All GET endpoints
jq -r '.paths | to_entries[] | .key as $p | .value | to_entries[] | select(.key == "get") | "GET \($p)"' spec.json

# Endpoints returning arrays
jq -r '.paths | to_entries[] | .key as $p | .value | to_entries[] | select(.value.responses?["200"]?.content?["application/json"]?.schema?.type? == "array") | "\(.key | ascii_upcase) \($p)"' spec.json

# All schemas referenced by a specific schema
jq '[.components.schemas["Name"] | .. | .["$ref"]? // empty]' spec.json
```
