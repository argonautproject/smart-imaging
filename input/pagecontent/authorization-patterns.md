*This page is non-normative.* Using the [functional roles defined on the home page](index.html#actors), it describes how cooperating services decide which studies to release and enforce those decisions during image retrieval.

### Example access restrictions

These fictional examples use permissions configured by the health system.

#### A parent preparing records for a second opinion

Elena uses a SMART-connected app to collect records for an independent orthopedic opinion about her 16-year-old daughter Maya’s ankle injury. The app retrieves the ankle X-ray, its report, and relevant clinical records under Elena’s configured proxy access.

Maya also has a pelvic ultrasound from an encounter marked confidential. The health system’s policy permits Elena to receive the ankle study but excludes the ultrasound from her proxy access.

The app’s token has Maya’s patient context, but that does not grant Elena access to every study belonging to Maya. The ImagingStudy search returns the ankle study and its endpoint, omits the ultrasound, and the retrieval service does not release the ultrasound under Elena’s authorization.

#### A health system running a cardiac imaging quality-review service

A health system runs a background service that collects newly available cardiac images and reports for continuous quality improvement. The service uses SMART Backend Services. The health system configures its permissions to cover cardiac studies for patients included in the program.

Jordan Ellis is included in the program and has a cardiac MRI and a knee X-ray. The service is permitted to retrieve the cardiac MRI, but not the knee X-ray. Its `system/ImagingStudy.rs` scope remains subject to those configured permissions.

In both cases, the study list and image retrieval need to respect the same access restriction. The client does not need an in-band representation of the organization’s proxy-access rules, consent records, or quality-review program permissions.

### Authorizing a DICOMweb request

The DICOMweb service can combine several sources of information to decide whether to release a requested study:

* **Access token** — The credential a Client presents to show which authorization it is using. The service checks that the token is active, issued by the configured Authorization Server, authorized for that service, and sufficient for the requested data. It uses the validated client identity, scopes, and patient or user context where applicable. An opaque token can be checked through introspection without requiring the service to interpret its contents.

* **Optional signed study context** — Integrity-protected study information supplied by the Imaging FHIR Server, for example in an Endpoint's WADO-RS base URL. It can help the DICOMweb Server identify the study and evaluate access alongside the current token and current policy. It is not an independent bearer grant and is not bound to the token instance used for the search.

* **Token introspection** — The Authorization Server can supply the token’s status, granted scopes, client identity, and available user or patient context. Standard introspection fields do not necessarily express all the study-level restrictions the service needs to enforce.

* **A FHIR query using the caller's token** — After validating the token for retrieval, the service can query the trusted Imaging FHIR Server for the requested study using the caller's token only if that token is authorized for both services and permits the query. An authorized matching result contributes to the study-access decision; search permission alone does not authorize WADO-RS retrieval. Any patient constraint uses the [patient-identity contract](patient-identity.html), not an assumption that Clinical and Imaging FHIR Patient logical IDs match. A DPoP proof for the incoming retrieval request cannot be forwarded as proof for a different callback request; use an appropriately authenticated decision API or another configured authorization mechanism instead.

* **An explicit authorization-decision API** — Instead of querying ImagingStudy, the service can ask directly whether the original caller is permitted to retrieve a study. The requesting service authenticates itself and supplies trusted caller context. This guide does not define that internal API.

* **Locally configured or shared policy** — The service can apply its own configured rules or consult policy shared with the Authorization Server or Imaging FHIR Server. The cooperating systems agree how the relevant permissions and policy changes are communicated and enforced.

These mechanisms can be combined. For example, a DICOMweb service might validate a token through introspection, verify signed study context, and consult an internal decision service for current consent restrictions. Another might validate the token and evaluate the study against local policy without using signed context.

The [cooperating-server baseline](specification.html#cooperating-servers) supports one token across participating Clinical FHIR, Imaging FHIR, and WADO-RS servers for both App Launch and Backend Services. Retrieval accepts any currently valid token from the configured Authorization Server that authorizes the recipient and requested data, including refreshed or newly issued tokens; it need not be the token used for study search. Optional DPoP or per-endpoint OAuth Token Exchange modes can be offered at registration alongside that baseline. The Client follows the [token-handling requirements](specification.html#app-token-handling) and treats the returned Endpoint address as an opaque base URL.

### Ways to divide authorization responsibilities

The diagrams show three ways to divide policy evaluation and retrieval enforcement under the single-token baseline. They begin after token issuance. Solid arrows show Client interactions; dashed arrows show internal coordination. Boxes group responsibilities and do not necessarily represent separate products. Every request uses a currently valid token authorized for its recipient and requested data, not necessarily the same token instance throughout.

#### The gateway evaluates policy and controls retrieval

A gateway provides both the Imaging FHIR Server and DICOMweb Server. It combines token validation, such as introspection, with locally configured or shared policy. It uses those permissions to filter the study list and check each image request before retrieving data from an internal image archive, such as a PACS. The gateway authenticates to that archive using its own internal archive credentials, without forwarding the Client's SMART token.

<div style="margin: 1.5em 0;">
<img src="authorization-gateway.svg" alt="A gateway hosts Imaging FHIR and DICOMweb. Both use its study-access policy; DICOMweb controls retrieval from an internal image archive." style="display: block; width: 100%; max-width: 960px; height: auto; margin: 0 auto;"/>
</div>

*The gateway provides both imaging roles. Its access to the archive is separate from the client’s access to the gateway.*

For Elena’s request, the gateway applies the configured proxy-access restrictions. For the quality-review service’s request, it applies the health system’s configured cardiac-study permissions. Its own archive credentials may allow broader access, but it releases only what the requesting client is permitted to retrieve. Other client-accessible routes must not bypass that enforcement.

#### The Imaging FHIR Server supplies signed study context

The Imaging FHIR Server can supply optional signed study context with each permitted study. The DICOMweb Server validates that context alongside the current token and current access policy before retrieving images. The services agree on the context format, trusted issuer and verification keys, intended recipient, study identifiers, and any applicable series or instance restrictions. No signing format or cryptographic implementation is defined by this guide.

<div style="margin: 1.5em 0;">
<img src="authorization-grant.svg" alt="The Imaging FHIR Server supplies optional signed study context. DICOMweb validates its integrity, the current token, and current policy before accessing the archive using internal credentials." style="display: block; width: 100%; max-width: 960px; height: auto; margin: 0 auto;"/>
</div>

Signed context is an input to authorization, not a second bearer grant. The DICOMweb Server verifies its integrity and applicability to the requested study and content, and evaluates the current token and current policy. Possession of the URL alone grants no access. Substituting a different study, series, or instance into a URL does not bypass these checks.

Context-specific Endpoints can be returned as response-local Bundle entries, as described in [Finding studies](specification.html#finding-studies). The [Bundle example](Bundle-imaging-study-context-search-response.html) shows UUID reference resolution and an HTTPS retrieval address. Its `illustrative-signed-context` path segment is illustrative text, not a usable signature or a defined wire format.

When context is carried in the Endpoint's WADO-RS base URL, the Client preserves the full path prefix and appends retrieval paths as specified in [Retrieving images](specification.html#retrieving-images). The Client does not inspect, generate, or renew signed context and does not assume that all studies share a base URL.

A signature protects integrity, not confidentiality. Signed URL contents may be readable by the Client and exposed in URL logs. Minimize identifying information, protect URLs in transit and storage, and use encryption or server-side references when confidentiality is needed. Neither signature validation nor URL secrecy replaces token validation and current access policy.

If context is absent, stale, expired, or unusable, the service can re-evaluate the requested access against the current token and policy, locally or through a trusted decision service, without relying on that context. If it cannot establish authorization, it does not release the data. An authorized refreshed or newly issued token does not require a new Endpoint, and this pattern adds no mandatory expired-context study-search retry for the Client.

#### DICOMweb requests an access decision before retrieval

The Imaging FHIR Server filters the study list, and the DICOMweb Server checks the caller’s permission when an image request arrives. In the diagram, it asks the system responsible for study-access decisions before reading the archive.

<div style="margin: 1.5em 0;">
<img src="authorization-recheck.svg" alt="The DICOMweb Server asks the imaging study service to check access for the original caller and requested study before releasing data from the image archive." style="display: block; width: 100%; max-width: 960px; height: auto; margin: 0 auto;"/>
</div>

*The check uses the original caller’s authorization, not the retrieval service’s broader archive permissions.*

For each retrieval, the DICOMweb Server performs the [required token and access checks](specification.html#imaging-server-authorization), using cooperating services where appropriate. The callback contributes a study-access decision through an authorized ImagingStudy query or an explicit decision API; it does not replace the required [ImagingStudy read permission](specification.html#imaging-permissions) for WADO-RS. A caller-token query requires authorization for both recipients and for the query itself; a retrieval DPoP proof cannot be forwarded to authenticate that callback. A decision API instead authenticates the requesting service and evaluates trusted original-caller context, not the service's broader archive permissions. The service combines the decision with scopes, patient context where applicable, and any endpoint-specific restrictions. A service with sufficient token context and local policy can make the decision without the illustrated callback. After authorization, it accesses the internal archive using internal archive credentials rather than forwarding the Client's SMART token.

The implementation needs to handle unavailable decision services and avoid circular checks—for example, a FHIR query that waits for an archive request that is itself waiting for the same FHIR query.

### Implementation considerations

#### Expiry and policy changes

Each retrieval requires a currently valid SMART token and current authorization for the requested data. Document how policy changes take effect and how cached decisions or optional signed context are invalidated or re-evaluated. Expired context is not evidence of current permission; a server-side current-policy check can replace it. Token refresh or replacement does not bind the Client to a new retrieval URL or a new study search.

#### Audit records

Record the client, any represented user, the patient where applicable, and the study. Correlate the presented token, any signed context, and the retrieval decision without exposing tokens, sensitive URL contents, or internal credentials in logs.

#### All retrieval paths

Apply authorization to all supported retrieval forms: metadata, rendered images, frames, instances, series, and full studies. ImagingStudy read permission (including a covering wildcard or SMART v1 read scope) authorizes supported WADO-RS retrieval of the study's authorized content, subject to patient-, user-, or system-level policy. Search-only permission does not authorize pixels; this mapping does not authorize QIDO-RS or storage operations. A request made directly to a known image URL needs protection even if it did not follow a study search.

Implementers can combine these approaches. EHR vendors, PACS vendors, authorization-service providers, and gateway implementers can share the work without changing the client’s study-search and retrieval protocol.

### Background and implementation references

These sources describe relevant concepts and building blocks. They do not establish that a particular product implements every flow shown here.

* [SMART 2.2: scopes and underlying permissions](https://hl7.org/fhir/smart-app-launch/STU2.2/scopes-and-launch-context.html) · [Token introspection](https://hl7.org/fhir/smart-app-launch/STU2.2/token-introspection.html)
* [FHIR R4 security and access control](https://hl7.org/fhir/R4/security.html) · [Consent](https://hl7.org/fhir/R4/consent.html) · [IHE Privacy Consent on FHIR](https://profiles.ihe.net/ITI/PCF/volume-1.html)
* [Orthanc external authorization service](https://orthanc.uclouvain.be/book/plugins/authorization.html) · [Gateway deployment guidance](https://orthanc.uclouvain.be/book/faq/security.html) · [Study-sharing token implementation](https://github.com/orthanc-team/orthanc-auth-service)
