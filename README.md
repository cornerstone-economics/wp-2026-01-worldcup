# WP-2026-01 — The diaspora multiplier: Curaçao at the 2026 World Cup and what the resident-population unit cannot see

**Status:** in production. Target release: 21 May 2026.
**Series:** Cornerstone Economics Working Papers, [papers.c-economics.com](https://papers.c-economics.com).
**Identifier:** WP-2026-01.
**License:** text CC-BY 4.0, code MIT.

## Abstract

Curaçao opens its first World Cup against Germany on 14 June 2026. With about 150,000 residents it is the smallest country ever to qualify for the men's tournament, less than half the population of Iceland in 2018. At world rank 82 the qualification reads as anomalous, and the natural inference is that the FIFA ranking misses something. We find the opposite: across 202 nations FIFA rank moves systematically with resident population, and Curaçao is not under-measured but over-performing its population by about 80 rank places, in the same residual cluster as Uruguay, Croatia, Portugal, Belgium, and the Netherlands. The Curaçao men's senior squad carries a Transfermarkt market value of €193 per resident, equal to Iceland's, with every player developing abroad in a professional league. FIFA's parent-and-grandparent eligibility rule extends the recruitable pool from 150,000 residents to a multi-generation diaspora concentrated in Dutch and other European professional football. For small states with substantial diasporas, the resident-population unit may not be the right reference for measuring competitive capacity.

## What is in this repository

`paper.qmd` is the master manuscript. `references.bib` holds citations. `data/` holds the squad and ranking datasets, `analysis/` holds the R scripts that build the figures, and `notes/` holds prior drafting material that informed the paper but is not part of the paper itself (the v3 NL opinion piece, the two teaser variants, and the project framing notes).

## Build

```bash
quarto render paper.qmd
```

Local rendering needs Quarto 1.5+, R 4.4+, and a XeLaTeX engine. CI on push handles the canonical build and attaches the PDF to GitHub Releases.

## Companion writing

Three Dutch-language teasers exist for this paper. They are kept in `notes/` for reference and will be deployed (or not) as a separate communications decision; they are not part of the working paper and do not share its DOI.
