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
Requirements for the Imaging FHIR Server. The shared authorization arrangement and
scope mapping are specified in [Cooperating servers](specification.html#cooperating-servers)
and [Imaging permissions](specification.html#imaging-permissions). WADO-RS retrieval
is specified in [Retrieving images](specification.html#retrieving-images).
"""
* rest[0].mode = #server
* rest[0].security.description = """
FHIR requests carry a SMART access token issued by the Authorization Server configured
for the deployment. Requirements for supported authorization modes and token acquisition
are specified in [Authorization](specification.html#authorization). The required
single-token baseline and optional DPoP or per-endpoint OAuth Token Exchange arrangements
are specified in [Cooperating servers](specification.html#cooperating-servers).
Token validation and access enforcement on every request are specified in
[Imaging Server authorization](specification.html#imaging-server-authorization);
read and search permissions are specified in
[Imaging permissions](specification.html#imaging-permissions).
Discovery of the endpoint's Patient-reference base is specified in
[Patient-reference base](patient-identity.html#patient-reference-base);
grant binding and per-endpoint patient context are specified in
[Endpoint patient context](patient-identity.html#endpoint-patient-context).
Discovery of supported grants through `grant_types_supported` and token-endpoint
authentication metadata is specified in [Discovery](specification.html#discovery).
Clients protect tokens and limit their recipients as specified in
[Client token handling](specification.html#app-token-handling).
Retrieval accepts any currently valid token from the configured Authorization Server
that authorizes the requested access, including refreshed or newly issued tokens;
it does not require the token used for the search. See
[Retrieving images](specification.html#retrieving-images).
"""
* rest[0].resource[0].type = #ImagingStudy
* rest[0].resource[0].supportedProfile = Canonical(SmartImagingStudy)
* rest[0].resource[0].documentation = """
The Imaging FHIR Server SHALL support searching ImagingStudy by the standard `patient`
parameter according to [Patient references](patient-identity.html#patient-references),
alone and in combination with `identifier` (a DICOM Study Instance UID in
`urn:oid:...` form). The Imaging FHIR Server SHOULD support `patient` + `_lastUpdated`.
Supporting servers SHALL document their timestamp-update behavior in their developer
documentation.
The Imaging FHIR Server SHALL support `_include=ImagingStudy:endpoint`
for referenced study- and series-level Endpoints in the search Bundle. Clients SHALL
resolve Endpoints provided as response-local Bundle entries, separately addressable
resources included in the Bundle, or contained resources, including UUID URN and
REST references. The server MAY use response-local Endpoints with urn:uuid fullUrl
values and SHALL include each response-local Endpoint on the same Bundle page as
each referencing study, even without an _include request.

Study representation, released inventory, endpoint coverage, and status interpretation
are specified in [Finding studies](specification.html#finding-studies).

Searches SHALL enforce the access rules in
[Imaging Server authorization](specification.html#imaging-server-authorization)
and [Finding studies](specification.html#finding-studies): patient-scoped requests
outside the granted patient context and backend requests for unauthorized patients
receive 403 Forbidden. Results and included Endpoints SHALL exclude unauthorized
studies. Neither authorization mode requires population-wide search.

When a backing source is slow or unavailable, the Imaging FHIR Server MAY return
available matches with an OperationOutcome entry whose `Bundle.entry.search.mode`
is `outcome` and `OperationOutcome.issue.code` is `incomplete`. The Imaging FHIR
Server SHALL describe the complete released series and instance inventory for each
returned study, including when the set of study matches is incomplete.
The Imaging FHIR Server MAY instead respond `503 Service Unavailable` with a
`Retry-After` header. Client retry guidance is specified in
[Finding studies](specification.html#finding-studies).
"""
* rest[0].resource[0].interaction[0].code = #search-type
* rest[0].resource[0].searchInclude[0] = "ImagingStudy:endpoint"
* rest[0].resource[0].searchParam[0].name = "patient"
* rest[0].resource[0].searchParam[0].definition = "http://hl7.org/fhir/SearchParameter/clinical-patient"
* rest[0].resource[0].searchParam[0].type = #reference
* rest[0].resource[0].searchParam[0].documentation = "The Imaging FHIR Server SHALL support a Patient reference following [Patient references](patient-identity.html#patient-references), alone and with `identifier`, and SHOULD support it with `_lastUpdated`."
* rest[0].resource[0].searchParam[1].name = "identifier"
* rest[0].resource[0].searchParam[1].definition = "http://hl7.org/fhir/SearchParameter/clinical-identifier"
* rest[0].resource[0].searchParam[1].type = #token
* rest[0].resource[0].searchParam[1].documentation = "A DICOM Study Instance UID in `urn:oid:...` form, used with `patient` to look up a specific study."
* rest[0].resource[0].searchParam[2].name = "_lastUpdated"
* rest[0].resource[0].searchParam[2].definition = "http://hl7.org/fhir/SearchParameter/Resource-lastUpdated"
* rest[0].resource[0].searchParam[2].type = #date
* rest[0].resource[0].searchParam[2].documentation = "The Imaging FHIR Server SHOULD support this parameter with `patient` to filter studies by their FHIR resource update timestamp, e.g. `_lastUpdated=gt2023-04-17T04:00:00Z`. Supporting servers SHALL document their timestamp-update behavior in their developer documentation."
