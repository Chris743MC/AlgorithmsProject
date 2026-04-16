library(tidyverse)

setwd("C:/Users/graur/Desktop/AlgorithmsProject-main")

# -----------------------------
# 1. LOAD DATA
# -----------------------------

df <- read_csv("combined_results.csv")

# -----------------------------
# 2. CHECK REQUIRED COLUMNS
# -----------------------------

required_cols <- c("input_file", "algorithm", "input_size", "energy_kwh")
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
    n = as.numeric(input_size),
    energy_uwh = as.numeric(energy_kwh) * 1e9,
    n_log_n = n * log(n),
    n_sq = n^2
  ) %>%
  drop_na(n, energy_uwh) %>%
  filter(algorithm == "bubble" | n >= 50000)

# -----------------------------
# 4. REMOVE EXTREME CASES
# -----------------------------

plot_df <- plot_df %>%
  group_by(algorithm) %>%
  mutate(
    q1 = quantile(energy_uwh, 0.25, na.rm = TRUE),
    q3 = quantile(energy_uwh, 0.75, na.rm = TRUE),
    iqr = q3 - q1,
    lower_bound = q1 - 1.5 * iqr,
    upper_bound = q3 + 1.5 * iqr
  ) %>%
  filter(energy_uwh >= lower_bound, energy_uwh <= upper_bound) %>%
  ungroup() %>%
  select(-q1, -q3, -iqr, -lower_bound, -upper_bound)

# -----------------------------
# 5. HELPER FUNCTION
# -----------------------------

scale_curve <- function(curve, observed_y) {
  curve * (max(observed_y, na.rm = TRUE) / max(curve, na.rm = TRUE))
}

# -----------------------------
# 6. FUNCTION TO MAKE TOTAL ENERGY PLOT
# -----------------------------

make_energy_plot <- function(data, algo_name, pretty_name = algo_name) {
  
  algo_df <- data %>%
    filter(algorithm == algo_name) %>%
    arrange(n)
  
  if (nrow(algo_df) == 0) {
    stop(paste("No data found for algorithm:", algo_name))
  }
  
  curve_df <- algo_df %>%
    distinct(n) %>%
    arrange(n) %>%
    mutate(
      ref_n = n,
      ref_nlogn = n * log(n),
      ref_nsq = n^2,
      scaled_n = scale_curve(ref_n, algo_df$energy_uwh),
      scaled_nlogn = scale_curve(ref_nlogn, algo_df$energy_uwh),
      scaled_nsq = scale_curve(ref_nsq, algo_df$energy_uwh)
    ) %>%
    pivot_longer(
      cols = c(scaled_n, scaled_nlogn, scaled_nsq),
      names_to = "curve",
      values_to = "curve_value"
    ) %>%
    mutate(
      curve = recode(
        curve,
        scaled_n = "n",
        scaled_nlogn = "n log n",
        scaled_nsq = "n²"
      )
    )
  
  ggplot() +
    geom_point(
      data = algo_df,
      aes(x = n, y = energy_uwh),
      color = "black",
      size = 2
    ) +
    geom_line(
      data = curve_df,
      aes(x = n, y = curve_value, color = curve),
      linewidth = 1
    ) +
    scale_color_manual(
      values = c("n" = "blue", "n log n" = "green", "n²" = "red")
    ) +
    labs(
      title = paste(pretty_name, "- Energy vs Input Size"),
      x = "Input size (n)",
      y = "Energy (µWh)",
      color = "Reference curve"
    ) +
    theme_minimal(base_size = 12) +
    scale_y_continuous(labels = scales::label_number())
}

# -----------------------------
# 7. FUNCTION TO MAKE NORMALIZED ENERGY PLOT (UPDATED)
# -----------------------------

make_normalized_plot <- function(data, algo_name, pretty_name = algo_name) {
  
  algo_df <- data %>%
    filter(algorithm == algo_name) %>%
    arrange(n) %>%
    mutate(
      energy_per_n = energy_uwh / n
    )
  
  if (nrow(algo_df) == 0) {
    stop(paste("No data found for algorithm:", algo_name))
  }
  
  ggplot() +
    geom_point(
      data = algo_df,
      aes(x = n, y = energy_per_n),
      color = "black",
      size = 2
    ) +
    labs(
      title = paste(pretty_name, "- Normalized Energy vs Input Size"),
      x = "Input size (n)",
      y = "Energy (µWh)"
    ) +
    theme_minimal(base_size = 12) +
    scale_y_continuous(labels = scales::label_number())
}

# -----------------------------
# 8. R-SQUARED SUMMARY
# -----------------------------

get_r2 <- function(data, predictor_name) {
  model_formula <- as.formula(paste("energy_uwh ~", predictor_name))
  model <- lm(model_formula, data = data)
  summary(model)$r.squared
}

r2_table <- plot_df %>%
  group_by(algorithm) %>%
  group_modify(~{
    tibble(
      points = nrow(.x),
      r2_n = get_r2(.x, "n"),
      r2_nlogn = get_r2(.x, "n_log_n"),
      r2_nsq = get_r2(.x, "n_sq")
    )
  }) %>%
  ungroup() %>%
  mutate(
    best_fit = case_when(
      r2_n >= r2_nlogn & r2_n >= r2_nsq ~ "n",
      r2_nlogn >= r2_n & r2_nlogn >= r2_nsq ~ "n log n",
      TRUE ~ "n^2"
    )
  ) %>%
  arrange(algorithm)

point_counts <- plot_df %>%
  count(algorithm, name = "num_points")

r2_table_display <- r2_table %>%
  mutate(
    r2_n = round(r2_n, 4),
    r2_nlogn = round(r2_nlogn, 4),
    r2_nsq = round(r2_nsq, 4)
  )

cat("\nPoints used per algorithm:\n")
print(point_counts)

cat("\nR-squared summary for total energy:\n")
print(r2_table_display)

# -----------------------------
# 9. GENERATE PLOTS
# -----------------------------

bubble_energy_plot   <- make_energy_plot(plot_df, "bubble",   "Bubble Sort")
counting_energy_plot <- make_energy_plot(plot_df, "counting", "Counting Sort")
merge_energy_plot    <- make_energy_plot(plot_df, "merge",    "Merge Sort")
quick_energy_plot    <- make_energy_plot(plot_df, "quick",    "Quick Sort")

bubble_norm_plot     <- make_normalized_plot(plot_df, "bubble",   "Bubble Sort")
counting_norm_plot   <- make_normalized_plot(plot_df, "counting", "Counting Sort")
merge_norm_plot      <- make_normalized_plot(plot_df, "merge",    "Merge Sort")
quick_norm_plot      <- make_normalized_plot(plot_df, "quick",    "Quick Sort")

# -----------------------------
# 10. PRINT PLOTS
# -----------------------------

bubble_energy_plot
counting_energy_plot
merge_energy_plot
quick_energy_plot

bubble_norm_plot
counting_norm_plot
merge_norm_plot
quick_norm_plot
