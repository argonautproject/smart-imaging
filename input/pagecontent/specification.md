This page is the complete specification: how an App discovers an imaging endpoint, gets authorized, lists a patient's studies, and downloads DICOM data. The specification supports both SMART App Launch and [SMART Backend Services](#backend-services); deployments can support either or both patterns. The actors are defined on the [home page](index.html), including the Imaging FHIR Server and DICOMweb Server functions collectively called the Imaging Server.

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

The SMART access token authorizes clinical FHIR access and `ImagingStudy` search, subject to the granted scopes and underlying access permissions. Each returned WADO-RS Endpoint tells the client whether to present that same token for DICOM retrieval or follow a bearer capability URL without it (see [Retrieving images](#retrieving-images)). Both retrieval patterns apply equally to [SMART App Launch](https://hl7.org/fhir/smart-app-launch/app-launch.html) and [SMART Backend Services](#backend-services). Deployments SHALL support at least one of these authorization modes and MAY support both. A token-protected endpoint may also carry a token-bound capability. Neither retrieval pattern requires a separate user authorization step or a client-side token exchange.

#### App Launch

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="sequence-flow-mobile.svg"/>
<img src="sequence-flow.svg" alt="Sequence diagram: the app authorizes with the Authorization Server, optionally queries the Clinical FHIR Server, searches ImagingStudy on the Imaging Server, and retrieves DICOM data from WADO-RS; the Imaging Server validates the token with the Authorization Server via introspection" style="max-width: 100%; height: auto;"/>
</picture>
<p><em>This example shows App Launch with token-protected WADO-RS retrieval. Either authorization mode can also return capability URLs.</em></p>
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

The app presents this `access_token` as a Bearer token for clinical FHIR reads and `ImagingStudy` searches. For WADO-RS retrieval, it follows the returned Endpoint's `requires-access-token` flag as described in [Retrieving images](#retrieving-images).

<a id="backend-services"></a>

#### Backend Services

This mode supports clients whose access is authorized in advance by the source organization, such as a referral service retrieving images for patients it is permitted to serve. It uses ordinary patient-specific queries; it does not require bulk export or population-wide search.

**Obtaining a token.** The Backend Client and Authorization Server SHALL follow [SMART Backend Services](https://hl7.org/fhir/smart-app-launch/STU2.2/backend-services.html), including registration, asymmetric client authentication, and the `client_credentials` grant. The client requests `system/ImagingStudy.rs`; deployments supporting this mode SHALL support that scope. A granted wildcard covering the same interactions MAY also be used. Scopes for clinical resources are requested separately as needed, in the same token request.

The resulting access token is used for study search. For DICOM retrieval, the client follows the returned Endpoint's `requires-access-token` flag, just as in App Launch: `true` means present the existing access token; `false` means follow the bearer capability URL without that token. The signed JWT used to authenticate the client at the token endpoint is not the access token and SHALL NOT be used as the bearer token for imaging requests.

**Access permissions.** In this guide, `system/ImagingStudy.rs` permits study search and retrieval of the associated DICOM data only within the client's pre-authorized access. It does not grant access to all patients or all studies. The Authorization Server and participating resource servers SHALL have an arrangement that allows them to enforce the client's applicable access restrictions consistently. How those permissions are assigned and communicated is deployment-specific.

There is no required `patient` launch context in this mode. Each search uses the patient's FHIR logical ID in the source Clinical FHIR Server's namespace (for example, `123` for `Patient/123`), as in the App Launch flow, not an MRN or the receiving organization's patient ID. The Imaging Server maps that identity to its records as described in [Imaging Identifiers](identifiers.html). The search parameter selects data, not permission to access it. Patient matching and discovering which organizations hold records remain outside this guide. Backend use of `patient/` or `user/` scopes is not defined by this mode.

**Example (non-normative).** A referral service is registered with the source organization. Its permissions allow study A for patient `123`, but not study B for the same patient or any studies for patient `456`. It obtains a short-lived token with `system/ImagingStudy.rs` using SMART Backend Services. In this example, A's returned Endpoint has `requires-access-token = true`.

| Request with that token | Result |
|---|---|
| Search `ImagingStudy?patient=123&_include=ImagingStudy:endpoint` | Returns A and its endpoint; omits B |
| Retrieve A through its WADO-RS endpoint using the same token | Returns A's DICOM data |
| Request B directly through the token-protected WADO-RS endpoint | Denied; the token does not authorize B |
| Search `ImagingStudy?patient=456` | `403 Forbidden`; this patient is outside the client's authorized access |

If the service also needs clinical reports, it requests an appropriate clinical scope, such as `system/DiagnosticReport.rs`. The Clinical FHIR Server independently enforces the permissions applicable to those reports.

Alternatively, the authorized search could return a bearer capability URL for A with `requires-access-token = false`. The service retrieves A without sending its SMART token. The capability grants access to A, not B; changing the requested study does not broaden that grant.

#### Token validation and access enforcement (both modes)

**Trusting the token.** If the Imaging Server and Authorization Server operate as one system, this is ordinary local token validation. If they are separate systems, the Imaging Server needs a way to check tokens issued by the Authorization Server. The expected mechanism is [SMART Token Introspection](https://hl7.org/fhir/smart-app-launch/token-introspection.html):

```
POST https://auth.example.org/introspect
Content-Type: application/x-www-form-urlencoded

token=access-token-value-unguessable
```

Other trust arrangements (for example, signed tokens the Imaging Server can verify directly) MAY be used, provided the server can enforce the checks below.

**Required token checks.** Before serving an imaging FHIR request or a WADO-RS request with `requires-access-token = true`, the Imaging Server SHALL confirm that:

1. the token is **active** (not expired or revoked) and issued by the configured Authorization Server for use at this resource server;
2. the token's **scopes cover the request** — patient-level imaging scopes for App Launch mode, or system-level imaging scopes for Backend Services mode; and
3. the request is within the **authorized access**, according to the applicable mode:
   * **App Launch:** the token's patient context SHALL match the patient whose data is requested — the `?patient=` parameter on a FHIR search, or the patient who owns the study on a WADO-RS retrieval. Any additional access restrictions SHALL also be enforced.
   * **Backend Services:** the Imaging Server SHALL establish the client identity from validated token information and enforce that client's pre-authorized access, narrowed by the granted scopes, for the requested patient and studies.

Missing patient context SHALL NOT be treated as authorization for system-level access. A server not supporting the Backend Services mode SHALL NOT grant imaging access on the basis of system scopes. A server SHALL NOT serve data when it cannot establish the applicable permissions. For tokens carrying more than one scope, each grant retains its own context and restrictions; permissions SHALL NOT be broadened by combining the context of one grant with another grant's scope.

SMART introspection returns `client_id` and granted scopes, and patient context when it was issued. It does not define a complete representation of a client's underlying permissions. An active token with `system/ImagingStudy.rs` is therefore insufficient on its own to establish which studies the client may access. Separate Imaging Servers need a policy lookup, shared authorization service, or another arrangement that enforces those permissions.

**Issuing capability URLs.** Before returning an Endpoint carrying a bearer or token-bound capability, the Imaging FHIR Server SHALL perform the token and access checks above on the FHIR request and limit the capability to data and retrieval operations authorized by that request. The DICOMweb Server validates the capability and, for token-bound capabilities, the associated SMART token and its binding. Bearer capability expiry SHALL be no later than the expiry of the SMART token authorizing issuance. See [Retrieving images](#retrieving-images) for validation and lifetime requirements.

The Imaging Server MAY gather additional information from the Clinical FHIR Server to make an access decision — for example, using its own [SMART Backend Services](https://hl7.org/fhir/smart-app-launch/backend-services.html) credentials to fetch `Patient/123` and obtain identifiers for cross-mapping. This internal use does not imply support for backend imaging clients and SHALL NOT expand the requesting client's access. See [Imaging Identifiers](identifiers.html).

**Requirements.**

* For deployments supporting **App Launch**, the **Authorization Server** SHALL support SMART App Launch and SHALL offer scopes permitting `ImagingStudy` read access (`patient/ImagingStudy.rs`, `patient/*.rs`, or the SMART 1.0 equivalents).
* The **Authorization Server** SHALL provide a way for Imaging Servers to validate its tokens — SMART Token Introspection unless another arrangement is in place.
* Deployments advertising **Backend Services imaging support** SHALL meet that mode's discovery, token acquisition, and access-enforcement requirements. App Launch support is not required for a Backend Services-only deployment.
* The **Imaging Server** SHALL enforce the token checks and capability-issuance rules above. For token-protected retrieval, the **DICOMweb Server** SHALL perform the required token and access checks. If the URL also carries a token-bound capability, the server SHALL additionally validate the capability, its binding to the presented token, and its permitted data and operations. All applicable restrictions SHALL be enforced. For bearer-capability retrieval, the server SHALL validate the capability and enforce its permitted data, operations, and lifetime without requiring the original SMART token.
* The **App**, including a **Backend Client**, SHALL treat the access token as a secret and present it only to the Authorization Server, the Clinical FHIR Server covered by the authorization, the Imaging Server's FHIR endpoint, and WADO-RS endpoints the Imaging Server has designated (via `Endpoint.address` with `requires-access-token` = `true`). The token SHALL NOT be forwarded to unrelated organizations or arbitrary referenced endpoints.

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

The server SHALL also support `_include=ImagingStudy:endpoint`, so that studies whose Endpoints are standalone resources come back in the same Bundle. Endpoints MAY instead be contained within each `ImagingStudy`; apps SHALL support both forms. See the [server CapabilityStatement](CapabilityStatement-smart-imaging-server.html) for the machine-readable version.

The server returns a searchset Bundle of `ImagingStudy` resources conforming to the [SMART ImagingStudy](StructureDefinition-smart-imaging-study.html) profile. Every study carries its **DICOM Study Instance UID** (an identifier with system `urn:dicom:uid` and a `urn:oid:...` value), its **status**, **patient**, and **modality**, and at least one **endpoint** conforming to [SMART WADO-RS Endpoint](StructureDefinition-smart-wado-endpoint.html) — the WADO-RS base URL where the DICOM data lives, plus a `requires-access-token` flag telling the app whether to send its SMART token there. Studies should also carry descriptive detail when available — start time, series and instance counts, per-series metadata — so apps can show a useful study list before downloading anything.

Worked examples: [study with a contained Endpoint](ImagingStudy-imaging-study-contained-endpoint.html), [study with an external Endpoint](ImagingStudy-imaging-study-external-endpoint.html), [study with a capability URL](ImagingStudy-imaging-study-capability-url.html), and a [complete search response Bundle](Bundle-imaging-search-response.html).

**Slow backends: 503 + Retry-After.** Some Imaging Servers front systems that answer slowly — for example, a proxy that issues a DICOM C-FIND to a PACS on first request. Rather than holding the connection open, the server MAY respond:

```
HTTP/1.1 503 Service Unavailable
Retry-After: 30
```

The app SHOULD wait the indicated number of seconds and repeat the identical request. Once results are ready, the server responds normally with the Bundle.

**Access control.** Every search is subject to the checks in [Authorization](#authorization). In App Launch mode, the `patient` search parameter SHALL match the token's patient context; a mismatch receives `403 Forbidden`, not an empty Bundle. In Backend Services mode, a request for a patient outside the client's authorized access SHALL receive `403 Forbidden`. Within an authorized patient, the server SHALL omit studies and included Endpoints the client is not permitted to access. A successful search may therefore return only some studies, or none. These rules also apply when a search includes `identifier` or `_lastUpdated`. Both modes use the patient-specific search combinations above; this guide does not require unfiltered or population-wide search.

*Scaling (non-normative).* Passing every search through to an underlying PACS can overload systems that were never built for consumer-scale traffic. Implementations have had good results with caching `ImagingStudy` resources (with a heuristic for invalidation), and with change feeds from the PACS or RIS to invalidate precisely instead of guessing. The 503/Retry-After pattern complements caching: the first request warms the cache; retries hit it.

### Retrieving images

A **capability URL** carries or identifies permission to retrieve specified imaging data. The permission may be encoded in protected URL contents or maintained by the service under an opaque identifier. A **bearer capability URL** is sufficient on its own for its permitted retrievals. A **token-bound capability URL** additionally requires the associated SMART access token. An ordinary token-protected endpoint need not use a capability URL.

Each study's Endpoint gives the app a WADO-RS base URL in `Endpoint.address`. The app appends `/studies/{Study Instance UID}` — using the plain UID from the study's `urn:dicom:uid` identifier (strip the `urn:oid:` prefix). The Endpoint's `requires-access-token` flag determines how the request is authorized:

| `requires-access-token` | Client behavior |
|---|---|
| `true` | The client SHALL send the same SMART access token used for the authorized FHIR request as a Bearer token. |
| `false` | The URL carries a bearer capability. The client SHALL follow it without sending its SMART access token. |

Clients SHALL support both forms, regardless of whether they obtained their token through App Launch or Backend Services. `false` does not mean the images are public: possession of the bearer capability URL grants access. Clients SHALL treat capability URLs as credentials and protect them from unintended disclosure, including through logs or referrer headers.

For a token-protected endpoint:

```
GET https://imaging.example.org/wado-rs/studies/1.2.840.99999999.19341866.1571297684
Accept: multipart/related; type=application/dicom; transfer-syntax=*
Authorization: Bearer access-token-value-unguessable
```

For a bearer-capability endpoint whose base URL is `https://imaging.example.org/wado-capability/opaque-example-capability`, the corresponding request has no SMART Authorization header:

```
GET https://imaging.example.org/wado-capability/opaque-example-capability/studies/1.2.840.99999999.19341866.1571297684
Accept: multipart/related; type=application/dicom; transfer-syntax=*
```

The capability value above is illustrative. Servers SHALL use unguessable or cryptographically protected capabilities and SHALL ensure that appending WADO-RS paths cannot grant access beyond the capability's authorized data and operations.

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

**Retrieval authorization.** For `requires-access-token = true`, the DICOMweb Server SHALL perform the token and access checks in [Authorization](#authorization) on every request. If the URL also carries a token-bound capability, the server SHALL validate that capability and its binding to the presented token, and enforce its permitted data and operations as well. For `false`, the server SHALL validate the bearer capability and enforce its authorized data, operations, and expiry or revocation conditions. These checks apply to every supported retrieval, including metadata, rendered images, instances, and frames, whether or not the client previously searched for the study.

**Lifetime and revocation.** Capability URLs SHOULD be short-lived. Servers SHALL document the lifetime and revocation behavior of both bearer and token-bound capabilities. A bearer capability URL SHALL expire no later than the SMART access token authorizing its issuance; the issuer SHALL determine that token's expiry before issuing the capability. Deployments SHALL document whether revoking the issuing token also invalidates outstanding bearer capabilities before their scheduled expiry. Where early revocation is not propagated, a bearer capability can remain usable until its own expiry. A token-bound capability requires its associated token to remain valid, in addition to satisfying the capability's own lifetime and revocation conditions.

The retrieval service SHALL check capability validity when accepting each request. A response authorized before expiry MAY finish after expiry. New or retried requests SHALL be checked again.

A retrieval request using an expired or revoked URL capability SHALL receive `403 Forbidden`.

**Refreshing a retrieval endpoint.** If DICOM retrieval returns `401 Unauthorized` or `403 Forbidden`, the client can repeat the `ImagingStudy` search for the patient and Study Instance UID, using a valid SMART token and refreshing it first if necessary. The server evaluates the current authorization before returning the study and its Endpoint.

If the search returns the study, the client can retry retrieval using the returned Endpoint and its `requires-access-token` flag. If the study is not returned, or retrieval is again rejected for authorization, the client stops this recovery attempt.

**Credential protection.** Disclosure of a bearer capability URL can disclose access to its permitted data. A token-bound capability URL alone is insufficient without its associated valid token. Clients SHALL protect both forms from unintended disclosure.

[Implementing Study-Level Authorization](authorization-patterns.html) describes ways to distribute these decisions and checks among cooperating systems.

The WADO-RS endpoint SHALL deny requests outside the authorized access without returning DICOM data. A full-study request SHALL NOT return a successful partial study when access restrictions exclude some of its contents; the server SHALL deny that request. If assembling authorized data takes time (for example, a C-MOVE from a PACS under the hood), the endpoint MAY respond `503` with a `Retry-After` header, exactly as in [Finding studies](#finding-studies).
