*This page is non-normative.* If you come from the FHIR world and DICOM identifiers are new to you (or vice versa), this page explains the systems involved in hospital imaging, the identifiers each one mints, and how those identifiers tie the EHR's view of a study to the imaging system's view.

Five identifiers do almost all the work in imaging integrations:

| Identifier | Minted by | What it names |
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
<img src="ordering-workflow.svg" alt="Workflow: ordering mints the Accession Number in the RIS; acquisition mints the DICOM UIDs in the PACS; reporting ties the report back to the EHR by MRN and Accession Number" style="max-width: 100%; height: auto;"/>
</picture>
</div>

1. **Order** — A clinician orders imaging in the EHR for a patient (identified by MRN). The RIS accepts the order and mints an **Accession Number**, which the EHR stores on its `ServiceRequest`.
2. **Acquire** — The modality performs the study; the images land in the PACS carrying a fresh **Study Instance UID** (with Series and SOP Instance UIDs beneath it), plus the patient's MRN and the Accession Number in the DICOM headers.
3. **Report** — A radiologist reads the study and files a report keyed by MRN + Accession Number; it reaches the EHR as a `DiagnosticReport` (and/or `DocumentReference`), ideally also carrying the Study Instance UID.

### Mapping between the models

Three systems hold three views of the same study. The shared identifiers are what let an app (or an Imaging Server) walk between them:

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="identifiers-map-mobile.svg"/>
<img src="identifiers-map.svg" alt="Three columns — the EHR's FHIR model, the Imaging Server's FHIR model, and the DICOM model — connected by the shared identifiers MRN, Accession Number, and Study Instance UID" style="max-width: 100%; height: auto;"/>
</picture>
</div>

* **In DICOM**, the study record itself carries the Accession Number, the Study Instance UID, and patient demographics including MRN; series and instances hang beneath it with their own UIDs.
* **On the Imaging Server (FHIR)**, `ImagingStudy` mirrors the DICOM hierarchy: the Study Instance UID as its identifier, series and instance UIDs within, a reference to the `Patient` (MRN), optionally a `basedOn` reference carrying the Accession Number, and `endpoint` references pointing at WADO-RS.
* **In the EHR (FHIR)**, the `ServiceRequest` carries the Accession Number and the `DiagnosticReport` should reference the study by Study Instance UID — an *identifier reference*, not necessarily a resolvable URL.

That last point is deliberate: the EHR and the Imaging Server stay **loosely coupled**. The EHR doesn't need to know the Imaging Server's URLs; it just records identifiers. An app that finds a `DiagnosticReport` with a Study Instance UID can search the Imaging Server with `patient={id}&identifier=urn:oid:{uid}` and get the actual study — which is exactly why [Finding studies](specification.html#finding-studies) requires that search combination. And the Imaging Server, handed a token for `Patient/123`, can fetch that Patient from the EHR to learn the MRN it needs to query its own PACS — which is why [Authorization](specification.html#authorization) mentions Backend Services access.

How EHRs should represent imaging reports in FHIR is ultimately jurisdictional guidance territory (for example, [US Core](https://www.hl7.org/fhir/us/core/)); the model above reflects the direction of early consensus.
