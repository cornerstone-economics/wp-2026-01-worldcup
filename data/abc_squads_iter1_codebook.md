# ABC islands diaspora squad dataset — codebook

**Iteration:** 1
**Compiled:** 2026-04-20
**Scope:** Four national teams (Aruba women, Curaçao women, Aruba men, Curaçao men) as of the most recent confirmed squad calls.
**Related project:** `01-projects/diaspora-football-research.md`

## Purpose

Structural spine for two pieces of work: the Dick Draayer article on the 6-1 result, and the working paper on diaspora football economies across gender lines in the ABC islands. The unit of analysis is the player, the key variables are club country and league tier, and the comparison of interest is the share of each squad based in European professional football versus island-based or amateur clubs.

## Headline numbers

**Curaçao men (26 players):** roughly 24 of 26 in European or other fully professional leagues (Netherlands, Turkey, Switzerland, England, Germany, Saudi Arabia, USA). Zero based on Curaçao. Full diaspora model in its mature form.

**Aruba men (26 players):** roughly 13 of 26 in the Netherlands, but almost entirely in second division, third division (Tweede Divisie), amateur Hoofdklasse, or reserve/youth teams. The other 13 in the domestic Aruban league. Zero in Eredivisie first teams. Thin diaspora pipeline weighted toward the lower reaches of Dutch football.

**Curaçao women (22 players, November 2025 squad):** roughly 13 of 22 based abroad (Netherlands, Germany, Greece, USA college), 9 in the local Curaçao league. Of the 13 abroad, only two in the top Dutch professional division (Nisia at Sparta Rotterdam, Martina at Excelsior Rotterdam). Rest at Dutch amateur or semi-professional clubs.

**Aruba women (23 players, April 2026 squad):** three players with high-confidence European professional club affiliations (Verhoeve at FC Utrecht, Lammers at Excelsior Rotterdam, Gumbs at AA Gent). The other twenty have no public club data. **Main data gap.** Best inference from 24ora (players travelled from Netherlands to Panama) and Dutch-heavy surname pattern is that a substantial share are Netherlands-based. Closing this gap requires AVB source or deeper Dutch amateur-league search per player.

## Variable definitions

| Variable | Values | Notes |
|----------|--------|-------|
| team_code | ARU-W, CUW-W, ARU-M, CUW-M | |
| position | GK, DEF, MID, FWD, X | X = unknown |
| club_country | ISO 3-letter | ABW=Aruba, CUW=Curaçao, NLD=Netherlands, BEL=Belgium, DEU=Germany, GRC=Greece, USA, TUR=Turkey, SAU=Saudi Arabia, CHE=Switzerland, GBR=UK, MYS=Malaysia, X=unknown |
| league_tier | 1, 2, 3, R, Y, L, X | 1=top flight, 2=second tier, 3=third+amateur, R=reserve/development, Y=youth U19-, L=local island league, X=unknown |
| confidence | H, M, L, U | H=verified recent source, M=plausible single source, L=inferred, U=unknown |

## Coding decisions

- Dutch Tweede Divisie and Hoofdklasse coded as tier 3 (below the professional/semi-professional threshold that falls between Eerste Divisie and Tweede Divisie). This preserves the analytically relevant boundary. Split if finer resolution needed.
- Jong Holland is a Curaçao club despite the Dutch-sounding name. Coded CUW local.
- Cumberland University (Tennessee) is NAIA level, coded USA tier 3.
- De Graafschap Vrouwen plays in Dutch Eerste Klasse Zondag (fifth tier women's). Coded tier 3 conservatively.
- Livano Comenencia coded MID (recent minutes in midfield) despite Sofascore listing as DEF.

## Sources

- Aruba women: 24ora.com English edition, 6 April 2026
- Curaçao women: Curaçao Chronicle, 26 November 2025 (assumed close to April 2026 squad)
- Aruba men: FotMob team page, verified against March 2026 FIFA Series
- Curaçao men: FotMob + Sofascore for broader pool
- Player clubs: Transfermarkt, Soccerway, FBref, Wikipedia, vrouweneredivisie.nl, LinkedIn, Alamy captions

## Head coach table

| Team | Head coach | Career highlight | Appointed |
|------|-----------|-------------------|-----------|
| Aruba women | Arjan van der Laan | Head coach Netherlands women's national team 2015-2016 | March 2024 |
| Curaçao women | Johan van Heertum | Dutch coaching background; no senior national team head role | ~2024 |
| Aruba men | Marvic Bermúdez | Career mainly domestic/CONCACAF | ~2022 |
| Curaçao men | Fred Rutten | Former Netherlands assistant; long Eredivisie/Bundesliga career | February 2026 |

## Next iteration targets

1. Close the 20 Aruba women unknowns (Transfermarkt + ask Verhoeve in interview)
2. Pull April 21 2026 FIFA women's rankings for both islands
3. Add head-to-head results (men's all-time ABC derby + women's two meetings)
4. Add birthplace data for diaspora players (born-in-Caribbean vs born-in-NL split)
5. Build coach-level historical file (appointment dates, credentials, prior national-team experience across cycles)
