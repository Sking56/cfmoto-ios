# Licensing research

Research date: 2026-10-04. Upstream snapshot: `zanderp/open-cfmoto` commit `0abbe2a70119d6dd46ac6b8a0715ff267fcdb316` (2026-09-15). Scope: license and provenance investigation for MVP-005; no project license selection or distribution approval.

## Observed upstream terms

The pinned [LICENSE](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/LICENSE) contains AGPL version 3. The pinned [NOTICE](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/NOTICE) grants version 3 or later, identifies Alexandru and contributors, and attributes incorporated Android Auto receiver code to the headunit lineage. It also records earlier open-cfmoto forks without explicit licenses; that provenance statement is not an independent grant from those authors. Sampled `BikeLink.kt` and `BikeWifi.kt` headers declare `AGPL-3.0-or-later`. In contrast, `QrData.kt` and `PxcHandshake.kt` begin with package declarations and lack per-file license headers. Do not interpret missing headers as a permissive grant; investigate their lineage before reuse under the repository's stated terms.

The [README licensing section](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/README.md#-license) discusses alternate terms for original contributions; those cannot relicense other authors' incorporated code. Its contributor policy belongs to that repository and is not automatically adopted here.

## Reuse implications

AGPL sections 4–6 require preservation of notices and govern conveying covered source, modified works, and object code with corresponding source obligations. Section 13 addresses remote users interacting with a modified network-capable version; it does not mean every unrelated app using Wi-Fi inherits AGPL. Source: the pinned LICENSE above and [FSF AGPL text](https://www.gnu.org/licenses/agpl-3.0-body.html).

Translating Kotlin into Swift does not by itself remove the original license obligations. The [FSF translation FAQ](https://www.gnu.org/licenses/gpl-faq.en.html#TranslateCode) treats translation as modification. Protocol facts can inform an independently written implementation, but this research does not establish a legally clean provenance boundary for future code. Record that boundary per change before reuse.

## Repository decision and inventory

[LICENSE](../../LICENSE) remains an explicit decision placeholder. Original SwiftUI scaffolding and portable tooling were authored for this repository; upstream source is downloaded only into ignored research directories. No Android Auto receiver, Kotlin source, APK, third-party library, or upstream license text is incorporated in the foundation. Synthetic byte fixtures require generation and source provenance, not a claim that a hardware capture occurred.

The upstream [dependency declaration](https://github.com/zanderp/open-cfmoto/blob/0abbe2a70119d6dd46ac6b8a0715ff267fcdb316/app/build.gradle.kts) lists Android/Google and other libraries that this native iOS MVP does not need. Its NOTICE describes dependency terms, but omits the declared OkHttp dependency; therefore it is not a complete dependency audit. This project currently uses Apple frameworks plus Python's standard library for portable checks and has no runtime third-party dependencies.

Before importing code, record file, exact revision, authors, applicable license, modification, destination, notices, and distribution obligations. Preserve source headers; do not invent copyright ownership or dual-licensing rights. For future distribution, obtain the project owner's license decision and resolve any incorporated-code obligations first. CFMOTO, MotoPlay and Carbit names identify interoperability targets; no affiliation or trademark permission is asserted.

## Verification limits

Mac Gate 1 provenance: `OpenCFMoto/Pairing/*.swift`, `OpenCFMoto/EasyConnect/*.swift`, the Swift host probe, Python dashboard peer and new tests were authored for this repository from the reviewed protocol facts and invented fixtures. No upstream Kotlin/source file, crypto implementation, library or notice text was copied or translated into these changes. No third-party runtime dependency was introduced. This records the implementation approach and is not an independent legal clearance or a project-license decision.

License, NOTICE, README and build declaration were fetched at the exact revision; sampled headers were inspected in the matching local upstream clone. This is a research finding, not a determination about all upstream contributors' rights, patents, regional interoperability law, Apple distribution terms, or every dependency. No App Store release is in scope. Independent review and its tested branch SHA must be recorded before merging this workstream.
