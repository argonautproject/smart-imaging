Profile: SmartImagingStudy
Parent: ImagingStudy
Id: smart-imaging-study
Title: "SMART ImagingStudy"
Description: """
An ImagingStudy returned by a SMART Imaging Access server, with a DICOM Study
Instance UID identifier and, when the study status is `available`, at least one
SMART WADO-RS Endpoint for retrieving its DICOM data.
"""
* obeys smart-wado-endpoint-when-available
* identifier 1..* MS
* identifier ^short = "Study identifiers (DICOM Study Instance UID required; Accession Number required when known)"
* identifier ^definition = "Identifiers for the study. Every study SHALL include its DICOM Study Instance UID in the `dicomUid` slice (`system = urn:dicom:uid`, `value = urn:oid:...`). When the server knows a study's Accession Number, it SHALL also include it in the `accession` slice (`type = http://terminology.hl7.org/CodeSystem/v2-0203#ACSN`, `value` set to the Accession Number, and `system` set to the assigning authority URI when known), and SHOULD additionally populate `basedOn.identifier` for FHIR R6 and IHE MADO compatibility."
* identifier ^slicing.discriminator.type = #pattern
* identifier ^slicing.discriminator.path = "$this"
* identifier ^slicing.rules = #open
* identifier contains
    dicomUid 1..1 MS and
    accession 0..* MS
* identifier[dicomUid] ^short = "DICOM Study Instance UID"
* identifier[dicomUid] ^definition = "The study's DICOM Study Instance UID, expressed as an identifier with system `urn:dicom:uid` and a value of the form `urn:oid:...`."
* identifier[dicomUid] ^patternIdentifier.system = "urn:dicom:uid"
* identifier[dicomUid].system 1..1
* identifier[dicomUid].system = "urn:dicom:uid" (exactly)
* identifier[dicomUid].value 1..1
* identifier[accession] ^short = "Accession Number (required when known)"
* identifier[accession] ^definition = "The order's Accession Number associated with the study, using `type = http://terminology.hl7.org/CodeSystem/v2-0203#ACSN`, `value` set to the Accession Number, and `system` set to the assigning authority URI when known. Servers SHALL populate this slice whenever the study's Accession Number is known."
* identifier[accession] ^patternIdentifier.type = $V2-0203#ACSN
* identifier[accession].type 1..1 MS
* identifier[accession].type = $V2-0203#ACSN
* identifier[accession].system 0..1 MS
* identifier[accession].value 1..1 MS
* status MS
* status ^short = "registered | available | cancelled | entered-in-error | unknown"
* status ^definition = "The current state of the study. When `status` is `available`, at least one SMART WADO-RS Endpoint (`endpoint[wadoRs]`) SHALL be present."
* subject only Reference(Patient)
* subject MS
* subject ^short = "The patient this study belongs to"
* basedOn MS
* basedOn ^short = "Order(s) the study fulfills (SHOULD include Accession Number in basedOn.identifier when known)"
* basedOn ^definition = "The order(s) or request(s) that the imaging study fulfills. When the server knows a study's Accession Number, in addition to populating `identifier[accession]` (`SHALL`), it SHOULD also populate a `basedOn` reference carrying `basedOn.identifier` (`type = http://terminology.hl7.org/CodeSystem/v2-0203#ACSN`, `value` set to the Accession Number, and `system` set to the assigning authority URI when known) for wider compatibility with FHIR R6 and IHE MADO."
* modality 1..* MS
* endpoint 0..* MS
* endpoint ^slicing.discriminator.type = #value
* endpoint ^slicing.discriminator.path = "resolve().connectionType"
* endpoint ^slicing.rules = #open
* endpoint ^short = "Endpoints for this study (SMART WADO-RS endpoint required when status is available)"
* endpoint ^definition = "Endpoints for interacting with the study. When `status` is `available`, at least one endpoint SHALL conform to the SMART WADO-RS Endpoint profile (`wadoRs` slice) at the study level; studies with no retrievable instances (such as `registered` or `cancelled`) MAY omit `endpoint`. Additional endpoints (such as an image viewer) MAY also be present."
* endpoint contains wadoRs 0..* MS
* endpoint[wadoRs] only Reference(SmartWadoEndpoint)
* endpoint[wadoRs] ^short = "WADO-RS endpoint(s) for retrieving this study's DICOM data"
* endpoint[wadoRs] ^definition = "Endpoint(s) conforming to the SMART WADO-RS Endpoint profile, from which the app retrieves DICOM data using its SMART token. Required (`1..*`) when `ImagingStudy.status` is `available`. Endpoints may be response-local Bundle entries, contained resources, or separately addressable resources."
* started MS
* numberOfSeries MS
* numberOfInstances MS
* series MS
* series.uid MS
* series.number MS
* series.modality MS
* series.numberOfInstances MS
* series.instance MS
* series.instance.uid MS
* series.instance.number MS
* series.instance.sopClass MS

Invariant: smart-wado-endpoint-when-available
Description: "When status is 'available', at least one SMART WADO-RS endpoint is required."
Severity: #error
Expression: "status = 'available' implies endpoint.resolve().where(connectionType.system = 'http://terminology.hl7.org/CodeSystem/endpoint-connection-type' and connectionType.code = 'dicom-wado-rs').exists()"

Profile: SmartWadoEndpoint
Parent: Endpoint
Id: smart-wado-endpoint
Title: "SMART WADO-RS Endpoint"
Description: """
A DICOM WADO-RS endpoint referenced from a SMART ImagingStudy.

The `address` is a WADO-RS base URL: the app appends
`/studies/{Study Instance UID}` (and optionally deeper paths) and presents
the same SMART access token used for the authorized FHIR request.

The address may be a capability URL carrying study-specific permissions bound
to that token. For these response-specific Endpoints, servers SHOULD use a
Bundle entry with a `urn:uuid:...` fullUrl, referenced by ImagingStudy.endpoint.
The UUID identifies the Endpoint within the response; `address` remains the
HTTPS retrieval base URL. See [Finding studies](specification.html#finding-studies).
"""
* status MS
* connectionType MS
* connectionType = $ConnType#dicom-wado-rs
* address MS
* address ^short = "WADO-RS base URL (append /studies/{uid} to retrieve)"
