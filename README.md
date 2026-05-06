# WP-2026-01 — Curaçao at the World Cup: what the FIFA ranking does not measure

**Status:** in production. Target release: 14 May 2026.
**Series:** Cornerstone Economics Working Papers, [papers.c-economics.com](https://papers.c-economics.com).
**Identifier:** WP-2026-01.
**License:** text CC-BY 4.0, code MIT.

## Abstract

Curaçao qualified for the 2026 FIFA World Cup at world rank 82, the smallest country by population ever to do so. The qualification looks anomalous against the ranking, but the ranking itself is the source of the apparent anomaly. This paper formalises the diaspora measurement gap in FIFA's Elo-style ranking and estimates its size for a panel of small CONCACAF and UEFA states. The result generalises beyond Curaçao to other small states with large diasporas (Cabo Verde, Albania, Suriname).

## What is in this repository

`paper.qmd` is the master manuscript. `references.bib` holds citations. `data/` holds the squad and ranking datasets, `analysis/` holds the R scripts that build the figures, and `notes/` holds prior drafting material that informed the paper but is not part of the paper itself (the v3 NL opinion piece, the two teaser variants, and the project framing notes).

## Build

```bash
quarto render paper.qmd
```

Local rendering needs Quarto 1.5+, R 4.4+, and a XeLaTeX engine. CI on push handles the canonical build and attaches the PDF to GitHub Releases.

## Companion writing

Three Dutch-language teasers exist for this paper. They are kept in `notes/` for reference and will be deployed (or not) as a separate communications decision; they are not part of the working paper and do not share its DOI.
