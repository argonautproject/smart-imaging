Profile: SmartImagingStudy
Parent: ImagingStudy
Id: smart-imaging-study
Title: "SMART ImagingStudy"
Description: """
An ImagingStudy returned by a SMART Imaging Access server, with a DICOM Study
Instance UID identifier and, when the study status is `available`, at least one
SMART WADO-RS Endpoint for retrieving its DICOM data. When `status` is
`available`, the study SHALL list its released series (with `uid`) and each
series SHALL list its released instances (with `uid` and `sopClass`).
"""
* obeys smart-wado-endpoint-when-available
* obeys smart-hierarchy-when-available
* identifier 1..* MS
* identifier ^slicing.discriminator.type = #value
* identifier ^slicing.discriminator.path = "system"
* identifier ^slicing.rules = #open
* identifier contains dicomUid 1..1 MS
* identifier[dicomUid] ^short = "DICOM Study Instance UID"
* identifier[dicomUid] ^definition = "The study's DICOM Study Instance UID, expressed as an identifier with system `urn:dicom:uid` and a value of the form `urn:oid:...`."
* identifier[dicomUid].system 1..1
* identifier[dicomUid].system = "urn:dicom:uid" (exactly)
* identifier[dicomUid].value 1..1
* status MS
* status ^short = "registered | available | cancelled | entered-in-error | unknown"
* status ^definition = "The current state of the study. When `status` is `available`, at least one SMART WADO-RS Endpoint (`endpoint[wadoRs]`) SHALL be present."
* subject only Reference(Patient)
* subject MS
* subject ^short = "The patient this study belongs to"
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
* series ^short = "Series in the released study (Must Support; populated when the study has series)"
* series ^definition = "Series included in the released study (`0..* MS`; populated whenever the study has series in the released subset). When access policy restricts specific series or instances, `series` and `series.instance` SHALL reflect the authorized subset."
* series.uid MS
* series.number MS
* series.modality MS
* series.numberOfInstances MS
* series.endpoint MS
* series.endpoint ^short = "Series-specific endpoint(s) (WADO-RS series.endpoint overrides study WADO-RS endpoint for this series)"
* series.endpoint ^definition = "Optional endpoint(s) for this series. Per FHIR R4, a `series.endpoint` overrides a study-level `endpoint` of the same `connectionType` for that series. Any WADO-RS endpoint (`connectionType = dicom-wado-rs`) on `series.endpoint` SHALL conform to `SmartWadoEndpoint`, be designated by the trusted Imaging FHIR Server, and support series- and instance-level WADO-RS retrieval for that series. A series-level endpoint does not replace the required study-level WADO-RS endpoint on an `available` study."
* series.instance MS
* series.instance ^short = "Instances in the series (Must Support; populated for each instance in the series)"
* series.instance ^definition = "Instances included in the series (`0..* MS`), giving clients a complete inventory of SOP Instance UIDs and SOP Classes upfront (for example, to retrieve a single slice, waveform, structured report, or Key Object Selection document). Compatible with IHE MADO (including its `MadoKeyObjectDocumentTitle` extension for conveying Key Object Selection document titles)."
* series.instance.uid MS
* series.instance.number MS
* series.instance.sopClass MS

Invariant: smart-wado-endpoint-when-available
Description: "When status is 'available', at least one SMART WADO-RS endpoint is required."
Severity: #error
Expression: "status = 'available' implies endpoint.resolve().where(connectionType.system = 'http://terminology.hl7.org/CodeSystem/endpoint-connection-type' and connectionType.code = 'dicom-wado-rs').exists()"

Invariant: smart-hierarchy-when-available
Description: "When status is 'available', the study lists its released series and each series lists its released instances."
Severity: #error
Expression: "status = 'available' implies (series.exists() and series.all(instance.exists()))"

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
