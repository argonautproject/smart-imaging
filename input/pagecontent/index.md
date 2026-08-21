Apps can already use [SMART App Launch](https://hl7.org/fhir/smart-app-launch/) to get a patient's clinical data from an EHR. **SMART Imaging Access extends that same authorization to imaging**: with one approval from the user, an app can find a patient's imaging studies and download the DICOM data — no separate imaging login, no second consent screen.

This helps patients gather their own records, supports second opinions, streamlines research data donation, and lets clinicians pull studies into their preferred viewers.

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="system-map-mobile.svg"/>
<img src="system-map.svg" alt="System map: an app talks to the EHR for authorization and clinical data, and to the Imaging Server for study metadata and DICOM data" style="max-width: 100%; height: auto;"/>
</picture>
</div>

### How it works

1. **Discover** — The app finds the EHR's imaging endpoint, either from the EHR's `.well-known/smart-configuration` or out-of-band configuration. ([Discovery](specification.html#discovery))
2. **Authorize** — The app completes a normal SMART App Launch flow with the EHR and receives an access token with patient context. ([Authorization](specification.html#authorization))
3. **Query clinical data** *(optional)* — The app uses the token against the EHR's clinical FHIR server as usual — for example, to fetch the Patient resource or imaging DiagnosticReports.
4. **Find studies** — The app searches the imaging endpoint for the patient's `ImagingStudy` resources, each of which links to a WADO-RS endpoint. ([Finding studies](specification.html#finding-studies))
5. **Fetch images** — The app retrieves DICOM data from the WADO-RS endpoint, presenting the same access token. ([Retrieving images](specification.html#retrieving-images))

### Actors

This guide uses three actor names throughout:

* **App** — a user-facing application (patient- or provider-facing) that has completed SMART App Launch with the EHR.
* **EHR** — the clinical system: a SMART on FHIR authorization server, a token introspection endpoint, and a clinical FHIR server.
* **Imaging Server** — the imaging system: a FHIR endpoint serving `ImagingStudy` resources, plus one or more DICOM WADO-RS endpoints. It may be part of the EHR, a PACS-vendor service, or a standalone proxy in front of a PACS.

These are roles, not deployment requirements. The `ImagingStudy` resources may live in the EHR's own FHIR server; the WADO-RS endpoint may be a thin proxy over an existing PACS; any combination works as long as the interfaces behave as described.

### Scope

In scope:

* Discovering an imaging endpoint associated with an EHR
* Reusing the EHR-issued SMART access token for imaging requests, with server-side validation (for example, via [SMART Token Introspection](https://hl7.org/fhir/smart-app-launch/token-introspection.html))
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
