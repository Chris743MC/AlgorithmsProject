library(tidyverse)
library(broom)

# -----------------------------
# 1. LOAD PREPARED DATASET
# -----------------------------

df <- read_csv("prepared_results.csv")

# -----------------------------
# 2. CHECK REQUIRED COLUMNS
# -----------------------------

required_cols <- c("machine", "algorithm", "n", "energy_j")
missing_cols <- setdiff(required_cols, names(df))

if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
}

# -----------------------------
# 3. REMOVE IQR OUTLIERS
# -----------------------------
# Same logic as the graph script:
# remove values outside the IQR within each machine + algorithm group

df <- df %>%
  group_by(machine, algorithm) %>%
  mutate(
    q1 = quantile(energy_j, 0.25, na.rm = TRUE),
    q3 = quantile(energy_j, 0.75, na.rm = TRUE),
    iqr = q3 - q1,
    lower_bound = q1 - 1.5 * iqr,
    upper_bound = q3 + 1.5 * iqr
  ) %>%
  filter(energy_j >= lower_bound, energy_j <= upper_bound) %>%
  ungroup() %>%
  select(-q1, -q3, -iqr, -lower_bound, -upper_bound)

# -----------------------------
# 4. CREATE MACHINE PAIRS
# -----------------------------

df <- df %>%
  mutate(
    machine_pair = case_when(
      machine %in% c("m1", "m3") ~ "m1+m3",
      machine %in% c("m2", "m4") ~ "m2+m4",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(machine_pair))

# -----------------------------
# 5. AVERAGE WITHIN EACH PAIR
# -----------------------------
# This keeps the analysis aligned with your graph structure

pair_df <- df %>%
  group_by(algorithm, machine_pair, n) %>%
  summarise(
    mean_energy = mean(energy_j, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    n_log_n = n * log(n),
    n_sq = n^2
  )

# -----------------------------
# 6. FUNCTION TO EXTRACT R²
# -----------------------------

get_r_squared <- function(data, formula) {
  model <- lm(formula, data = data)
  summary(model)$r.squared
}

# -----------------------------
# 7. REGRESSION BY ALGORITHM + PAIR
# -----------------------------

pair_regression_results <- pair_df %>%
  group_by(algorithm, machine_pair) %>%
  group_modify(~{
    tibble(
      r2_n = get_r_squared(.x, mean_energy ~ n),
      r2_nlogn = get_r_squared(.x, mean_energy ~ n_log_n),
      r2_nsq = get_r_squared(.x, mean_energy ~ n_sq)
    )
  }) %>%
  ungroup()

# -----------------------------
# 8. AVERAGE THE TWO PAIRS
# -----------------------------
# Final table has one row per algorithm

regression_results <- pair_regression_results %>%
  group_by(algorithm) %>%
  summarise(
    r2_n = mean(r2_n, na.rm = TRUE),
    r2_nlogn = mean(r2_nlogn, na.rm = TRUE),
    r2_nsq = mean(r2_nsq, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    best_fit = case_when(
      r2_n >= r2_nlogn & r2_n >= r2_nsq ~ "O(n)",
      r2_nlogn >= r2_n & r2_nlogn >= r2_nsq ~ "O(n log n)",
      r2_nsq >= r2_n & r2_nsq >= r2_nlogn ~ "O(n²)",
      TRUE ~ "undetermined"
    )
  ) %>%
  mutate(
    r2_n = round(r2_n, 4),
    r2_nlogn = round(r2_nlogn, 4),
    r2_nsq = round(r2_nsq, 4)
  ) %>%
  arrange(algorithm)

# -----------------------------
# 9. PRINT RESULTS
# -----------------------------

print(regression_results)

# Optional: inspect pair-level results too
print(pair_regression_results)

# -----------------------------
# 10. SAVE RESULTS
# -----------------------------

write_csv(regression_results, "regression_results.csv")
write_csv(pair_regression_results, "regression_results_by_pair.csv")