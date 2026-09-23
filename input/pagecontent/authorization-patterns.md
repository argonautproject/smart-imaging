*This page is non-normative.* Using the [functional roles defined on the home page](index.html#actors), it describes how cooperating services decide which studies to release and enforce those decisions during image retrieval.

### Example access restrictions

The following fictional examples assume that the source organization has already configured the relevant permissions. They illustrate the technical result, not rules about which studies a particular person or service should be allowed to access.

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

* **The access token** — The token supplied with the request connects it to a granted authorization. The service validates it rather than assuming that its contents can be read or trusted directly.

* **A capability URL** — A **capability URL** is a retrieval URL that carries or identifies study-specific permissions bound to the requesting SMART token. The permission may be encoded in protected URL contents or stored by the service under an opaque identifier. The retrieval service validates both the capability and the presented token. An ordinary study URL is not a capability merely because it identifies a study.

* **Token introspection** — The Authorization Server can supply the token’s status, granted scopes, client identity, and available user or patient context. Standard introspection fields do not necessarily express all the study-level restrictions the service needs to enforce.

* **A FHIR query using the caller’s token** — The service validates the token for the requested retrieval and queries the trusted Imaging FHIR Server for the patient and Study Instance UID using that same token. The Imaging FHIR Server applies the caller’s study-access policy; an authorized matching result establishes the study-specific permission. The token must be valid for both services.

* **An explicit authorization-decision API** — Instead of querying ImagingStudy, the service can ask directly whether the original caller is permitted to retrieve a study. The requesting service authenticates itself and supplies trusted caller context. This guide does not define that internal API.

* **Locally configured or shared policy** — The service can apply its own configured rules or consult policy shared with the Authorization Server or Imaging FHIR Server. The cooperating systems agree how the relevant permissions and policy changes are communicated and enforced.

These mechanisms can be combined. For example, a DICOMweb service might validate a token through introspection, validate a token-bound capability URL for the requested study, and consult an internal decision service for current consent restrictions. Another might validate the token and enforce a capability issued after the Imaging FHIR Server has evaluated those restrictions.

The client presents the same SMART token for study search and every image retrieval, using the Endpoint returned by the Imaging FHIR Server. This applies to App Launch and Backend Services; the client does not need to inspect the URL to determine how the server evaluates access.

### Ways to divide authorization responsibilities

The following examples show how cooperating services can divide the work of deciding which studies to release and enforcing those decisions. They can be combined or adapted; none is required by this guide.

Solid arrows in the diagrams show client interactions; dashed arrows show internal coordination. The diagrams start after the client has obtained a SMART token. Token issuance and clinical FHIR access are omitted so the drawings can focus on study-access decisions. The outer boxes group functions: an imaging study service combines Imaging FHIR with study-release policy; a retrieval service provides DICOMweb and retrieval authorization; a gateway can provide both. These labels do not require separate products or additional standardized actors.

#### The gateway evaluates policy and controls retrieval

A gateway provides both the Imaging FHIR Server and DICOMweb Server. It combines token validation, such as introspection, with locally configured or shared policy. It uses those permissions to filter the study list and check each image request before retrieving data from an internal image archive, such as a PACS.

<div style="margin: 1.5em 0;">
<img src="authorization-gateway.svg" alt="A gateway hosts Imaging FHIR and DICOMweb. Both use its study-access policy; DICOMweb controls retrieval from an internal image archive." style="display: block; width: 100%; max-width: 960px; height: auto; margin: 0 auto;"/>
</div>

*The gateway provides both imaging roles. Its access to the archive is separate from the client’s access to the gateway.*

For Elena’s request, the gateway applies the configured proxy-access restrictions. For the quality-review service’s request, it applies the health system’s configured cardiac-study permissions. Its own archive credentials may allow broader access, but it releases only what the requesting client is permitted to retrieve. Other client-accessible routes must not bypass that enforcement.

#### The Imaging FHIR Server issues a capability URL; DICOMweb enforces its permissions

In this example, the imaging study service provides Imaging FHIR and evaluates the study-release rules. The Authorization Server supplies validated token context; the imaging study service makes the study-level release decision. An EHR, imaging platform, or independently implemented service could perform that work. The imaging study service evaluates its own policy when answering the study query and returns a capability URL for each permitted study. A separate DICOMweb service validates the capability and enforces its permissions. It can also use token introspection or other checks where the configuration requires them, without reproducing all the policy logic used by the issuer.

<div style="margin: 1.5em 0;">
<img src="authorization-grant.svg" alt="A separate imaging study service evaluates study permissions and returns capability URLs. DICOMweb validates the capabilities before reading the archive." style="display: block; width: 100%; max-width: 960px; height: auto; margin: 0 auto;"/>
</div>

*The imaging study service owns the release decision. The DICOMweb service enforces the permissions carried by the capability URL.*

A capability URL could permit retrieval of Maya’s ankle X-ray or Jordan’s cardiac MRI. It would not permit retrieval of the excluded study simply because that study belongs to the same patient.

The client presents the SMART token used for the study search when retrieving images through the capability URL. The DICOMweb Server checks the token's validity, the capability's binding to that token, and all applicable restrictions.

For a capability URL, the Imaging FHIR Server should return a response-local Endpoint entry with a `urn:uuid:...` fullUrl and use that same URN in `ImagingStudy.endpoint.reference`. The client resolves the URN within the search Bundle to obtain the Endpoint's HTTPS address. This keeps the response-specific authorization information in its own resource, with a response-local identity. See the [complete Bundle example](Bundle-imaging-capability-search-response.html).

The capability is carried in the returned Endpoint’s WADO-RS base URL; the client constructs study and other retrieval paths as specified in [Retrieving images](specification.html#retrieving-images). The issuer and retrieval service agree how to represent and validate capabilities within the guide’s lifetime and access requirements. The service rejects requests that substitute an unauthorized study identifier into a valid retrieval URL.

#### DICOMweb requests an access decision before retrieval

The Imaging FHIR Server filters the study list, and the DICOMweb Server checks the caller’s permission when an image request arrives. In the diagram, it asks the system responsible for study-access decisions before reading the archive.

<div style="margin: 1.5em 0;">
<img src="authorization-recheck.svg" alt="The DICOMweb Server asks the imaging study service to check access for the original caller and requested study before releasing data from the image archive." style="display: block; width: 100%; max-width: 960px; height: auto; margin: 0 auto;"/>
</div>

*The check uses the original caller’s authorization, not the retrieval service’s broader archive permissions.*

For token-protected retrieval, the DICOMweb Server performs the [required token and access checks](specification.html#authorization), using cooperating services where appropriate. The callback establishes permission for the requested study through an authorized ImagingStudy query or an explicit decision API. The service combines that decision with the token’s scopes, patient context where applicable, and any endpoint-specific restrictions. A service with sufficient token context and local policy can make the decision without the illustrated callback.

The implementation needs to handle unavailable decision services and avoid circular checks—for example, a FHIR query that waits for an archive request that is itself waiting for the same FHIR query.

### Implementation considerations

#### Expiry and policy changes

Each retrieval requires a valid SMART token. Capability URLs are also subject to their own expiry and revocation conditions. Document how capabilities expire, how decisions are cached, and how policy changes take effect. A refreshed token may require a new Endpoint from an authorized study search. See the [lifetime and recovery requirements](specification.html#retrieving-images).

#### Audit records

Record the client, any represented user, the patient, and the study. Correlate the presented token, any capability, and the retrieval decision without exposing credentials in logs.

#### All retrieval paths

Apply authorization to all supported retrieval forms: metadata, rendered images, frames, instances, and full studies. A request made directly to a known image URL needs protection even if it did not follow a study search.

Implementers can combine these approaches. EHR vendors, PACS vendors, authorization-service providers, and gateway implementers can share the work without changing the client’s study-search and retrieval protocol.

### Background and implementation references

These sources describe relevant concepts and building blocks. They do not establish that a particular product implements every flow shown here.

* [SMART 2.2: scopes and underlying permissions](https://hl7.org/fhir/smart-app-launch/STU2.2/scopes-and-launch-context.html) · [Token introspection](https://hl7.org/fhir/smart-app-launch/STU2.2/token-introspection.html)
* [FHIR R4 security and access control](https://hl7.org/fhir/R4/security.html) · [Consent](https://hl7.org/fhir/R4/consent.html) · [IHE Privacy Consent on FHIR](https://profiles.ihe.net/ITI/PCF/volume-1.html)
* [Orthanc external authorization service](https://orthanc.uclouvain.be/book/plugins/authorization.html) · [Gateway deployment guidance](https://orthanc.uclouvain.be/book/faq/security.html) · [Study-sharing token implementation](https://github.com/orthanc-team/orthanc-auth-service)
