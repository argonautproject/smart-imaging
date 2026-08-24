Instance: smart-imaging-server
InstanceOf: CapabilityStatement
Usage: #definition
Title: "SMART Imaging Access Server"
Description: "Requirements for a SMART Imaging Access FHIR endpoint."
* name = "SmartImagingAccessServer"
* status = #draft
* date = "2026-08-21"
* kind = #requirements
* fhirVersion = #4.0.1
* format = #json
* description = """
Requirements for the Imaging Server's FHIR endpoint. In addition to the FHIR
behavior described here, the server hosts or links to WADO-RS endpoints as
described in [Retrieving images](specification.html#retrieving-images), and
validates SMART access tokens as described in
[Authorization](specification.html#authorization).
"""
* rest[0].mode = #server
* rest[0].security.description = "Requests carry a SMART on FHIR access token issued by the organization's authorization server. The Imaging Server validates the token through SMART Token Introspection (or internally, when operated as one system with the authorization server) and enforces patient context and scopes."
* rest[0].resource[0].type = #ImagingStudy
* rest[0].resource[0].supportedProfile = Canonical(SmartImagingStudy)
* rest[0].resource[0].documentation = """
The server SHALL support searching ImagingStudy by patient, alone and in
combination with `_lastUpdated` and `identifier` (a DICOM Study Instance UID
in `urn:oid:...` form). The server SHALL support `_include=ImagingStudy:endpoint`
so apps receive the WADO-RS Endpoint for each study, whether contained or external.

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
