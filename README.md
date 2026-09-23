# SMART Imaging Access IG

FHIR Implementation Guide for **SMART Imaging Access**: apps get a patient's
imaging studies and DICOM data using the same SMART on FHIR authorization they
already use for clinical data.

The guide supports both SMART App Launch and SMART Backend Services. Deployments
can support either or both patterns, using the same study search and DICOM
retrieval interfaces subject to the applicable access permissions.
In either pattern, returned imaging endpoints tell clients whether to send their
existing SMART token or follow a capability URL without it.

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

- `input/fsh/` — profiles (SmartImagingStudy, SmartWadoEndpoint), the
  requires-access-token extension, server CapabilityStatement, examples
- `input/pagecontent/` — narrative pages (plain-language spec)
- `input/images/` — hand-crafted SVG diagrams; each has a `-mobile` variant
  selected via `<picture>` at narrow widths
- `.github/workflows/build.yml` — CI build + GitHub Pages deploy
