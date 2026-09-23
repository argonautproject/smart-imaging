*This page is non-normative.* If you come from the FHIR world and DICOM identifiers are new to you (or vice versa), this page explains the systems involved in hospital imaging, the identifiers each one assigns, and how those identifiers tie clinical records to the imaging system's view of a study.

Five identifiers do almost all the work in imaging integrations:

| Identifier | Assigned by | What it names |
|---|---|---|
| **MRN** | EHR | The patient, within one organization |
| **Accession Number** | RIS | The imaging *order* |
| **Study Instance UID** | Imaging modality/PACS | One DICOM study |
| **Series Instance UID** | Imaging modality/PACS | One series within a study |
| **SOP Instance UID** | Imaging modality/PACS | One instance (e.g., one slice) within a series |

### The imaging workflow

A simplified view of hospital imaging (inspired by the [IHE Radiology profiles](https://profiles.ihe.net/RAD/), with worklist details omitted):

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="ordering-workflow-mobile.svg"/>
<img src="ordering-workflow.svg" alt="Workflow: ordering assigns the Accession Number in the RIS; acquisition assigns the DICOM UIDs in the PACS; reporting ties the report back to the EHR by MRN and Accession Number" style="max-width: 100%; height: auto;"/>
</picture>
</div>

1. **Order** — A clinician orders imaging in the EHR for a patient (identified by MRN). The RIS accepts the order and assigns an **Accession Number**, which the EHR stores on its `ServiceRequest`.
2. **Acquire** — The modality performs the study; the images land in the PACS carrying a fresh **Study Instance UID** (with Series and SOP Instance UIDs beneath it), plus the patient's MRN and the Accession Number in the DICOM headers.
3. **Report** — A radiologist reads the study and files a report keyed by MRN + Accession Number; it reaches the EHR as a `DiagnosticReport` (and/or `DocumentReference`), ideally also carrying the Study Instance UID.

### Mapping between the models

Clinical FHIR, imaging FHIR, and DICOM each represent a view of the same study. The shared identifiers are what let an app (or an Imaging Server) walk between them:

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="identifiers-map-mobile.svg"/>
<img src="identifiers-map.svg" alt="Three columns — the Clinical FHIR Server's model, the Imaging Server's FHIR model, and the DICOM model — connected by the shared identifiers MRN, Accession Number, and Study Instance UID" style="max-width: 100%; height: auto;"/>
</picture>
</div>

* **In DICOM**, the study record itself carries the Accession Number, the Study Instance UID, and patient demographics including MRN; series and instances have their own UIDs.
* **On the Imaging FHIR Server**, `ImagingStudy` mirrors the DICOM hierarchy: the Study Instance UID as its identifier, series and instance UIDs within, a reference to the FHIR `Patient` resource, optionally a `basedOn` reference carrying the Accession Number, and `endpoint` references pointing at WADO-RS. An MRN may be used internally to map that patient to imaging records.
* **On the Clinical FHIR Server**, the `ServiceRequest` carries the Accession Number and the `DiagnosticReport` should reference the study by Study Instance UID — an *identifier reference*, not necessarily a resolvable URL.

A clinical record can identify a study by Study Instance UID without recording its retrieval URL. The app locates the study and its Endpoint using `patient={id}&identifier=urn:oid:{uid}`, as described in [Finding studies](specification.html#finding-studies).

To map `Patient/123` to its PACS records, the Imaging FHIR Server can fetch that Patient from the Clinical FHIR Server and obtain its MRN. See the Backend Services example in [Authorization](specification.html#authorization).

Representation of imaging reports in FHIR is covered by jurisdiction-specific implementation guides, such as [US Core](https://www.hl7.org/fhir/us/core/). The model above reflects the direction of early consensus.
