library(tidyverse)

setwd("C:/Users/graur/Documents/Coding/PracticalStats")

# Load data
df <- read_csv("100k_results.csv")

# Keep only random inputs for all algorithms
plot_df <- df %>%
  filter(algorithm %in% c("bubble", "counting", "merge", "quick")) %>%
  filter(str_detect(input_file, "^random_")) %>%
  mutate(
    time = as.numeric(wall_time_ms),
    n = as.numeric(input_size),
    n_log_n = n * log(n),
    n_sq = n^2
  ) %>%
  drop_na(time, n)

# Remove outliers using IQR per algorithm
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

# Count points per algorithm
point_counts <- plot_df %>%
  count(algorithm, name = "num_points")

# Scaling function
scale_to_time <- function(x, time_vals) {
  x * (max(time_vals, na.rm = TRUE) / max(x, na.rm = TRUE))
}

# Scale curves per algorithm
plot_df <- plot_df %>%
  group_by(algorithm) %>%
  mutate(
    n_scaled = scale_to_time(n, time),
    nlogn_scaled = scale_to_time(n_log_n, time),
    nsq_scaled = scale_to_time(n_sq, time)
  ) %>%
  ungroup()

# Reshape for plotting
plot_long <- plot_df %>%
  select(algorithm, n, time, n_scaled, nlogn_scaled, nsq_scaled) %>%
  pivot_longer(
    cols = c(n_scaled, nlogn_scaled, nsq_scaled),
    names_to = "curve",
    values_to = "curve_value"
  ) %>%
  mutate(
    curve = recode(
      curve,
      n_scaled = "n",
      nlogn_scaled = "n log n",
      nsq_scaled = "n^2"
    )
  )

# Plot
ggplot() +
  geom_point(
    data = plot_df,
    aes(x = n, y = time),
    color = "black"
  ) +
  geom_line(
    data = plot_long,
    aes(x = n, y = curve_value, color = curve),
    linewidth = 1
  ) +
  facet_wrap(~ algorithm, scales = "free_y") +
  labs(
    title = "Execution Time vs Input Size (Random Inputs Only, IQR Filtered)",
    x = "Input Size (n)",
    y = "Execution Time (ms)",
    color = "Reference Curve"
  ) +
  theme_minimal()

# Correlation summary table
cor_table <- plot_df %>%
  group_by(algorithm) %>%
  summarise(
    points = n(),
    cor_n = cor(time, n, use = "complete.obs"),
    cor_nlogn = cor(time, n_log_n, use = "complete.obs"),
    cor_nsq = cor(time, n_sq, use = "complete.obs"),
    .groups = "drop"
  ) %>%
  arrange(algorithm)

# Console output
cat("\nPoints used per algorithm (random only, after IQR filter):\n")
print(point_counts)

cat("\nCorrelation summary:\n")
print(cor_table)