# SMART Imaging Access IG

FHIR Implementation Guide for **SMART Imaging Access**: apps get a patient's
imaging studies and DICOM data using the same SMART on FHIR authorization they
already use for clinical data.

The guide supports both SMART App Launch and SMART Backend Services. Deployments
can support either or both patterns, using the same study search and DICOM
retrieval interfaces subject to the applicable access permissions.
In either pattern, clients present the same SMART access token for study search
and DICOM retrieval. Servers can use token-bound capability URLs to carry
study-specific permissions to the retrieval service.

Grew out of the [Sync for Science imaging spec](https://github.com/sync-for-science/imaging);
reference implementation and sandbox at <https://github.com/jmandel/smart-imaging>
and <https://imaging.argo.run>.

**CI build:** <https://build.fhir.org/ig/argonautproject/smart-imaging/> (rebuilt
on every push by the [FHIR auto-builder](https://github.com/FHIR/auto-ig-builder)).

## Building

Requires Node (with [SUSHI](https://fshschool.org/docs/sushi/)), Java 17+, and Jekyll.

```sh
sushi .                                # compile FSH only
java -jar input-cache/publisher.jar -ig .   # full IG build into output/
```

Get the publisher with:

```sh
mkdir -p input-cache
curl -L https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar \
  -o input-cache/publisher.jar
```

## Layout

- `input/fsh/` — profiles (SmartImagingStudy, SmartWadoEndpoint),
  server CapabilityStatement, examples
- `input/pagecontent/` — narrative pages (plain-language spec)
- `input/images/` — native SVG diagrams, with `<picture>` used to select
  mobile variants where provided
- `.github/workflows/build.yml` — CI build + GitHub Pages deploy
