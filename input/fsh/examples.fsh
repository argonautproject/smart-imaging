// ---------- Patient ----------

Instance: patient-example
InstanceOf: Patient
Usage: #example
Title: "Example Patient"
Description: "A patient with an MRN, hosted at `https://clinical.example.org/fhir/Patient/patient-example` and referenced by the externally anchored imaging examples."
* identifier.system = "http://hospital.example.org/mrn"
* identifier.value = "8675309"
* name.family = "Argonaut"
* name.given = "Jason"

// ---------- Study with a contained Endpoint ----------

Instance: wado-endpoint-contained
InstanceOf: SmartWadoEndpoint
Usage: #inline
* id = "e"
* status = #active
* connectionType = $ConnType#dicom-wado-rs
* payloadType = $PayloadType#any
* address = "https://imaging.example.org/wado-rs"

Instance: imaging-study-contained-endpoint
InstanceOf: SmartImagingStudy
Usage: #example
Title: "ImagingStudy with contained Endpoint"
Description: "A CT study whose WADO-RS Endpoint is contained in the resource."
* contained[0] = wado-endpoint-contained
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.19341866.1571297684"
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* started = "2023-02-24T14:02:49Z"
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 1
* numberOfInstances = 3
* endpoint[wadoRs].reference = "#e"
* series.uid = "1.2.840.99999999.19341866.1571297684.1"
* series.number = 1
* series.modality = $DCM#CT
* series.numberOfInstances = 3
* series.instance[0].uid = "1.2.840.99999999.19341866.1571297684.1.1"
* series.instance[0].number = 1
* series.instance[0].sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2
* series.instance[1].uid = "1.2.840.99999999.19341866.1571297684.1.2"
* series.instance[1].number = 2
* series.instance[1].sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2
* series.instance[2].uid = "1.2.840.99999999.19341866.1571297684.1.3"
* series.instance[2].number = 3
* series.instance[2].sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2

// ---------- Study with an external Endpoint ----------

Instance: wado-endpoint-example
InstanceOf: SmartWadoEndpoint
Usage: #example
Title: "Standalone WADO-RS Endpoint"
Description: "A WADO-RS Endpoint published as its own resource and shared by many studies."
* status = #active
* connectionType = $ConnType#dicom-wado-rs
* payloadType = $PayloadType#any
* address = "https://pacs.example.org/dicom-web"

Instance: imaging-study-external-endpoint
InstanceOf: SmartImagingStudy
Usage: #example
Title: "ImagingStudy with external Endpoint"
Description: "An MR study that references a standalone WADO-RS Endpoint resource."
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.82943819.1948573621"
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* started = "2023-05-11T09:30:00Z"
* modality = $DCM#MR "Magnetic Resonance"
* numberOfSeries = 1
* numberOfInstances = 1
* endpoint[wadoRs] = Reference(wado-endpoint-example)
* series.uid = "1.2.840.99999999.82943819.1948573621.1"
* series.number = 1
* series.modality = $DCM#MR
* series.numberOfInstances = 1
* series.instance.uid = "1.2.840.99999999.82943819.1948573621.1.1"
* series.instance.number = 1
* series.instance.sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.4

// ---------- Search response with a response-local capability Endpoint ----------

Instance: capability-endpoint-inline
InstanceOf: SmartWadoEndpoint
Usage: #inline
* id = "7d30f876-3d28-4c21-9f9d-13bfa9dd42a0"
* status = #active
* connectionType = $ConnType#dicom-wado-rs
* payloadType = $PayloadType#any
* address = "https://imaging.example.org/wado-capability/opaque-example-capability"

Instance: capability-study-inline
InstanceOf: SmartImagingStudy
Usage: #inline
* id = "imaging-study-capability"
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.19341866.1571297684"
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* started = "2023-02-24T14:02:49Z"
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 1
* numberOfInstances = 3
* endpoint[wadoRs].reference = "urn:uuid:7d30f876-3d28-4c21-9f9d-13bfa9dd42a0"
* series.uid = "1.2.840.99999999.19341866.1571297684.1"
* series.number = 1
* series.modality = $DCM#CT
* series.numberOfInstances = 3
* series.instance[0].uid = "1.2.840.99999999.19341866.1571297684.1.1"
* series.instance[0].number = 1
* series.instance[0].sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2
* series.instance[1].uid = "1.2.840.99999999.19341866.1571297684.1.2"
* series.instance[1].number = 2
* series.instance[1].sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2
* series.instance[2].uid = "1.2.840.99999999.19341866.1571297684.1.3"
* series.instance[2].number = 3
* series.instance[2].sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2

Instance: imaging-capability-search-response
InstanceOf: Bundle
Usage: #example
Title: "ImagingStudy search with a response-local capability Endpoint"
Description: """
An authorized search response containing a CT study and an Endpoint specific
to the requesting SMART token. The ImagingStudy references the Endpoint's
urn:uuid fullUrl. The client resolves that reference within this Bundle, appends
the study path to Endpoint.address, and presents the same SMART access token
when retrieving DICOM data. The retrieval service validates the token, the
capability, and their binding. The URL and UUID are illustrative values.
"""
* type = #searchset
* total = 1
* link[0].relation = "self"
* link[0].url = "https://imaging.example.org/fhir/ImagingStudy?patient=https%3A%2F%2Fclinical.example.org%2Ffhir%2FPatient%2Fpatient-example&_include=ImagingStudy:endpoint"
* entry[0].fullUrl = "https://imaging.example.org/fhir/ImagingStudy/imaging-study-capability"
* entry[0].resource = capability-study-inline
* entry[0].search.mode = #match
* entry[1].fullUrl = "urn:uuid:7d30f876-3d28-4c21-9f9d-13bfa9dd42a0"
* entry[1].resource = capability-endpoint-inline
* entry[1].search.mode = #include

// ---------- Search response Bundle ----------

Instance: imaging-search-response
InstanceOf: Bundle
Usage: #example
Title: "ImagingStudy search response"
Description: "What an app receives from `GET [imaging-base]/ImagingStudy?patient=...&_include=ImagingStudy:endpoint`."
* type = #searchset
* total = 2
* link[0].relation = "self"
* link[0].url = "https://imaging.example.org/fhir/ImagingStudy?patient=https%3A%2F%2Fclinical.example.org%2Ffhir%2FPatient%2Fpatient-example&_include=ImagingStudy:endpoint"
* entry[0].fullUrl = "https://imaging.example.org/fhir/ImagingStudy/imaging-study-contained-endpoint"
* entry[0].resource = imaging-study-contained-endpoint
* entry[0].search.mode = #match
* entry[1].fullUrl = "https://imaging.example.org/fhir/ImagingStudy/imaging-study-external-endpoint"
* entry[1].resource = imaging-study-external-endpoint
* entry[1].search.mode = #match
* entry[2].fullUrl = "https://imaging.example.org/fhir/Endpoint/wado-endpoint-example"
* entry[2].resource = wado-endpoint-example
* entry[2].search.mode = #include

// ---------- Study with mixed endpoint connection types ----------

Instance: qido-endpoint-example
InstanceOf: Endpoint
Usage: #example
Title: "QIDO-RS Endpoint"
Description: "A non-WADO-RS Endpoint that can appear alongside SMART WADO-RS Endpoints. This guide's WADO-RS retrieval and token-presentation rules do not define access to this endpoint."
* status = #active
* connectionType = $ConnType#dicom-qido-rs
* payloadType = $PayloadType#any
* address = "https://pacs.example.org/dicom-query"

Instance: wado-endpoint-secondary-example
InstanceOf: SmartWadoEndpoint
Usage: #example
Title: "Secondary archive WADO-RS Endpoint"
Description: "A SMART WADO-RS Endpoint for direct access to a series stored in a second archive."
* status = #active
* connectionType = $ConnType#dicom-wado-rs
* payloadType = $PayloadType#any
* address = "https://archive-two.example.org/dicom-web"

Instance: imaging-study-mixed-endpoints
InstanceOf: SmartImagingStudy
Usage: #example
Title: "ImagingStudy with mixed endpoint connection types"
Description: "A CT study with two released series and their complete instance inventories. The study-level SMART WADO-RS Endpoint covers both series. The first series inherits that WADO-RS coverage despite having a QIDO-RS Endpoint; the second overrides it with a direct WADO-RS Endpoint for series and instance retrieval. The study and second-series lists also demonstrate mixed connection types."
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.20261112.1"
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 2
* numberOfInstances = 2
* endpoint[wadoRs] = Reference(wado-endpoint-example)
* endpoint[1] = Reference(qido-endpoint-example)
* series[0].uid = "1.2.840.99999999.20261112.1.1"
* series[0].number = 1
* series[0].modality = $DCM#CT
* series[0].numberOfInstances = 1
* series[0].endpoint = Reference(qido-endpoint-example)
* series[0].instance.uid = "1.2.840.99999999.20261112.1.1.1"
* series[0].instance.number = 1
* series[0].instance.sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2
* series[1].uid = "1.2.840.99999999.20261112.1.2"
* series[1].number = 2
* series[1].modality = $DCM#CT
* series[1].numberOfInstances = 1
* series[1].endpoint[wadoRs] = Reference(wado-endpoint-secondary-example)
* series[1].endpoint[1] = Reference(qido-endpoint-example)
* series[1].instance.uid = "1.2.840.99999999.20261112.1.2.1"
* series[1].instance.number = 1
* series[1].instance.sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2

// ---------- Study with direct series-level WADO-RS coverage ----------

Instance: imaging-study-series-endpoint
InstanceOf: SmartImagingStudy
Usage: #example
Title: "ImagingStudy with series in separate archives"
Description: "A CT study with two released series in separate archives, each with a direct SMART WADO-RS Endpoint and its complete instance inventory. No study-level Endpoint is advertised. The App retrieves each series or instance from its designated Endpoint rather than assuming either archive can return the whole study. The source does not supply series or instance numbers for the second series."
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.20261112.2"
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 2
* numberOfInstances = 2
* series[0].uid = "1.2.840.99999999.20261112.2.1"
* series[0].number = 1
* series[0].modality = $DCM#CT
* series[0].numberOfInstances = 1
* series[0].endpoint[wadoRs] = Reference(wado-endpoint-example)
* series[0].instance.uid = "1.2.840.99999999.20261112.2.1.1"
* series[0].instance.number = 1
* series[0].instance.sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2
* series[1].uid = "1.2.840.99999999.20261112.2.2"
* series[1].modality = $DCM#CT
* series[1].numberOfInstances = 1
* series[1].endpoint[wadoRs] = Reference(wado-endpoint-secondary-example)
* series[1].instance.uid = "1.2.840.99999999.20261112.2.2.1"
* series[1].instance.sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2

// ---------- Metadata without WADO-RS retrieval endpoints ----------

Instance: imaging-study-metadata-only
InstanceOf: SmartImagingStudy
Usage: #example
Title: "Registered ImagingStudy without retrieval endpoints"
Description: "Metadata for a registered CT study with no associated instances or released series yet. Its metadata is accessible under the authorization, but no retrieval Endpoint is supplied."
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.20261112.3"
* status = #registered
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 0
* numberOfInstances = 0

Instance: imaging-study-available-not-retrievable
InstanceOf: SmartImagingStudy
Usage: #example
Title: "Available ImagingStudy without WADO-RS access"
Description: "Metadata for a CT study whose associated instances exist, so its status is available, but whose series have not been released for WADO-RS retrieval. Its metadata is accessible under the authorization; no study- or series-level retrieval Endpoint is supplied."
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.20261112.4"
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 1
* numberOfInstances = 3
* series.uid = "1.2.840.99999999.20261112.4.1"
* series.number = 1
* series.modality = $DCM#CT
* series.numberOfInstances = 3

// ---------- Independent Patient-hosting imaging server ----------

Instance: patient-independent-example
InstanceOf: Patient
Usage: #example
Title: "Patient on an independent imaging server"
Description: "A Patient hosted at `https://ris.example.org/fhir/Patient/987` in the imaging server's own Patient namespace."
* id = "987"
* active = true

Instance: independent-wado-endpoint-contained
InstanceOf: SmartWadoEndpoint
Usage: #inline
* id = "e"
* status = #active
* connectionType = $ConnType#dicom-wado-rs
* payloadType = $PayloadType#any
* address = "https://ris.example.org/wado-rs"

Instance: imaging-study-independent-patient
InstanceOf: SmartImagingStudy
Usage: #example
Title: "ImagingStudy with a local Patient on an independent imaging server"
Description: """
A CT study hosted at `https://ris.example.org/fhir`. This server omits
`patient_reference_base`, so its Patient-reference base is its own FHIR base.
The subject resolves to its local Patient at `https://ris.example.org/fhir/Patient/987`.
The deployment binds patient-scoped access to this Patient at authorization time,
as specified in [Endpoint patient context](patient-identity.html#endpoint-patient-context).
The contained WADO-RS Endpoint covers the study's one released series and instance.
"""
* contained[0] = independent-wado-endpoint-contained
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.20261112.5"
* status = #available
* subject = Reference(patient-independent-example)
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 1
* numberOfInstances = 1
* endpoint[wadoRs].reference = "#e"
* series.uid = "1.2.840.99999999.20261112.5.1"
* series.number = 1
* series.modality = $DCM#CT
* series.numberOfInstances = 1
* series.instance.uid = "1.2.840.99999999.20261112.5.1.1"
* series.instance.number = 1
* series.instance.sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2
