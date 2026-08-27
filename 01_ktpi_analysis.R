########################################################################
# KBO Team Performance Index (KTPI) — "What Wins in KBO?"
# Author: [your name]
# Data: KBO team batting & pitching, 1982-2021 (public domain / CC0)
#
# This script builds a team-strength index that combines offense and
# pitching, then empirically tests how much each contributes to winning
# rather than assuming an arbitrary 50/50 split.
########################################################################

library(tidyverse)
library(broom)
library(scales)

# ----------------------------------------------------------------------
# 1. LOAD & MERGE
# ----------------------------------------------------------------------

batting  <- read_csv("kbobattingdata.csv")
pitching <- read_csv("kbopitchingdata.csv")

kbo <- batting %>%
  inner_join(
    pitching,
    by = c("year", "team"),
    suffix = c("_bat", "_pit")
  ) %>%
  arrange(year, team)

stopifnot(nrow(kbo) == nrow(batting))  # confirms a clean 1:1 merge

# ----------------------------------------------------------------------
# 2. FEATURE ENGINEERING
# ----------------------------------------------------------------------

kbo <- kbo %>%
  mutate(
    hr_rate               = homeruns / at_bats,
    bb_rate               = bases_on_balls / plate_appearances,
    runs_allowed_per_game = runs_pit / games_pit
  )

# Metrics where a HIGHER raw value is better
offense_cols <- c("OPS", "OBP", "SLG", "runs_per_game_bat", "hr_rate", "bb_rate")

# Pitching metrics where a LOWER raw value is better (sign will be flipped)
pitching_cols_lower_better <- c("ERA", "WHIP", "walks_9", "homeruns_9",
                                 "runs_allowed_per_game")
# Pitching metric where higher is better
pitching_cols_higher_better <- c("strikeouts_9")

# Standardize every metric WITHIN its own season. This is the key step that
# makes eras comparable — a .750 OPS league (1980s) and a .750 OPS league
# (2010s) mean very different things in raw terms, but z-scores put every
# team on the same "how good were they relative to their own year" scale.
z_within_season <- function(x, year) {
  ave(x, year, FUN = function(v) (v - mean(v)) / sd(v))
}

kbo <- kbo %>%
  mutate(across(all_of(offense_cols),
                ~ z_within_season(.x, year), .names = "z_{.col}")) %>%
  mutate(across(all_of(pitching_cols_lower_better),
                ~ -z_within_season(.x, year), .names = "z_{.col}")) %>%
  mutate(across(all_of(pitching_cols_higher_better),
                ~ z_within_season(.x, year), .names = "z_{.col}"))

offense_z_cols  <- paste0("z_", offense_cols)
pitching_z_cols <- paste0("z_", c(pitching_cols_lower_better, pitching_cols_higher_better))

kbo <- kbo %>%
  rowwise() %>%
  mutate(
    Offense_z  = mean(c_across(all_of(offense_z_cols))),
    Pitching_z = mean(c_across(all_of(pitching_z_cols)))
  ) %>%
  ungroup() %>%
  # re-standardize the composites so both land on the same scale for regression
  group_by(year) %>%
  mutate(
    Offense_z  = as.numeric(scale(Offense_z)),
    Pitching_z = as.numeric(scale(Pitching_z))
  ) %>%
  ungroup()

write_csv(kbo, "kbo_merged.csv")
