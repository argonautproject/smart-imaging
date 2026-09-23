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
* status = #available
* subject.reference = "https://clinical.example.org/fhir/Patient/patient-example"
* started = "2023-02-24T14:02:49Z"
* modality = $DCM#CT "Computed Tomography"
* numberOfSeries = 1
* numberOfInstances = 3
* endpoint.reference = "#e"
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
* endpoint = Reference(wado-endpoint-example)
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
* endpoint.reference = "urn:uuid:7d30f876-3d28-4c21-9f9d-13bfa9dd42a0"

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
* link[0].url = "https://imaging.example.org/fhir/ImagingStudy?patient=patient-example&_include=ImagingStudy:endpoint"
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
