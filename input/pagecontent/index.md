Apps can already use SMART authorization to get clinical data. **SMART Imaging Access extends that same authorization to imaging**: an app can find a patient's imaging studies and retrieve the DICOM data using its existing access token, a capability URL returned by the authorized FHIR request, or both.

This helps patients gather their own records, supports second opinions, streamlines research data donation, and lets clinicians pull studies into their preferred viewers.

The guide supports both [SMART App Launch](specification.html#app-launch), for user-facing authorization, and [SMART Backend Services](specification.html#backend-services), for pre-authorized clients. Deployments can support either or both patterns. Neither requires a separate imaging authorization step.

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="system-map-mobile.svg"/>
<img src="system-map.svg" alt="System map: an app authorizes with the Authorization Server, optionally queries the Clinical FHIR Server, and uses the Imaging Server for study metadata and DICOM data; the Imaging Server validates tokens through the Authorization Server's introspection endpoint" style="max-width: 100%; height: auto;"/>
</picture>
<p><em>The diagram illustrates App Launch with token-protected retrieval. Either authorization mode can also return capability URLs. These roles may be implemented by one product or multiple cooperating products. The dashed connection shows token validation using SMART Token Introspection.</em></p>
</div>

### How it works

1. **Discover** — The app finds the imaging endpoint, either from the clinical FHIR endpoint's `.well-known/smart-configuration` or out-of-band configuration. ([Discovery](specification.html#discovery))
2. **Authorize** — The app completes SMART App Launch and receives an access token with patient context. Where Backend Services is supported, a pre-authorized client instead obtains a system-scoped token through SMART Backend Services. ([Authorization](specification.html#authorization))
3. **Query clinical data** *(optional)* — The app uses the token against the Clinical FHIR Server — for example, to fetch the Patient resource or imaging DiagnosticReports.
4. **Find studies** — The app searches the imaging endpoint for the patient's `ImagingStudy` resources, each of which links to a WADO-RS endpoint. ([Finding studies](specification.html#finding-studies))
5. **Fetch images** — The app checks the Endpoint's `requires-access-token` flag: `true` means send the existing SMART token; `false` means follow the bearer capability URL without it. ([Retrieving images](specification.html#retrieving-images))

### Actors

This guide uses the following actor names throughout:

* **App** — a client accessing clinical and imaging data. A user-facing application (patient- or provider-facing) can connect through SMART App Launch; a pre-authorized service can connect through SMART Backend Services. Unless stated otherwise, the guide's discovery, search, retrieval, and token-handling requirements apply to Backend Clients too.
* **Backend Client** — an App using SMART Backend Services, with access authorized in advance rather than through a user-facing launch.
* **Authorization Server** — the SMART authorization server configured for the deployment. It supports client registration, token issuance, and token validation for participating resource servers. Depending on the supported modes, it provides App Launch authorization and refresh, Backend Services token issuance for pre-authorized clients, or both. It may be provided by an EHR or another service.
* **Clinical FHIR Server** — a FHIR service exposing clinical resources such as `Patient`, `DiagnosticReport`, and `ServiceRequest`. Its SMART configuration can advertise imaging endpoints. An app may query it for clinical data as part of an imaging workflow.
* **Imaging Server** — the collective term for two cooperating functions:
    * **Imaging FHIR Server** — serves `ImagingStudy` resources and returns the WADO-RS Endpoints through which authorized clients can retrieve images.
    * **DICOMweb Server** — provides WADO-RS retrieval through those endpoints and enforces the applicable retrieval authorization.

These are functional roles, not product categories. One product may implement several roles, or cooperating products may implement them separately. For example, an EHR, imaging platform, or adapter could provide Imaging FHIR; a PACS, archive service, or gateway could provide DICOMweb; and an EHR or a standalone authorization service could provide the Authorization Server. “DICOMweb Server” here refers to the WADO-RS retrieval functionality described in this guide.

[Implementing Study-Level Authorization](authorization-patterns.html) illustrates how these functions can share policy decisions and enforce access to individual studies.

In U.S. certified deployments, the Authorization Server role can be supplied by the authorization capabilities of a Health IT Module certified to [§170.315(g)(10)](https://healthit.gov/test-method/standardized-api-for-patient-and-population-services-acb-atl/). Deploying SMART Imaging Access also requires configuring the participating services to support the imaging discovery, scopes, and token validation described in this guide. This guide defines technical roles and interfaces without requiring changes to certification categories.

### Scope

See [Connecting Organizations](networks.html) for how this guide can serve as a building block for image exchange between health systems.

In scope:

* Discovering an imaging endpoint through SMART configuration or direct configuration
* Reusing the SMART access token issued by the Authorization Server for imaging requests, with server-side validation (for example, via [SMART Token Introspection](https://hl7.org/fhir/smart-app-launch/token-introspection.html))
* Returning bearer or token-bound capability URLs for DICOM retrieval, in either authorization mode
* Searching `ImagingStudy` by patient and retrieving DICOM data via WADO-RS
* Backend Services access, with system scopes and enforcement of each client's pre-authorized permissions

Out of scope (for now):

* Writing or uploading imaging data
* Token exchange for imaging-scoped tokens — deployments that need this may layer it on; future versions may define optional metadata for it
* DICOM capabilities beyond the minimum retrieval requirements in [Retrieving images](specification.html#retrieving-images)
* Cross-organization trust agreements, patient matching, record location, and destination-system import workflows

### History

This guide grew out of the [Sync for Science (S4S) Imaging specification](https://github.com/sync-for-science/imaging), developed by the SMART team for the NIH *All of Us* research program, and continues under the Argonaut Project.

### Dependencies

{% include dependency-table.xhtml %}

{% include globals-table.xhtml %}

### Cross-version analysis

{% include cross-version-analysis.xhtml %}

### Intellectual property statements

{% include ip-statements.xhtml %}
