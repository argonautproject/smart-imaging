Profile: SmartImagingStudy
Parent: ImagingStudy
Id: smart-imaging-study
Title: "SMART ImagingStudy"
Description: """
An ImagingStudy as returned by a SMART Imaging Access server.

Guarantees the two things an app needs from every study: the DICOM Study
Instance UID (as an identifier) and at least one WADO-RS Endpoint from which
the study's DICOM data can be retrieved.
"""
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
* subject only Reference(Patient)
* subject MS
* subject ^short = "The patient this study belongs to"
* modality 1..* MS
* endpoint 1..* MS
* endpoint only Reference(SmartWadoEndpoint)
* endpoint ^short = "WADO-RS endpoint(s) for retrieving this study's DICOM data"
* endpoint ^definition = "At least one Endpoint conforming to the SMART WADO-RS Endpoint profile, from which the app retrieves DICOM data using its SMART token. Endpoints may be response-local Bundle entries, contained resources, or separately addressable resources."
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
