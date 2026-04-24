library(tidyverse)

setwd("C:/Users/graur/Documents/Coding/PracticalStats")

# -----------------------------
# 1. LOAD DATA
# -----------------------------

df <- read_csv("100k_results.csv")

# -----------------------------
# 2. CHECK REQUIRED COLUMNS
# -----------------------------

required_cols <- c("input_file", "algorithm", "input_size", "wall_time_ms")
missing_cols <- setdiff(required_cols, names(df))

if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
}

# -----------------------------
# 3. PREPARE DATA
# -----------------------------

plot_df <- df %>%
  filter(algorithm %in% c("bubble", "counting", "merge", "quick")) %>%
  filter(str_detect(input_file, "^random_")) %>%
  mutate(
    time = as.numeric(wall_time_ms),
    n = as.numeric(input_size)
  ) %>%
  drop_na(time, n)

# -----------------------------
# 4. REMOVE OUTLIERS USING IQR
# -----------------------------

plot_df <- plot_df %>%
  group_by(algorithm) %>%
  mutate(
    q1 = quantile(time, 0.25, na.rm = TRUE),
    q3 = quantile(time, 0.75, na.rm = TRUE),
    iqr = IQR(time, na.rm = TRUE),
    lower = q1 - 1.5 * iqr,
    upper = q3 + 1.5 * iqr
  ) %>%
  filter(time >= lower, time <= upper) %>%
  ungroup() %>%
  select(-q1, -q3, -iqr, -lower, -upper)

# -----------------------------
# 5. SUMMARY TABLE
# -----------------------------

summary_table <- plot_df %>%
  group_by(algorithm) %>%
  summarise(
    points = n(),
    mean_time = mean(time, na.rm = TRUE),
    median_time = median(time, na.rm = TRUE),
    sd_time = sd(time, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(algorithm)

cat("\nExecution time summary by algorithm:\n")
print(summary_table)

# -----------------------------
# 6. SINGLE BOXPLOT
# -----------------------------
ggplot(plot_df, aes(x = algorithm, y = time, fill = algorithm)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.7) +
  stat_summary(
    fun = mean,
    geom = "point",
    color = "red",
    size = 3
  ) +
  labs(
    title = "Execution Time Comparison (Random Inputs Only, IQR Filtered)",
    subtitle = "Red dot = mean execution time",
    x = "Algorithm",
    y = "Execution Time (ms)"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none") +
  coord_cartesian(ylim = c(0, 600))