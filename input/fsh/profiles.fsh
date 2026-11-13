Profile: SmartImagingStudy
Parent: ImagingStudy
Id: smart-imaging-study
Title: "SMART ImagingStudy"
Description: """
An ImagingStudy returned by a SMART Imaging Access server, with a DICOM Study
Instance UID identifier and optional study- and series-level Endpoints.
WADO-RS Endpoints conform to the SMART WADO-RS Endpoint profile; other endpoint
types are also permitted. Endpoint coverage for released series is specified in
[Finding studies](specification.html#finding-studies).
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
* status ^comment = "The available status indicates that associated instances exist, not that they are accessible through WADO-RS. Study metadata may be returned without retrieval endpoints, subject to access policy."
* subject only Reference(Patient)
* subject MS
* subject ^short = "The patient this study belongs to"
* subject ^definition = "The Patient this study belongs to. The Patient-reference namespace and reference forms follow [Patient-reference base](patient-identity.html#patient-reference-base) and [Patient references](patient-identity.html#patient-references)."
* modality 1..* MS
* endpoint 0..* MS
* endpoint only Reference(Endpoint)
* endpoint ^short = "Study-level endpoints, including WADO-RS and other connection types"
* endpoint ^definition = "Endpoints associated with this study. WADO-RS endpoints conform to the SMART WADO-RS Endpoint profile and provide study-level coverage for released series; other connection types are permitted. Endpoints may be response-local Bundle entries, contained resources, or separately addressable resources."
* endpoint ^slicing.discriminator.type = #pattern
* endpoint ^slicing.discriminator.path = "resolve().connectionType"
* endpoint ^slicing.rules = #open
* endpoint contains wadoRs 0..* MS
* endpoint[wadoRs] only Reference(SmartWadoEndpoint)
* endpoint[wadoRs] ^short = "SMART WADO-RS endpoints providing study-level coverage"
* endpoint[wadoRs] ^definition = "SMART WADO-RS endpoints providing full-study retrieval of all released series and instances. A direct series-level WADO-RS endpoint overrides study-level coverage for series and instance requests for that series."
* started MS
* numberOfSeries MS
* numberOfInstances MS
* series 0..* MS
* series ^comment = "The Imaging FHIR Server SHALL populate every released series and its UID. Released content is content made available for retrieval under the current authorization; the presence of metadata alone does not establish release."
* series.uid MS
* series.number 0..1 MS
* series.number ^comment = "The Imaging FHIR Server SHALL populate this element when its value is present in the source."
* series.modality MS
* series.endpoint 0..* MS
* series.endpoint only Reference(Endpoint)
* series.endpoint ^short = "Series-level endpoints, including WADO-RS and other connection types"
* series.endpoint ^definition = "Endpoints associated with this series. WADO-RS endpoints conform to the SMART WADO-RS Endpoint profile; other connection types are permitted. A released series has WADO-RS endpoint coverage directly at this level or inherited from a study-level WADO-RS endpoint."
* series.endpoint ^slicing.discriminator.type = #pattern
* series.endpoint ^slicing.discriminator.path = "resolve().connectionType"
* series.endpoint ^slicing.rules = #open
* series.endpoint contains wadoRs 0..* MS
* series.endpoint[wadoRs] only Reference(SmartWadoEndpoint)
* series.endpoint[wadoRs] ^short = "SMART WADO-RS endpoints providing direct series coverage"
* series.endpoint[wadoRs] ^definition = "SMART WADO-RS endpoints providing direct access to this released series and its instances. For series and instance requests, a direct WADO-RS endpoint overrides study-level WADO-RS coverage for this series. Direct series-level WADO-RS endpoints are not required when the series inherits WADO-RS endpoint coverage from the study level."
* series.numberOfInstances MS
* series.instance 0..* MS
* series.instance ^comment = "The Imaging FHIR Server SHALL populate every released instance, including its UID and SOP Class. This requirement does not require an instance inventory for series described only as known, unretrievable metadata."
* series.instance.uid MS
* series.instance.number 0..1 MS
* series.instance.number ^comment = "The Imaging FHIR Server SHALL populate this element when its value is present in the source."
* series.instance.sopClass MS

Profile: SmartWadoEndpoint
Parent: Endpoint
Id: smart-wado-endpoint
Title: "SMART WADO-RS Endpoint"
Description: """
A DICOM WADO-RS endpoint referenced at study or series level from a SMART ImagingStudy.

The `address` is an opaque WADO-RS base URL. The client preserves its path
prefix when appending the applicable study, series, or instance retrieval path.
The endpoint participates in the single-token arrangement specified in
[Cooperating servers](specification.html#cooperating-servers). The DICOMweb
Server SHALL accept any currently valid token from the configured Authorization
Server that authorizes the requested access; it need not be the token used
for the search. Retrieval permissions are specified in
[Imaging permissions](specification.html#imaging-permissions).

The DICOMweb Server SHALL support series- and instance-level retrieval at
this endpoint. When advertised at study level, the endpoint covers all released
series and instances and SHALL support full-study retrieval. Retrieval remains
subject to the token and access checks in
[Imaging Server authorization](specification.html#imaging-server-authorization)
and the denial requirements in [Retrieving images](specification.html#retrieving-images).

Endpoints may be response-local Bundle entries with a `urn:uuid:...` fullUrl,
referenced by ImagingStudy.endpoint or ImagingStudy.series.endpoint.
The UUID identifies the Endpoint within the response; `address` remains the
HTTPS retrieval base URL. The Imaging FHIR Server SHALL include each response-local
Endpoint on the same Bundle page as each referencing study, even without `_include`.
See [Finding studies](specification.html#finding-studies).

An address may carry optional signed study context, as illustrated in the
non-normative [authorization patterns](authorization-patterns.html).
Such context is not a bearer permission and does not replace validation of the
current token and current access policy.
"""
* status MS
* connectionType MS
* connectionType = $ConnType#dicom-wado-rs
* address MS
* address ^short = "WADO-RS base URL for constructing retrieval paths"
