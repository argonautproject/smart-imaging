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
Requirements for the Imaging FHIR Server. WADO-RS retrieval and SMART token
validation are specified in [Retrieving images](specification.html#retrieving-images)
and [Authorization](specification.html#authorization).
"""
* rest[0].mode = #server
* rest[0].security.description = """
FHIR requests carry a SMART access token issued by the Authorization Server configured
for the deployment. Requirements for supported authorization modes, token acquisition,
token validation, access enforcement, and capability issuance are specified in
[Authorization](specification.html#authorization). Mode-specific discovery requirements
are specified in [Discovery](specification.html#discovery). Requirements for presenting
the same token on retrieval, validating capabilities and their token binding, and
enforcing capability lifetime and revocation are specified in
[Retrieving images](specification.html#retrieving-images).
"""
* rest[0].resource[0].type = #ImagingStudy
* rest[0].resource[0].supportedProfile = Canonical(SmartImagingStudy)
* rest[0].resource[0].documentation = """
The server SHALL support searching ImagingStudy by Patient logical ID using relative
or absolute Patient references under FHIR reference-search rules, alone and in
combination with `_lastUpdated` or `identifier` (a DICOM Study Instance UID
in `urn:oid:...` form). The server SHALL support `_include=ImagingStudy:endpoint`
for referenced study- and series-level Endpoints in the search Bundle. Apps SHALL
resolve Endpoints provided as response-local Bundle entries, separately addressable
resources included in the Bundle, or contained resources. Response-specific
capability Endpoints SHOULD use urn:uuid fullUrl values; the server SHALL include
them on the same Bundle page as each referencing study, even without an _include request.

Study representation, released inventory, endpoint coverage, and status interpretation
are specified in [Finding studies](specification.html#finding-studies).

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
* rest[0].resource[0].searchParam[0].documentation = "The server SHALL support search by Patient logical ID using relative or absolute Patient references under the FHIR reference-search rules, alone and in combination with `_lastUpdated` or `identifier`. See [Finding studies](specification.html#patient-references)."
* rest[0].resource[0].searchParam[1].name = "identifier"
* rest[0].resource[0].searchParam[1].definition = "http://hl7.org/fhir/SearchParameter/clinical-identifier"
* rest[0].resource[0].searchParam[1].type = #token
* rest[0].resource[0].searchParam[1].documentation = "A DICOM Study Instance UID in `urn:oid:...` form, used with `patient` to look up a specific study."
* rest[0].resource[0].searchParam[2].name = "_lastUpdated"
* rest[0].resource[0].searchParam[2].definition = "http://hl7.org/fhir/SearchParameter/Resource-lastUpdated"
* rest[0].resource[0].searchParam[2].type = #date
* rest[0].resource[0].searchParam[2].documentation = "Used with `patient` to fetch only studies updated after a given time, e.g. `_lastUpdated=gt2023-04-17T04:00:00Z`."
