---
layout: default
title: Swift SDK
---

# Swift SDK

The official JSON Structure SDK for Swift.

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/json-structure/sdk.git", from: "0.5.3")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "JsonStructure", package: "sdk")
    ]
)
```

## Package Links

- **GitHub**: [json-structure/sdk/swift](https://github.com/json-structure/sdk/tree/master/swift)

## Usage

```swift
import JsonStructure

// Validate a schema
let schemaValidator = SchemaValidator()
let schemaResult = schemaValidator.validate(schema)

// Validate an instance against a schema
let instanceValidator = InstanceValidator()
let instanceResult = instanceValidator.validate(instance, schema: schema)
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- Swift 5.9+ support
- iOS, macOS, tvOS, watchOS, Linux support
- Codable integration

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/swift#readme) for full documentation.
