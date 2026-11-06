// ---------- Patient ----------

Instance: patient-example
InstanceOf: Patient
Usage: #example
Title: "Example Patient"
Description: "A patient with an MRN, as known to the Clinical FHIR Server."
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
* identifier[accession].type = $V2-0203#ACSN
* identifier[accession].system = "http://hospital.example.org/accession"
* identifier[accession].value = "ACC-2023-0042"
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* basedOn[0].type = "ServiceRequest"
* basedOn[0].identifier.type = $V2-0203#ACSN
* basedOn[0].identifier.system = "http://hospital.example.org/accession"
* basedOn[0].identifier.value = "ACC-2023-0042"
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

// ---------- Search response with a response-local study-context Endpoint ----------

Instance: study-context-endpoint-inline
InstanceOf: SmartWadoEndpoint
Usage: #inline
* id = "7d30f876-3d28-4c21-9f9d-13bfa9dd42a0"
* status = #active
* connectionType = $ConnType#dicom-wado-rs
* payloadType = $PayloadType#any
* address = "https://imaging.example.org/wado-ctx/opaque-study-context"

Instance: study-context-study-inline
InstanceOf: SmartImagingStudy
Usage: #inline
* id = "imaging-study-context"
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

Instance: imaging-study-context-search-response
InstanceOf: Bundle
Usage: #example
Title: "ImagingStudy search with a response-local study-context Endpoint"
Description: """
An authorized search response containing a CT study and a response-local
Endpoint entry whose `urn:uuid` fullUrl is referenced from `ImagingStudy.endpoint`.
The client resolves that reference within this Bundle, treats `Endpoint.address`
as an opaque WADO-RS base URL, appends `/studies/{Study Instance UID}`, and
presents any currently valid SMART access token covering the study. The URL
and UUID are illustrative values.
"""
* type = #searchset
* total = 1
* link[0].relation = "self"
* link[0].url = "https://imaging.example.org/fhir/ImagingStudy?patient=patient-example&_include=ImagingStudy:endpoint"
* entry[0].fullUrl = "https://imaging.example.org/fhir/ImagingStudy/imaging-study-context"
* entry[0].resource = study-context-study-inline
* entry[0].search.mode = #match
* entry[1].fullUrl = "urn:uuid:7d30f876-3d28-4c21-9f9d-13bfa9dd42a0"
* entry[1].resource = study-context-endpoint-inline
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
* link[0].url = "https://imaging.example.org/fhir/ImagingStudy?patient=patient-example&_include=ImagingStudy:endpoint"
* entry[0].fullUrl = "https://imaging.example.org/fhir/ImagingStudy/imaging-study-contained-endpoint"
* entry[0].resource = imaging-study-contained-endpoint
* entry[0].search.mode = #match
* entry[1].fullUrl = "https://imaging.example.org/fhir/ImagingStudy/imaging-study-external-endpoint"
* entry[1].resource = imaging-study-external-endpoint
* entry[1].search.mode = #match
* entry[2].fullUrl = "https://imaging.example.org/fhir/Endpoint/wado-endpoint-example"
* entry[2].resource = wado-endpoint-example
* entry[2].search.mode = #include

// ---------- Study with both WADO-RS and QIDO-RS Endpoints ----------

Instance: qido-endpoint-contained
InstanceOf: Endpoint
Usage: #inline
* id = "qido"
* status = #active
* connectionType = $ConnType#dicom-qido-rs
* payloadType = $PayloadType#any
* address = "https://imaging.example.org/qido-rs"

Instance: imaging-study-wado-and-qido
InstanceOf: SmartImagingStudy
Usage: #example
Title: "ImagingStudy with WADO-RS and QIDO-RS Endpoints"
Description: "A CT study carrying both a contained SMART WADO-RS Endpoint for DICOM retrieval and a second non-WADO-RS Endpoint (QIDO-RS)."
* contained[0] = wado-endpoint-contained
* contained[1] = qido-endpoint-contained
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.19341866.1571297684"
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* started = "2023-02-24T14:02:49Z"
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 1
* numberOfInstances = 3
* endpoint[wadoRs].reference = "#e"
* endpoint[1].reference = "#qido"
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

// ---------- Study with a series-level WADO-RS Endpoint ----------

Instance: series-wado-endpoint-contained
InstanceOf: SmartWadoEndpoint
Usage: #inline
* id = "series-wado"
* status = #active
* connectionType = $ConnType#dicom-wado-rs
* payloadType = $PayloadType#any
* address = "https://specialty-archive.example.org/wado-rs"

Instance: imaging-study-series-endpoint
InstanceOf: SmartImagingStudy
Usage: #example
Title: "ImagingStudy with a series-level WADO-RS Endpoint"
Description: "An available study with a study-level SMART WADO-RS Endpoint covering the full study and a series-level SMART WADO-RS Endpoint overriding WADO-RS retrieval for that series."
* contained[0] = wado-endpoint-contained
* contained[1] = series-wado-endpoint-contained
* identifier[dicomUid].system = "urn:dicom:uid"
* identifier[dicomUid].value = "urn:oid:1.2.840.99999999.19341866.1571297684"
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* started = "2023-02-24T14:02:49Z"
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 1
* numberOfInstances = 1
* endpoint[wadoRs].reference = "#e"
* series.uid = "1.2.840.99999999.19341866.1571297684.1"
* series.number = 1
* series.modality = $DCM#CT
* series.numberOfInstances = 1
* series.endpoint[0].reference = "#series-wado"
* series.instance[0].uid = "1.2.840.99999999.19341866.1571297684.1.1"
* series.instance[0].number = 1
* series.instance[0].sopClass = urn:ietf:rfc:3986#urn:oid:1.2.840.10008.5.1.4.1.1.2
