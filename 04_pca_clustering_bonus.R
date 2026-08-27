########################################################################
# 5. BONUS: PCA + CLUSTERING — are there distinct team "archetypes"?
########################################################################

library(tidyverse)
library(broom)

kbo <- read_csv("kbo_final.csv")

feature_cols <- c(paste0("z_", c("OPS","OBP","SLG","runs_per_game_bat","hr_rate","bb_rate")),
                   paste0("z_", c("ERA","WHIP","walks_9","homeruns_9",
                                  "runs_allowed_per_game","strikeouts_9")))

feat_matrix <- kbo %>% select(all_of(feature_cols)) %>% as.matrix()

pca <- prcomp(feat_matrix, center = TRUE, scale. = TRUE)
summary(pca)  # check how much variance PC1/PC2 explain

pca_scores <- as_tibble(pca$x[, 1:2]) %>%
  rename(PC1 = PC1, PC2 = PC2) %>%
  bind_cols(kbo %>% select(year, team, Offense_pctile, Pitching_pctile,
                            win_loss_percentage))

# k-means on the two composite indices to find team "types"
set.seed(42)
km <- kmeans(kbo %>% select(Offense_pctile, Pitching_pctile), centers = 4, nstart = 25)
kbo$cluster <- factor(km$cluster)

cluster_summary <- kbo %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    avg_offense  = mean(Offense_pctile),
    avg_pitching = mean(Pitching_pctile),
    avg_win_pct  = mean(win_loss_percentage)
  ) %>%
  arrange(desc(avg_win_pct))

print(cluster_summary)
# Expect something like: one cluster of "elite/balanced" teams with the
# best win%, one "offense-carried", one "pitching-carried", and one
# "bottom-feeder" cluster weak in both — label these once you see the
# actual centers.

cluster_plot <- kbo %>%
  ggplot(aes(x = Offense_pctile, y = Pitching_pctile, color = cluster)) +
  geom_point(alpha = 0.75, size = 2) +
  labs(title = "KBO team-season archetypes (k-means, k = 4)",
       x = "Offense percentile", y = "Pitching percentile", color = "Cluster") +
  theme_minimal(base_size = 13)

ggsave("plots/team_archetype_clusters.png", cluster_plot, width = 8, height = 6, dpi = 150)

write_csv(kbo, "kbo_final_with_clusters.csv")
