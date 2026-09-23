Instance: smart-imaging-server
InstanceOf: CapabilityStatement
Usage: #definition
Title: "SMART Imaging Access Server"
Description: "Requirements for a SMART Imaging Access FHIR endpoint."
* name = "SmartImagingAccessServer"
* status = #draft
* date = "2026-09-23"
* kind = #requirements
* fhirVersion = #4.0.1
* format = #json
* description = """
Requirements for the Imaging FHIR Server, the FHIR function of the Imaging Server. In addition to the FHIR
behavior described here, the server hosts or links to WADO-RS endpoints as
described in [Retrieving images](specification.html#retrieving-images), and
validates SMART access tokens as described in
[Authorization](specification.html#authorization).
"""
* rest[0].mode = #server
* rest[0].security.description = """
FHIR requests carry a SMART access token issued by the Authorization Server configured
for the deployment. Deployments SHALL support SMART App Launch, SMART Backend
Services, or both, as defined in [Authorization](specification.html#authorization).
Supported modes are advertised for each imaging endpoint with the corresponding
capability http://fhir.org/argonaut/smart-imaging/capabilities/app-launch or
http://fhir.org/argonaut/smart-imaging/capabilities/backend-services (or both).
The Imaging Server validates the token and enforces granted scopes and underlying
access restrictions. App Launch requests SHALL match the token's patient context.
Backend Services requests SHALL be limited to the client's pre-authorized access;
system/ImagingStudy.rs does not grant access to all patients or studies.
Missing patient context SHALL NOT imply system-level access. Every WADO-RS
request SHALL carry the same SMART access token used for the authorized FHIR
request. A returned Endpoint address may be a capability URL; the DICOMweb
Server then validates the token, the capability, and their binding and enforces
all applicable restrictions. Capability issuance SHALL be limited to the data
and operations authorized by the FHIR request. Each retrieval SHALL enforce the
validation, lifetime, and revocation requirements in
[Retrieving images](specification.html#retrieving-images).
"""
* rest[0].resource[0].type = #ImagingStudy
* rest[0].resource[0].supportedProfile = Canonical(SmartImagingStudy)
* rest[0].resource[0].documentation = """
The server SHALL support searching ImagingStudy by patient, alone and in
combination with `_lastUpdated` and `identifier` (a DICOM Study Instance UID
in `urn:oid:...` form). The server SHALL support `_include=ImagingStudy:endpoint`
so apps receive the WADO-RS Endpoint for each study. Apps SHALL resolve Endpoints
provided as response-local Bundle entries, separately addressable resources
included in the Bundle, or contained resources. Response-specific capability
Endpoints SHOULD use urn:uuid fullUrl values; the server SHALL include them on
the same Bundle page as each referencing study, even without an _include request.

Searches SHALL enforce the access rules in [Finding studies](specification.html#finding-studies):
patient-context mismatches and backend requests for unauthorized patients receive
403 Forbidden. Results and included Endpoints SHALL exclude unauthorized studies.
Neither authorization mode requires population-wide search.

If results are not yet available (for example, the server is querying an
underlying PACS), the server MAY respond `503` with a `Retry-After` header;
the app retries after the indicated number of seconds.
"""
* rest[0].resource[0].interaction[0].code = #search-type
* rest[0].resource[0].searchInclude[0] = "ImagingStudy:endpoint"
* rest[0].resource[0].searchParam[0].name = "patient"
* rest[0].resource[0].searchParam[0].definition = "http://hl7.org/fhir/SearchParameter/clinical-patient"
* rest[0].resource[0].searchParam[0].type = #reference
* rest[0].resource[0].searchParam[0].documentation = "The patient whose studies are requested. SHALL be supported alone and in combination with `_lastUpdated` or `identifier`."
* rest[0].resource[0].searchParam[1].name = "identifier"
* rest[0].resource[0].searchParam[1].definition = "http://hl7.org/fhir/SearchParameter/clinical-identifier"
* rest[0].resource[0].searchParam[1].type = #token
* rest[0].resource[0].searchParam[1].documentation = "A DICOM Study Instance UID in `urn:oid:...` form, used with `patient` to look up a specific study."
* rest[0].resource[0].searchParam[2].name = "_lastUpdated"
* rest[0].resource[0].searchParam[2].definition = "http://hl7.org/fhir/SearchParameter/Resource-lastUpdated"
* rest[0].resource[0].searchParam[2].type = #date
* rest[0].resource[0].searchParam[2].documentation = "Used with `patient` to fetch only studies updated after a given time, e.g. `_lastUpdated=gt2023-04-17T04:00:00Z`."
