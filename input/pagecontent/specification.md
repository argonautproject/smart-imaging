This page specifies endpoint discovery, authorization, study search, and DICOM retrieval. The specification supports both SMART App Launch and [SMART Backend Services](#backend-services); deployments can support either or both patterns. The actors are defined on the [home page](index.html), including the Imaging FHIR Server and DICOMweb Server functions collectively called the Imaging Server.

### Discovery

An app learns the imaging endpoint in one of two ways: **in-band**, from the clinical FHIR endpoint's SMART configuration document, or **out-of-band**, from direct configuration (an endpoint directory, a partner agreement). In-band discovery requires no per-site setup for the app; apps SHOULD prefer it when available and MAY fall back to out-of-band configuration.

A Clinical FHIR Server supporting in-band discovery SHALL advertise imaging support with the capability string **`smart-imaging-access`** in its endpoint's `.well-known/smart-configuration`:

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

The app reads this document, sees `smart-imaging-access`, and knows it can search `https://imaging.example.org/fhir/ImagingStudy` with the access token it gets from the Authorization Server named in the document.

**App Launch support.** A deployment supporting App Launch SHALL advertise `http://fhir.org/argonaut/smart-imaging/capabilities/app-launch` alongside `smart-imaging-access` for each imaging endpoint supporting that mode. The SMART configuration SHALL advertise `authorization_code` in `grant_types_supported` and meet SMART App Launch discovery requirements.

**Backend Services support.** A deployment supporting the [Backend Services mode](#backend-services) SHALL additionally advertise `http://fhir.org/argonaut/smart-imaging/capabilities/backend-services` alongside `smart-imaging-access` for each imaging endpoint supporting that mode. This URI is a capability identifier, not an API endpoint. In the Clinical FHIR Server's `.well-known/smart-configuration`, the capability goes in the top-level or associated endpoint's `capabilities` array as above; `grant_types_supported` and token authentication metadata remain at the top level, describing the advertised Authorization Server. That document SHALL include `client_credentials` in `grant_types_supported` and meet SMART's [asymmetric client authentication discovery requirements](https://hl7.org/fhir/smart-app-launch/STU2.2/client-confidential-asymmetric.html#discovery-requirements). It SHOULD list `system/ImagingStudy.rs` in `scopes_supported`.

The `smart-imaging-access` capability identifies the imaging interface; it does not imply either authorization mode. Deployments supporting both modes SHALL advertise both mode-specific capabilities. Support for a grant type alone does not establish support for that mode at an imaging endpoint. Clients using in-band discovery SHALL check the corresponding imaging-specific capability; out-of-band configuration MAY establish the same support explicitly. Advertising support does not grant access to any particular client.

### Authorization

The app presents the same SMART access token for clinical FHIR access, `ImagingStudy` search, and DICOM retrieval, subject to the granted scopes and underlying access permissions. The guide supports [SMART App Launch](https://hl7.org/fhir/smart-app-launch/app-launch.html) and [SMART Backend Services](#backend-services). Deployments SHALL support at least one of these authorization modes and MAY support both. Servers MAY return token-bound capability URLs to carry study-specific permissions to the retrieval service. The client uses the returned endpoint and its existing token in either case; no separate user authorization step or client-side token exchange is required.

#### App Launch

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="sequence-flow-mobile.svg"/>
<img src="sequence-flow.svg" alt="Sequence diagram: the app authorizes with the Authorization Server, optionally queries the Clinical FHIR Server, searches ImagingStudy on the Imaging Server, and retrieves DICOM data from WADO-RS; the Imaging Server validates the token with the Authorization Server via introspection" style="max-width: 100%; height: auto;"/>
</picture>
<p><em>This example shows App Launch, with the same SMART access token used for clinical data, study search, and WADO-RS retrieval.</em></p>
</div>

**Obtaining a token.** The app runs a standard SMART App Launch flow (for example, a standalone launch) against the Authorization Server, requesting scopes that cover imaging: `patient/ImagingStudy.rs` (SMART 2.0), `patient/ImagingStudy.read` (SMART 1.0), or a wildcard that includes it such as `patient/*.rs`. The user approves sharing, and the app receives a token response with patient context:

```js
{
  "access_token": "access-token-value-unguessable",
  "expires_in": 3600,
  "refresh_token": "refresh-token-value-unguessable-and-long-lasting",
  "patient": "123"
}
```

The app SHALL present this `access_token` as a Bearer token for clinical FHIR reads, `ImagingStudy` searches, and WADO-RS retrievals at the designated endpoints.

<a id="backend-services"></a>

#### Backend Services

This mode supports clients whose access is authorized in advance by the source organization, such as a referral service retrieving images for patients it is permitted to serve. It uses ordinary patient-specific queries; it does not require bulk export or population-wide search.

**Obtaining a token.** The Backend Client and Authorization Server SHALL follow [SMART Backend Services](https://hl7.org/fhir/smart-app-launch/STU2.2/backend-services.html), including registration, asymmetric client authentication, and the `client_credentials` grant. The client requests `system/ImagingStudy.rs`; deployments supporting this mode SHALL support that scope. A granted wildcard covering the same interactions MAY also be used. Include any required clinical-resource scopes in the same token request.

The client SHALL present the resulting access token as a Bearer token for study search and DICOM retrieval at the designated endpoints, just as in App Launch. The signed JWT used to authenticate the client at the token endpoint is not the access token and SHALL NOT be used as the bearer token for imaging requests.

**Access permissions.** In this guide, `system/ImagingStudy.rs` permits study search and retrieval of the associated DICOM data only within the client's pre-authorized access. It does not grant access to all patients or all studies. The Authorization Server and participating resource servers SHALL have an arrangement that allows them to enforce the client's applicable access restrictions consistently. How those permissions are assigned and communicated is deployment-specific.

There is no required `patient` launch context in this mode. Each search uses the patient's FHIR logical ID in the source Clinical FHIR Server's namespace (for example, `123` for `Patient/123`), as in the App Launch flow, not an MRN or the receiving organization's patient ID. The Imaging Server maps that identity to its records as described in [Imaging Identifiers](identifiers.html). The search parameter selects data, not permission to access it. Patient matching and discovering which organizations hold records remain outside this guide. Backend use of `patient/` or `user/` scopes is not defined by this mode.

**Example (non-normative).** A referral service is registered with the source organization. Its permissions allow study A for patient `123`, but not study B for the same patient or any studies for patient `456`. It obtains a short-lived token with `system/ImagingStudy.rs` using SMART Backend Services.

| Request with that token | Result |
|---|---|
| Search `ImagingStudy?patient=123&_include=ImagingStudy:endpoint` | Returns A and its endpoint; omits B |
| Retrieve A through its WADO-RS endpoint using the same token | Returns A's DICOM data |
| Request B directly through the token-protected WADO-RS endpoint | Denied; the token does not authorize B |
| Search `ImagingStudy?patient=456` | `403 Forbidden`; this patient is outside the client's authorized access |

If the service also needs clinical reports, it requests an appropriate clinical scope, such as `system/DiagnosticReport.rs`. The Clinical FHIR Server independently enforces the permissions applicable to those reports.

The authorized search may return a token-bound capability URL for A. The service presents the same SMART token when using that URL. The retrieval service enforces the token and the capability's permission for A; changing the requested study does not broaden that permission.

#### Token validation and access enforcement (both modes)

**Trusting the token.** If the Imaging Server and Authorization Server operate as one system, this is ordinary local token validation. If they are separate systems, the Imaging Server needs a way to check tokens issued by the Authorization Server. The expected mechanism is [SMART Token Introspection](https://hl7.org/fhir/smart-app-launch/token-introspection.html):

```
POST https://auth.example.org/introspect
Content-Type: application/x-www-form-urlencoded

token=access-token-value-unguessable
```

Other trust arrangements (for example, signed tokens the Imaging Server can verify directly) MAY be used, provided the server can enforce the checks below.

**Required token checks.** Before serving any imaging FHIR or WADO-RS request, the Imaging Server SHALL confirm that:

1. the token is **active** (not expired or revoked) and issued by the configured Authorization Server for use at this resource server;
2. the token's **scopes cover the request** — patient-level imaging scopes for App Launch mode, or system-level imaging scopes for Backend Services mode; and
3. the request is within the **authorized access**, according to the applicable mode:
   * **App Launch:** the token's patient context SHALL match the patient whose data is requested — the `?patient=` parameter on a FHIR search, or the patient who owns the study on a WADO-RS retrieval. Any additional access restrictions SHALL also be enforced.
   * **Backend Services:** the Imaging Server SHALL establish the client identity from validated token information and enforce that client's pre-authorized access, narrowed by the granted scopes, for the requested patient and studies.

Missing patient context SHALL NOT be treated as authorization for system-level access. A server not supporting the Backend Services mode SHALL NOT grant imaging access on the basis of system scopes. A server SHALL NOT serve data when it cannot establish the applicable permissions. For tokens carrying more than one scope, each grant retains its own context and restrictions; permissions SHALL NOT be broadened by combining the context of one grant with another grant's scope.

SMART introspection returns `client_id` and granted scopes, and patient context when it was issued. It does not define a complete representation of a client's underlying permissions. An active token with `system/ImagingStudy.rs` is therefore insufficient on its own to establish which studies the client may access. Separate Imaging Servers need a policy lookup, shared authorization service, or another arrangement that enforces those permissions.

**Issuing capability URLs.** Before returning an Endpoint carrying a capability, the Imaging FHIR Server SHALL perform the token and access checks above and limit the capability to data and retrieval operations authorized by that request. The capability SHALL be bound to the SMART token authorizing the FHIR request. The DICOMweb Server SHALL validate the token, the capability, and their binding, and enforce all applicable restrictions. See [Finding studies](#finding-studies) for response-specific Endpoints and [Retrieving images](#retrieving-images) for validation and lifetime requirements.

The Imaging Server MAY gather additional information from the Clinical FHIR Server to make an access decision — for example, using its own [SMART Backend Services](https://hl7.org/fhir/smart-app-launch/backend-services.html) credentials to fetch `Patient/123` and obtain identifiers for cross-mapping. This internal use does not imply support for backend imaging clients and SHALL NOT expand the requesting client's access. See [Imaging Identifiers](identifiers.html).

**Responsibilities by actor.**

* For deployments supporting **App Launch**, the **Authorization Server** SHALL support SMART App Launch and SHALL offer scopes permitting `ImagingStudy` read access (`patient/ImagingStudy.rs`, `patient/*.rs`, or the SMART 1.0 equivalents).
* The **Authorization Server** SHALL provide a way for Imaging Servers to validate its tokens — SMART Token Introspection unless another arrangement is in place.
* Deployments advertising **Backend Services imaging support** SHALL meet that mode's discovery, token acquisition, and access-enforcement requirements. App Launch support is not required for a Backend Services-only deployment.
* The **Imaging Server** SHALL enforce the token checks and capability-issuance rules above. The **DICOMweb Server** SHALL perform the required token and access checks on every retrieval. If the URL carries a capability, the server SHALL additionally validate the capability, its binding to the presented token, and its permitted data and operations. All applicable restrictions SHALL be enforced.
* The **App**, including a **Backend Client**, SHALL treat the access token as a secret and present it only to the Authorization Server, the Clinical FHIR Server covered by the authorization, the Imaging Server's FHIR endpoint, and WADO-RS endpoints the Imaging Server has designated (via `Endpoint.address`). The token SHALL NOT be forwarded to unrelated organizations or arbitrary referenced endpoints.

### Finding studies

The app searches `ImagingStudy` by patient on the Imaging FHIR Server, asking it to include each study's WADO-RS Endpoint:

```
GET https://imaging.example.org/fhir/ImagingStudy?patient=123&_include=ImagingStudy:endpoint
Authorization: Bearer access-token-value-unguessable
```

The Imaging Server SHALL support these search parameter combinations:

| Query | Use case |
|---|---|
| `patient=123` | List the patient's studies accessible under this authorization |
| `patient=123&_lastUpdated=gt2023-04-17T04:00:00Z` | Incremental sync: only studies updated since the app last checked |
| `patient=123&identifier=urn:oid:1.2.3` | Look up one study by DICOM Study Instance UID |

The Imaging FHIR Server SHALL support `_include=ImagingStudy:endpoint` so that referenced Endpoints are returned in the search Bundle. An Endpoint may be a response-local Bundle entry, a separately addressable resource included in the Bundle, or a contained resource within an `ImagingStudy`. Apps SHALL support all three forms and resolve references using the [FHIR Bundle reference-resolution rules](https://hl7.org/fhir/R4/bundle.html#references). See the [server CapabilityStatement](CapabilityStatement-smart-imaging-server.html) for the machine-readable requirements.

**Response-specific Endpoints.** For capability URLs, servers SHOULD return the Endpoint as a response-local Bundle entry with a `urn:uuid:...` value in `Bundle.entry.fullUrl` and the same value in `ImagingStudy.endpoint.reference`. The server SHALL include that Endpoint entry on the same Bundle page as each study referencing it, including when the request omits `_include`. The UUID identifies the Endpoint within the response; it is not the retrieval address. The app resolves the reference to the included Endpoint and uses its HTTPS `address` as the WADO-RS base URL. Such Endpoints represent authorization for the requesting token, not reusable Endpoint records for other authorization contexts.

The server returns a searchset Bundle of `ImagingStudy` resources conforming to the [SMART ImagingStudy](StructureDefinition-smart-imaging-study.html) profile. Every study carries its **DICOM Study Instance UID** (an identifier with system `urn:dicom:uid` and a `urn:oid:...` value), its **status**, **patient**, and **modality**, and at least one **endpoint** conforming to [SMART WADO-RS Endpoint](StructureDefinition-smart-wado-endpoint.html) — the WADO-RS base URL where the app retrieves DICOM data using its SMART token. Studies should also carry descriptive detail when available — start time, series and instance counts, per-series metadata — so apps can show a useful study list before downloading anything.

Worked examples: [study with a contained Endpoint](ImagingStudy-imaging-study-contained-endpoint.html), [study with an external Endpoint](ImagingStudy-imaging-study-external-endpoint.html), [search response with a response-local capability Endpoint](Bundle-imaging-capability-search-response.html), and a [complete search response Bundle](Bundle-imaging-search-response.html).

**Delayed search results: 503 and Retry-After.** Some Imaging Servers front systems that answer slowly — for example, a proxy that issues a DICOM C-FIND to a PACS on first request. Rather than holding the connection open, the server MAY respond:

```
HTTP/1.1 503 Service Unavailable
Retry-After: 30
```

The app SHOULD wait the indicated number of seconds and repeat the identical request. Once results are ready, the server responds normally with the Bundle.

**Access control.** Every search is subject to the checks in [Authorization](#authorization). In App Launch mode, the `patient` search parameter SHALL match the token's patient context; a mismatch receives `403 Forbidden`, not an empty Bundle. In Backend Services mode, a request for a patient outside the client's authorized access SHALL receive `403 Forbidden`. Within an authorized patient, the server SHALL omit studies and included Endpoints the client is not permitted to access. A successful search may therefore return only some studies, or none. These rules also apply when a search includes `identifier` or `_lastUpdated`. Both modes use the patient-specific search combinations above; this guide does not require unfiltered or population-wide search.

*Scaling (non-normative).* Forwarding every search to the PACS can overload it. Caching study metadata can reduce that load. Cache invalidation can use time-based rules or change feeds from the PACS or RIS. The 503/Retry-After pattern complements caching: the first request warms the cache; retries hit it. Cache underlying study metadata separately from response-specific authorization data. For each response, apply the current authorization and assemble Endpoint entries and references for the requesting token.

### Retrieving images

Each study's Endpoint supplies a WADO-RS base URL in `Endpoint.address`. The app removes the `urn:oid:` prefix from the study's `urn:dicom:uid` identifier value and appends `/studies/{Study Instance UID}` to the base URL. It SHALL send the same SMART access token used for the authorized FHIR request in the `Authorization` header:

```
GET https://imaging.example.org/wado-rs/studies/1.2.840.99999999.19341866.1571297684
Accept: multipart/related; type=application/dicom; transfer-syntax=*
Authorization: Bearer access-token-value-unguessable
```

A server MAY use a **capability URL**: a WADO-RS base URL that carries or identifies study-specific permissions bound to the requesting SMART token. The permissions may be encoded in protected URL contents or stored by the service under an opaque identifier. The client uses this address and its existing SMART token in the same way as any other returned endpoint. For example:

```
GET https://imaging.example.org/wado-capability/opaque-example-capability/studies/1.2.840.99999999.19341866.1571297684
Accept: multipart/related; type=application/dicom; transfer-syntax=*
Authorization: Bearer access-token-value-unguessable
```

The capability value above is illustrative. Servers SHALL use unguessable or cryptographically protected capabilities, validate their binding to the presented token, and ensure that appending WADO-RS paths cannot grant access beyond the capability's permitted data and operations. Clients SHALL treat returned addresses as opaque base URLs, preserve their capability information when constructing retrieval paths, and protect them from unintended disclosure.

<div class="stu-note" style="border-left: 4px solid #2563eb; background: #f0f6ff; padding: 0.75em 1em; margin: 1em 0;">
<p><strong>Design question (non-normative):</strong> Should this guide also support bearer capability URLs, where clients are explicitly instructed not to send their SMART access token?</p>
</div>

**Full-study retrieval.** The WADO-RS endpoint SHALL support full-study retrieval with `Accept: multipart/related; type=application/dicom; transfer-syntax=*`. Accepting `transfer-syntax=*` lets the server return stored files without re-encoding, so even a static file server behind an authorizing proxy can participate. The response is the study's DICOM instances as a multipart body:

```
HTTP/1.1 200 OK
Content-Type: multipart/related; type=application/dicom; boundary=...

[DICOM instances, one part each]
```

**Additional retrieval operations.** Further WADO-RS capabilities enable richer app behavior (progressive loading, thumbnails, viewing without a full download). Servers SHOULD support, per the [DICOMweb WADO-RS standard](https://dicom.nema.org/medical/dicom/current/output/html/part18.html):

* **Series-level** retrieval — `GET /studies/{uid}/series/{uid}`
* **Instance-level** retrieval — `GET /studies/{uid}/series/{uid}/instances/{uid}`
* **Frame-level** retrieval — `.../instances/{uid}/frames/{n}`
* **Rendered** images — `.../rendered` at study, series, or instance level
* **Metadata** — `GET /studies/{uid}/metadata` (and at series/instance level)
* **Transfer-syntax negotiation** — re-encoding payloads to match the `Accept` header

Apps SHOULD degrade gracefully: try the richer request, fall back to full-study retrieval if the server doesn't offer it.

**Retrieval authorization.** The DICOMweb Server SHALL perform the token and access checks in [Authorization](#authorization) on every request. If the URL carries a capability, the server SHALL additionally validate that capability and its binding to the presented token, and enforce its permitted data and operations. These checks apply to every supported retrieval, including metadata, rendered images, instances, and frames, whether or not the client previously searched for the study.

**Lifetime and revocation.** A capability requires its associated SMART token to remain valid and is also subject to its own lifetime and revocation conditions. Servers SHALL document capability lifetime and revocation behavior. Capabilities SHOULD be short-lived. The retrieval service SHALL check token and capability validity when accepting each request. A response authorized before expiry MAY finish after expiry. New or retried requests SHALL be checked again. A retrieval request using an expired or revoked URL capability SHALL receive `403 Forbidden`.

**Refreshing a retrieval endpoint.** If DICOM retrieval returns `401 Unauthorized` or `403 Forbidden`, the client can repeat the `ImagingStudy` search for the patient and Study Instance UID, using a valid SMART token and refreshing it first if necessary. The server evaluates the current authorization before returning the study and its Endpoint.

If the search returns the study, the client can retry retrieval using the returned Endpoint and the SMART token used for that search. If the study is not returned, or retrieval is again rejected for authorization, the client stops this recovery attempt.

**Credential protection.** Clients SHALL protect both access tokens and capability URLs from unintended disclosure. A capability URL is usable only with its associated valid SMART token.

[Implementing Study-Level Authorization](authorization-patterns.html) describes ways to distribute these decisions and checks among cooperating systems.

The WADO-RS endpoint SHALL deny requests outside the authorized access without returning DICOM data. A full-study request SHALL NOT return a successful partial study when access restrictions exclude some of its contents; the server SHALL deny that request. If assembling authorized data takes time (for example, a C-MOVE from a PACS under the hood), the endpoint MAY respond `503` with a `Retry-After` header, exactly as in [Finding studies](#finding-studies).
