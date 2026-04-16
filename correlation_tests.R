library(tidyverse)

# -----------------------------
# 1. LOAD PREPARED DATASET
# -----------------------------

df <- read_csv("prepared_results.csv")

# -----------------------------
# 2. CHECK REQUIRED COLUMNS
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
    lower_bound = q1 - 1.5 * iqr,
    upper_bound = q3 + 1.5 * iqr
  ) %>%
  filter(energy_j >= lower_bound, energy_j <= upper_bound) %>%
  ungroup() %>%
  select(-q1, -q3, -iqr, -lower_bound, -upper_bound)

# -----------------------------
# 6. AVERAGE WITHIN EACH MACHINE
# -----------------------------

machine_df <- df %>%
  group_by(machine, algorithm, n) %>%
  summarise(
    mean_energy = mean(energy_j, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    n_log_n = n * log(n),
    n_sq = n^2
  )

# -----------------------------
# 7. CORRELATION PER MACHINE
# -----------------------------

cor_results_machine <- machine_df %>%
  group_by(machine, algorithm) %>%
  summarise(
    cor_n = cor(mean_energy, n, method = "pearson", use = "complete.obs"),
    cor_nlogn = cor(mean_energy, n_log_n, method = "pearson", use = "complete.obs"),
    cor_nsq = cor(mean_energy, n_sq, method = "pearson", use = "complete.obs"),
    .groups = "drop"
  )

# -----------------------------
# 8. AVERAGE ACROSS MACHINES
# -----------------------------

cor_results <- cor_results_machine %>%
  group_by(algorithm) %>%
  summarise(
    cor_n = mean(cor_n, na.rm = TRUE),
    cor_nlogn = mean(cor_nlogn, na.rm = TRUE),
    cor_nsq = mean(cor_nsq, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    best_fit = case_when(
      cor_n >= cor_nlogn & cor_n >= cor_nsq ~ "O(n)",
      cor_nlogn >= cor_n & cor_nlogn >= cor_nsq ~ "O(n log n)",
      cor_nsq >= cor_n & cor_nsq >= cor_nlogn ~ "O(n²)",
      TRUE ~ "undetermined"
    )
  ) %>%
  mutate(
    cor_n = round(cor_n, 4),
    cor_nlogn = round(cor_nlogn, 4),
    cor_nsq = round(cor_nsq, 4)
  ) %>%
  arrange(algorithm)

# -----------------------------
# 9. PRINT RESULTS
# -----------------------------

print(cor_results)

# Optional: inspect per-machine values
print(cor_results_machine)