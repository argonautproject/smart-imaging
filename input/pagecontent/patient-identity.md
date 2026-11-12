This page defines the normative requirements for Patient namespaces, endpoint-specific Patient authorization, Patient references, and cross-endpoint resource linkage. The [Specification](specification.html) defines the discovery, authorization, search, and retrieval workflow. The [worked examples](#worked-examples) below are non-normative; [Imaging Identifiers](identifiers.html) provides non-normative DICOM and FHIR identifier background.

<a id="patient-reference-base"></a>

### Patient-reference metadata and publication

This guide defines `patient_reference_base` as an optional discovery property containing the absolute FHIR base URL of the endpoint's Patient namespace. It appears at the top level of `.well-known/smart-configuration` and alongside `url` and `capabilities` in an `associated_endpoints` entry. When omitted, it defaults to the described endpoint's own FHIR base.

An Imaging FHIR Server using another server's Patient namespace SHALL publish that server's base as `patient_reference_base` in its discovery document. The named server is that endpoint's Patient anchor. For every endpoint they describe, Clinical and Imaging FHIR Servers SHALL publish the same effective Patient-reference base and capabilities in their own discovery document and peer `associated_endpoints` entries.

<a id="endpoint-patient-context"></a>

### Endpoint-specific Patient authorization

For `patient/` authorization involving an externally anchored endpoint or multiple FHIR endpoints, the Authorization Server SHALL bind the authorized Patient at each endpoint and communicate those bindings through SMART 2.2's experimental [`authorization_details`](https://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#experimental-authorization-details-for-multiple-servers-exp). Each `smart_on_fhir` entry identifies the applicable FHIR base URLs in `locations` and FHIR versions in `fhirVersions`.

A bare `patient` value identifies a Patient local to the entry's `locations` base. For an externally anchored endpoint, the Authorization Server SHALL supply the absolute Patient URL under its advertised Patient-reference base. URL-valued `patient` context is an extension defined by this guide. An omitted per-entry context inherits the top-level context under SMART's rules; the top-level `patient` belongs to the FHIR endpoint against which authorization was requested. Discovery metadata does not rebase an inherited bare value. The externally anchored endpoint needs its explicit absolute Patient context even when it is the only authorized FHIR endpoint.

The Authorization Server SHALL grant patient-scoped access at an endpoint only when it has established that endpoint's authorized Patient binding. Imaging Servers SHALL enforce the same binding using validated token information or their trusted authorization arrangement. Client-side identifier matching does not establish or expand that grant.

Patient-context matching compares Patient identity, including its namespace. The [token validation and access-enforcement requirements](specification.html#imaging-server-authorization) apply to both Imaging FHIR and DICOMweb requests.

<a id="patient-references"></a>

### Patient searches and subject references

**App.** The App determines the Imaging FHIR Server's Patient namespace from [Patient-reference metadata](#patient-reference-base). For `patient/` access, the App uses the Patient bound to that endpoint's authorization grant. For `user/` or `system/` access, the App can obtain the applicable Patient reference from prior context or an authorized lookup at the Patient-hosting server. Identifier-based lookup uses the identifier's system and value; zero or multiple matches need resolution before selecting a Patient.

When the Patient-reference base is the Imaging FHIR Server itself, the App can search with a local logical ID (`patient=123`), a typed relative reference (`patient=Patient/123`), or the corresponding absolute URL. For an externally anchored Imaging FHIR Server, the App SHALL use the anchor's absolute Patient URL when supplying the `patient` parameter. Relative references retain their normal FHIR resolution against the server being queried.

**Imaging FHIR Server.** The Imaging FHIR Server SHALL populate `ImagingStudy.subject` with a reference to the Patient in its effective Patient-reference base. For an external base, that reference SHALL be absolute. For its own base, the reference can be relative or absolute. Relative references in resources retain their normal FHIR resolution against the resource's hosting endpoint.

For user-level access, a launch Patient provides workflow context; the grant is bounded by the authorizing user's permissions. Backend Services has no required launch Patient and uses `system/` scopes within the client's pre-authorized access. These authorization rules are defined in the [Specification](specification.html#imaging-server-authorization).

<a id="cross-endpoint-linkage"></a>

### Cross-endpoint resource linkage

A FHIR resource's `id` identifies it within its resource type and hosting FHIR base. Deployment-side matching and mapping mechanisms are outside this guide's scope.

When communicating established resource linkage across FHIR endpoints, Apps and FHIR Servers SHALL identify corresponding resources using shared FHIR business identifiers, matching `Identifier.system` and `Identifier.value` through agreed assigning-authority mappings, or an absolute reference to the target resource. They SHALL NOT infer correspondence from equal logical IDs at different FHIR base URLs.

For `user/` and `system/` access, an App using this linkage to locate a corresponding Patient, study, order, or clinician SHALL use the applicable shared identifier or a known target reference within its authorized access.

The target server SHALL independently validate the token and authorize the requested operation.

[SMART 2.2 `fhirContext`](https://hl7.org/fhir/smart-app-launch/STU2.2/scopes-and-launch-context.html#fhir-context) can identify a launch resource by a relative reference or a business identifier. It can appear at the top level of a token response or within an endpoint-specific `authorization_details` entry. A relative reference in an endpoint-specific entry identifies the resource at the applicable FHIR base in `locations`. A business identifier supports correlation with a separate representation at another endpoint. Launch-patient context is carried in `patient`; SMART permits Patient entries in `fhirContext` only with an explicit non-`launch` role.

<a id="worked-examples"></a>

### Worked examples (non-normative)

All examples and explanations in this section are non-normative. They illustrate the requirements above.

#### Three deployment topologies

| Topology | Patient namespace | Example study subject |
|---|---|---|
| Unified clinical and imaging endpoint at `https://clinical.example.org/fhir` | Its own Patient resources | `Patient/123` |
| Imaging facade at `https://imaging.example.org/fhir`, anchored to clinical Patients | `https://clinical.example.org/fhir` | `https://clinical.example.org/fhir/Patient/123` |
| Independent imaging endpoint at `https://ris.example.org/fhir` | Its own Patient resources | `Patient/987` |

The deployment can associate clinical Patient `123` with RIS Patient `987` for the same person. Each logical ID belongs to its hosting endpoint. The imaging facade can map its anchor Patient URLs to PACS records through shared registration feeds, an MPI, or an authorized backend lookup without hosting Patient resources itself.

#### Discovering the Patient namespace

The following JSON excerpts omit unrelated SMART discovery fields. The local defaults in the topology table require no `patient_reference_base` property. The clinical endpoint advertises both an externally anchored facade and an independent Patient-hosting RIS at `https://clinical.example.org/fhir/.well-known/smart-configuration`:

```json
{
  "capabilities": ["launch-standalone"],
  "associated_endpoints": [
    {
      "url": "https://imaging.example.org/fhir",
      "capabilities": [
        "smart-imaging-access",
        "http://fhir.org/argonaut/smart-imaging/capabilities/app-launch"
      ],
      "patient_reference_base": "https://clinical.example.org/fhir"
    },
    {
      "url": "https://ris.example.org/fhir",
      "capabilities": [
        "smart-imaging-access",
        "http://fhir.org/argonaut/smart-imaging/capabilities/app-launch"
      ]
    }
  ]
}
```

The facade's own document at `https://imaging.example.org/fhir/.well-known/smart-configuration` describes the same capabilities and Patient-reference base:

```json
{
  "capabilities": [
    "smart-imaging-access",
    "http://fhir.org/argonaut/smart-imaging/capabilities/app-launch"
  ],
  "patient_reference_base": "https://clinical.example.org/fhir",
  "associated_endpoints": [
    {
      "url": "https://clinical.example.org/fhir",
      "capabilities": ["launch-standalone"]
    }
  ]
}
```


#### Establishing patient-scoped access

In this deployment, the Authorization Server establishes clinical Patient `123` and RIS Patient `987` as the authorized Patients for the same person. If it cannot establish the RIS binding, patient-scoped RIS access remains unauthorized. Imaging-only apps can receive their bindings without requesting Patient demographic scopes.

In this token response example, the original authorized FHIR endpoint is `https://clinical.example.org/fhir`. The clinical entry inherits the top-level scope; the imaging entries each specify their granted imaging scope. The facade entry supplies the clinical Patient's absolute URL using this guide's extension:

```json
{
  "access_token": "access-token-value-unguessable",
  "token_type": "Bearer",
  "scope": "launch/patient patient/DiagnosticReport.rs",
  "patient": "123",
  "authorization_details": [
    {
      "type": "smart_on_fhir",
      "locations": ["https://clinical.example.org/fhir"],
      "fhirVersions": ["4.0.1"],
      "patient": "123"
    },
    {
      "type": "smart_on_fhir",
      "locations": ["https://imaging.example.org/fhir"],
      "fhirVersions": ["4.0.1"],
      "scope": "patient/ImagingStudy.rs",
      "patient": "https://clinical.example.org/fhir/Patient/123"
    },
    {
      "type": "smart_on_fhir",
      "locations": ["https://ris.example.org/fhir"],
      "fhirVersions": ["4.0.1"],
      "scope": "patient/ImagingStudy.rs",
      "patient": "987"
    }
  ]
}
```

The clinical and RIS entries supply their local Patient IDs; the facade supplies the clinical Patient URL. Each resource server obtains its endpoint-specific binding through token introspection or another trusted validation arrangement.

#### Searching with the authorized Patient reference

The app uses the facade's absolute Patient context:

```
GET https://imaging.example.org/fhir/ImagingStudy?patient=https%3A%2F%2Fclinical.example.org%2Ffhir%2FPatient%2F123&_include=ImagingStudy:endpoint
Authorization: Bearer access-token-value-unguessable
```

The returned study has this subject:

```json
{
  "subject": {
    "reference": "https://clinical.example.org/fhir/Patient/123"
  }
}
```

At the independent RIS, the same token's RIS binding authorizes a search for its local Patient `987`:

```
GET https://ris.example.org/fhir/ImagingStudy?patient=987&_include=ImagingStudy:endpoint
Authorization: Bearer access-token-value-unguessable
```

The RIS can return `"subject": {"reference": "Patient/987"}`. For the unified topology, the corresponding local query is `ImagingStudy?patient=123`, with `"subject": {"reference": "Patient/123"}`.

#### User- and system-scoped Patient lookup

A client with Patient search permission at the RIS can search `Patient?identifier=https%3A%2F%2Fclinical.example.org%2Fidentifiers%2Fmrn%7CMRN456` and use the matched RIS Patient reference, `Patient/987`. For the facade, an authorized lookup occurs at its clinical Patient anchor and yields `https://clinical.example.org/fhir/Patient/123`. The workflow resolves zero or multiple matches before selecting a Patient. The imaging query uses the resulting Patient reference within the client's imaging permission.

#### Launch context and study linkage

**Endpoint-specific resource reference.** When the imaging resource's logical ID is known, the Authorization Server can supply it in that endpoint's context:

```json
{
  "authorization_details": [
    {
      "type": "smart_on_fhir",
      "locations": ["https://imaging.example.org/fhir"],
      "fhirVersions": ["4.0.1"],
      "scope": "patient/ImagingStudy.rs",
      "patient": "https://clinical.example.org/fhir/Patient/123",
      "fhirContext": [
        {
          "reference": "ImagingStudy/42"
        }
      ]
    }
  ]
}
```

This context identifies `https://imaging.example.org/fhir/ImagingStudy/42` directly.

**Identifier-based correlation.** A clinical launch can instead supply shared study and order identifiers for locating corresponding resources at another endpoint:

```json
{
  "fhirContext": [
    {
      "type": "ImagingStudy",
      "identifier": {
        "system": "urn:dicom:uid",
        "value": "urn:oid:1.2.840.113619.2.55.3.604688435.123.1"
      }
    },
    {
      "type": "ServiceRequest",
      "identifier": {
        "system": "https://clinical.example.org/identifiers/accession",
        "value": "ACC789"
      }
    }
  ]
}
```

Using the study identifier and the facade's authorized Patient context, the App searches:

```
GET https://imaging.example.org/fhir/ImagingStudy?patient=https%3A%2F%2Fclinical.example.org%2Ffhir%2FPatient%2F123&identifier=urn%3Adicom%3Auid%7Curn%3Aoid%3A1.2.840.113619.2.55.3.604688435.123.1&_include=ImagingStudy:endpoint
Authorization: Bearer access-token-value-unguessable
```

The returned study can have a different logical ID from an `ImagingStudy` at the Clinical FHIR Server. Its shared Study Instance UID supplies the correlation. The Imaging FHIR Server independently authorizes the search and returns only permitted studies and Endpoints. A launch context containing `DiagnosticReport/42` instead leads the App to that report at its originating endpoint and then to its study or order linkage.
