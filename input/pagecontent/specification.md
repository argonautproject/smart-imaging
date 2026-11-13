*This page is normative, except for examples and sections explicitly marked non-normative.*

This page specifies endpoint discovery, authorization, study search, and DICOM retrieval. The guide supports both [SMART App Launch](#app-launch) and [SMART Backend Services](#backend-services); deployments can support either or both patterns.

Actors are defined on the [home page](index.html#actors). **Client** covers user-facing Apps and Backend Clients; **Imaging Server** refers collectively to the Imaging FHIR Server and DICOMweb Server functions.

| Actor | Responsibilities |
|---|---|
| Client | [Discover the endpoint and supported flow](#discovery-app); [obtain and protect the token](#app-token-handling); [search and resolve Endpoints](#finding-studies-app); [retrieve images](#retrieving-images-app) |
| Clinical FHIR Server | [Advertise imaging endpoints for in-band discovery](#discovery-clinical-fhir-server); [enforce access to clinical resources in Backend Services](#backend-services) |
| Authorization Server | [Support App Launch](#app-launch) or [Backend Services](#backend-services); [bind endpoint-specific Patient context](patient-identity.html#endpoint-patient-context); [enable token validation](#authorization-server) |
| Imaging FHIR Server | [Validate tokens and enforce access](#imaging-server-authorization); [designate participating retrieval endpoints](#cooperating-servers); [search and return studies and Endpoints](#finding-studies-imaging-fhir-server) |
| DICOMweb Server | [Validate tokens and enforce access](#imaging-server-authorization); [serve authorized retrievals](#retrieving-images-dicomweb-server) |

### Discovery

The client learns the imaging endpoint and the authorization flows it supports. Discovery can be **in-band**, from the Clinical FHIR Server's SMART configuration document, or **out-of-band**, from direct configuration (an endpoint directory, a partner agreement).

<a id="discovery-app"></a>

#### Client: discovery

In-band discovery requires no per-site setup for the client; clients SHOULD prefer it when available and MAY fall back to out-of-band configuration.

The `smart-imaging-access` capability identifies the imaging interface. Clients using in-band discovery SHALL check `grant_types_supported` for the grant their authorization flow uses: `authorization_code` for App Launch or `client_credentials` for Backend Services. Out-of-band configuration MAY establish flow support. Access remains subject to the checks in [Authorization](#authorization).

The client determines the endpoint's Patient namespace from its [Patient-reference metadata](patient-identity.html#patient-reference-base).

<a id="discovery-clinical-fhir-server"></a>

#### Clinical FHIR Server and deployment

A Clinical FHIR Server supporting in-band discovery SHALL advertise imaging support with the capability string **`smart-imaging-access`** in its endpoint's `.well-known/smart-configuration`:

* in the top-level `capabilities` array, if that FHIR endpoint also serves `ImagingStudy` as described here, or
* in `associated_endpoints[].capabilities`, if a separate FHIR endpoint does.

**App Launch support.** For deployments supporting App Launch, the SMART configuration SHALL include `authorization_code` in `grant_types_supported` and meet SMART App Launch discovery requirements.

**Backend Services support.** For deployments supporting [Backend Services](#backend-services), the SMART configuration SHALL include `client_credentials` in `grant_types_supported` and meet SMART's [asymmetric client authentication discovery requirements](https://hl7.org/fhir/smart-app-launch/STU2.2/client-confidential-asymmetric.html#discovery-requirements). It SHOULD list `system/ImagingStudy.rs` in `scopes_supported`.

Grant types, token-endpoint authentication metadata, and `scopes_supported` appear at the top level and describe the advertised Authorization Server.

Patient-namespace metadata and its publication requirements are defined in [Patient Identity and Resource Linkage](patient-identity.html#patient-reference-base).

**Example (non-normative).** A Clinical FHIR Server at `https://clinical.example.org/fhir` whose associated imaging endpoint is hosted separately at `https://imaging.example.org/fhir` would serve this at `https://clinical.example.org/fhir/.well-known/smart-configuration`:

```js
{
  "authorization_endpoint": "https://auth.example.org/authorize",
  "token_endpoint": "https://auth.example.org/token",
  "grant_types_supported": ["authorization_code"],
  "capabilities": ["launch-standalone", "..."],
  "associated_endpoints": [
    {
      "url": "https://imaging.example.org/fhir",
      "patient_reference_base": "https://clinical.example.org/fhir",
      "capabilities": ["smart-imaging-access"]
    }
  ]
}
```

The client discovers the imaging endpoint and `authorization_code` support, then requests authorization from the advertised Authorization Server.

### Authorization

The client obtains SMART authorization for clinical FHIR access, `ImagingStudy` search, and DICOM retrieval, subject to the granted scopes and underlying access permissions. The guide supports [SMART App Launch](https://hl7.org/fhir/smart-app-launch/app-launch.html) and [SMART Backend Services](#backend-services). Deployments SHALL support at least one of these authorization flows and MAY support both. The [single-token baseline](#cooperating-servers) requires no separate imaging authorization or client-side token exchange.

<a id="app-token-handling"></a>

#### Client: token handling

The client SHALL protect its access token and present it only to the Authorization Server, Clinical FHIR Server covered by its authorization, discovered or configured Imaging FHIR Server, and SMART WADO-RS endpoints designated by that Imaging FHIR Server. The client SHALL NOT send the token to other Endpoint connection types, arbitrary references, unrelated organizations, or across cross-origin redirects.

<a id="cooperating-servers"></a>

#### Deployment: authorization across cooperating servers

Deployments SHALL support a single access token across participating Clinical FHIR, Imaging FHIR, and WADO-RS servers. The deployment establishes the participating services through SMART discovery or trusted configuration, and the Authorization Server SHALL authorize those services. The Imaging FHIR Server SHALL designate only WADO-RS `Endpoint.address` values within that authorization arrangement.

**Informative audience clarification.** A SMART authorization code flow can be initiated against any participating FHIR server, identified by the authorization request's `aud`. Each resource server still confirms that the presented token is authorized for it through the deployment's arrangement with the Authorization Server.

The Authorization Server and participating resource servers MAY offer sender-constrained tokens using [DPoP](https://www.rfc-editor.org/rfc/rfc9449) or per-endpoint tokens using [OAuth Token Exchange](https://www.rfc-editor.org/rfc/rfc8693) at client registration alongside the single-token baseline. Token-presentation instructions below describe the baseline bearer-token flow; registered stronger mechanisms use their corresponding presentation requirements.

<a id="imaging-permissions"></a>

#### Imaging permissions

This guide defines how SMART ImagingStudy permissions authorize WADO-RS retrieval. The `patient/`, `user/`, and `system/` prefixes retain their patient, user, and pre-authorized-client boundaries.

| Granted permission | Authorized operations |
|---|---|
| `ImagingStudy.s` | FHIR ImagingStudy search |
| `ImagingStudy.r` | FHIR ImagingStudy read where supported, and supported WADO-RS retrieval of the authorized study content |
| `ImagingStudy.rs` | Both search and read/retrieval |

Covering wildcards have the same effect; SMART 1.0 `.read` is equivalent to `.rs`. Read permission covers supported study, series, instance, frame, metadata, and rendered retrievals. It does not require support for optional operations or authorize QIDO-RS, storage, or viewer launch. All requests remain bounded by the grant and underlying access policy.

#### App Launch

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="sequence-flow-mobile.svg"/>
<img src="sequence-flow.svg" alt="Sequence diagram: the App authorizes with the Authorization Server, optionally queries the Clinical FHIR Server, searches ImagingStudy on the Imaging FHIR Server, and retrieves DICOM data from the DICOMweb Server; the Imaging Server validates the token with the Authorization Server via introspection" style="max-width: 100%; height: auto;"/>
</picture>
<p><em>This example shows App Launch using the single-token baseline within participating services.</em></p>
</div>

**Authorization Server.** For deployments supporting App Launch, the Authorization Server SHALL support SMART App Launch and SHALL offer scopes permitting `ImagingStudy` read access (`patient/ImagingStudy.rs`, `patient/*.rs`, or the SMART 1.0 equivalents).

**App.** The App runs a standard SMART App Launch flow (for example, a standalone launch) against the Authorization Server, requesting scopes that cover imaging: `patient/ImagingStudy.rs` (SMART 2.0), `patient/ImagingStudy.read` (SMART 1.0), or a wildcard that includes it such as `patient/*.rs`.

**Example (standalone launch, non-normative).** The App requests `launch/patient patient/ImagingStudy.rs offline_access` for patient context, imaging access, and a refresh token usable beyond the user's online session. The user approves sharing, and the Authorization Server grants all requested scopes in this response:

```js
{
  "access_token": "access-token-value-unguessable",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "launch/patient patient/ImagingStudy.rs offline_access",
  "refresh_token": "refresh-token-value-unguessable-and-long-lasting",
  "patient": "123",
  "authorization_details": [
    {
      "type": "smart_on_fhir",
      "locations": ["https://imaging.example.org/fhir"],
      "fhirVersions": ["4.0.1"],
      "patient": "https://clinical.example.org/fhir/Patient/123"
    }
  ]
}
```

The `scope` value reports the scopes actually granted, which can differ from those requested.

The `authorization_details` entry identifies the Patient authorized at the separate Imaging FHIR Server, using the [endpoint-specific context rules](patient-identity.html#endpoint-patient-context).

In the single-token baseline, the App SHALL present a currently valid access token as a Bearer token at the authorized clinical FHIR, Imaging FHIR, and WADO-RS endpoints.

Where user-level imaging access is supported, the App can request `user/ImagingStudy.rs` or a wildcard covering the same interactions. The resulting access is bounded by the authorizing user's permissions.

<a id="backend-services"></a>

#### Backend Services

This mode supports Backend Clients whose access is authorized in advance by the source organization, such as a referral service retrieving images for patients it is permitted to serve. It uses ordinary patient-specific queries; it does not require bulk export or population-wide search.

**Deployment.** Deployments advertising Backend Services imaging support SHALL meet that mode's discovery, token acquisition, and access-enforcement requirements. App Launch support is not required for a Backend Services-only deployment.

**Backend Client and Authorization Server.** The Backend Client and Authorization Server SHALL follow [SMART Backend Services](https://hl7.org/fhir/smart-app-launch/STU2.2/backend-services.html), including registration, asymmetric client authentication, and the `client_credentials` grant. The Backend Client requests `system/ImagingStudy.rs`; deployments supporting this mode SHALL support that scope. A granted wildcard covering the same interactions MAY also be used. The Backend Client includes any required clinical-resource scopes in the same token request.

In the single-token baseline, the Backend Client SHALL present a currently valid access token as a Bearer token for study search and DICOM retrieval at the designated endpoints. The signed JWT used to authenticate the client at the token endpoint is not the access token and SHALL NOT be used as the bearer token for imaging requests.

**Authorization Server and participating resource servers.** In this guide, `system/ImagingStudy.rs` permits study search and retrieval of the associated DICOM data only within the Backend Client's pre-authorized access. It does not grant access to all patients or all studies. The Authorization Server and participating resource servers SHALL have an arrangement that allows them to enforce the Backend Client's applicable access restrictions consistently. How those permissions are assigned and communicated is deployment-specific.

**Patient identity.** There is no required `patient` launch context in this mode. When searching by patient, the Backend Client uses the applicable Patient reference described in [Patient references](patient-identity.html#patient-references). Backend use of `patient/` or `user/` scopes is not defined by this mode.

**Example (non-normative).** A referral service is registered with the source organization. In this example, `Patient/123` and `Patient/456` are local to the Imaging FHIR Server. Its permissions allow study A for patient `123`, but not study B for the same patient or any studies for patient `456`. It obtains a short-lived token with `system/ImagingStudy.rs` using SMART Backend Services.

| Request under that authorization | Result |
|---|---|
| Search `ImagingStudy?patient=123&_include=ImagingStudy:endpoint` | Returns A and its endpoint; omits B |
| Obtain a new token authorizing A and retrieve A through the returned WADO-RS endpoint without repeating the search | Returns A's DICOM data |
| Request B directly through the token-protected WADO-RS endpoint | Denied; the token does not authorize B |
| Search `ImagingStudy?patient=456` | `403 Forbidden`; this patient is outside the client's authorized access |

If the service also needs clinical reports, it requests an appropriate clinical scope, such as `system/DiagnosticReport.rs`. The Clinical FHIR Server independently enforces the permissions applicable to those reports.

Retrieval of A remains subject to current authorization, including when the service refreshes its token or obtains a new token. Changing the requested study does not broaden the service's access.

<a id="authorization-server"></a>

#### Authorization Server: token validation

The Authorization Server SHALL provide a way for Imaging Servers to validate its tokens — SMART Token Introspection unless another arrangement is in place.

Endpoint-specific Patient bindings and their communication to clients and Imaging Servers are specified in [Patient authorization context](patient-identity.html#endpoint-patient-context).

<a id="token-validation-and-access-enforcement-both-modes"></a>
<a id="imaging-server-authorization"></a>

#### Imaging Server: token validation and access enforcement (both modes)

These duties apply to both the Imaging FHIR Server and DICOMweb Server.

**Trusting the token.** If the Imaging Server and Authorization Server operate as one system, this is ordinary local token validation. If they are separate systems, the Imaging Server needs a way to check tokens issued by the Authorization Server. The expected mechanism is [SMART Token Introspection](https://hl7.org/fhir/smart-app-launch/token-introspection.html):

```
POST https://auth.example.org/introspect
Content-Type: application/x-www-form-urlencoded

token=access-token-value-unguessable
```

Other trust arrangements (for example, signed tokens the Imaging Server can verify directly) MAY be used, provided the Imaging Server can enforce the checks below.

**Required token checks.** Before serving any imaging FHIR or WADO-RS request, the Imaging Server SHALL confirm that:

1. the token is **active** (not expired or revoked), issued by the configured Authorization Server, and **authorized for use at this resource server**;
2. the token's **scopes cover the request**; and
3. the request is within the **authorized access**, according to the grant authorizing the request:
   * **Patient-level (`patient/`) scopes:** the patient identified by the grant's patient context SHALL be the patient whose data is requested — identified by the `patient` reference on a FHIR search, or associated with the requested study on a WADO-RS retrieval. Any additional access restrictions SHALL also be enforced.
   * **System-level (`system/`) scopes:** the Imaging Server SHALL establish the client identity from validated token information and enforce that client's pre-authorized access, narrowed by the granted scopes, for the requested patient and studies.
   * **User-level (`user/`) scopes:** the Imaging Server SHALL establish the authorizing user's permissions from validated token information or its trusted authorization arrangement and enforce them, narrowed by the granted scopes, for the requested patient and studies.

The Imaging Server interprets patient context using the [endpoint-specific context rules](patient-identity.html#endpoint-patient-context) and search references using the [Patient reference rules](patient-identity.html#patient-references).

Missing patient context SHALL NOT be treated as authorization for system-level access. An Imaging Server not supporting the Backend Services mode SHALL NOT grant imaging access on the basis of system scopes. An Imaging Server SHALL NOT serve data when it cannot establish the applicable permissions. For tokens carrying more than one scope, each grant retains its own context and restrictions; permissions SHALL NOT be broadened by combining the context of one grant with another grant's scope.

SMART introspection returns `client_id` and granted scopes, and patient context when it was issued. It does not define a complete representation of a client's underlying permissions. An active token with `system/ImagingStudy.rs` is therefore insufficient on its own to establish which studies the client may access. Separate Imaging Servers need a policy lookup, shared authorization service, or another arrangement that enforces those permissions.

The Imaging Server MAY gather additional information from the Clinical FHIR Server to make an access decision — for example, using its own [SMART Backend Services](https://hl7.org/fhir/smart-app-launch/backend-services.html) credentials to fetch `Patient/123` and obtain identifiers for cross-mapping. As part of a policy lookup, the Imaging Server can also call an internal permission API to determine which studies the requesting client is permitted to access. This internal use does not imply support for backend imaging clients and SHALL NOT expand the requesting client's access. See [Imaging Identifiers](identifiers.html).

### Finding studies

The client can search `ImagingStudy` by patient on the Imaging FHIR Server to obtain study metadata, the released series and instance inventory, and retrieval Endpoints.

<a id="finding-studies-app"></a>

#### Client: study search

The client selects the Patient reference and constructs the search using [Patient Identity and Resource Linkage](patient-identity.html#patient-references).

**Example (non-normative).** For the split clinical/imaging deployment above, the client searches the Imaging FHIR Server with its authorized absolute Patient reference and asks it to include referenced Endpoints:

```
GET https://imaging.example.org/fhir/ImagingStudy?patient=https%3A%2F%2Fclinical.example.org%2Ffhir%2FPatient%2F123&_include=ImagingStudy:endpoint
Authorization: Bearer access-token-value-unguessable
```

An Endpoint may be a response-local Bundle entry, a separately addressable resource included in the Bundle, or a contained resource within an `ImagingStudy`. Clients SHALL support all three forms and resolve references using the [FHIR Bundle reference-resolution rules](https://hl7.org/fhir/R4/bundle.html#references), including UUID URNs and REST references to Bundle entries.

For this guide's retrieval flow, the client selects SMART WADO-RS Endpoints identified by `Endpoint.connectionType` system `http://terminology.hl7.org/CodeSystem/endpoint-connection-type` and code `dicom-wado-rs`.

For a response-local Endpoint with a `urn:uuid:...` fullUrl, the UUID identifies the Endpoint within the Bundle; it is not the retrieval address. The client resolves the selected WADO-RS Endpoint's reference to the included Endpoint and uses its HTTPS `address` as the WADO-RS base URL.

The released series and instance UIDs and SOP Classes let the client select objects and check retrieval completeness without first downloading a whole study. See [Retrieving images](#retrieving-images) for choosing a study- or series-level WADO-RS Endpoint and constructing request paths.

If the Imaging FHIR Server returns `503 Service Unavailable` with `Retry-After`, the client SHOULD wait the indicated number of seconds and repeat the identical request.

<a id="finding-studies-imaging-fhir-server"></a>

#### Imaging FHIR Server: study search

**Supported searches.** The table specifies required and recommended search support for the Imaging FHIR Server, using Patient references as described in [Patient references](patient-identity.html#patient-references), under the [FHIR reference-search rules](https://hl7.org/fhir/R4/search.html#reference). The table uses `patient=123` for an endpoint using its own Patient namespace.

| Query | Support | Use case |
|---|---|---|
| `patient=123` | SHALL | List the patient's studies accessible under this authorization |
| `patient=123&_lastUpdated=gt2023-04-17T04:00:00Z` | SHOULD | Filter studies by their FHIR resource update timestamp |
| `patient=123&identifier=urn:dicom:uid%7Curn:oid:1.2.3` | SHALL | Look up one study by DICOM Study Instance UID |
| `patient=123&identifier=https%3A%2F%2Fhospital.example.org%2Faccessions%7CACC20261112` | SHALL | Find studies by accession number and assigning authority |
| `patient=123&identifier=ACC20261112` | SHALL | Find studies by accession value across assigning authorities |

The Imaging FHIR Server SHALL support `patient` + `identifier` for accession numbers, DICOM Study Instance UIDs, and other study identifiers. It SHALL accept both `identifier={system}|{value}` (namespace and value) and `identifier={value}` (value only, regardless of namespace). Query parameter values are URL-encoded on the wire. The Imaging FHIR Server SHALL return only studies matching the requested patient and identifier that the Client is authorized to access. One accession can match multiple studies.

The Imaging FHIR Server supporting `patient` + `_lastUpdated` SHALL document its timestamp-update behavior in its developer documentation.

The Imaging FHIR Server SHALL support `_include=ImagingStudy:endpoint` so that referenced Endpoints are returned in the search Bundle. This existing search parameter covers both `ImagingStudy.endpoint` and `ImagingStudy.series.endpoint`; no separate series-endpoint include is needed. See the [server CapabilityStatement](CapabilityStatement-smart-imaging-server.html) for the advertised search capabilities.

**Access control.** The Imaging FHIR Server SHALL enforce the checks in [Authorization](#authorization) on every search. For requests authorized by `patient/` scopes, the server SHALL return `403 Forbidden` if a supplied `patient` reference identifies a different patient from the grant's patient context. For requests authorized by `system/` scopes, the server SHALL return `403 Forbidden` if the requested patient is outside the client's authorized access. The server SHALL omit studies and included Endpoints the client is not permitted to access. These rules apply to all supported search combinations.

**Study representation and inventory.** The Imaging FHIR Server returns a searchset Bundle of `ImagingStudy` resources conforming to the [SMART ImagingStudy](StructureDefinition-smart-imaging-study.html) profile. Every study carries its **DICOM Study Instance UID** (an identifier with system `urn:dicom:uid` and a `urn:oid:...` value), its **status**, **patient**, and **modality**.

**Accession numbers.** The Imaging FHIR Server SHALL populate the repeatable Must Support `ImagingStudy.identifier[accession]` slice when an accession is known, including DICOM Accession Number `(0008,0050)`. The Imaging FHIR Server SHALL set `Identifier.type` to include `http://terminology.hl7.org/CodeSystem/v2-0203#ACSN`, `Identifier.value` to the accession value, and `Identifier.system` to the assigning-authority URI when known.

The Imaging FHIR Server MAY support additional representations, including [IHE MADO](https://profiles.ihe.net/RAD/MADO/). This guide requires neither duplicate accession data in other elements nor `basedOn` support. [FHIR R5](https://hl7.org/fhir/R5/imagingstudy.html#notes) and [FHIR R6 draft](https://build.fhir.org/imagingstudy.html#accession-number) accession guidance are informative references; this guide profiles FHIR R4.

The study's subject follows the [Patient-reference requirements](patient-identity.html#patient-references).

See the non-normative [Study UID assumption](identifiers.html#study-uid-assumption) for the expected study/patient association across the Imaging FHIR and DICOMweb Servers.

The Imaging FHIR Server MAY release an authorized subset of a study or series. It SHALL populate every released series and instance, including `series.uid`, `series.instance.uid`, and `series.instance.sopClass`. Released content is content designated for DICOM retrieval under the current authorization; metadata alone does not establish release. The Imaging FHIR Server SHALL populate `series.number` and `series.instance.number` when their values are present in the source. These number elements remain `0..1` with Must Support; they can be absent when the source does not supply them.

Additional descriptive details, such as start time, series and instance counts, and further per-series metadata, help clients present a useful study list and should be included when available. The released UID hierarchy is compatible with [IHE MADO](https://profiles.ihe.net/RAD/MADO/). MADO's optional [`MadoKeyObjectDocumentTitle` extension](https://profiles.ihe.net/RAD/MADO/StructureDefinition-MadoKeyObjectDocumentTitle.html) conveys the title of a Key Object Selection document, allowing clients to distinguish KOS purposes.

**Endpoint coverage.** Both `ImagingStudy.endpoint` and `ImagingStudy.series.endpoint` use open slicing: the lists and their WADO-RS slices are `0..*` with Must Support. WADO-RS Endpoints conform to [SMART WADO-RS Endpoint](StructureDefinition-smart-wado-endpoint.html); other connection types are also permitted.

The Imaging FHIR Server SHALL provide a SMART WADO-RS Endpoint for every released series, directly at series level or inherited from study level. A study-level WADO-RS Endpoint covers all released series and instances. For series and instance requests, a series-level WADO-RS Endpoint overrides the study-level WADO-RS Endpoint for that series. Other series endpoint connection types do not override inherited WADO-RS coverage. Separate series-level Endpoints can provide coverage without any study-level WADO-RS Endpoint.

FHIR `status = available` means that instances have been associated with the study, not that they are accessible through WADO-RS. Subject to the access rules above, the Imaging FHIR Server can return known study metadata without retrieval Endpoints, including for registered or cancelled studies and for studies with `status = available` whose content is not retrievable.

**Response-local Endpoints.** The Imaging FHIR Server MAY use response-local Endpoints with a `urn:uuid:...` value in `Bundle.entry.fullUrl` and the same value in `ImagingStudy.endpoint.reference` or `ImagingStudy.series.endpoint.reference`. The Imaging FHIR Server SHALL include each response-local Endpoint on the same Bundle page as each study referencing it at either level, even when the request omits `_include`.

Worked examples:

| Example | What it demonstrates |
|---|---|
| [Contained Endpoint](ImagingStudy-imaging-study-contained-endpoint.html) | Study-level WADO-RS coverage and a complete instance inventory |
| [External Endpoint](ImagingStudy-imaging-study-external-endpoint.html) | A separately addressable WADO-RS Endpoint |
| [Response-local study-context Endpoint](Bundle-imaging-study-context-search-response.html) | A WADO-RS base URL resolved within the search Bundle |
| [Mixed endpoint types and a series override](ImagingStudy-imaging-study-mixed-endpoints.html) | WADO-RS inheritance, a direct series override, and non-WADO-RS Endpoints |
| [Series in separate archives](ImagingStudy-imaging-study-series-endpoint.html) | Two direct series Endpoints and no study-wide endpoint |
| [Authorized subset](ImagingStudy-imaging-study-authorized-subset.html) | Complete released inventory when policy excludes another series |
| [Registered study metadata](ImagingStudy-imaging-study-metadata-only.html) | No associated instances or retrieval Endpoints |
| [Available but unretrievable study](ImagingStudy-imaging-study-available-not-retrievable.html) | Known instances without WADO-RS access |
| [Independent Patient namespace](ImagingStudy-imaging-study-independent-patient.html) | A local Patient reference on an imaging server with its own Patient records |
| [Search response Bundle](Bundle-imaging-search-response.html) | Study matches with included Endpoints |
| [Incomplete search response](Bundle-imaging-search-incomplete-response.html) | Available study matches, a resolvable Endpoint, and an incomplete-results warning |
| [Accession search Bundle](Bundle-imaging-accession-search-response.html) | Two authorized studies sharing an accession; repeatable accession identifiers, including one with an unknown assigning authority |

**Incomplete search results.** When a backing source is slow or unavailable, the Imaging FHIR Server MAY return available matches with an `OperationOutcome` entry whose `Bundle.entry.search.mode` is `outcome` and `OperationOutcome.issue.code` is `incomplete`. The Imaging FHIR Server SHALL describe the complete released series and instance inventory for each returned study, including when the set of study matches is incomplete.

**Delayed search results: 503 and Retry-After.** When a backing source is slow or unavailable — for example, a proxy is waiting for a DICOM C-FIND response from a PACS — the Imaging FHIR Server MAY instead respond:

```
HTTP/1.1 503 Service Unavailable
Retry-After: 30
```

Once results are ready, the Imaging FHIR Server responds normally with the Bundle.

*Scaling (non-normative).* Forwarding every search to the PACS can overload it. Caching study metadata can reduce that load. Cache invalidation can use time-based rules or change feeds from the PACS or RIS. The 503/Retry-After pattern complements caching: the first request warms the cache; retries hit it. Cache underlying study metadata separately from request-specific authorization decisions. For each response, apply the current authorization and assemble Endpoint entries and references for the requesting client.

For correlation with Patient, order, report, and clinician resources at other FHIR endpoints, see [Cross-endpoint resource linkage](patient-identity.html#cross-endpoint-linkage).

### Retrieving images

Each SMART WADO-RS Endpoint supplies a base URL in `Endpoint.address`. The client uses the released UID inventory and the applicable endpoint to retrieve a study, a series, or an individual instance with a currently valid token authorizing that access.

<a id="retrieving-images-app"></a>

#### Client: image retrieval

**Selecting an endpoint.** For a full-study request, the client uses an advertised study-level WADO-RS Endpoint. For series or instance retrieval, it uses the series-level WADO-RS Endpoint when present, otherwise the study-level WADO-RS Endpoint. A series-level override does not change which endpoint serves full-study requests.

**Constructing requests.** Clients SHALL treat `Endpoint.address` as an opaque WADO-RS base URL, preserve its path prefix when appending retrieval paths, and SHALL NOT assume that all studies share one base URL. The client removes the `urn:oid:` prefix from the study's `urn:dicom:uid` identifier value. Series and SOP Instance UIDs come directly from `series.uid` and `series.instance.uid`. The client appends the appropriate path to the selected `Endpoint.address`:

| Retrieval | Path appended to the WADO-RS base URL |
|---|---|
| Study | `/studies/{Study Instance UID}` |
| Series | `/studies/{Study Instance UID}/series/{Series Instance UID}` |
| Instance | `/studies/{Study Instance UID}/series/{Series Instance UID}/instances/{SOP Instance UID}` |

In the single-token baseline, the client SHALL send a currently valid SMART access token authorizing the requested retrieval in the `Authorization` header. The DICOMweb Server SHALL accept any currently valid token from the configured Authorization Server that authorizes that access, including refreshed or newly issued tokens. For example:

```
GET https://imaging.example.org/wado-rs/studies/1.2.840.99999999.19341866.1571297684
Accept: multipart/related; type=application/dicom; transfer-syntax=*
Authorization: Bearer access-token-value-unguessable
```

For the [study with series in separate archives](ImagingStudy-imaging-study-series-endpoint.html), the client can retrieve an instance from the second archive using:

```
GET https://archive-two.example.org/dicom-web/studies/1.2.840.99999999.20261112.2/series/1.2.840.99999999.20261112.2.2/instances/1.2.840.99999999.20261112.2.2.1
Accept: multipart/related; type=application/dicom; transfer-syntax=*
Authorization: Bearer access-token-value-unguessable
```

**Optional operations.** Clients SHOULD degrade gracefully when optional operations are unavailable, using series- or instance-level retrieval, or full-study retrieval where a study-level WADO-RS Endpoint is advertised.

<a id="transfer-syntax-requests"></a>

##### Transfer-syntax requests

For DICOM-instance retrieval (`application/dicom`), the client expresses acceptable encodings and preferences in `Accept`. Each alternative names one transfer syntax. Higher `q` values indicate greater preference; omitted `q` means `1`, and `q=0` excludes an alternative. Selection is independent for each instance.

**Lossless preferred, with uncompressed fallback:**

```
Accept: multipart/related; type="application/dicom"; transfer-syntax=1.2.840.10008.1.2.4.90; q=1, multipart/related; type="application/dicom"; transfer-syntax=1.2.840.10008.1.2.1; q=0.8
```

**Uncompressed Explicit VR Little Endian:**

```
Accept: multipart/related; type="application/dicom"; transfer-syntax=1.2.840.10008.1.2.1
```

**As stored:**

```
Accept: multipart/related; type="application/dicom"; transfer-syntax=*
```

**Lossy preferred, with lossless and uncompressed fallbacks:**

```
Accept: multipart/related; type="application/dicom"; transfer-syntax=1.2.840.10008.1.2.4.91; q=1, multipart/related; type="application/dicom"; transfer-syntax=1.2.840.10008.1.2.4.90; q=0.8, multipart/related; type="application/dicom"; transfer-syntax=1.2.840.10008.1.2.1; q=0.6
```

Omitting `transfer-syntax` selects Explicit VR Little Endian (`1.2.840.10008.1.2.1`), subject to [DICOM's default-syntax exceptions](https://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_8.7.3.4.html). Explicitly requesting that UID permits only that encoding. A client storing or sharing a study SHOULD retrieve a lossless or as-stored copy. As-stored content may already be lossy; lossless encoding does not restore information previously lost.

After `406 Not Acceptable`, the client can retrieve individual series or instances, or broaden `Accept` to include other syntaxes it can process. Further partial-retrieval behavior requires coordination with DICOM WG-27.

<a id="retrieving-images-dicomweb-server"></a>

#### DICOMweb Server: image retrieval

**Required retrieval operations.** The DICOMweb Server SHALL support series- and instance-level retrieval at every SMART WADO-RS Endpoint for the content it serves, per the [DICOMweb WADO-RS standard](https://dicom.nema.org/medical/dicom/current/output/html/part18.html).

At a SMART WADO-RS Endpoint advertised at study level, the DICOMweb Server SHALL also support full-study retrieval covering all released series and instances. As-stored retrieval can avoid re-encoding, but does not remove the transfer-syntax capabilities required below. Operation support does not override token or access restrictions.

The response returns the requested DICOM instances as a multipart body:

```
HTTP/1.1 200 OK
Content-Type: multipart/related; type="application/dicom"; boundary=instances

--instances
Content-Type: application/dicom; transfer-syntax=1.2.840.10008.1.2.1

[DICOM instance bytes]
--instances--
```

**Additional retrieval operations.** Further WADO-RS capabilities enable richer client behavior (progressive loading, thumbnails, viewing without a full download). DICOMweb Servers SHOULD support:

* **Frame-level** retrieval — `.../instances/{uid}/frames/{n}`
* **Rendered** images — `.../rendered` at study, series, or instance level
* **Metadata** — `GET /studies/{uid}/metadata` (and at series/instance level)

<a id="transfer-syntax-negotiation"></a>

##### Transfer-syntax negotiation

The following requirements apply to retrieval of DICOM instances as `application/dicom`. Negotiation for other representations, including rendered images, follows the applicable DICOMweb rules.

**Server capabilities.** The DICOMweb Server SHALL support Explicit VR Little Endian (`1.2.840.10008.1.2.1`) for every instance, except when pixel data is available only in a DICOM-defined lossy syntax or is too large for this encoding. For either exception, the server SHALL be able to return a DICOM-defined syntax. It SHOULD support JPEG 2000 Lossless (`1.2.840.10008.1.2.4.90`), JPEG-LS Lossless (`1.2.840.10008.1.2.4.80`), and JPEG Lossless, Non-Hierarchical, First-Order Prediction (`1.2.840.10008.1.2.4.70`). It MAY offer lossy syntaxes, subject to the selection rules below.

**Selection per instance.** The DICOMweb Server SHALL select an acceptable representation for each instance according to the client's preferences and the [DICOM media-type selection rules](https://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_8.7.8.html). Different instances in one response may use different transfer syntaxes.

The DICOMweb Server SHALL support `transfer-syntax=*` for as-stored retrieval without adding lossy compression. Stored representations remain subject to DICOM web-transfer restrictions. For private stored syntaxes, the server SHOULD NOT return them unless explicitly requested and SHOULD return an acceptable DICOM-defined syntax instead.

The DICOMweb Server SHALL apply new lossy compression only when a lossy syntax is explicitly listed in `Accept` and selected by preference. It SHALL set Lossy Image Compression `(0028,2110)` to `01` and record Lossy Image Compression Ratio `(0028,2112)` and Method `(0028,2114)`.

**Response and failure.** The DICOMweb Server SHALL declare each instance's actual transfer syntax in its response part's `Content-Type`. If no acceptable representation can be returned, it SHALL return `406 Not Acceptable`. If only some instances in a study or series have acceptable representations, it MAY reject the request with `406 Not Acceptable`.

##### Retrieval access and availability

**Retrieval authorization.** The DICOMweb Server SHALL perform the token and access checks in [Authorization](#authorization) on every request and enforce all applicable restrictions. These checks apply to every supported retrieval, including full studies, series, instances, frames, metadata, and rendered images, whether or not the client previously searched for the study.

The DICOMweb Server MAY successfully return an authorized subset of a study or series when access policy excludes other content. It SHALL NOT return content outside the authorized access. A study-level WADO-RS Endpoint covers all released content, as described in [Endpoint coverage](#finding-studies-imaging-fhir-server).

**Expiry and revocation.** The DICOMweb Server SHALL check token validity when accepting each request. A response authorized before expiry MAY finish after expiry. New or retried requests SHALL be checked again.

**Delayed retrieval.** If released content is temporarily unavailable while being assembled (for example, a C-MOVE from a PACS under the hood), the DICOMweb Server MAY respond `503 Service Unavailable` with `Retry-After`. Policy-excluded content is not delayed content. Further coordination of delayed and partial WADO-RS responses with DICOM WG-27 is pending.

[Implementing Study-Level Authorization](authorization-patterns.html) describes ways to distribute these decisions and checks among cooperating systems.
