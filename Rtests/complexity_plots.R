library(tidyverse)

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
    pair_name = case_when(
      machine %in% c("m1", "m3") ~ "m1+m3",
      machine %in% c("m2", "m4") ~ "m2+m4",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(pair_name))

# -----------------------------
# 5. CREATE TRANSFORMED X-VALUES
# -----------------------------

df <- df %>%
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
# 6. FUNCTION TO MAKE ONE PLOT
# -----------------------------

make_regression_plot <- function(data, algo_name, selected_pair, pretty_name, x_label) {
  
  algo_df <- data %>%
    filter(algorithm == algo_name, pair_name == selected_pair) %>%
    arrange(x_transform)
  
  if (nrow(algo_df) == 0) {
    stop(
      paste(
        "No data found for algorithm:", algo_name,
        "and pair:", selected_pair
      )
    )
  }
  
  ggplot(algo_df, aes(x = x_transform, y = energy_j, shape = machine)) +
    geom_point(size = 2.2, alpha = 0.75) +
    geom_smooth(method = "lm", se = FALSE, linewidth = 0.9) +
    labs(
      title = paste(pretty_name, ":", selected_pair),
      x = x_label,
      y = "Energy (J)",
      shape = "Machine"
    ) +
    theme_minimal(base_size = 12)
}

# -----------------------------
# 7. GENERATE 8 PLOTS
# -----------------------------

bubble_m1m3 <- make_regression_plot(
  df, "bubble", "m1+m3", "Bubble Sort", "n²"
)

bubble_m2m4 <- make_regression_plot(
  df, "bubble", "m2+m4", "Bubble Sort", "n²"
)

merge_m1m3 <- make_regression_plot(
  df, "merge", "m1+m3", "Merge Sort", "n log n"
)

merge_m2m4 <- make_regression_plot(
  df, "merge", "m2+m4", "Merge Sort", "n log n"
)

quick_m1m3 <- make_regression_plot(
  df, "quick", "m1+m3", "Quick Sort", "n log n"
)

quick_m2m4 <- make_regression_plot(
  df, "quick", "m2+m4", "Quick Sort", "n log n"
)

counting_m1m3 <- make_regression_plot(
  df, "counting", "m1+m3", "Counting Sort", "n"
)

counting_m2m4 <- make_regression_plot(
  df, "counting", "m2+m4", "Counting Sort", "n"
)

# -----------------------------
# 8. PRINT PLOTS
# -----------------------------

bubble_m1m3
bubble_m2m4
merge_m1m3
merge_m2m4
quick_m1m3
quick_m2m4
counting_m1m3
counting_m2m4
