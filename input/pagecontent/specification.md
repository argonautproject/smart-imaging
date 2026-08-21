This page is the complete specification: how an App finds an EHR's imaging endpoint, gets authorized, lists a patient's studies, and downloads DICOM data. The actors (App, EHR, Imaging Server) are defined on the [home page](index.html).

### Discovery

An app learns the imaging endpoint in one of two ways: **in-band**, from the EHR's SMART configuration document, or **out-of-band**, from direct configuration (an endpoint directory, a partner agreement). In-band discovery requires no per-site setup; apps SHOULD prefer it when available and MAY fall back to out-of-band configuration.

An EHR supporting in-band discovery SHALL advertise imaging support with the capability string **`smart-imaging-access`** in its `.well-known/smart-configuration`:

* in the top-level `capabilities` array, if the EHR's own FHIR endpoint serves `ImagingStudy` as described here, or
* in `associated_endpoints[].capabilities`, if a separate FHIR endpoint does.

For example, an EHR at `https://ehr.example.org/fhir` whose imaging endpoint is hosted separately at `https://imaging.example.org/fhir` would serve this at `https://ehr.example.org/fhir/.well-known/smart-configuration`:

```js
{
  "authorization_endpoint": "https://ehr.example.org/authorize",
  "token_endpoint": "https://ehr.example.org/token",
  "capabilities": ["launch-standalone", "..."],
  "associated_endpoints": [
    {
      "url": "https://imaging.example.org/fhir",
      "capabilities": ["smart-imaging-access"]
    }
  ]
}
```

The app reads this document, sees `smart-imaging-access`, and knows it can search `https://imaging.example.org/fhir/ImagingStudy` with the access token it gets from this EHR's authorization server.

### Authorization

One authorization covers everything: the app completes a normal [SMART App Launch](https://hl7.org/fhir/smart-app-launch/app-launch.html) with the EHR, and the resulting access token works for clinical data, `ImagingStudy` search, and DICOM retrieval. There is no separate imaging authorization step and no token exchange.

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="sequence-flow-mobile.svg"/>
<img src="sequence-flow.svg" alt="Sequence diagram: the app authorizes with the EHR, optionally fetches clinical data, searches ImagingStudy on the Imaging Server, and retrieves DICOM data from WADO-RS; the Imaging Server validates the token with the EHR via introspection" style="max-width: 100%; height: auto;"/>
</picture>
</div>

**Obtaining a token.** The app runs a standard SMART App Launch flow (for example, a standalone launch) against the EHR's authorization server, requesting scopes that cover imaging: `patient/ImagingStudy.rs` (SMART 2.0), `patient/ImagingStudy.read` (SMART 1.0), or a wildcard that includes it such as `patient/*.rs`. The user approves sharing, and the app receives a token response with patient context:

```js
{
  "access_token": "access-token-value-unguessable",
  "expires_in": 3600,
  "refresh_token": "refresh-token-value-unguessable-and-long-lasting",
  "patient": "123"
}
```

The app then presents this same `access_token` as a Bearer token on every request in this guide: clinical FHIR reads, `ImagingStudy` searches, and WADO-RS retrievals (when the endpoint's `requires-access-token` extension is `true`, which is the expected configuration).

**Trusting the token.** If the Imaging Server is part of the EHR, this is ordinary local token validation. If it's a separate system, it needs a way to check tokens issued by the EHR's authorization server. The expected mechanism is [SMART Token Introspection](https://hl7.org/fhir/smart-app-launch/token-introspection.html):

```
POST https://ehr.example.org/introspect
Content-Type: application/x-www-form-urlencoded

token=access-token-value-unguessable
```

Other trust arrangements (for example, signed tokens the Imaging Server can verify directly) MAY be used, provided the server can enforce the checks below.

**Required checks.** Before serving any imaging request — FHIR or WADO-RS — the Imaging Server SHALL confirm that:

1. the token is **active** (not expired or revoked);
2. the token's **patient context matches** the patient whose data is requested — the `?patient=` parameter on a FHIR search, or the patient who owns the study on a WADO-RS retrieval; and
3. the token's **scopes cover the request** — `patient/ImagingStudy.rs`, `patient/*.read`, or equivalent.

The Imaging Server MAY gather additional information from the EHR to make this decision — for example, using [SMART Backend Services](https://hl7.org/fhir/smart-app-launch/backend-services.html) to fetch `Patient/123` and obtain the patient's identifiers (such as an MRN) for cross-mapping to its own records. See [Imaging Identifiers](identifiers.html) for how these identifiers relate.

**Requirements.**

* The **EHR** SHALL support SMART App Launch and SHALL offer scopes permitting `ImagingStudy` read access (`patient/ImagingStudy.rs`, `patient/*.rs`, or the SMART 1.0 equivalents).
* The **EHR** SHALL provide a way for Imaging Servers to validate its tokens — SMART Token Introspection unless another arrangement is in place.
* The **Imaging Server** SHALL validate every access token and enforce patient context and scopes, as above.
* The **App** SHALL treat the access token as a secret and present it only to the EHR, the Imaging Server's FHIR endpoint, and WADO-RS endpoints the Imaging Server has designated (via `Endpoint.address` with `requires-access-token` = `true`).

### Finding studies

The app searches `ImagingStudy` by patient, asking the server to include each study's WADO-RS Endpoint:

```
GET https://imaging.example.org/fhir/ImagingStudy?patient=123&_include=ImagingStudy:endpoint
Authorization: Bearer access-token-value-unguessable
```

The Imaging Server SHALL support these search parameter combinations:

| Query | Use case |
|---|---|
| `patient=123` | List all of a patient's studies |
| `patient=123&_lastUpdated=gt2023-04-17T04:00:00Z` | Incremental sync: only studies updated since the app last checked |
| `patient=123&identifier=urn:oid:1.2.3` | Look up one study by DICOM Study Instance UID |

The server SHALL also support `_include=ImagingStudy:endpoint`, so that studies whose Endpoints are standalone resources come back in the same Bundle. Endpoints MAY instead be contained within each `ImagingStudy`; apps SHALL support both forms. See the [server CapabilityStatement](CapabilityStatement-smart-imaging-server.html) for the machine-readable version.

The server returns a searchset Bundle of `ImagingStudy` resources conforming to the [SMART ImagingStudy](StructureDefinition-smart-imaging-study.html) profile. Every study carries its **DICOM Study Instance UID** (an identifier with system `urn:dicom:uid` and a `urn:oid:...` value), its **status**, **patient**, and **modality**, and at least one **endpoint** conforming to [SMART WADO-RS Endpoint](StructureDefinition-smart-wado-endpoint.html) — the WADO-RS base URL where the DICOM data lives, plus a `requires-access-token` flag telling the app to send its SMART token there. Studies should also carry descriptive detail when available — start time, series and instance counts, per-series metadata — so apps can show a useful study list before downloading anything.

Worked examples: [study with a contained Endpoint](ImagingStudy-imaging-study-contained-endpoint.html), [study with an external Endpoint](ImagingStudy-imaging-study-external-endpoint.html), and a [complete search response Bundle](Bundle-imaging-search-response.html).

**Slow backends: 503 + Retry-After.** Some Imaging Servers front systems that answer slowly — for example, a proxy that issues a DICOM C-FIND to a PACS on first request. Rather than holding the connection open, the server MAY respond:

```
HTTP/1.1 503 Service Unavailable
Retry-After: 30
```

The app SHOULD wait the indicated number of seconds and repeat the identical request. Once results are ready, the server responds normally with the Bundle.

**Access control.** Every search is subject to the token checks in [Authorization](#authorization): the server SHALL ensure the `patient` search parameter matches the token's patient context. A request for another patient's studies gets a `403`, not an empty Bundle.

*Scaling (non-normative).* Passing every search through to an underlying PACS can overload systems that were never built for consumer-scale traffic. Implementations have had good results with caching `ImagingStudy` resources (with a heuristic for invalidation), and with change feeds from the PACS or RIS to invalidate precisely instead of guessing. The 503/Retry-After pattern complements caching: the first request warms the cache; retries hit it.

### Retrieving images

Each study's Endpoint gives the app a WADO-RS base URL in `Endpoint.address`. The app appends `/studies/{Study Instance UID}` — using the plain UID from the study's `urn:dicom:uid` identifier (strip the `urn:oid:` prefix) — and sends its SMART access token:

```
GET https://imaging.example.org/wado-rs/studies/1.2.840.99999999.19341866.1571297684
Accept: multipart/related; type=application/dicom; transfer-syntax=*
Authorization: Bearer access-token-value-unguessable
```

**Minimum retrieval support.** The WADO-RS endpoint SHALL support full-study retrieval with `Accept: multipart/related; type=application/dicom; transfer-syntax=*`. Accepting `transfer-syntax=*` lets the server return stored files without re-encoding, so even a static file server behind an authorizing proxy can participate. The response is the study's DICOM instances as a multipart body:

```
HTTP/1.1 200 OK
Content-Type: multipart/related; type=application/dicom; boundary=...

[DICOM instances, one part each]
```

**Additional retrieval support.** Further WADO-RS capabilities enable richer app behavior (progressive loading, thumbnails, viewing without a full download). Servers SHOULD support, per the [DICOMweb WADO-RS standard](https://dicom.nema.org/medical/dicom/current/output/html/part18.html):

* **Series-level** retrieval — `GET /studies/{uid}/series/{uid}`
* **Instance-level** retrieval — `GET /studies/{uid}/series/{uid}/instances/{uid}`
* **Frame-level** retrieval — `.../instances/{uid}/frames/{n}`
* **Rendered** images — `.../rendered` at study, series, or instance level
* **Metadata** — `GET /studies/{uid}/metadata` (and at series/instance level)
* **Transfer-syntax negotiation** — re-encoding payloads to match the `Accept` header

Apps SHOULD degrade gracefully: try the richer request, fall back to full-study retrieval if the server doesn't offer it.

The same rules as the FHIR API apply, and the WADO-RS endpoint enforces them itself — a leaked study URL is useless without a valid token. The endpoint SHALL validate the access token and SHALL confirm the requested study belongs to the token's patient before returning any data (see [Authorization](#authorization)). If assembling the data takes time (for example, a C-MOVE from a PACS under the hood), the endpoint MAY respond `503` with a `Retry-After` header, exactly as in [Finding studies](#finding-studies).
