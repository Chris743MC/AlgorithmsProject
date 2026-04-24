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
    n = as.numeric(input_size),
    n_log_n = n * log(n),
    n_sq = n^2
  ) %>%
  drop_na(time, n) %>%
  filter(algorithm == "bubble" | n >= 50000)

# -----------------------------
# 4. REMOVE EXTREME CASES
# -----------------------------

plot_df <- plot_df %>%
  group_by(algorithm) %>%
  mutate(
    q1 = quantile(time, 0.25, na.rm = TRUE),
    q3 = quantile(time, 0.75, na.rm = TRUE),
    iqr = q3 - q1,
    lower_bound = q1 - 1.5 * iqr,
    upper_bound = q3 + 1.5 * iqr
  ) %>%
  filter(time >= lower_bound, time <= upper_bound) %>%
  ungroup() %>%
  select(-q1, -q3, -iqr, -lower_bound, -upper_bound)

# -----------------------------
# 5. COUNT POINTS
# -----------------------------

point_counts <- plot_df %>%
  count(algorithm, name = "num_points")

# -----------------------------
# 6. HELPER FUNCTIONS
# -----------------------------

get_r2 <- function(data, predictor_name) {
  model_formula <- as.formula(paste("time ~", predictor_name))
  model <- lm(model_formula, data = data)
  summary(model)$r.squared
}

get_corr <- function(data, predictor_name) {
  cor(data$time, data[[predictor_name]], use = "complete.obs", method = "pearson")
}

predictor_label <- function(predictor_name) {
  case_when(
    predictor_name == "n" ~ "n",
    predictor_name == "n_log_n" ~ "n log n",
    predictor_name == "n_sq" ~ "n²",
    TRUE ~ predictor_name
  )
}

# -----------------------------
# 7. CORRELATION / R^2 SUMMARY
# -----------------------------

fit_table <- plot_df %>%
  group_by(algorithm) %>%
  group_modify(~{
    tibble(
      points = nrow(.x),
      corr_n = get_corr(.x, "n"),
      corr_nlogn = get_corr(.x, "n_log_n"),
      corr_nsq = get_corr(.x, "n_sq"),
      r2_n = get_r2(.x, "n"),
      r2_nlogn = get_r2(.x, "n_log_n"),
      r2_nsq = get_r2(.x, "n_sq")
    )
  }) %>%
  ungroup() %>%
  mutate(
    best_fit = case_when(
      abs(corr_n) >= abs(corr_nlogn) & abs(corr_n) >= abs(corr_nsq) ~ "n",
      abs(corr_nlogn) >= abs(corr_n) & abs(corr_nlogn) >= abs(corr_nsq) ~ "n_log_n",
      TRUE ~ "n_sq"
    ),
    best_fit_label = predictor_label(best_fit)
  ) %>%
  arrange(algorithm)

fit_table_display <- fit_table %>%
  mutate(
    corr_n = round(corr_n, 4),
    corr_nlogn = round(corr_nlogn, 4),
    corr_nsq = round(corr_nsq, 4),
    r2_n = round(r2_n, 4),
    r2_nlogn = round(r2_nlogn, 4),
    r2_nsq = round(r2_nsq, 4)
  )

cat("\nPoints used per algorithm (random only, bubble uncapped, others n >= 50000, after IQR filter):\n")
print(point_counts)

cat("\nCorrelation / R-squared summary:\n")
print(fit_table_display)

# -----------------------------
# 8. FUNCTION TO MAKE BEST-FIT PLOT
# -----------------------------

make_best_fit_plot <- function(data, fit_summary, algo_name, pretty_name = algo_name) {
  
  algo_df <- data %>%
    filter(algorithm == algo_name) %>%
    arrange(n)
  
  if (nrow(algo_df) == 0) {
    stop(paste("No data found for algorithm:", algo_name))
  }
  
  best_predictor <- fit_summary %>%
    filter(algorithm == algo_name) %>%
    pull(best_fit)
  
  if (length(best_predictor) == 0) {
    stop(paste("No best-fit predictor found for algorithm:", algo_name))
  }
  
  best_predictor <- best_predictor[[1]]
  x_label <- predictor_label(best_predictor)
  
  algo_df <- algo_df %>%
    mutate(
      x_best = case_when(
        best_predictor == "n" ~ n,
        best_predictor == "n_log_n" ~ n_log_n,
        best_predictor == "n_sq" ~ n_sq
      )
    )
  
  corr_value <- fit_summary %>%
    filter(algorithm == algo_name) %>%
    mutate(
      best_corr = case_when(
        best_fit == "n" ~ corr_n,
        best_fit == "n_log_n" ~ corr_nlogn,
        best_fit == "n_sq" ~ corr_nsq
      )
    ) %>%
    pull(best_corr)
  
  corr_value <- round(corr_value[[1]], 4)
  
  ggplot(algo_df, aes(x = x_best, y = time)) +
    geom_point(color = "black", size = 2) +
    geom_smooth(method = "lm", se = FALSE, color = "blue", linewidth = 1) +
    labs(
      title = paste(pretty_name, "- Best Linear Fit"),
      subtitle = paste("Best predictor:", x_label, "| Correlation =", corr_value),
      x = x_label,
      y = "Execution Time (ms)"
    ) +
    theme_minimal(base_size = 12) +
    scale_y_continuous(labels = scales::label_number()) +
    scale_x_continuous(labels = scales::label_number())
}

# -----------------------------
# 9. GENERATE 4 PLOTS
# -----------------------------

bubble_best_plot   <- make_best_fit_plot(plot_df, fit_table, "bubble",   "Bubble Sort")
counting_best_plot <- make_best_fit_plot(plot_df, fit_table, "counting", "Counting Sort")
merge_best_plot    <- make_best_fit_plot(plot_df, fit_table, "merge",    "Merge Sort")
quick_best_plot    <- make_best_fit_plot(plot_df, fit_table, "quick",    "Quick Sort")

# -----------------------------
# 10. PRINT PLOTS
# -----------------------------

bubble_best_plot
counting_best_plot
merge_best_plot
quick_best_plot
