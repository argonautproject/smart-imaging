Instance: smart-imaging-server
InstanceOf: CapabilityStatement
Usage: #definition
Title: "SMART Imaging Access Server"
Description: "Requirements for a SMART Imaging Access FHIR endpoint."
* name = "SmartImagingAccessServer"
* status = #draft
* date = "2026-11-06"
* kind = #requirements
* fhirVersion = #4.0.1
* format = #json
* description = """
Requirements for the Imaging FHIR Server. WADO-RS retrieval and SMART token
validation are specified in [Retrieving images](specification.html#retrieving-images)
and [Authorization](specification.html#authorization).
"""
* rest[0].mode = #server
* rest[0].security.description = """
FHIR requests carry a SMART access token issued by the Authorization Server configured
for the deployment. Deployments SHALL support SMART App Launch, SMART Backend
Services, or both, as defined in [Authorization](specification.html#authorization).
Supported modes are advertised for each imaging endpoint with the corresponding
capability http://fhir.org/argonaut/smart-imaging/capabilities/app-launch or
http://fhir.org/argonaut/smart-imaging/capabilities/backend-services (or both).
The Authorization Server SHALL authorize the participating resource servers for
the flow, and both the Imaging FHIR Server and DICOMweb Server SHALL verify
that the token is active and authorized for use at their endpoint. The Imaging
Server enforces granted scopes and underlying access restrictions. App Launch
requests SHALL match the token's patient context. Backend Services requests
SHALL be limited to the client's pre-authorized access; system/ImagingStudy.rs
does not grant access to all patients or studies. Missing patient context SHALL
NOT imply system-level access. The Imaging FHIR Server SHALL designate only
WADO-RS Endpoint addresses operated within the deployment's authorization
arrangement. Clients send their SMART access token only to the Authorization
Server, the authorized Clinical FHIR Server, the discovered or configured
Imaging FHIR Server, and the SMART WADO-RS endpoints designated by that Imaging
FHIR Server (never to non-WADO-RS Endpoint addresses on the study, untrusted
resources, or cross-origin redirects). On every WADO-RS retrieval, the DICOMweb
Server SHALL validate the presented token, enforce all applicable study and
series restrictions, and accept any currently valid SMART token from the
Authorization Server that authorizes access to the study (including tokens
obtained through refresh or subsequent token requests). See
[Retrieving images](specification.html#retrieving-images).
"""
* rest[0].resource[0].type = #ImagingStudy
* rest[0].resource[0].supportedProfile = Canonical(SmartImagingStudy)
* rest[0].resource[0].documentation = """
The server SHALL support searching ImagingStudy by patient, alone and in
combination with `identifier` (a DICOM Study Instance UID in `urn:oid:...`
form). The server SHOULD also support searching by `patient` in combination
with `_lastUpdated`. Servers that support it SHALL document in
their developer documentation which changes update `_lastUpdated`.
The server SHALL support `_include=ImagingStudy:endpoint`
so apps receive the WADO-RS Endpoint for each study. Apps SHALL resolve Endpoints
provided as response-local Bundle entries, separately addressable resources
included in the Bundle, or contained resources. Servers MAY use response-local
Endpoints. A response-local Endpoint uses a `urn:uuid` value in
`Bundle.entry.fullUrl`; the server SHALL include it on
the same Bundle page as each referencing study, even without an `_include` request.

Searches SHALL enforce the access rules in [Finding studies](specification.html#finding-studies):
patient-context mismatches and backend requests for unauthorized patients receive
403 Forbidden. Results and included Endpoints SHALL exclude unauthorized studies.
When access restrictions exclude only specific series or instances within a
study, the server MAY either withhold the study or expose the authorized subset
consistently across `ImagingStudy` and WADO-RS retrieval. Neither authorization
mode requires population-wide search.

If results are not yet available (for example, the server is querying an
underlying PACS), the server MAY respond `503` with a `Retry-After` header;
the app retries after the indicated number of seconds. When some results are available while another source is slow or unreachable, the
server MAY return the available matches alongside an `OperationOutcome` entry
with `search.mode = outcome` and `issue.code = incomplete`. An app can repeat
the search later to obtain the remaining results.
"""
* rest[0].resource[0].interaction[0].code = #search-type
* rest[0].resource[0].searchInclude[0] = "ImagingStudy:endpoint"
* rest[0].resource[0].searchParam[0].name = "patient"
* rest[0].resource[0].searchParam[0].definition = "http://hl7.org/fhir/SearchParameter/clinical-patient"
* rest[0].resource[0].searchParam[0].type = #reference
* rest[0].resource[0].searchParam[0].documentation = "The patient whose studies are requested. SHALL be supported alone and in combination with `identifier`, and SHOULD be supported in combination with `_lastUpdated`."
* rest[0].resource[0].searchParam[1].name = "identifier"
* rest[0].resource[0].searchParam[1].definition = "http://hl7.org/fhir/SearchParameter/clinical-identifier"
* rest[0].resource[0].searchParam[1].type = #token
* rest[0].resource[0].searchParam[1].documentation = "A DICOM Study Instance UID in `urn:oid:...` form, used with `patient` to look up a specific study."
* rest[0].resource[0].searchParam[2].name = "_lastUpdated"
* rest[0].resource[0].searchParam[2].definition = "http://hl7.org/fhir/SearchParameter/Resource-lastUpdated"
* rest[0].resource[0].searchParam[2].type = #date
* rest[0].resource[0].searchParam[2].extension[0].url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest[0].resource[0].searchParam[2].extension[0].valueCode = #SHOULD
* rest[0].resource[0].searchParam[2].documentation = "SHOULD be supported with `patient` to filter for `ImagingStudy` resources created or modified since a given timestamp (e.g., `_lastUpdated=gt2023-04-17T04:00:00Z`). Servers supporting `_lastUpdated` SHALL document in their developer documentation which change types update `_lastUpdated`. Tracks changes to the FHIR `ImagingStudy` resource rather than in-place DICOM edits or removed studies."
