Extension: RequiresAccessToken
Id: requires-access-token
Title: "Requires Access Token"
Description: """
Indicates whether retrieving data from this endpoint requires the same
access token that authorized the request which returned the endpoint.

When `true` on a WADO-RS Endpoint returned by a SMART Imaging Access server,
the app presents the same SMART access token it used for the ImagingStudy
search when it retrieves DICOM data from the endpoint. The URL may also carry
a token-bound capability whose permissions and binding are enforced alongside
the token checks; a token-protected endpoint need not use a capability URL.

When `false`, the endpoint URL carries a bearer capability and the app
follows it without sending its SMART access token. The URL is a credential,
not an indication that the data is public. Both values apply equally to
SMART App Launch and SMART Backend Services. A bearer capability SHALL expire
no later than the SMART token authorizing its issuance.
See [Retrieving images](specification.html#retrieving-images) for enforcement,
lifetime, and early-revocation requirements.

This mirrors the `requiresAccessToken` concept from the
[FHIR Asynchronous Bulk Data Request Pattern](https://hl7.org/fhir/async-bulk.html),
expressed as an extension so it can travel on an Endpoint resource.
"""
Context: Endpoint
* value[x] only boolean
* value[x] 1..1

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
* endpoint ^definition = "At least one Endpoint (contained or external) conforming to the SMART WADO-RS Endpoint profile, from which the app can retrieve the study's DICOM data."
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
`/studies/{Study Instance UID}` (and optionally deeper paths) to retrieve
DICOM data. The `requires-access-token` extension says whether the app
presents its SMART access token on those requests (`true`) or follows a
bearer capability URL without that token (`false`). A token-protected URL may
also carry a token-bound capability; the server then enforces both sets of
restrictions. Both forms can be returned
for clients using either SMART App Launch or SMART Backend Services.
"""
* status MS
* connectionType MS
* connectionType = $ConnType#dicom-wado-rs
* address MS
* address ^short = "WADO-RS base URL (append /studies/{uid} to retrieve)"
* extension contains RequiresAccessToken named requiresAccessToken 1..1 MS
* extension[requiresAccessToken] ^short = "Whether WADO-RS requests use the same SMART access token"
