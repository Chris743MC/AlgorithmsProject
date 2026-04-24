library(tidyverse)
library(broom)
# -----------------------------
# 1. LOAD DATA
# -----------------------------

df <- read_csv("prepared_results.csv")

# -----------------------------
# 2. CHECK COLUMNS
# -----------------------------

required_cols <- c("machine", "algorithm", "n", "energy_j", "input_file")
missing_cols <- setdiff(required_cols, names(df))

if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
}

# -----------------------------
# 3. EXTRACT INPUT CASE
# -----------------------------

df <- df %>%
  mutate(
    case = case_when(
      str_detect(str_to_lower(input_file), "random") ~ "random",
      str_detect(str_to_lower(input_file), "sorted") ~ "sorted",
      str_detect(str_to_lower(input_file), "reverse") ~ "reverse",
      TRUE ~ "other"
    )
  )

# -----------------------------
# 4. KEEP ONLY RANDOM FOR QUICK
# -----------------------------

df <- df %>%
  filter(!(algorithm == "quick" & case != "random"))

# -----------------------------
# 5. REMOVE IQR OUTLIERS
# -----------------------------

df <- df %>%
  group_by(machine, algorithm) %>%
  mutate(
    q1 = quantile(energy_j, 0.25, na.rm = TRUE),
    q3 = quantile(energy_j, 0.75, na.rm = TRUE),
    iqr = q3 - q1,
    lower = q1 - 1.5 * iqr,
    upper = q3 + 1.5 * iqr
  ) %>%
  filter(energy_j >= lower, energy_j <= upper) %>%
  ungroup() %>%
  select(-q1, -q3, -iqr, -lower, -upper)

# -----------------------------
# 6. AVERAGE WITHIN EACH MACHINE
# -----------------------------

machine_df <- df %>%
  group_by(machine, algorithm, n) %>%
  summarise(
    mean_energy = mean(energy_j, na.rm = TRUE),
    .groups = "drop"
  )

# -----------------------------
# 7. APPLY COMPLEXITY TRANSFORMS
# -----------------------------

machine_df <- machine_df %>%
  mutate(
    x_transform = case_when(
      algorithm == "bubble"   ~ n^2,
      algorithm == "merge"    ~ n * log(n),
      algorithm == "quick"    ~ n * log(n),
      algorithm == "counting" ~ n,
      TRUE ~ NA_real_
    )
  )

# -----------------------------
# 8. REGRESSION FOR EACH MACHINE
# -----------------------------

reg_results_machine <- machine_df %>%
  group_by(machine, algorithm) %>%
  do({
    model <- lm(mean_energy ~ x_transform, data = .)
    tibble(
      r_squared = summary(model)$r.squared
    )
  }) %>%
  ungroup()

# -----------------------------
# 9. FINAL TABLE (AVERAGE MACHINES)
# -----------------------------

reg_results <- reg_results_machine %>%
  group_by(algorithm) %>%
  summarise(
    r_squared = mean(r_squared, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    r_squared = round(r_squared, 4)
  ) %>%
  arrange(algorithm)

# -----------------------------
# 10. PRINT RESULTS
# -----------------------------

print(reg_results)
print(reg_results_machine)