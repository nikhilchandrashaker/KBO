########################################################################
# 4. BUILD KTPI + BALANCE SCORE + LEADERBOARDS
########################################################################

library(tidyverse)

kbo <- read_csv("kbo_merged.csv")

# Weights come from the OVERALL regression in 02_what_wins.R, not an
# arbitrary guess.
w_offense  <- 0.473
w_pitching <- 0.527

kbo <- kbo %>%
  group_by(year) %>%
  mutate(
    Offense_pctile  = percent_rank(Offense_z) * 100,
    Pitching_pctile = percent_rank(Pitching_z) * 100
  ) %>%
  ungroup() %>%
  mutate(
    KTPI           = w_offense * Offense_pctile + w_pitching * Pitching_pctile,
    Balance        = 100 - abs(Offense_pctile - Pitching_pctile),
    # "Complete" teams need to be good at BOTH, not just balanced at being
    # average in both — Complete_Score rewards the weaker of the two sides.
    Complete_Score = pmin(Offense_pctile, Pitching_pctile)
  )

# --- Best team-seasons in KBO history (by KTPI) ------------------------
best_teams <- kbo %>%
  arrange(desc(KTPI)) %>%
  select(year, team, Offense_pctile, Pitching_pctile, KTPI,
         wins, losses, win_loss_percentage) %>%
  slice_head(n = 15)

print(best_teams)

# --- Most "complete" teams (elite AND balanced) -------------------------
most_complete <- kbo %>%
  arrange(desc(Complete_Score)) %>%
  select(year, team, Offense_pctile, Pitching_pctile, KTPI, Balance,
         Complete_Score, win_loss_percentage) %>%
  slice_head(n = 15)

print(most_complete)

# Note on the early-era ties: the KBO had only 6-8 teams through the 1980s
# and early 1990s, so within-season percentile ranks are coarse (steps of
# ~12.5-16.7 points). A team topping both categories in a 6-team season is
# a real, if lower-resolution, accomplishment — flag this as a caveat in
# any write-up rather than treating every #1 tie as literally identical.

write_csv(kbo, "kbo_final.csv")
write_csv(best_teams, "leaderboard_best_ktpi.csv")
write_csv(most_complete, "leaderboard_most_complete.csv")

# --- Supporting visualization: offense vs pitching scatter --------------
scatter_plot <- kbo %>%
  ggplot(aes(x = Offense_pctile, y = Pitching_pctile, color = win_loss_percentage)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_gradient(low = "#D6EAF8", high = "#154360", name = "Win%") +
  labs(
    title = "Every KBO team-season: Offense vs. Pitching (percentile within year)",
    subtitle = "Points near the diagonal are 'balanced'; upper-right corner is 'complete'",
    x = "Offense percentile", y = "Pitching percentile"
  ) +
  theme_minimal(base_size = 13)

ggsave("plots/offense_vs_pitching_scatter.png", scatter_plot, width = 8, height = 6, dpi = 150)
