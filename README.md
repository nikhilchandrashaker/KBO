# KBO Team Performance Index (KTPI) — "What Wins in KBO?"

A research project on 40 seasons (1982-2021) of KBO team batting and
pitching data, asking one question: **what actually makes a KBO team win?**

## Files

| File | Purpose |
|---|---|
| `kbobattingdata.csv`, `kbopitchingdata.csv` | Raw source data (team-season level, CC0) |
| `01_ktpi_analysis.R` | Load, merge, engineer rate stats, build within-season z-scores, composite Offense/Pitching indices |
| `02_what_wins.R` | Regress Win% on Offense/Pitching — overall and by era |
| `03_ktpi_leaderboards.R` | Build KTPI, Balance, and Complete Score; leaderboards + scatter plot |
| `04_pca_clustering_bonus.R` | PCA + k-means to find team "archetypes" |
| `app.R` | Interactive Shiny dashboard — season selector → team rankings → click a team for its full breakdown |

Run `01` → `04` in order; each writes a CSV the next one reads.

## Running the dashboard

```r
install.packages(c("shiny", "tidyverse", "DT"))  # first time only
source("01_ktpi_analysis.R")
source("03_ktpi_leaderboards.R")   # produces kbo_final.csv, which app.R needs
shiny::runApp("app.R")
```

The app shows a season picker, a sortable team-rankings table (Offense,
Pitching, KTPI, Balance percentiles), and — click any row — a full
breakdown for that team: raw offensive and pitching stats, KTPI and
percentile ranks, and a scatter plot showing where that team sat in its
league that year.

## Method summary

1. **Standardize within season**, not across the whole 40-year span. A
   .750 OPS meant something very different in 1985 than in 2019, so every
   raw stat is converted to a z-score relative to that year's league only.
   This is what makes era comparisons valid.
2. **Offense_z** = average of z(OPS, OBP, SLG, Runs/G, HR rate, BB rate).
   **Pitching_z** = average of z(ERA, WHIP, BB/9, HR/9, Runs Allowed/G,
   K/9), with the "lower is better" stats sign-flipped first.
3. **Don't assume 50/50.** Regress `Win% ~ Offense_z + Pitching_z` and use
   the standardized coefficients as the actual weights.

## Headline findings (from this dataset)

- **Pooled across 1982-2021** (n = 323 team-seasons, R² = 0.79):
  pitching explains **≈53%** of the offense+pitching contribution to
  win%, offense **≈47%**. Pitching has a real but modest edge — not the
  landslide "pitching wins championships" folklore sometimes claims.
- **By era**, pitching's edge is persistent rather than growing or
  shrinking on a clean trend: roughly 53% (80s) → 51% (90s) → **56%
  (2000s, the largest gap)** → 52% (2010s) → 51% (2020-21). There's no
  tidy story of the KBO becoming steadily more offense- or
  pitching-driven the way MLB's has shifted over time — it's been close
  to a coin flip in every era, with the 2000s as the one outlier decade.
- **Most complete team-seasons** (elite in both offense and pitching,
  not just accidentally balanced while mediocre): 1988 Haitai Tigers,
  1994 LG Twins, 1998 & 2000 Hyundai Unicorns, 2002 & 2012 Samsung Lions,
  2008 SK Wyverns, 2019 Kiwoom Heroes all topped both categories in their
  season.

**Caveat to disclose in any write-up:** the KBO had only 6-8 teams
through the late 1980s/early 1990s, so within-season percentiles are
coarse there (steps of ~12-17 points) — several "tied for #1" seasons in
that era reflect that resolution limit, not literally identical
performance.

## Suggested next steps

- Wire this into a Shiny app (season selector → team rankings → click a
  team for its offense/pitching/percentile breakdown, per the original
  dashboard sketch).
- Extend the "what wins" regression to predict playoff success, not just
  regular-season win%, once postseason data is available.
- Cal Lutheran Baseball Reference project can reuse the same z-score /
  percentile machinery for a smaller, single-team dataset.
