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

* **Access token** — The credential an app presents to show which authorization it is using. The service checks that the token is valid for the request and uses its validated client identity, scopes, and any supplied patient or user context. An opaque token can be checked through introspection without requiring the service to interpret its contents.

* **Signed study-context URL (`Endpoint.address` path context)** — A study-specific WADO-RS base URL whose path carries cryptographically signed context: the permitted `Study Instance UID`, any series restrictions, and the inputs the release decision depended on. It lets the Imaging FHIR Server pass context and a pre-evaluated decision to the DICOMweb Server.

* **Token introspection** — The Authorization Server can supply the token’s status, granted scopes, client identity, and available user or patient context. Standard introspection fields do not necessarily express all the study-level restrictions the service needs to enforce.

* **A FHIR query using the caller’s token** — The service validates the token for the requested retrieval and queries the trusted Imaging FHIR Server for the patient and Study Instance UID using that same token. The Imaging FHIR Server applies the caller’s study-access policy; an authorized matching result establishes the study-specific permission. The token must be valid for both services. This replays the caller's token between services; an explicit decision API avoids that.

* **An explicit authorization-decision API** — Instead of querying ImagingStudy, the service can ask directly whether the original caller is permitted to retrieve a study. The requesting service authenticates itself and supplies trusted caller context. This guide does not define that internal API.

* **Locally configured or shared policy** — The service can apply its own configured rules or consult policy shared with the Authorization Server or Imaging FHIR Server. The cooperating systems agree how the relevant permissions and policy changes are communicated and enforced.

These mechanisms can be combined. For example, a DICOMweb service might validate a token through introspection and verify a signed study-context segment in the WADO-RS base URL, or consult an internal decision service for current consent restrictions.

The client presents its valid SMART token for study search and every image retrieval at the SMART WADO-RS Endpoint designated by the trusted Imaging FHIR Server. This applies to App Launch and Backend Services; the client treats `Endpoint.address` as an opaque base URL and does not need to inspect it to determine how the server evaluates access.

### Ways to divide authorization responsibilities

The diagrams show three ways to divide policy evaluation and retrieval enforcement. They begin after token issuance. Solid arrows show client interactions; dashed arrows show internal coordination. Boxes group responsibilities and do not necessarily represent separate products.

#### The gateway evaluates policy and controls retrieval

A gateway provides both the Imaging FHIR Server and DICOMweb Server. It combines token validation, such as introspection, with locally configured or shared policy. It uses those permissions to filter the study list and check each image request before retrieving data from an internal image archive, such as a PACS.

<div style="margin: 1.5em 0;">
<img src="authorization-gateway.svg" alt="A gateway hosts Imaging FHIR and DICOMweb. Both use its study-access policy; DICOMweb controls retrieval from an internal image archive." style="display: block; width: 100%; max-width: 960px; height: auto; margin: 0 auto;"/>
</div>

*The gateway provides both imaging roles. Its access to the archive is separate from the client’s access to the gateway.*

For Elena’s request, the gateway applies the configured proxy-access restrictions. For the quality-review service’s request, it applies the health system’s configured cardiac-study permissions. Its own archive credentials may allow broader access, but it releases only what the requesting client is permitted to retrieve. Other client-accessible routes must not bypass that enforcement.

#### The Imaging FHIR Server returns a signed study-context URL; DICOMweb enforces its context

When the Imaging FHIR Server and DICOMweb Server do not share a runtime database, the Imaging FHIR Server can evaluate the caller’s permissions during `ImagingStudy` search and return a study-specific `Endpoint.address` whose path includes a cryptographically signed context segment (for example, `https://imaging.example.org/wado-ctx/{signed-context}`).

<div style="margin: 1.5em 0;">
<img src="authorization-grant.svg" alt="A separate imaging study service evaluates study permissions and returns signed study-context URLs. DICOMweb validates the token and signed context before reading the archive." style="display: block; width: 100%; max-width: 960px; height: auto; margin: 0 auto;"/>
</div>

For example, in a Backend Services flow (`system/ImagingStudy.rs`), a WADO-RS request carries `/studies/{StudyInstanceUID}` and a system-scoped token whose introspection response does not name a patient. Packing the clinical FHIR `Patient` logical ID, the permitted `Study Instance UID`, any series subset restrictions, and the decision inputs into the signed URL path lets a stateless DICOMweb proxy evaluate the request (or make a targeted callback by FHIR `Patient` ID) without maintaining its own DICOM-to-FHIR patient index.

To implement this pattern safely while preserving standard WADO-RS behavior for clients:

1. **Cryptographically sign the context and always validate the SMART token:** Protect the path context with a cryptographic signature (do not rely on unguessable URL strings alone) and validate on every request that the presented SMART token is active, authorized for the endpoint, and carries an appropriate imaging scope.
2. **Lock the URL to the authorized study and subset:** Verify that `/studies/{uid}` (and any `/series/{uid}` or `/instances/{uid}`) appended by the client matches the study and authorized subset in the signed context. Respond to a mismatch as for any resource not released to the caller, following [PS3.18 §8.5](https://dicom.nema.org/medical/dicom/current/output/chtml/part18/sect_8.5.html).
3. **Support token renewal and re-evaluate when context differs:** Bind the signed context to every input the release decision depended on: client, patient, scopes, and the user where policy is user-specific. A token matching on all of these can rely on the context, including refreshed or newly issued tokens. If the token differs on any input, cannot establish one, or a policy timestamp in the context has elapsed, re-evaluate access with the Imaging FHIR Server or decision service. If that service is unavailable, do not release data.
4. **Treat the context as readable:** A signature protects integrity, not confidentiality. Include only what is acceptable in URLs and access logs, or encrypt the context.

Servers returning study-specific Endpoints can include them as contained resources or response-local Bundle entries (`urn:uuid:...`), as shown in the [Bundle example](Bundle-imaging-study-context-search-response.html).

#### DICOMweb requests an access decision before retrieval

The Imaging FHIR Server filters the study list, and the DICOMweb Server checks the caller’s permission when an image request arrives. In the diagram, it asks the system responsible for study-access decisions before reading the archive.

<div style="margin: 1.5em 0;">
<img src="authorization-recheck.svg" alt="The DICOMweb Server asks the imaging study service to check access for the original caller and requested study before releasing data from the image archive." style="display: block; width: 100%; max-width: 960px; height: auto; margin: 0 auto;"/>
</div>

*The check uses the original caller’s authorization, not the retrieval service’s broader archive permissions.*

For each retrieval, the DICOMweb Server performs the [required token and access checks](specification.html#authorization), using cooperating services where appropriate. The callback establishes permission for the requested study through an authorized ImagingStudy query or an explicit decision API. The service combines that decision with the token’s scopes, patient context where applicable, and any endpoint-specific restrictions. A service with sufficient token context and local policy can make the decision without the illustrated callback.

The implementation needs to handle unavailable decision services and avoid circular checks—for example, a FHIR query that waits for an archive request that is itself waiting for the same FHIR query.

### Implementation considerations

#### Expiry and policy changes

Each retrieval requires a currently valid SMART token covering the study. Document how authorization decisions are cached and how consent or policy changes take effect.

#### Audit records

Record the client, any represented user, the patient, and the study. Correlate the presented token and the retrieval decision without exposing credentials in logs.

#### All retrieval paths

Apply authorization to all supported retrieval forms: metadata, rendered images, frames, instances, and full studies. A request made directly to a known image URL needs protection even if it did not follow a study search.

Implementers can combine these approaches. EHR vendors, PACS vendors, authorization-service providers, and gateway implementers can share the work without changing the client’s study-search and retrieval protocol.

### Background and implementation references

These sources describe relevant concepts and building blocks. They do not establish that a particular product implements every flow shown here.

* [SMART 2.2: scopes and underlying permissions](https://hl7.org/fhir/smart-app-launch/STU2.2/scopes-and-launch-context.html) · [Token introspection](https://hl7.org/fhir/smart-app-launch/STU2.2/token-introspection.html)
* [FHIR R4 security and access control](https://hl7.org/fhir/R4/security.html) · [Consent](https://hl7.org/fhir/R4/consent.html) · [IHE Privacy Consent on FHIR](https://profiles.ihe.net/ITI/PCF/volume-1.html)
* [Orthanc external authorization service](https://orthanc.uclouvain.be/book/plugins/authorization.html) · [Gateway deployment guidance](https://orthanc.uclouvain.be/book/faq/security.html) · [Study-sharing token implementation](https://github.com/orthanc-team/orthanc-auth-service)
