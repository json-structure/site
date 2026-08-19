---
layout: post
title: "Semantic and Reference-System Annotations"
date: 2026-08-06
author: Clemens Vasters
image: /social-cards/semantic-annotations.png
description: >-
  Two schemas can agree that a member is a double in metres, pass every
  validator, and still be describing water level above a tide gauge and height
  above the ellipsoid. A new IETF Internet-Draft puts the missing fact in the
  schema: nine optional keywords, nearly all of them one shape, binding an EPSG
  coordinate system, an ICC profile, an ITU-R weighting curve, an ICAO register,
  a Landsat band set and a spacecraft vector frame alike - and saying which of
  your members supplies which axis. Type systems describe shape, graph
  vocabularies annotate instances, catalogs describe datasets, and the domain
  standards that got this right do not survive leaving their ecosystem. This is
  the first mechanism that spans all of them at zero bytes on the wire.
---

<style>
pre.jsonx {
  font-family: "JetBrains Mono", "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
  font-size: 0.86rem;
  line-height: 1.55;
  background: #fbfbfd;
  border: 1px solid #e2e2ea;
  border-radius: 4px;
  padding: 1rem 1.1rem;
  overflow-x: auto;
  color: #24292f;
}
pre.jsonx .k   { color: #005cc5; }
pre.jsonx .s   { color: #032f62; }
pre.jsonx .n   { color: #b31d28; }
pre.jsonx .b   { color: #6f42c1; }
pre.jsonx .p   { color: #6a737d; }
pre.jsonx .c   { color: #6a737d; font-style: italic; }
pre.jsonx .ann {
  color: #8a4b00;
  font-weight: 700;
  background: #fff3d4;
  border-bottom: 2px solid #e6a817;
  padding: 0 2px;
  border-radius: 2px;
}
pre.jsonx .annb {
  display: block;
  background: #fffaf0;
  border-left: 3px solid #e6a817;
  margin-left: -1.1rem;
  padding-left: calc(1.1rem - 3px);
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
.legend .swatch {
  background: #fff3d4;
  border-bottom: 2px solid #e6a817;
  padding: 0 4px;
  font-weight: 700;
  color: #8a4b00;
  font-family: monospace;
}
.legend .swatch.lnk {
  background: #d7f2ef;
  border-bottom: 2px solid #2ba39a;
  color: #14625c;
}
table.results {
  border-collapse: collapse;
  width: 100%;
  font-size: 0.92rem;
  margin: 1.2rem 0 1.6rem 0;
}
table.results th,
table.results td {
  border-bottom: 1px solid #e2e2ea;
  padding: 0.45rem 0.6rem;
  text-align: left;
  vertical-align: top;
}
table.results th {
  border-bottom: 2px solid #c9c9d4;
  font-weight: 700;
}
table.results td.num {
  font-family: "JetBrains Mono", Consolas, monospace;
  white-space: nowrap;
  width: 8rem;
}
</style>

**Two schemas can agree that a member is a `double` in metres, pass every
validator, and still be describing different quantities.** *JSON Structure:
Semantic and Reference-System Annotations* is a new IETF Internet-Draft that
puts the missing fact in the schema.

**Why it matters.** The fact that would have stopped the bad arithmetic lives in
a PDF, in a field name somebody hopes will be read the right way, or in the head
of an engineer who has since moved teams. No mainstream schema language has a
slot for it, so nothing downstream can check it — and every value still
validates.

**The short version.** Nine optional keywords, nearly all of them the same
shape: a `reference` that identifies a definition, and a `kind` that names the
model that definition belongs to. That one shape binds an EPSG coordinate
system, an ICC profile, an ITU-R weighting curve, an ICAO register, a Landsat
band set, and a spacecraft vector frame alike. Validation is unchanged. Bytes on
the wire are unchanged.

**Skip ahead:** [the keywords](#the-keywords) ·
[why nothing else covers this](#hasnt-somebody-solved-this) ·
[worked samples](#sample-three-letters-that-lie) ·
[what the measurements say](#can-a-machine-read-one-of-these-cold) ·
[links and status](#where-to-look)

## The failure this exists to stop

Two teams publish telemetry. Both schemas declare a member `double`. Both,
because these are careful people who use JSON Structure Units, declare the unit
`m`. Every validator on earth is happy. Somebody joins the two streams and
subtracts.

One of them was water level above a tide-gauge datum. The other was height above
the WGS-84 ellipsoid. They differ by tens of metres, and by how much depends on
where you are standing. Nothing validated wrong. Nothing threw. The result is
simply not a number about anything.

**The schema had nowhere to put the one fact that would have caught it.** The
draft gives it somewhere to go.

## The keywords

It extends JSON Structure Core with optional annotations, in four groups.

**Bind a node to a published term.** [`concepts`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#concepts) and [`observedProperty`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#observed-property) attach a
type or a member to a definition somebody else maintains — QUDT, the CF standard
names, a SKOS scheme, a domain catalogue — so two systems calling one thing by
two names can establish that they mean the same thing.

**Say what the record observes.** [`semanticRole`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#semantic-role) separates the result from the
property observed, the feature it belongs to, the procedure that produced it,
and the several distinct times one record can carry. [`derivation`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#derivation), [`statistic`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#statistic),
[`phenomenonTimeRelation`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#phenomenon-time-relation), and [`cadence`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#cadence) record what has already been done to the
value: measured, modelled, calculated; a mean, a maximum, a fourth-highest; an
instant, an interval, an accumulation; every minute, or on change.

**Name the reference system.** [`temporalReferenceSystem`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#temporal-reference-systems),
[`coordinateReferenceSystem`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#coordinate-reference-systems), [`linearReferenceSystem`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#linear-reference-systems), [`vectorReferenceFrames`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#vector-reference-frames),
[`tensorReferenceFrames`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#tensor-reference-frames), and [`frameTransforms`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#frame-transforms) say what a position, a direction,
or an orientation is read against — and, this is the part nothing else does,
*which of your members supplies which axis*.

**Resolve compound values.** [`colorSpaces`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#color-spaces), [`audioChannels`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#audio-channels), and [`spectralBands`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#spectral-bands)
map a set of members onto the channels or bands that give them meaning.
[`codedValues`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#coded-values) binds a short code to the register that assigns it a meaning.
[`measurementConditioning`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#measurement-conditioning-keyword) carries the frequency weighting, time weighting, and
level reference that a conditioned measurement already has baked in.

Nearly all of them are the same shape: an object with a `reference` that
identifies a definition and a `kind` that names the model that definition
belongs to. Learn the shape once and you have nine keywords.

One test decided every one of them. A quality of a value earns a keyword when a
consumer must know it to decide whether two values may be combined, and when it
holds for the type rather than varying per record. Axis order, weighting curve,
and the register a code came from all pass: get one wrong and the arithmetic is
wrong while every value still validates. Licensing and retention fail, because
they change nothing about what may be computed. A per-observation calibration
record fails, because it belongs in the payload.

The draft publishes no vocabulary, no reference system, no color space, no code
list. Established bodies do that, and an annotation points at one. What is here
is the form of the pointer, and the rules by which a processor checks that your
members agree with what you pointed at.

## Hasn't somebody solved this?

Several people have, and each of them solved it somewhere that does not travel.

**Type systems describe shape.** JSON Schema, Avro, Protobuf, Thrift, Table
Schema, Parquet, Iceberg — every one of them will tell you a member is a 64-bit
float and none of them has a place to record what it is a float *of*. That is
not an oversight. Shape is what they were built for, and a [`description`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#description-keyword) string
is where everything else has been going for twenty years.

**Graph vocabularies carry meaning on the instance.** RDF, JSON-LD, schema.org
bind a property to an IRI, which answers *what is this*. They do not answer
*what is this resolved against*. A JSON-LD context has no way to say that three
members are the components of one vector in one frame, or that two members are
the axes of a CRS and here is their order. And the binding rides with the
document — a mechanism priced for a catalog page, not for a telemetry topic
doing a hundred thousand records a second.

**Catalogs describe datasets.** DCAT, ISO 19115, DataHub, OpenMetadata, Unity
Catalog: ownership, lineage, coverage, licensing, freshness. Exactly right for
governance, and the wrong altitude for this. A catalog entry sits beside the
stream and never reaches into a record to say the third number is earthward.

**Domain standards nailed it, inside one domain.** CF conventions in netCDF.
SensorML and Observations & Measurements in OGC SWE. ICC profiles in color.
ITU weighting curves in audio. DICOM in medical imaging. CCSDS in spaceflight.
SDMX in official statistics. These are decades of careful work by people who
understood the hazard perfectly well. None of them is a schema language for
JSON, and none of them survives contact with the boundary. Take a netCDF file
apart into a Kafka topic and the CF attributes are simply gone.

**Semantic conventions name fields.** OpenTelemetry maintains a registry saying
what `http.request.method` means, and it works. But it is a naming agreement,
not a reference-system mechanism: nothing in it can express axis order or a
weighting curve, and it only governs the fields the registry has reached.

So: type-level, so it costs nothing per record. In the schema that already
ships with the data, so it crosses the boundary the domain standards do not.
Pointing at the registries those communities already maintain, so it competes
with none of them.

And then the part with no precedent anywhere on that list — **it is one shape**.
The same `reference`-and-`kind` pair binds an EPSG coordinate system, an ICC
profile, an ITU-R weighting curve, an ICAO register, a Landsat band set, a
spacecraft vector frame, a leap-second-free ordinal clock. Those communities
have never shared a mechanism and have had no reason to look for one. Under
these keywords the difference between a color space and a coordinate reference
system is which registry the pointer resolves against, and a consumer that
learned to check one has learned to check all of them.

## Sample: three letters that lie

<p class="legend">In the JSON that follows, annotation keywords are marked
<span class="swatch">like&nbsp;this</span>, and the names that bind the frame to
the members it governs are marked <span class="swatch lnk">like&nbsp;this</span>.
Everything else is ordinary JSON Structure.</p>

**The hazard: three components whose names invite three wrong readings.**

The GOES spacecraft magnetometers publish three components named `hp`, `he`, and
`hn`. Read those letters the obvious way and you get all three wrong. `hp` is
northward. `he` is *earthward*. `hn` is eastward, and the `n` is for *normal*.

They are one vector resolved in a spacecraft-local frame that no register
serves, so the frame is written out in the schema as a meta-type and cited by
pointer. The sample carries a description on every member; all but one are
stripped here:

<pre class="jsonx"><span class="p">{</span>
  <span class="k">"$schema"</span><span class="p">:</span> <span class="s">"https://json-structure.org/meta/semantic-annotations/v0/#"</span><span class="p">,</span>
  <span class="k">"$id"</span><span class="p">:</span> <span class="s">"https://schemas.example.org/semantic-annotations/real-world/20-goes-magnetometer"</span><span class="p">,</span>
  <span class="k">"$uses"</span><span class="p">: [</span><span class="s">"JSONStructureSemanticAnnotations"</span><span class="p">],</span>
  <span class="k">"name"</span><span class="p">:</span> <span class="s">"GoesMagnetometer"</span><span class="p">,</span>
  <span class="k">"type"</span><span class="p">:</span> <span class="s">"object"</span><span class="p">,</span>
<span class="annb">  <span class="ann">"observedProperty"</span><span class="p">: {</span> <span class="k">"reference"</span><span class="p">:</span> <span class="s">"https://catalog.example.org/observable-properties/geomagnetic-field-vector-at-spacecraft/v1"</span><span class="p">,</span> <span class="k">"kind"</span><span class="p">:</span> <span class="s">"example-catalog"</span> <span class="p">},</span></span>
  <span class="k">"properties"</span><span class="p">: {</span>
    <span class="k">"time_tag"</span><span class="p">: {</span>
      <span class="k">"type"</span><span class="p">:</span> <span class="s">"datetime"</span><span class="p">,</span>
<span class="annb">      <span class="ann">"semanticRole"</span><span class="p">:</span> <span class="s">"phenomenonTime"</span><span class="p">,</span> <span class="ann">"cadence"</span><span class="p">: {</span> <span class="k">"kind"</span><span class="p">:</span> <span class="s">"fixed"</span><span class="p">,</span> <span class="k">"period"</span><span class="p">:</span> <span class="s">"PT1M"</span> <span class="p">}</span></span>
    <span class="p">},</span>
    <span class="k">"satellite"</span><span class="p">: {</span>
      <span class="k">"type"</span><span class="p">:</span> <span class="s">"int32"</span><span class="p">,</span>
<span class="annb">      <span class="ann">"semanticRole"</span><span class="p">:</span> <span class="s">"observingProcedure"</span></span>
    <span class="p">},</span>
    <span class="k lnk">"hp"</span><span class="p">: {</span>
      <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span> <span class="k">"unit"</span><span class="p">:</span> <span class="s">"nT"</span><span class="p">,</span>
<span class="annb">      <span class="ann">"semanticRole"</span><span class="p">:</span> <span class="s">"observationValue"</span><span class="p">,</span> <span class="ann">"derivation"</span><span class="p">:</span> <span class="s">"measured"</span><span class="p">,</span> <span class="ann">"phenomenonTimeRelation"</span><span class="p">:</span> <span class="s">"instant"</span><span class="p">,</span>
      <span class="ann">"observedProperty"</span><span class="p">: {</span> <span class="k">"reference"</span><span class="p">:</span> <span class="s">"http://qudt.org/vocab/quantitykind/MagneticFluxDensity"</span><span class="p">,</span> <span class="k">"kind"</span><span class="p">:</span> <span class="s">"qudt-quantity-kind"</span> <span class="p">}</span></span>
    <span class="p">},</span>
    <span class="k lnk">"hn"</span><span class="p">: {</span>
      <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span> <span class="k">"unit"</span><span class="p">:</span> <span class="s">"nT"</span><span class="p">,</span>
<span class="annb">      <span class="ann">"semanticRole"</span><span class="p">:</span> <span class="s">"observationValue"</span><span class="p">,</span> <span class="ann">"derivation"</span><span class="p">:</span> <span class="s">"measured"</span><span class="p">,</span> <span class="ann">"phenomenonTimeRelation"</span><span class="p">:</span> <span class="s">"instant"</span><span class="p">,</span>
      <span class="ann">"observedProperty"</span><span class="p">: {</span> <span class="k">"reference"</span><span class="p">:</span> <span class="s">"http://qudt.org/vocab/quantitykind/MagneticFluxDensity"</span><span class="p">,</span> <span class="k">"kind"</span><span class="p">:</span> <span class="s">"qudt-quantity-kind"</span> <span class="p">}</span></span>
    <span class="p">},</span>
    <span class="k lnk">"he"</span><span class="p">: {</span>
      <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span> <span class="k">"unit"</span><span class="p">:</span> <span class="s">"nT"</span><span class="p">,</span>
<span class="annb">      <span class="ann">"semanticRole"</span><span class="p">:</span> <span class="s">"observationValue"</span><span class="p">,</span> <span class="ann">"derivation"</span><span class="p">:</span> <span class="s">"measured"</span><span class="p">,</span> <span class="ann">"phenomenonTimeRelation"</span><span class="p">:</span> <span class="s">"instant"</span><span class="p">,</span>
      <span class="ann">"observedProperty"</span><span class="p">: {</span> <span class="k">"reference"</span><span class="p">:</span> <span class="s">"http://qudt.org/vocab/quantitykind/MagneticFluxDensity"</span><span class="p">,</span> <span class="k">"kind"</span><span class="p">:</span> <span class="s">"qudt-quantity-kind"</span> <span class="p">}</span></span>
    <span class="p">},</span>
    <span class="k">"total"</span><span class="p">: {</span>
      <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span> <span class="k">"unit"</span><span class="p">:</span> <span class="s">"nT"</span><span class="p">,</span> <span class="k">"minimum"</span><span class="p">:</span> <span class="n">0</span><span class="p">,</span>
      <span class="k">"description"</span><span class="p">:</span> <span class="s">"Magnitude of the field vector, from the `total` field, computed by the publisher as the root of the sum of the squares of `hp`, `he` and `hn`. It is not an independent reading and adds no information to the three components, but it is frame-invariant where they are not, so it is the member to compare across spacecraft. Quiet-time values at geostationary altitude lie between roughly 100 and 120 nT."</span><span class="p">,</span>
<span class="annb">      <span class="ann">"semanticRole"</span><span class="p">:</span> <span class="s">"observationValue"</span><span class="p">,</span> <span class="ann">"derivation"</span><span class="p">:</span> <span class="s">"calculated"</span><span class="p">,</span> <span class="ann">"phenomenonTimeRelation"</span><span class="p">:</span> <span class="s">"instant"</span><span class="p">,</span>
      <span class="ann">"observedProperty"</span><span class="p">: {</span> <span class="k">"reference"</span><span class="p">:</span> <span class="s">"http://qudt.org/vocab/quantitykind/MagneticFluxDensity"</span><span class="p">,</span> <span class="k">"kind"</span><span class="p">:</span> <span class="s">"qudt-quantity-kind"</span> <span class="p">}</span></span>
    <span class="p">},</span>
    <span class="k">"arcjet_flag"</span><span class="p">: {</span>
      <span class="k">"type"</span><span class="p">:</span> <span class="s">"boolean"</span><span class="p">,</span>
<span class="annb">      <span class="ann">"semanticRole"</span><span class="p">:</span> <span class="s">"resultQuality"</span></span>
    <span class="p">}</span>
  <span class="p">},</span>
<span class="annb">  <span class="ann">"vectorReferenceFrames"</span><span class="p">: [</span>
    <span class="p">{</span> <span class="k">"reference"</span><span class="p">: {</span> <span class="k">"$ref"</span><span class="p">:</span> <span class="s lnk">"#/definitions/GoesEpnFrame"</span> <span class="p">},</span> <span class="k">"kind"</span><span class="p">:</span> <span class="s">"type"</span><span class="p">,</span> <span class="k">"components"</span><span class="p">: [</span><span class="s lnk">"hp"</span><span class="p">,</span> <span class="s lnk">"he"</span><span class="p">,</span> <span class="s lnk">"hn"</span><span class="p">] }</span>
  <span class="p">],</span></span>
  <span class="k">"required"</span><span class="p">: [</span><span class="s">"time_tag"</span><span class="p">,</span> <span class="s">"satellite"</span><span class="p">,</span> <span class="s">"arcjet_flag"</span><span class="p">],</span>
  <span class="k">"additionalProperties"</span><span class="p">:</span> <span class="b">false</span><span class="p">,</span>
  <span class="k">"definitions"</span><span class="p">: {</span>
    <span class="k lnk">"GoesEpnFrame"</span><span class="p">: {</span>
      <span class="k">"name"</span><span class="p">:</span> <span class="s">"GoesEpnFrame"</span><span class="p">,</span>
      <span class="k">"type"</span><span class="p">:</span> <span class="s">"tuple"</span><span class="p">,</span>
      <span class="k">"properties"</span><span class="p">: {</span>
        <span class="k">"p"</span><span class="p">: {</span> <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span> <span class="k">"description"</span><span class="p">:</span> <span class="s">"Perpendicular to the orbital plane, positive northward."</span> <span class="p">},</span>
        <span class="k">"e"</span><span class="p">: {</span> <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span> <span class="k">"description"</span><span class="p">:</span> <span class="s">"Perpendicular to p, positive earthward."</span> <span class="p">},</span>
        <span class="k">"n"</span><span class="p">: {</span> <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span> <span class="k">"description"</span><span class="p">:</span> <span class="s">"Perpendicular to p and e, positive eastward. The name is normal, not north."</span> <span class="p">}</span>
      <span class="p">},</span>
      <span class="k">"tuple"</span><span class="p">: [</span><span class="s">"p"</span><span class="p">,</span> <span class="s">"e"</span><span class="p">,</span> <span class="s">"n"</span><span class="p">]</span>
    <span class="p">}</span>
  <span class="p">}</span>
<span class="p">}</span></pre>

A record off that feed:

<pre class="jsonx"><span class="p">{</span>
  <span class="k">"time_tag"</span><span class="p">:</span> <span class="s">"2026-07-31T05:12:00Z"</span><span class="p">,</span>
  <span class="k">"satellite"</span><span class="p">:</span> <span class="n">19</span><span class="p">,</span>
  <span class="k">"hp"</span><span class="p">:</span> <span class="n">103.42</span><span class="p">,</span>
  <span class="k">"hn"</span><span class="p">:</span> <span class="n">-18.77</span><span class="p">,</span>
  <span class="k">"he"</span><span class="p">:</span> <span class="n">6.05</span><span class="p">,</span>
  <span class="k">"total"</span><span class="p">:</span> <span class="n">105.31</span><span class="p">,</span>
  <span class="k">"arcjet_flag"</span><span class="p">:</span> <span class="b">false</span>
<span class="p">}</span></pre>

Seven numbers and a boolean. Nothing in there tells you that `hn` being negative
means eighteen nanotesla *westward*, or that `hp` from satellite 19 must not go
into the same average as `hp` from satellite 18. The instance never carries
that. Only the schema can.

Look at what falls out. `total` is the magnitude, and `derivation: "calculated"`
says it was produced by deterministic arithmetic that no named summary covers —
not measured, not estimated, not one of [`minimum`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#minimum), [`maximum`](https://json-structure.github.io/validation/draft-vasters-json-structure-validation.html#maximum) or `mean`, which
would have taken `derivation: "statistic"` instead. So it adds no information
the three components do not already carry.

But look at where it is *not*. `total` is absent from the `components` array of
[`vectorReferenceFrames`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#vector-reference-frames), and that absence is the annotation. `hp`, `he` and `hn`
are resolved in a spacecraft-local frame, so their numbers mean nothing outside
it. A magnitude is frame-invariant. **`total` is therefore the member that may
be compared across two spacecraft, and `hp` is not.** Try guessing that from the
field names.

And `arcjet_flag` is `resultQuality`. When the electric thrusters fire they
generate a field at the sensor that looks exactly like a geophysical signal.
Flagged records get thrown away, not corrected.

## Sample: a decibel is not a number

**The hazard: a unit that means nothing until you know what was done to the
signal before it was written down.**

A citizen sensor node reports three sound levels, all in `dB`. A decibel means
nothing until you know the weighting it was taken under and the reference it
stands against. A-weighted and unweighted over the same sound are different
numbers. Relative to twenty micropascals and relative to digital full scale are
different numbers again.

<pre class="jsonx"><span class="k">"noise_laeq_db"</span><span class="p">: {</span>
  <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span> <span class="k">"unit"</span><span class="p">:</span> <span class="s">"dB"</span><span class="p">,</span>
<span class="annb">  <span class="ann">"semanticRole"</span><span class="p">:</span> <span class="s">"observationValue"</span><span class="p">,</span>
  <span class="ann">"measurementConditioning"</span><span class="p">: {</span> <span class="k">"weighting"</span><span class="p">:</span> <span class="s">"a"</span><span class="p">,</span> <span class="k">"levelReference"</span><span class="p">:</span> <span class="s">"soundPressure"</span> <span class="p">}</span></span>
<span class="p">},</span>
<span class="k">"noise_la_min_db"</span><span class="p">: {</span>
  <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span><span class="p">,</span> <span class="k">"unit"</span><span class="p">:</span> <span class="s">"dB"</span><span class="p">,</span>
<span class="annb">  <span class="ann">"semanticRole"</span><span class="p">:</span> <span class="s">"observationValue"</span><span class="p">,</span> <span class="ann">"derivation"</span><span class="p">:</span> <span class="s">"statistic"</span><span class="p">,</span> <span class="ann">"statistic"</span><span class="p">:</span> <span class="s">"minimum"</span><span class="p">,</span>
  <span class="ann">"measurementConditioning"</span><span class="p">: {</span> <span class="k">"weighting"</span><span class="p">:</span> <span class="s">"a"</span><span class="p">,</span> <span class="k">"levelReference"</span><span class="p">:</span> <span class="s">"soundPressure"</span> <span class="p">}</span></span>
<span class="p">}</span></pre>

And a record:

<pre class="jsonx"><span class="p">{</span>
  <span class="k">"sensor_id"</span><span class="p">:</span> <span class="n">28483</span><span class="p">,</span>
  <span class="k">"observed_at"</span><span class="p">:</span> <span class="s">"2026-08-02 14:35:00"</span><span class="p">,</span>
  <span class="k">"noise_laeq_db"</span><span class="p">:</span> <span class="n">58.4</span><span class="p">,</span>
  <span class="k">"noise_la_min_db"</span><span class="p">:</span> <span class="n">47.1</span><span class="p">,</span>
  <span class="k">"noise_la_max_db"</span><span class="p">:</span> <span class="n">79.6</span><span class="p">,</span>
  <span class="k">"pm2_5_ug_m3"</span><span class="p">:</span> <span class="n">12.3</span><span class="p">,</span>
  <span class="k">"temperature_celsius"</span><span class="p">:</span> <span class="n">24.7</span>
<span class="p">}</span></pre>

`58.4`. Against what, weighted how? The record does not say and cannot. Put it
in a bucket with an unweighted 58.4 from a professional meter two streets over
and you have averaged two different quantities that print the same.

Two details in there matter more than the keyword. The feed names the weighting
but not the time constant, so `timeWeighting` is left out rather than guessed
at. And the particulate and temperature channels in the same record carry a unit
and no conditioning at all, because nothing is hidden in them. An annotation you
do not need is an annotation you do not write.

## Sample: a code is not its meaning

**The hazard: an opaque string that validates forever while telling a join
planner nothing.**

`B77W` is an aircraft type because ICAO Doc 8643 says so. `EGLL` is an aerodrome
because Doc 7910 says so. Both are strings. Both validate against
`"type": "string"` forever without anybody learning anything.

<pre class="jsonx"><span class="k">"aircraft_short"</span><span class="p">: {</span>
  <span class="k">"type"</span><span class="p">:</span> <span class="s">"string"</span><span class="p">,</span>
<span class="annb">  <span class="ann">"codedValues"</span><span class="p">: {</span> <span class="k">"reference"</span><span class="p">:</span> <span class="s">"https://www.icao.int/operational-safety/doc-8643-aircraft-type-designators"</span><span class="p">,</span> <span class="k">"kind"</span><span class="p">:</span> <span class="s">"icao"</span> <span class="p">}</span></span>
<span class="p">},</span>
<span class="k">"departure"</span><span class="p">: {</span>
  <span class="k">"type"</span><span class="p">:</span> <span class="s">"string"</span><span class="p">,</span>
<span class="annb">  <span class="ann">"codedValues"</span><span class="p">: {</span> <span class="k">"reference"</span><span class="p">:</span> <span class="s">"https://store.icao.int/en/location-indicators-doc-7910"</span><span class="p">,</span> <span class="k">"kind"</span><span class="p">:</span> <span class="s">"icao"</span> <span class="p">}</span></span>
<span class="p">}</span></pre>

The record it describes:

<pre class="jsonx"><span class="p">{</span>
  <span class="k">"callsign"</span><span class="p">:</span> <span class="s">"BAW117"</span><span class="p">,</span>
  <span class="k">"cid"</span><span class="p">:</span> <span class="n">1002345</span><span class="p">,</span>
  <span class="k">"aircraft_short"</span><span class="p">:</span> <span class="s">"B77W"</span><span class="p">,</span>
  <span class="k">"departure"</span><span class="p">:</span> <span class="s">"EGLL"</span><span class="p">,</span>
  <span class="k">"arrival"</span><span class="p">:</span> <span class="s">"KJFK"</span><span class="p">,</span>
  <span class="k">"latitude"</span><span class="p">:</span> <span class="n">51.4775</span><span class="p">,</span>
  <span class="k">"longitude"</span><span class="p">:</span> <span class="n">-0.4614</span><span class="p">,</span>
  <span class="k">"altitude"</span><span class="p">:</span> <span class="n">37000</span><span class="p">,</span>
  <span class="k">"last_updated"</span><span class="p">:</span> <span class="s">"2026-08-02T14:35:07Z"</span>
<span class="p">}</span></pre>

Four opaque strings. A human who flies knows three of them on sight. A join
planner knows none, until [`codedValues`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#coded-values) tells it that two of them resolve
against tables it can go and fetch.

Both fields carry `kind: "icao"`, because ICAO is the register model behind them.
But they draw from two different lists, and it is `reference` that says which.
Confusing the two is the easiest mistake to make with this keyword, which is why
this sample exists.

## Sample: which number is the latitude?

**The hazard: two identical numbers in two different orders, and no record of
which is which.**

CRS84 is longitude-first. EPSG:4326 is latitude-first. Same points, same
ellipsoid, opposite order, and this has been quietly corrupting geospatial
pipelines for twenty years.

<pre class="jsonx"><span class="k">"crs84Position"</span><span class="p">: {</span>
  <span class="k">"type"</span><span class="p">:</span> <span class="s">"tuple"</span><span class="p">,</span>
  <span class="k">"properties"</span><span class="p">: {</span> <span class="k">"c1"</span><span class="p">: {</span> <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span> <span class="p">},</span> <span class="k">"c2"</span><span class="p">: {</span> <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span> <span class="p">} },</span>
  <span class="k">"tuple"</span><span class="p">: [</span><span class="s">"c1"</span><span class="p">,</span> <span class="s">"c2"</span><span class="p">],</span>
<span class="annb">  <span class="ann">"coordinateReferenceSystem"</span><span class="p">: {</span>
    <span class="k">"reference"</span><span class="p">:</span> <span class="s">"http://www.opengis.net/def/crs/OGC/1.3/CRS84"</span><span class="p">,</span>
    <span class="k">"kind"</span><span class="p">:</span> <span class="s">"ogc-crs"</span><span class="p">,</span> <span class="k">"coordinates"</span><span class="p">: [</span><span class="s">"c1"</span><span class="p">,</span> <span class="s">"c2"</span><span class="p">]</span>
  <span class="p">}</span></span>
<span class="p">},</span>
<span class="k">"epsg4326Position"</span><span class="p">: {</span>
  <span class="k">"type"</span><span class="p">:</span> <span class="s">"tuple"</span><span class="p">,</span>
  <span class="k">"properties"</span><span class="p">: {</span> <span class="k">"c1"</span><span class="p">: {</span> <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span> <span class="p">},</span> <span class="k">"c2"</span><span class="p">: {</span> <span class="k">"type"</span><span class="p">:</span> <span class="s">"double"</span> <span class="p">} },</span>
  <span class="k">"tuple"</span><span class="p">: [</span><span class="s">"c1"</span><span class="p">,</span> <span class="s">"c2"</span><span class="p">],</span>
<span class="annb">  <span class="ann">"coordinateReferenceSystem"</span><span class="p">: {</span>
    <span class="k">"reference"</span><span class="p">:</span> <span class="s">"http://www.opengis.net/def/crs/EPSG/0/4326"</span><span class="p">,</span>
    <span class="k">"kind"</span><span class="p">:</span> <span class="s">"ogc-crs"</span><span class="p">,</span> <span class="k">"coordinates"</span><span class="p">: [</span><span class="s">"c1"</span><span class="p">,</span> <span class="s">"c2"</span><span class="p">]</span>
  <span class="p">}</span></span>
<span class="p">}</span>
<span class="c">// and on the enclosing record, the vertical datum:</span>
<span class="annb"><span class="ann">"coordinateReferenceSystem"</span><span class="p">: {</span>
  <span class="k">"reference"</span><span class="p">:</span> <span class="s">"http://www.opengis.net/def/crs/EPSG/0/5703"</span><span class="p">,</span>  <span class="c">// NAVD88</span>
  <span class="k">"kind"</span><span class="p">:</span> <span class="s">"ogc-crs"</span><span class="p">,</span> <span class="k">"coordinates"</span><span class="p">: [</span><span class="s">"benchmarkElevation"</span><span class="p">]</span>
<span class="p">}</span></span></pre>

Now the instance:

<pre class="jsonx"><span class="p">{</span>
  <span class="k">"stationId"</span><span class="p">:</span> <span class="s">"USGS-12142000"</span><span class="p">,</span>
  <span class="k">"reportedAt"</span><span class="p">:</span> <span class="s">"2026-07-28T14:00:00Z"</span><span class="p">,</span>
  <span class="k">"benchmarkElevation"</span><span class="p">:</span> <span class="n">137.4</span><span class="p">,</span>
  <span class="k">"crs84Position"</span><span class="p">: [</span><span class="n">-121.5498</span><span class="p">,</span> <span class="n">47.8232</span><span class="p">],</span>
  <span class="k">"epsg4326Position"</span><span class="p">: [</span><span class="n">47.8232</span><span class="p">,</span> <span class="n">-121.5498</span><span class="p">]</span>
<span class="p">}</span></pre>

Four numbers, one point, no names anywhere. **Nothing in the instance says which
value is the latitude, and nothing in the type says it either.** `c1` and `c2`
are positions in an array and mean nothing on their own.

The word *latitude* never appears in this schema. It does not need to. The CRS
registry already says that axis 1 of CRS84 is longitude and axis 1 of EPSG:4326
is latitude — that fact has been published for decades. What was missing is the
join: which of *your* members supplies axis 1. That is all `coordinates` does,
and it is why the keyword binds members rather than just naming a CRS. Swap the
two references and the same two arrays describe a point in Kazakhstan, with
every validator still green.

And `137.4` is metres above NAVD88 — which is where this post came in.

## Can a machine read one of these cold?

**A machine can. The interesting question is which layer of the schema made the
difference, and the answer is not the flattering one.**

That second question is the one the `evaluation/` harness answers: a
mechanically derived rubric, four cumulative arms (`bare`, `prose`, `annotated`,
`spec`), a blinded supervisor grading claim by claim with a quote required per
verdict, and a second task where the subject must write executable Azure Stream
Analytics SQL — so a claim is scored against what the query *does* rather than
what the prose recites. Average a quantity the rubric forbids averaging and it
is marked wrong however well the surrounding sentence quotes the rule. Run it
with `--transport none` and it writes every prompt without calling a model, so
the method can be audited before any number out of it is trusted. That is a
feature.

Four things need defining before the tables mean anything.

**The four arms are the same schema with layers removed.** Each sample is run
four times, cumulatively, so the difference between two adjacent rows is
attributable to the one layer that separates them.

| arm | what the reader was given |
| --- | --- |
| `bare` | member names and types, nothing else |
| `prose` | `bare` plus every [`description`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#description-keyword) |
| `annotated` | `prose` plus the annotation keywords, specification withheld |
| `spec` | `annotated` plus the specification text |

**The four verdicts separate being wrong from being silent.** A claim is
`correct` if the transcript asserts it and stands behind it, `wrong` if it
asserts an incompatible reading, `declined` if it raises the matter and
explicitly refuses to settle it, and `untouched` if it never engages at all.
Stating the right answer but flagging it as a guess counts as `declined`, not
`correct` — without that rule a model's prior knowledge of METARs would swamp
the comparison. **Declining is not failing.** An unannotated schema does not
determine the reference frame, and saying so is the correct behaviour.

**Accuracy is `correct / (correct + wrong)`** — of the matters a reader
committed on, how often it was right. `coverage` is how much of the rubric it
engaged at all. `hazard` divides wrong answers by every claim, so silence is
free; `haz/ans` divides them by the claims the reader actually committed on,
which is the rate someone relying on it would meet in practice.

**Wrong answers are the number to watch, not right ones.** A silent schema
reader is a nuisance. One that confidently states the wrong reference frame is
the failure this whole document exists to prevent.

Two runs are under version control. The comprehension run — seed 23,
thirteen samples, 285 scoreable claims, 1140 verdicts:

| arm | correct | wrong | declined | untouched | coverage | accuracy | hazard | haz/ans |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `bare` | 49 | 28 | 123 | 85 | 0.7018 | 0.6364 | 0.0982 | 0.3636 |
| `prose` | 177 | 9 | 11 | 88 | 0.6912 | 0.9516 | 0.0316 | 0.0484 |
| `annotated` | 190 | 5 | 6 | 84 | 0.7053 | 0.9744 | 0.0175 | 0.0256 |
| `spec` | 202 | 6 | 4 | 73 | 0.7439 | 0.9712 | 0.0211 | 0.0288 |
{: .results}

**Look at the `declined` column, not the accuracy column.** The `bare` arm
declines 123 claims of 285 — it reads a schema of names and types, cannot tell
what the numbers mean, and correctly says so. Adding descriptions takes that to
11. That is the unremarkable result, and it is worth stating plainly: **a
description tells a reader enough to answer a question in words.**

The query run is the one that matters, because there the reader has to commit.
Seed 31, six samples, 188 scoreable claims, 752 verdicts, scored against
executable SQL rather than against prose:

| arm | correct | wrong | declined | untouched | coverage | accuracy | hazard | haz/ans |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `bare` | 30 | 61 | 12 | 85 | 0.5479 | 0.3297 | 0.3245 | 0.6703 |
| `prose` | 80 | 31 | 6 | 71 | 0.6223 | 0.7207 | 0.1649 | 0.2793 |
| `annotated` | 84 | 5 | 3 | 96 | 0.4894 | 0.9438 | 0.0266 | 0.0562 |
| `spec` | 91 | 22 | 5 | 70 | 0.6277 | 0.8053 | 0.1170 | 0.1947 |
{: .results}

**Prose stops helping the moment the answer has to run.** Accuracy on `bare`
falls from 0.6364 to 0.3297 — of the claims its query touches at all, two thirds
are violated. Prose lets a reader hedge and SQL does not. Collapse the violation
counts to distinct decisions — the rubric emits one claim per annotated member,
so a single bad division is scored once for every member it touches — and `bare`
and `prose` are level at eleven wrong decisions each, while the two
annotation-bearing arms make three. **A description is enough to describe the
feed correctly and not enough to make the reader write different SQL.**

The same collapsing rescues the `spec` arm, which read raw looks like a
regression at 22 violations. Three decisions produce them, one of which — turning
megawatts into megawatt-hours by dividing by the gap between records — is counted
twenty times because seventeen fuel members carry the same annotations.

The [`supportPeriod`](https://json-structure.github.io/semantic-annotations/draft-vasters-json-structure-sem-ann.html#support-period) claims show the same shape more sharply. Restricted to the 25
claims those annotations force, the `annotated` arm gets 6 right and 0 wrong; the
`spec` arm gets 7 right and 10 wrong, deriving the period from record spacing
anyway. Same annotations, plus the specification, opposite behaviour.

**The most plausible reading is that the specification text is not helping this
reader.** It is written for a human implementer deciding what to emit. Handed to
a small model that already has the annotation in front of it, it is several
thousand words of prose competing for attention with the schema — and attention
is the scarce resource. The arm that wins is `annotated`, which has the fact and
nothing else. Every jump worth having in this run happens between `prose` and
`annotated`, and the layer above it costs rather than pays.

That is a claim about context, not about the specification's quality, and one
run on one model does not settle it. But it is the reading the numbers support,
and it has a practical consequence: **ship the annotations to the reader, not the
document that explains them.**

Two further things belong next to any number quoted above. The grader is a model
and it is not stable: identical transcripts graded twice differ by 58 claims on
one arm, so no gap narrower than that means anything. And the rubric is derived
from the annotations, which grades the annotated arm against its own inputs — the
open question is not whether the annotations are stated but whether they are the
right things to state. Both caveats, and several more, are written down in the
[harness's own README](https://github.com/json-structure/semantic-annotations/blob/main/evaluation/README.md)
rather than left for a reader to find.

What no harness can tell you is whether an analysis is right for its *domain*.
That needs OGC, ICC, ITU, and the people who publish these feeds. That is the
review this draft needs.

## Where to look

**Start with the samples, not the draft.** Fifteen teaching samples introduce one
idea at a time. Twenty-eight real-world samples are transcribed from feeds that
actually exist: AIS vessel positions, METARs, lightning strokes, grid carbon
intensity, transit telemetry, USGS instantaneous values, Mode S aircraft
reports, GCMT moment tensors, CCSDS attitude quaternions, KITTI sensor
alignment, FOGRA characterization patches, MODIS fire detections, broadcast
audio frames.

Each one exists because of a specific hazard, and each root [`description`](https://json-structure.github.io/core/draft-vasters-json-structure-core.html#description-keyword) names
the hazard. Read half a dozen and you have the argument for the draft without
reading the draft.

- [The Internet-Draft on the Datatracker](https://datatracker.ietf.org/doc/draft-vasters-json-structure-sem-ann/)
- [The specification repository](https://github.com/json-structure/semantic-annotations)
  — also holds
  [`EVALUATION.md`](https://github.com/json-structure/semantic-annotations/blob/main/EVALUATION.md),
  the harness in
  [`evaluation/`](https://github.com/json-structure/semantic-annotations/tree/main/evaluation),
  and a long
  [`Q-A.md`](https://github.com/json-structure/semantic-annotations/blob/main/Q-A.md)
  of objections and answers
- [All 43 samples](https://github.com/json-structure/primer-and-samples/tree/main/samples/semantic-annotations)

## Status

Individual Internet-Draft, `draft-vasters-json-structure-sem-ann-00`. Not a
working group document. Discussion is on the
[json-structure mailing list](https://www.ietf.org/mailman/listinfo/json-structure).

**The most useful response is not agreement.** Name a keyword in here that fails
the test above — something a consumer does not need in order to decide whether
two values may be combined. Better still, bring a data set whose incompatibility
hazard none of these keywords can express. The second one is worth a lot more
than the first.
