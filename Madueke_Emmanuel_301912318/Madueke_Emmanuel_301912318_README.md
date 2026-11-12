# LMS summary

Owner, author, and maintainer: **Emmanuel Madueke**. Student number: **301912318**.

- [Three-page A4 PDF](Madueke_Emmanuel_301912318.pdf)
- [Editable HTML source](Madueke_Emmanuel_301912318.html)

The summary covers the case study, users/data/operations, all five activities, selected actual output, repository/evidence links, limitations, and references/AI declaration. The technical figures use the retained activity evidence and fresh reproduction at source commit `5ba7d37`, published as `20387ce`.

The document is finalised as a three-page summary at Emmanuel's request. Its reflection uses his recorded ERD choices and project direction, evaluates specific retained technical findings, and identifies independent reproduction as further personal verification. The declaration states the actual division between his direction/review and tool-executed checks. `docs/ai-use.md` was not changed.

## Supporting screenshots

The [nine-image screenshot gallery](../evidence/screenshots/Madueke_Emmanuel_301912318_README.md) covers the ERD, schema checks, query optimisation, COMMIT, ROLLBACK, isolation/concurrency, MongoDB results and proposed architecture. These are browser captures of retained output excerpts and diagrams, dated 22 October 2026; runtime logs remain dated 17 October. Upload supporting PNGs as required alongside the three-page PDF. All files in this submission directory use the requested student identifier; descriptive suffixes distinguish the Markdown notes.

## Public guidance and remaining submission actions

The reflection uses a description–analysis–future-action structure informed by the [University of Edinburgh Reflection Toolkit](https://reflection.ed.ac.uk/reflectors-toolkit/reflecting-on-experience/what-so-what-now-what) and [Monash reflective-practice guidance](https://www.monash.edu/student-academic-success/excel-at-writing/how-to-write/reflection/reflective-practice), consulted on 17 October 2026. These public sources informed structure; the project examples and personal contributions come from this portfolio. Both sources are acknowledged in the PDF.

The [access review](Madueke_Emmanuel_301912318_access-review.md) confirms the summary push and progressive history; private-repository status, assessor access and LMS upload remain outstanding. Finalising this document does not assert that those actions, or independent student runtime verification, have occurred. The historical working AI-use record remains unchanged; the summary contains a declaration covering assistance across the portfolio.

Retain the distinction between source commit `5ba7d37` and evidence commit `20387ce`, and between local runtime checks and untested distributed proposals.

## Technical verification preparation

A [case-specific preparation guide](../docs/Madueke_Emmanuel_301912318_technical-verification.md) links likely questions to source, outputs, and limitations across all five activities. It includes a rehearsal procedure but does not claim that Emmanuel has completed it.

## PDF production and checks

The PDF was rendered from the local HTML with Chrome headless, using A4 CSS and explicit page boundaries. `pdfinfo` reports three A4 pages; extracted text contains all five activity sections and all three footers. All pages were visually inspected for clipping and readability. Repository file links in the HTML were mapped to existing local targets; remote permissions and external URL availability were not tested.

To rebuild on this Mac, run from the repository root, using an unused temporary browser profile directory:

```sh
summary_browser_profile=$(mktemp -d /tmp/fashion-summary-browser.XXXXXX)
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --user-data-dir="$summary_browser_profile" \
  --print-to-pdf="$PWD/Madueke_Emmanuel_301912318/Madueke_Emmanuel_301912318.pdf" \
  "file://$PWD/Madueke_Emmanuel_301912318/Madueke_Emmanuel_301912318.html"
pdfinfo Madueke_Emmanuel_301912318/Madueke_Emmanuel_301912318.pdf
```

This intentionally replaces the PDF after editing its HTML source. Recheck the page count and visual layout after content changes; pagination can vary with renderer/fonts. Browser display-service diagnostic messages occurred during headless rendering, but the process exited zero and the PDF passed the checks above. No LMS upload has been performed.
