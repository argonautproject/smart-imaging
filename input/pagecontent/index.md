Apps can already use [SMART App Launch](https://hl7.org/fhir/smart-app-launch/) to get a patient's clinical data. **SMART Imaging Access extends that same authorization to imaging**: with one approval from the user, an app can find a patient's imaging studies and download the DICOM data — no separate imaging login, no second consent screen.

This helps patients gather their own records, supports second opinions, streamlines research data donation, and lets clinicians pull studies into their preferred viewers.

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="system-map-mobile.svg"/>
<img src="system-map.svg" alt="System map: an app authorizes with the Authorization Server, optionally queries the Clinical FHIR Server, and uses the Imaging Server for study metadata and DICOM data; the Imaging Server validates tokens through the Authorization Server's introspection endpoint" style="max-width: 100%; height: auto;"/>
</picture>
<p><em>These roles may be implemented by one product or multiple cooperating products. The dashed connection shows token validation using SMART Token Introspection.</em></p>
</div>

### How it works

1. **Discover** — The app finds the imaging endpoint, either from the clinical FHIR endpoint's `.well-known/smart-configuration` or out-of-band configuration. ([Discovery](specification.html#discovery))
2. **Authorize** — The app completes a normal SMART App Launch flow with the Authorization Server and receives an access token with patient context. ([Authorization](specification.html#authorization))
3. **Query clinical data** *(optional)* — The app uses the token against the Clinical FHIR Server — for example, to fetch the Patient resource or imaging DiagnosticReports.
4. **Find studies** — The app searches the imaging endpoint for the patient's `ImagingStudy` resources, each of which links to a WADO-RS endpoint. ([Finding studies](specification.html#finding-studies))
5. **Fetch images** — The app retrieves DICOM data from the WADO-RS endpoint, presenting the same access token. ([Retrieving images](specification.html#retrieving-images))

### Actors

This guide uses the following actor names throughout:

* **App** — a user-facing application (patient- or provider-facing) that connects through SMART App Launch.
* **Authorization Server** — the SMART authorization server configured for the deployment. It supports app registration, user authorization, token issuance and refresh, and token introspection for participating resource servers. It may be provided by an EHR or another service.
* **Clinical FHIR Server** — a FHIR service exposing clinical resources such as `Patient`, `DiagnosticReport`, and `ServiceRequest`. Its SMART configuration can advertise imaging endpoints. An app may query it for clinical data as part of an imaging workflow.
* **Imaging Server** — the imaging system: a FHIR endpoint serving `ImagingStudy` resources, plus one or more DICOM WADO-RS endpoints. It may be part of an EHR, a PACS-vendor service, or a standalone proxy in front of a PACS.

One product may implement multiple roles, or separate products may cooperate through the interfaces described here. For example, the same FHIR endpoint may serve both clinical resources and `ImagingStudy` resources, while a proxy in front of an existing PACS provides the WADO-RS endpoint.

In U.S. certified deployments, the Authorization Server role can be supplied by the authorization capabilities of a Health IT Module certified to [§170.315(g)(10)](https://healthit.gov/test-method/standardized-api-for-patient-and-population-services-acb-atl/). Deploying SMART Imaging Access also requires configuring the participating services to support the imaging discovery, scopes, and token validation described in this guide. This guide defines technical roles and interfaces without requiring changes to certification categories.

### Scope

See [Connecting Organizations](networks.html) for how this guide can serve as a building block for image exchange between health systems.

In scope:

* Discovering an imaging endpoint through SMART configuration or direct configuration
* Reusing the SMART access token issued by the Authorization Server for imaging requests, with server-side validation (for example, via [SMART Token Introspection](https://hl7.org/fhir/smart-app-launch/token-introspection.html))
* Searching `ImagingStudy` by patient and retrieving DICOM data via WADO-RS

Out of scope (for now):

* Writing or uploading imaging data
* Token exchange for imaging-scoped tokens — deployments that need this may layer it on; future versions may define optional metadata for it
* DICOM capabilities beyond the minimum retrieval requirements in [Retrieving images](specification.html#retrieving-images)

### History

This guide grew out of the [Sync for Science (S4S) Imaging specification](https://github.com/sync-for-science/imaging), developed by the SMART team for the NIH *All of Us* research program, and continues under the Argonaut Project.

### Dependencies

{% include dependency-table.xhtml %}

{% include globals-table.xhtml %}

### Cross-version analysis

{% include cross-version-analysis.xhtml %}

### Intellectual property statements

{% include ip-statements.xhtml %}
