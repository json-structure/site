
---
layout: default
image: /social-cards/home.png
---

# <img src="/media/logo.svg" alt="" class="inline-logo">JSON Structure

JSON Structure is a schema language that can describe data types and structures
whose definitions map cleanly to programming language types and database
constructs as well as to the popular JSON data encoding. The type model reflects
the needs of modern applications and allows for rich annotations with semantic
information that can be evaluated and understood by developers and by large
language models (LLMs).

<style>
pre.jsonx {
  font-family: "JetBrains Mono", "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
  font-size: 0.8rem;
  line-height: 1.55;
  background: #fbfbfd;
  border: 1px solid #e2e2ea;
  border-radius: 4px;
  padding: 1rem 1.1rem;
  overflow-x: auto;
  color: #24292f;
}
pre.jsonx .s { color: #032f62; }
pre.jsonx .n { color: #b31d28; }
pre.jsonx .p { color: #6a737d; }
pre.jsonx .k {
  color: #044289;
  font-weight: 700;
  background: #ddf0fb;
  border-bottom: 2px solid #2188cc;
  padding: 0 2px;
  border-radius: 2px;
}
pre.jsonx .x {
  color: #8a4b00;
  font-weight: 700;
  background: #fff3d4;
  border-bottom: 2px solid #e6a817;
  padding: 0 2px;
  border-radius: 2px;
}
pre.jsonx .lnk {
  background: #d7f2ef;
  border-bottom: 2px solid #2ba39a;
  padding: 0 2px;
  border-radius: 2px;
}
.legend {
  font-size: 0.85rem;
  color: #57606a;
  margin: 0 0 1.4rem 0;
}
.legend .sw {
  display: inline-block;
  width: 0.75rem;
  height: 0.75rem;
  border-radius: 2px;
  vertical-align: -1px;
  margin-right: 0.2rem;
}
</style>

<p class="legend">
<span class="sw" style="background:#ddf0fb;border-bottom:2px solid #2188cc"></span> core keywords &nbsp;·&nbsp;
<span class="sw" style="background:#fff3d4;border-bottom:2px solid #e6a817"></span> companion-specification keywords &nbsp;·&nbsp;
<span class="sw" style="background:#d7f2ef;border-bottom:2px solid #2ba39a"></span> the companions this schema opts into
</p>

<pre class="jsonx"><span class="p">{</span>
    <span class="k">"$schema"</span><span class="p">:</span> <span class="s">"https://json-structure.org/meta/extended/v0/#"</span><span class="p">,</span>
    <span class="k">"$id"</span><span class="p">:</span> <span class="s">"https://example.com/schemas/product"</span><span class="p">,</span>
    <span class="k">"$uses"</span><span class="p">: [</span><span class="lnk">"JSONStructureAlternateNames"</span><span class="p">,</span> <span class="lnk">"JSONStructureUnits"</span><span class="p">],</span>
    <span class="k">"type"</span><span class="p">:</span> <span class="s">"object"</span><span class="p">,</span>
    <span class="k">"name"</span><span class="p">:</span> <span class="s">"Product"</span><span class="p">,</span>
    <span class="k">"properties"</span><span class="p">: {</span>
        <span class="s">"id"</span><span class="p">: {</span>
            <span class="k">"type"</span><span class="p">:</span> <span class="s">"uuid"</span><span class="p">,</span>
            <span class="k">"description"</span><span class="p">:</span> <span class="s">"Unique identifier for the product"</span>
        <span class="p">},</span>
        <span class="s">"name"</span><span class="p">: {</span>
            <span class="k">"type"</span><span class="p">:</span> <span class="s">"string"</span><span class="p">,</span>
            <span class="x">"maxLength"</span><span class="p">:</span> <span class="n">100</span><span class="p">,</span>
            <span class="x">"altnames"</span><span class="p">: {</span>
                <span class="s">"json"</span><span class="p">:</span> <span class="s">"product_name"</span><span class="p">,</span>
                <span class="s">"lang:en"</span><span class="p">:</span> <span class="s">"Product Name"</span><span class="p">,</span>
                <span class="s">"lang:de"</span><span class="p">:</span> <span class="s">"Produktname"</span>
            <span class="p">}</span>
        <span class="p">},</span>
        <span class="s">"price"</span><span class="p">: {</span>
            <span class="k">"type"</span><span class="p">:</span> <span class="s">"decimal"</span><span class="p">,</span>
            <span class="x">"precision"</span><span class="p">:</span> <span class="n">10</span><span class="p">,</span>
            <span class="x">"scale"</span><span class="p">:</span> <span class="n">2</span><span class="p">,</span>
            <span class="x">"currency"</span><span class="p">:</span> <span class="s">"USD"</span>
        <span class="p">},</span>
        <span class="s">"weight"</span><span class="p">: {</span>
            <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span>
            <span class="x">"unit"</span><span class="p">:</span> <span class="s">"kg"</span>
        <span class="p">},</span>
        <span class="s">"created"</span><span class="p">: {</span>
            <span class="k">"type"</span><span class="p">:</span> <span class="s">"datetime"</span>
        <span class="p">},</span>
        <span class="s">"tags"</span><span class="p">: {</span>
            <span class="k">"type"</span><span class="p">:</span> <span class="s">"set"</span><span class="p">,</span>
            <span class="k">"items"</span><span class="p">: {</span> <span class="k">"type"</span><span class="p">:</span> <span class="s">"string"</span> <span class="p">}</span>
        <span class="p">},</span>
        <span class="s">"attributes"</span><span class="p">: {</span>
            <span class="k">"type"</span><span class="p">:</span> <span class="s">"map"</span><span class="p">,</span>
            <span class="k">"values"</span><span class="p">: {</span> <span class="k">"type"</span><span class="p">:</span> <span class="s">"string"</span> <span class="p">}</span>
        <span class="p">}</span>
    <span class="p">},</span>
    <span class="k">"required"</span><span class="p">: [</span><span class="s">"id"</span><span class="p">,</span> <span class="s">"name"</span><span class="p">,</span> <span class="s">"price"</span><span class="p">,</span> <span class="s">"created"</span><span class="p">]</span>
<span class="p">}</span>
</pre>

JSON Structure's syntax is similar to that of JSON Schema, but while JSON Schema
focuses on document validation, JSON Structure focuses on being a strong data
definition language that also supports validation.

- Clear mapping to programming language types
- Support for more precise numeric types and date/time representations
- Modular approach to extensions
- Simplified cross-references between schema documents
- Straightforward reuse patterns for types
- Support for multilingual descriptions and alternate names
- Support for symbols, scientific units, currency codes, and UCUM notation
- Support for semantic roles and reference systems on observation data

## Primer and Core Specification

The [Primer](json-structure-primer.html) is a high-level overview of the JSON
Structure language and its features. It is intended for developers and users who
want to understand the language's capabilities and how to use it effectively.

The [JSON Structure Core Specification](https://json-structure.github.io/core)
provides a detailed description of the JSON Structure language, including its
syntax, semantics, and data types. It is intended for implementers and
developers who want to create tools and libraries that work with JSON Structure.

## Extensions

- [JSON Structure: Import](https://json-structure.github.io/import): Defines a
  mechanism for importing external schemas and definitions into a schema
  document.
- [JSON Structure: Alternate Names and
  Descriptions](https://json-structure.github.io/alternate-names): Provides a
  mechanism for declaring multilingual descriptions, and alternate names and
  symbols for types and properties.
- [JSON Structure: Symbols, Scientific Units, and
  Currencies](https://json-structure.github.io/units): Defines annotation
  keywords for specifying symbols, scientific units, currency codes, and UCUM
  (Unified Code for Units of Measure) notation complementing type information.
- [JSON Structure: Validation](https://json-structure.github.io/validation):
  Specifies extensions to the core schema language for declaring validation
  rules for JSON data that have no structural impact on the schema.
- [JSON Structure:
  Composition](https://json-structure.github.io/conditional-composition):
  Defines a set of conditional composition rules for evaluating schemas.
- [JSON Structure:
  Relations](https://json-structure.github.io/relations): Declares identity
  constraints and inter-type relationships for objects and tuples.
- [JSON Structure: Semantic and Reference-System
  Annotations](https://json-structure.github.io/semantic-annotations): Declares
  what the values in an observation mean — the property observed, the feature it
  belongs to, the time it refers to — and the temporal, coordinate, and linear
  reference systems those values are expressed in.

## SDKs

Official JSON Structure SDKs are available for multiple languages:

| Language | Package | Install |
|----------|---------|---------|
| **TypeScript/JavaScript** | [@json-structure/sdk](https://www.npmjs.com/package/@json-structure/sdk) | `npm install @json-structure/sdk` |
| **Python** | [json-structure](https://pypi.org/project/json-structure/) | `pip install json-structure` |
| **.NET** | [JsonStructure](https://www.nuget.org/packages/JsonStructure) | `dotnet add package JsonStructure` |
| **Java** | [json-structure-sdk](https://central.sonatype.com/artifact/com.json-structure/json-structure-sdk) | Maven/Gradle (see docs) |
| **Go** | [github.com/json-structure/sdk/go](https://pkg.go.dev/github.com/json-structure/sdk/go) | `go get github.com/json-structure/sdk/go` |
| **Rust** | [json-structure](https://crates.io/crates/json-structure) | `cargo add json-structure` |
| **Ruby** | [jsonstructure](https://rubygems.org/gems/jsonstructure) | `gem install jsonstructure` |
| **R** | [jsonstructure](https://github.com/json-structure/sdk/tree/master/r) | `remotes::install_github("json-structure/sdk", subdir = "r")` |
| **Perl** | [JSON::Structure](https://metacpan.org/pod/JSON::Structure) | `cpanm JSON::Structure` |
| **PHP** | [json-structure/sdk](https://packagist.org/packages/json-structure/sdk) | `composer require json-structure/sdk` |
| **Swift** | [json-structure-swift](https://github.com/json-structure/sdk/tree/master/swift) | Swift Package Manager |
| **C** | [json-structure](https://github.com/json-structure/sdk/tree/master/c) | vcpkg or CMake FetchContent |

All SDKs provide schema validation and instance validation against JSON Structure schemas.

### VS Code Extension

The [JSON Structure VS Code Extension](https://marketplace.visualstudio.com/items?itemName=json-structure.json-structure-sdk) provides:
- Schema validation with inline diagnostics
- IntelliSense for JSON Structure keywords
- Hover documentation for types and properties
- Quick fixes for common issues

