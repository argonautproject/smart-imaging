*This page is non-normative.*

### A building block for image exchange

Sharing images between organizations for treatment, referrals, and second opinions is an important use case. SMART Imaging Access provides a building block for that work: a consistent way to access a health system's clinical and imaging data with a common approach to authorization.

Within a health system, clinical records and images often live in separate products. This guide describes how those products cooperate so an app can read clinical data, find imaging studies, and retrieve DICOM data under the same SMART authorization. The app presents the same SMART token for study search and image retrieval. The services can be operated by the health system or by vendors working on its behalf.

### Connecting organizations

A health system can participate in exchange through direct connections with partners, a shared exchange service, or interconnected networks. In each arrangement, SMART Imaging Access could provide the interface to the health system's data. Network integration would supply the additional mechanisms for cross-organization trust, authorization, patient matching, and record location.

<div style="text-align: center; margin: 1.5em 0;">
<picture>
<source media="(max-width: 640px)" srcset="network-building-block-mobile.svg"/>
<img src="network-building-block.svg" alt="A health system exposes clinical FHIR, imaging study metadata, and DICOM retrieval under common SMART authorization. Below it, three possible exchange arrangements are shown: direct partner connections, a shared exchange service, and interconnected networks. Each requires additional network integration." style="max-width: 100%; height: auto;"/>
</picture>
<p><em>Possible arrangements, not prescribed architectures. Lines show relationships, not token flows. Each organization has its own authorization boundary.</em></p>
</div>

For example, this capability could support integration into:

* **TEFCA-connected exchange in the United States**, where organizations connect through QHINs, Participants, or Subparticipants in a [network of networks](https://rce.sequoiaproject.org/participate/).
* **Imaging-sharing communities using IHE profiles**, such as [XDS-I.b and XCA-I](https://profiles.ihe.net/RAD/), which address sharing within and across communities.
* **Direct referral partnerships or regional exchanges**, with their own agreements and connection arrangements.

These are potential integration contexts; this guide does not specify the adapters or establish conformance to those networks' requirements.

### Work beyond this guide

This guide supports user-facing apps through SMART App Launch and [Backend Services access](specification.html#backend-services) for pre-authorized clients. For example, a referral service could retrieve permitted studies without a user-facing authorization step at the source organization.

Backend Services supplies the token acquisition protocol; organizations still need to establish trust and assign access permissions. Network-wide patient discovery, record location, and importing images into a receiving PACS require additional specifications and agreements. A SMART token issued for one deployment is not automatically valid at another organization.

The aim is to make clinical and imaging data consistently accessible at each participating health system, so broader exchange workflows can build on that capability.
