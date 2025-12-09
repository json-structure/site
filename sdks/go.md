---
layout: default
title: Go SDK
---

# Go SDK

The official JSON Structure SDK for Go.

## Installation

```bash
go get github.com/json-structure/sdk/go@v0.5.4
```

## Package Links

- **pkg.go.dev**: [github.com/json-structure/sdk/go](https://pkg.go.dev/github.com/json-structure/sdk/go)
- **GitHub**: [json-structure/sdk/go](https://github.com/json-structure/sdk/tree/master/go)

## Usage

```go
package main

import (
    jsonstructure "github.com/json-structure/sdk/go"
)

func main() {
    // Validate a schema
    schemaValidator := jsonstructure.NewSchemaValidator()
    schemaResult := schemaValidator.Validate(schema)

    // Validate an instance against a schema
    instanceValidator := jsonstructure.NewInstanceValidator()
    instanceResult := instanceValidator.Validate(instance, schema)
}
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- Go 1.21+ support
- Concurrent-safe validators
- Zero external dependencies

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/go#readme) for full documentation.
