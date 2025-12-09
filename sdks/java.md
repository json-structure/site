---
layout: default
title: Java SDK
---

# Java SDK

The official JSON Structure SDK for Java.

## Installation

### Maven

```xml
<dependency>
    <groupId>com.json-structure</groupId>
    <artifactId>json-structure-sdk</artifactId>
    <version>0.5.3</version>
</dependency>
```

### Gradle

```groovy
implementation 'com.json-structure:json-structure-sdk:0.5.3'
```

## Package Links

- **Maven Central**: [json-structure-sdk](https://central.sonatype.com/artifact/com.json-structure/json-structure-sdk)
- **GitHub**: [json-structure/sdk/java](https://github.com/json-structure/sdk/tree/master/java)

## Usage

```java
import com.jsonstructure.SchemaValidator;
import com.jsonstructure.InstanceValidator;

// Validate a schema
SchemaValidator schemaValidator = new SchemaValidator();
ValidationResult schemaResult = schemaValidator.validate(schema);

// Validate an instance against a schema
InstanceValidator instanceValidator = new InstanceValidator();
ValidationResult instanceResult = instanceValidator.validate(instance, schema);
```

## Features

- Schema validation against JSON Structure meta-schemas
- Instance validation against JSON Structure schemas
- Java 11+ support
- Thread-safe validators
- No external JSON library dependency (uses built-in)

## Documentation

See the [README](https://github.com/json-structure/sdk/tree/master/java#readme) for full documentation.
