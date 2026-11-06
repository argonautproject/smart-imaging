This page specifies endpoint discovery, authorization, study search, and DICOM retrieval. The specification supports both SMART App Launch and [SMART Backend Services](#backend-services); deployments can support either or both authorization modes. The actors are defined on the [home page](index.html), including the Imaging FHIR Server and DICOMweb Server functions collectively called the Imaging Server.

Each section below follows the steps of an imaging workflow and groups its requirements by the party responsible for them:

| Party | [Discovery](#discovery) | [Authorization](#authorization) | [Finding studies](#finding-studies) | [Retrieving images](#retrieving-images) |
|---|---|---|---|---|
| **App** | Finds the imaging endpoint and supported modes | Obtains and protects its token | Searches and resolves Endpoints | Builds requests and states acceptable transfer syntaxes |
| **Authorization Server** | Described by the SMART configuration | Issues tokens and supports their validation | | |
| **Clinical FHIR Server** | Advertises imaging endpoints | Enforces its own access permissions | | |
| **Imaging FHIR Server** | | Validates tokens and enforces access | Supports searches and returns studies and Endpoints | |
| **DICOMweb Server** | | Validates tokens and enforces access | | Serves retrieval, selects transfer syntaxes, and denies unauthorized requests |

### Discovery

An app needs to find the imaging endpoint and learn which authorization modes it supports before searching for studies. It learns the endpoint in one of two ways: **in-band**, from the clinical FHIR endpoint's SMART configuration document, or **out-of-band**, from direct configuration (an endpoint directory, a partner agreement).

**What the Clinical FHIR Server advertises.** A Clinical FHIR Server supporting in-band discovery SHALL advertise imaging support with the capability string **`smart-imaging-access`** in its endpoint's `.well-known/smart-configuration`:

* in the top-level `capabilities` array, if that FHIR endpoint also serves `ImagingStudy` as described here, or
* in `associated_endpoints[].capabilities`, if a separate FHIR endpoint does.

For example, a clinical FHIR endpoint at `https://clinical.example.org/fhir` whose associated imaging endpoint is hosted separately at `https://imaging.example.org/fhir` would serve this at `https://clinical.example.org/fhir/.well-known/smart-configuration`:

```js
{
  "authorization_endpoint": "https://auth.example.org/authorize",
  "token_endpoint": "https://auth.example.org/token",
  "grant_types_supported": ["authorization_code"],
  "capabilities": ["launch-standalone", "..."],
  "associated_endpoints": [
    {
      "url": "https://imaging.example.org/fhir",
      "capabilities": [
        "smart-imaging-access",
        "http://fhir.org/argonaut/smart-imaging/capabilities/app-launch"
      ]
    }
  ]
}
```

The `smart-imaging-access` capability identifies the imaging interface; it does not imply either authorization mode. So a deployment also advertises each mode it supports. Deployments supporting both modes SHALL advertise both mode-specific capabilities. Support for a grant type alone does not establish support for that mode at an imaging endpoint. Advertising support does not grant access to any particular client.

* **App Launch.** A deployment supporting App Launch SHALL advertise `http://fhir.org/argonaut/smart-imaging/capabilities/app-launch` alongside `smart-imaging-access` for each imaging endpoint supporting that mode. The SMART configuration SHALL advertise `authorization_code` in `grant_types_supported` and meet SMART App Launch discovery requirements.
* **Backend Services.** A deployment supporting the [Backend Services mode](#backend-services) SHALL additionally advertise `http://fhir.org/argonaut/smart-imaging/capabilities/backend-services` alongside `smart-imaging-access` for each imaging endpoint supporting that mode. This URI is a capability identifier, not an API endpoint. In the Clinical FHIR Server's `.well-known/smart-configuration`, the capability goes in the top-level or associated endpoint's `capabilities` array as above; `grant_types_supported` and token authentication metadata remain at the top level, describing the advertised Authorization Server. That document SHALL include `client_credentials` in `grant_types_supported` and meet SMART's [asymmetric client authentication discovery requirements](https://hl7.org/fhir/smart-app-launch/STU2.2/client-confidential-asymmetric.html#discovery-requirements). It SHOULD list `system/ImagingStudy.rs` in `scopes_supported`.

**What the app does.** In-band discovery requires no per-site setup for the app; apps SHOULD prefer it when available and MAY fall back to out-of-band configuration. The app reads the document above, sees `smart-imaging-access`, and knows it can search `https://imaging.example.org/fhir/ImagingStudy` with the access token it gets from the Authorization Server named in the document. Apps using in-band discovery SHALL check the corresponding imaging-specific capability; out-of-band configuration MAY establish the same support explicitly.

### Authorization

An app uses one SMART authorization across clinical data, study search, and image retrieval, so it doesn't need a separate imaging authorization. The app presents its SMART access token for clinical FHIR access, `ImagingStudy` search, and DICOM retrieval, subject to the granted scopes and underlying access permissions. The guide supports [SMART App Launch](https://hl7.org/fhir/smart-app-launch/app-launch.html) and [SMART Backend Services](#backend-services). Deployments SHALL support at least one of these authorization modes and MAY support both. The app uses the returned endpoint and a currently valid SMART token covering the study; no separate user authorization step is required.

#### App Launch

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="sequence-flow-mobile.svg"/>
<img src="sequence-flow.svg" alt="Sequence diagram: the app authorizes with the Authorization Server, optionally queries the Clinical FHIR Server, searches ImagingStudy on the Imaging Server, and retrieves DICOM data from WADO-RS; the Imaging Server validates the token with the Authorization Server via introspection" style="max-width: 100%; height: auto;"/>
</picture>
<p><em>This example shows App Launch, with the same SMART access token used for clinical data, study search, and WADO-RS retrieval.</em></p>
</div>

**What the Authorization Server does.** For deployments supporting App Launch, the Authorization Server SHALL support SMART App Launch and SHALL offer scopes permitting `ImagingStudy` read access (`patient/ImagingStudy.rs`, `patient/*.rs`, or the SMART 1.0 equivalents).

**What the app does.** The app runs a standard SMART App Launch flow (for example, a standalone launch) against the Authorization Server, requesting scopes that cover imaging: `patient/ImagingStudy.rs` (SMART 2.0), `patient/ImagingStudy.read` (SMART 1.0), or a wildcard that includes it such as `patient/*.rs`, along with any needed launch context or refresh scopes (such as `launch/patient` and `online_access`). The user approves sharing, and the app receives a token response with the granted scopes and patient context:

```js
{
  "access_token": "access-token-value-unguessable",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "launch/patient patient/ImagingStudy.rs online_access",
  "refresh_token": "refresh-token-value-unguessable-and-long-lasting",
  "patient": "123"
}
```

The app SHALL present this `access_token`, or a token obtained by refreshing it, as a Bearer token for clinical FHIR reads, `ImagingStudy` searches, and WADO-RS retrievals at the designated endpoints.

<a id="backend-services"></a>

#### Backend Services

This mode supports clients whose access is authorized in advance by the source organization, such as a referral service retrieving images for patients it is permitted to serve. It uses ordinary patient-specific queries; it does not require bulk export or population-wide search. Deployments advertising Backend Services imaging support SHALL meet this mode's discovery, token acquisition, and access-enforcement requirements. App Launch support is not required for a Backend Services-only deployment.

**How the Backend Client obtains a token.** The Backend Client and Authorization Server SHALL follow [SMART Backend Services](https://hl7.org/fhir/smart-app-launch/STU2.2/backend-services.html), including registration, asymmetric client authentication, and the `client_credentials` grant. The Backend Client requests `system/ImagingStudy.rs`; deployments supporting this mode SHALL support that scope. A granted wildcard covering the same interactions MAY also be used. Include any required clinical-resource scopes in the same token request.

The Backend Client SHALL present a currently valid access token obtained this way as a Bearer token for study search and DICOM retrieval at the designated endpoints, just as in App Launch. The signed JWT used to authenticate the client at the token endpoint is not the access token and SHALL NOT be used as the bearer token for imaging requests.

**How the Backend Client identifies the patient.** There is no required `patient` launch context in this mode. Each search uses the patient's FHIR logical ID in the source Clinical FHIR Server's namespace (for example, `123` for `Patient/123`), as in the App Launch flow, not an MRN or the receiving organization's patient ID. How the Backend Client obtains that logical ID (for example, through a clinical FHIR `Patient` query, prior exchange context, or an external patient-matching workflow) is outside this guide. The Imaging Server maps the source logical ID to its imaging records as described in [Imaging Identifiers](identifiers.html). Patient matching and discovering which organizations hold records remain outside this guide.

**What the scope permits.** In this guide, `system/ImagingStudy.rs` permits study search and retrieval of the associated DICOM data only within the client's pre-authorized access. It does not grant access to all patients or all studies. The search parameter selects data, not permission to access it. The Authorization Server and participating resource servers SHALL have an arrangement that allows them to enforce the client's applicable access restrictions consistently. How those permissions are assigned and communicated is deployment-specific. Backend use of `patient/` or `user/` scopes is not defined by this mode.

**Example (non-normative).** A referral service is registered with the source organization. Its permissions allow study A for patient `123`, but not study B for the same patient or any studies for patient `456`. It obtains a short-lived token with `system/ImagingStudy.rs` using SMART Backend Services.

| Request with that token | Result |
|---|---|
| Search `ImagingStudy?patient=123&_include=ImagingStudy:endpoint` | Returns A and its endpoint; omits B |
| Retrieve A through its WADO-RS endpoint using the same token | Returns A's DICOM data |
| Request B directly through the token-protected WADO-RS endpoint | Denied; the token does not authorize B |
| Search `ImagingStudy?patient=456` | `403 Forbidden`; this patient is outside the client's authorized access |

If the service also needs clinical reports, it requests an appropriate clinical scope, such as `system/DiagnosticReport.rs`. The Clinical FHIR Server independently enforces the permissions applicable to those reports.

#### Token validation and access enforcement

The Imaging FHIR Server and the DICOMweb Server can't rely on a request's contents to establish authorization. A WADO-RS request names a study, not a patient, and a valid token doesn't by itself establish which studies a client may access. So each server checks every request before returning data.

**What the Authorization Server provides.** The Authorization Server SHALL provide a way for Imaging Servers to validate its tokens — SMART Token Introspection unless another arrangement is in place.

**How the Imaging Server trusts the token.** If the Imaging Server and Authorization Server operate as one system, this is ordinary local token validation. If they are separate systems, the Imaging Server needs a way to check tokens issued by the Authorization Server. The expected mechanism is [SMART Token Introspection](https://hl7.org/fhir/smart-app-launch/token-introspection.html):

```
POST https://auth.example.org/introspect
Content-Type: application/x-www-form-urlencoded

token=access-token-value-unguessable
```

Other trust arrangements (for example, signed tokens the Imaging Server can verify directly) MAY be used, provided the server can enforce the checks below.

**Checks the Imaging Server performs.** Before serving any imaging FHIR or WADO-RS request, the Imaging Server SHALL confirm that:

1. the token is **active** (not expired or revoked), issued by the configured Authorization Server, and **authorized for use at this resource server**;
2. the token's **scopes cover the request** — patient-level imaging scopes for App Launch, or system-level imaging scopes for Backend Services; and
3. the request is within the **authorized access**, according to what the token carries:
   * **A token with a patient context (App Launch):** the request SHALL be for the patient in the token's patient context. The Imaging Server compares that patient with the `?patient=` parameter on a FHIR search, or with the patient who owns the study on a WADO-RS retrieval. Any additional access restrictions SHALL also be enforced.
   * **A token with system scopes (Backend Services):** the Imaging Server SHALL establish the client identity from validated token information and enforce that client's pre-authorized access, narrowed by the granted scopes, for the requested patient and studies.
   * **Either token:** a Study Instance UID is not by itself proof of patient identity or authorization; the Imaging Server SHALL verify that the requested study belongs to the authorized patient before returning metadata or DICOM instances.

These rules also apply where the context is absent or unclear:

* Missing patient context SHALL NOT be treated as authorization for system-level access.
* A server not supporting the Backend Services mode SHALL NOT grant imaging access on the basis of system scopes.
* A server SHALL NOT serve data when it cannot establish the applicable permissions.
* For tokens carrying more than one scope, each grant retains its own context and restrictions; permissions SHALL NOT be broadened by combining the context of one grant with another grant's scope.

SMART introspection returns `client_id` and granted scopes, and patient context when it was issued. It does not define a complete representation of a client's underlying permissions. An active token with `system/ImagingStudy.rs` is therefore insufficient on its own to establish which studies the client may access. Separate Imaging Servers need a policy lookup, shared authorization service, or another arrangement that enforces those permissions.

The Imaging Server MAY gather additional information from the Clinical FHIR Server to make an access decision — for example, using its own [SMART Backend Services](https://hl7.org/fhir/smart-app-launch/backend-services.html) credentials to fetch `Patient/123` and obtain identifiers for cross-mapping. This internal use does not imply support for backend imaging clients and SHALL NOT expand the requesting client's access. See [Imaging Identifiers](identifiers.html).

#### Using one token across servers

Clinical FHIR, `ImagingStudy` search, and PACS/DICOMweb retrieval often run on separate systems, and an app uses one authorization across them. Deployments SHALL support a single access token across the Clinical FHIR Server, the Imaging FHIR Server, and designated WADO-RS endpoints, so any conformant app can connect.

**What the deployment establishes.** Through `.well-known/smart-configuration` (`associated_endpoints`) or trusted out-of-band configuration, the deployment establishes which Imaging FHIR Server and designated WADO-RS endpoints are authorized to accept tokens from that Authorization Server, and the Authorization Server SHALL authorize those servers. The Imaging FHIR Server SHALL designate only WADO-RS `Endpoint.address` values operated within the deployment's authorization arrangement.

In the authorization request, `aud` identifies the FHIR server that prompted the authorization. It does not limit the authorization to that server: an authorization can also cover the Imaging FHIR Server and WADO-RS endpoints associated with it in the deployment. Each server confirms that the presented token's authorization is associated with it, through the deployment's arrangement with the Authorization Server, such as token introspection or shared configuration. That confirmation does not depend on the `aud` value matching the server's own URL.

**What the app does.** The Imaging FHIR Server the app found through discovery or direct configuration is the trusted Imaging FHIR Server for that authorization. A WADO-RS Endpoint designated by the trusted Imaging FHIR Server is part of this protocol, not an arbitrary reference, so apps present their token there as specified in this guide.

The App, including a Backend Client, SHALL treat the access token as a secret and present it only to the Authorization Server, the Clinical FHIR Server covered by the authorization, the discovered or configured Imaging FHIR Server, and SMART WADO-RS endpoints (`connectionType = dicom-wado-rs`) that the trusted Imaging FHIR Server has designated for the study (via `Endpoint.address`). The token SHALL NOT be sent to non-WADO-RS `Endpoint` addresses advertised on the study (such as viewer launch or QIDO-RS endpoints), unrelated organizations, arbitrary referenced endpoints, or across cross-origin redirects.

**Reducing token exposure.** Presenting one bearer token to several servers means a compromised or misconfigured server could replay it against another server that accepts it. Deployments can reduce this exposure in two ways:

* **A single gateway:** A deployment can expose clinical FHIR, `ImagingStudy` search, and WADO-RS retrieval behind a coherent gateway surface that terminates and validates the client's SMART token at the edge without forwarding the bearer token to internal PACS or archive systems (see [Implementing Study-Level Authorization](authorization-patterns.html)).
* **Stronger options offered at client registration:** alongside the single-token baseline, servers MAY offer sender-constrained tokens using [DPoP (RFC 9449)](https://www.rfc-editor.org/rfc/rfc9449.html) or per-endpoint tokens via [OAuth 2.0 Token Exchange (RFC 8693)](https://www.rfc-editor.org/rfc/rfc8693.html). Experience with these can inform future versions of SMART.

### Finding studies

An app searches for a patient's studies to learn what exists and where to retrieve it. The search returns each study's identifiers, its series and instance list, and the Endpoints for retrieving its images.

**What the app sends.** The app searches `ImagingStudy` by patient on the Imaging FHIR Server, asking it to include each study's WADO-RS Endpoint:

```
GET https://imaging.example.org/fhir/ImagingStudy?patient=123&_include=ImagingStudy:endpoint
Authorization: Bearer access-token-value-unguessable
```

**Searches the Imaging FHIR Server supports.** The Imaging FHIR Server SHALL support these search parameter combinations:

| Query | Use case |
|---|---|
| `patient=123` | List the patient's studies accessible under this authorization |
| `patient=123&identifier={system}%7C{value}`<br/>`patient=123&identifier={value}` | Look up studies by study identifier — such as DICOM Study Instance UID (`identifier=urn:dicom:uid%7Curn:oid:1.2.3` or `identifier=urn:oid:1.2.3`), Accession Number (`identifier=http://hospital.example.org/accession%7CACC-2023-0042` or `identifier=ACC-2023-0042`), or another identifier on `ImagingStudy.identifier` |

The Imaging FHIR Server SHOULD also support these search parameter combinations:

| Query | Use case |
|---|---|
| `patient=123&based-on:identifier={system}%7C{value}`<br/>`patient=123&based-on:identifier={value}` | Look up studies by order Accession Number on `ImagingStudy.basedOn.identifier` (FHIR R6 and IHE MADO compatibility) |
| `patient=123&_lastUpdated=gt2023-04-17T04:00:00Z` | Filter for `ImagingStudy` resources created or modified since a given timestamp |

Following [US Core `_lastUpdated` guidance](https://hl7.org/fhir/us/core/general-guidance.html#searching-using-lastupdated), Imaging FHIR Servers SHOULD support `patient` + `_lastUpdated`. Servers that support it SHALL document in `CapabilityStatement.rest.resource.searchParam.documentation` which changes update `_lastUpdated`. Because `_lastUpdated` reflects changes to the FHIR `ImagingStudy` resource, it does not necessarily change on in-place DICOM edits and does not report studies that were deleted, reassigned, or newly restricted.

The Imaging FHIR Server SHALL support `_include=ImagingStudy:endpoint` so that referenced Endpoints are returned in the search Bundle. See the [server CapabilityStatement](CapabilityStatement-smart-imaging-server.html) for the machine-readable requirements.

**What the Imaging FHIR Server returns.** The server returns a searchset Bundle of `ImagingStudy` resources conforming to the [SMART ImagingStudy](StructureDefinition-smart-imaging-study.html) profile. Every study carries its **DICOM Study Instance UID** (an identifier with system `urn:dicom:uid` and a `urn:oid:...` value), its **status**, **patient**, and **modality**. Studies should also carry descriptive detail when available — start time, series and instance counts, per-series metadata — so apps can show a useful study list before downloading anything.

* **Accession Number.** Clinical reports (`DiagnosticReport`, `ServiceRequest`) often carry the order's Accession Number rather than the DICOM Study Instance UID. When the Imaging FHIR Server knows a study's Accession Number, it SHALL include it in `ImagingStudy.identifier[accession]` (`type = http://terminology.hl7.org/CodeSystem/v2-0203#ACSN`, `value` set to the Accession Number, and `system` set to the assigning authority URI when known) and SHALL support searching by `patient` + `identifier`. Because one order can produce multiple studies, an Accession Number search may return more than one `ImagingStudy`. Because the FHIR R6 draft and [IHE MADO](https://profiles.ihe.net/RAD/MADO/index.html) place the Accession Number on `ImagingStudy.basedOn.identifier` (`type = ACSN`), servers knowing a study's Accession Number SHOULD also populate `ImagingStudy.basedOn.identifier` and SHOULD support `patient` + `based-on:identifier`.
* **Series and instance list.** Apps use a study's series and instance list to confirm they received everything released, detect added or removed content, skip SOP Classes they can't process, and retrieve a single instance, such as a Key Object Selection (`urn:oid:1.2.840.10008.5.1.4.1.1.88.59`) document, without downloading a full series. When `status` is `available`, the study SHALL list its released series (with `uid`, `number`, `modality`, and `numberOfInstances`) and each series SHALL list its released instances (with `uid`, `number`, and `sopClass`). This profile is compatible with [IHE MADO](https://profiles.ihe.net/RAD/MADO/index.html) (including its [`MadoKeyObjectDocumentTitle`](https://profiles.ihe.net/RAD/MADO/StructureDefinition-MadoKeyObjectDocumentTitle.html) extension for conveying a Key Object Selection document's title).
* **Study endpoints.** When `status` is `available`, the study carries at least one study-level **endpoint** conforming to [SMART WADO-RS Endpoint](StructureDefinition-smart-wado-endpoint.html) (`connectionType = dicom-wado-rs`) — the WADO-RS base URL where the app retrieves DICOM data using its SMART token; studies with no retrievable instances (such as `registered` or `cancelled`) MAY omit `endpoint`. A study MAY also list other study-level endpoints (such as an image viewer launch endpoint or a DICOMweb QIDO-RS endpoint) or series-level `ImagingStudy.series.endpoint` references, provided every `available` study supplies a study-level WADO-RS endpoint covering the study.
* **Series endpoints.** An `ImagingStudy.series.endpoint` with `connectionType = dicom-wado-rs` SHALL conform to [SMART WADO-RS Endpoint](StructureDefinition-smart-wado-endpoint.html), be designated by the trusted Imaging FHIR Server, and support series- and instance-level WADO-RS retrieval for that series; it overrides the study-level WADO-RS endpoint for that series while keeping the study-level WADO-RS endpoint for full-study retrieval. `_include=ImagingStudy:endpoint` includes both study- and series-level Endpoints.
* **Response-local Endpoints.** Imaging FHIR Servers MAY use response-local Endpoints. A response-local Endpoint uses a `urn:uuid` value in `Bundle.entry.fullUrl` and the same value in `ImagingStudy.endpoint.reference`. The server SHALL include that Endpoint entry on the same Bundle page as each study referencing it, including when the request omits `_include`.

Worked examples: [study with a contained Endpoint](ImagingStudy-imaging-study-contained-endpoint.html), [study with WADO-RS and QIDO-RS Endpoints](ImagingStudy-imaging-study-wado-and-qido.html), [study with a series-level WADO-RS Endpoint](ImagingStudy-imaging-study-series-endpoint.html), [study with an external Endpoint](ImagingStudy-imaging-study-external-endpoint.html), [search response with a response-local study-context Endpoint](Bundle-imaging-study-context-search-response.html), and a [complete search response Bundle](Bundle-imaging-search-response.html).

**How the app resolves Endpoints.** An Endpoint may be a response-local Bundle entry, a separately addressable resource included in the Bundle, or a contained resource within an `ImagingStudy`. Apps SHALL support all three forms and resolve references using the [FHIR Bundle reference-resolution rules](https://hl7.org/fhir/R4/bundle.html#references). For a response-local Endpoint, the UUID identifies the Endpoint within the response; the app resolves the reference to the included Endpoint and uses its HTTPS `address` as the WADO-RS base URL.

**Access control.** Every search is subject to the checks in [Authorization](#authorization). For a token with a patient context, the `patient` search parameter SHALL match the token's patient context; a mismatch receives `403 Forbidden`, not an empty Bundle. For a token with system scopes, a request for a patient outside the client's authorized access SHALL receive `403 Forbidden`. Within an authorized patient, the Imaging FHIR Server SHALL omit studies and included Endpoints the client is not permitted to access. A successful search may therefore return only some studies, or none. These rules also apply when a search includes `identifier` or `_lastUpdated`. Both authorization modes use the patient-specific search combinations above; this guide does not require unfiltered or population-wide search.

**Delayed or incomplete search results.** Some Imaging Servers front systems that answer slowly — for example, a proxy that issues a DICOM C-FIND to a PACS on first request, or a service aggregating across more than one archive. Rather than holding the connection open, the server MAY respond:

```
HTTP/1.1 503 Service Unavailable
Retry-After: 30
```

The app SHOULD wait the indicated delay and repeat the identical request. Once results are ready, the server responds normally with the Bundle.

When some studies are ready while another backing source is still responding or unreachable, the server MAY instead return the available `ImagingStudy` matches (`entry.search.mode = "match"`) together with an `OperationOutcome` entry (`entry.search.mode = "outcome"`, `issue.code = "incomplete"`). An app can repeat the search later to obtain the remaining results.

*Scaling (non-normative).* Forwarding every search to the PACS can overload it. Caching study metadata can reduce that load. Cache invalidation can use time-based rules or change feeds from the PACS or RIS. The 503/Retry-After pattern complements caching: the first request warms the cache; retries hit it. Cache underlying study metadata separately from response-specific authorization data. For each response, apply the current authorization and assemble Endpoint entries and references for the requesting client. Listing instances may require a query per series against the archive, so caching the instance inventory is especially useful.

### Retrieving images

An app retrieves DICOM data from the WADO-RS Endpoints returned by the search, using the same authorization. Requests follow DICOMweb, so an existing WADO-RS client needs little beyond its SMART token and the rules below.

#### What the app does

For an `available` study, its SMART WADO-RS Endpoint (`connectionType = dicom-wado-rs`) supplies a WADO-RS base URL in `Endpoint.address`. For series or instance retrieval, the app uses the series' WADO-RS Endpoint when one is present. Apps SHALL treat `Endpoint.address` as an opaque WADO-RS base URL (preserving any path prefix when appending `/studies/{Study Instance UID}`) and SHALL NOT assume all studies share a single base URL. The app removes the `urn:oid:` prefix from the study's `urn:dicom:uid` identifier value, appends `/studies/{Study Instance UID}` (or a series/instance path beneath it) to the base URL, and sends a currently valid SMART access token covering the study in the `Authorization` header:

```
GET https://imaging.example.org/wado-rs/studies/1.2.840.99999999.19341866.1571297684
Accept: multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.4.90, multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.1; q=0.6
Authorization: Bearer access-token-value-unguessable
```

<a id="transfer-syntax-negotiation"></a>

**Stating acceptable transfer syntaxes.** An app states which transfer syntaxes it can accept, in order of preference, in the `Accept` header of each WADO-RS retrieval. `Accept` takes a comma-separated list of media types with `q` weights ([PS3.18 §8.7.5](https://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_8.7.5.html)); an item without a weight counts as `q=1`, the top preference. When `transfer-syntax` is omitted, [PS3.18 §8.7.3](https://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_8.7.3.html) defaults to uncompressed Explicit VR Little Endian (`1.2.840.10008.1.2.1`).

Four request patterns cover most uses:

1. **Lossless compression, by preference.** An app that wants smaller payloads without losing fidelity lists the lossless compressed syntaxes it decodes, followed by uncompressed Explicit VR Little Endian (`1.2.840.10008.1.2.1`). Apps that only decode standard transfer syntaxes omit `*` so archives holding instances in proprietary or specialized syntaxes transcode to a listed syntax rather than returning unparseable bytes:

   ```
   Accept: multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.4.90,
           multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.4.80; q=0.9,
           multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.4.70; q=0.8,
           multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.1; q=0.6
   ```

2. **Uncompressed.** An app that wants uncompressed pixel data requests Explicit VR Little Endian:

   ```
   Accept: multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.1
   ```

3. **As stored.** An app that will archive, forward, or donate a study — or that can decode any transfer syntax defined by the DICOM Standard — requests `transfer-syntax=*` (either alone or as a lower-weighted fallback, such as `transfer-syntax=*; q=0.5`) to obtain each instance as stored:

   ```
   Accept: multipart/related; type=application/dicom; transfer-syntax=*
   ```

4. **Lossy, for viewing.** An app that needs to display a study quickly over a constrained connection lists a lossy syntax first with a lossless or uncompressed fallback. Because lossy output is not full fidelity, an app that will store or share the study SHOULD retrieve a lossless or as-stored copy:

   ```
   Accept: multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.4.50,
           multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.4.90; q=0.8,
           multipart/related; type=application/dicom; transfer-syntax=1.2.840.10008.1.2.1; q=0.6
   ```

After a `406`, an app can request smaller resources, such as individual series or instances, to find which ones can be provided in the syntaxes it accepts.

#### What the DICOMweb Server does

**Required retrieval operations.** A SMART WADO-RS Endpoint SHALL support study-, series-, and instance-level DICOM retrieval per the [DICOMweb WADO-RS standard](https://dicom.nema.org/medical/dicom/current/output/html/part18.html):

* **Study-level** retrieval — `GET /studies/{StudyInstanceUID}`
* **Series-level** retrieval — `GET /studies/{StudyInstanceUID}/series/{SeriesInstanceUID}`
* **Instance-level** retrieval — `GET /studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/{SOPInstanceUID}`

The response returns the requested DICOM instances as a `multipart/related` body:

```
HTTP/1.1 200 OK
Content-Type: multipart/related; type=application/dicom; boundary=...

[DICOM instances, one part each]
```

**Additional retrieval operations.** Further WADO-RS capabilities enable richer app behavior (progressive loading, thumbnails, viewing without a full download). DICOMweb Servers SHOULD also support:

* **Metadata** — `GET /studies/{uid}/metadata` (and at series/instance level)
* **Frame-level** retrieval — `.../instances/{uid}/frames/{n}`
* **Rendered** images — `.../rendered` at study, series, or instance level

**Selecting a transfer syntax.**

<div style="text-align: center; margin: 1.5em 0;">
<img src="transfer-syntax-decision.svg" alt="Flowchart: for each instance, the server walks the app's Accept list from highest q to lowest. If the item is * or matches the stored syntax, send as stored (an instance stored in a private syntax is sent in a standard syntax unless the request lists it). Otherwise, if the server can produce that syntax, re-encode losslessly or compress lossily (setting Lossy Image Compression 0028,2110 = 01 with ratio and method) and send; if no item in Accept can be produced, return 406 Not Acceptable." style="max-width: 100%; height: auto;"/>
</div>

* Explicit VR Little Endian gives every app a representation it can read, so DICOMweb Servers SHALL support `transfer-syntax=1.2.840.10008.1.2.1` (Explicit VR Little Endian, also the default when `transfer-syntax` is omitted) for every instance, except where the pixel data is available only in a lossy transfer syntax defined by the DICOM Standard, or is too long to encode in that syntax ([PS3.18 §8.7.3](https://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_8.7.3.html)). In those cases, the server SHALL be able to return the instance in a transfer syntax defined by the DICOM Standard. A lightweight file-backed server without runtime transcoding can meet this requirement by storing files in Explicit VR Little Endian.
* `transfer-syntax=*` lets an app receive what the archive holds, so DICOMweb Servers SHALL support it, returning each instance as stored without adding lossy compression. Instances already stored in a lossy syntax are returned in that form. DICOMweb Servers SHOULD NOT return a private transfer syntax unless the request lists it explicitly, and SHOULD answer `transfer-syntax=*` for such an instance with a transfer syntax defined by the DICOM Standard.
* DICOMweb Servers SHOULD support common lossless compressed transfer syntaxes — JPEG 2000 Lossless (`1.2.840.10008.1.2.4.90`), JPEG-LS Lossless (`1.2.840.10008.1.2.4.80`), and JPEG Lossless, Non-Hierarchical, First-Order Prediction (`1.2.840.10008.1.2.4.70`).
* DICOMweb Servers MAY offer lossy transfer syntaxes and SHALL apply lossy compression only when a lossy syntax is listed in `Accept` and selected by preference order, setting Lossy Image Compression `(0028,2110)` to `01` along with the compression ratio and method ([PS3.3 §C.7.6.1.1.5](https://dicom.nema.org/medical/dicom/current/output/chtml/part03/sect_C.7.6.html#sect_C.7.6.1.1.5)).
* Every response part SHALL declare the transfer syntax of the returned instance in its `Content-Type` header (`Content-Type: application/dicom; transfer-syntax=...`).
* If the DICOMweb Server cannot provide any transfer syntax accepted by the request, it SHALL respond `406 Not Acceptable`.

**Authorizing retrieval.** The DICOMweb Server SHALL perform the token and access checks in [Authorization](#authorization) on every request — including study, series, instance, metadata, rendered, and frame retrievals, whether or not the app previously searched for the study — and SHALL accept any currently valid SMART token from the configured Authorization Server that authorizes access to the study (including tokens obtained through refresh or subsequent token requests).

The DICOMweb Server SHALL deny requests outside the authorized access without returning DICOM data. When access restrictions exclude only specific series or instances within a study, the Imaging Server MAY either withhold the study or expose the authorized subset consistently across `ImagingStudy` and WADO-RS retrieval. Status codes follow [PS3.18 §8.5](https://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_8.5.html). A DICOMweb Server can respond `404 Not Found` to requests for excluded series or instances so that a client cannot infer that they exist.

**When data takes time to assemble.** If assembling the requested data takes time (for example, a C-MOVE from a PACS under the hood), the DICOMweb Server MAY respond `503 Service Unavailable` with a `Retry-After` header, as in [Finding studies](#finding-studies), rather than returning an incomplete `200 OK` payload. Future revisions of this guide will align with DICOM WG-27 as DICOM standardizes delayed or partial WADO-RS retrieval.

[Implementing Study-Level Authorization](authorization-patterns.html) describes ways to distribute these decisions and checks among cooperating systems, including gateways and signed study-context URLs.
