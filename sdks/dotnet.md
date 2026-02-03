---
layout: default
title: .NET SDK
---

# <img src="/media/logo.svg" alt="" class="inline-logo">.NET SDK

The official JSON Structure SDK for .NET (C#, F#, VB.NET).

## Installation

```bash
dotnet add package JsonStructure
```

Or via Package Manager:

```powershell
Install-Package JsonStructure
```

## Package Links

- **NuGet**: [JsonStructure](https://www.nuget.org/packages/JsonStructure)
- **GitHub**: [json-structure/sdk/dotnet](https://github.com/json-structure/sdk/tree/master/dotnet)

## Usage

```csharp
using JsonStructure;

// Validate a schema
var schemaValidator = new SchemaValidator();
var schemaResult = schemaValidator.Validate(schema);

// Validate an instance against a schema
var instanceValidator = new InstanceValidator();
var instanceResult = instanceValidator.Validate(instance, schema);
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- .NET 6.0+ and .NET Standard 2.0 support
- Thread-safe validators
- Strong typing with nullable reference types

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/dotnet#readme) for full documentation.
