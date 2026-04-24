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
# 3. REMOVE EXTREME CASES
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
# 4. HELPER FUNCTION
# -----------------------------

scale_curve <- function(curve, observed_y) {
  curve * (max(observed_y, na.rm = TRUE) / max(curve, na.rm = TRUE))
}

# -----------------------------
# 5. FUNCTION TO MAKE ONE PLOT
# -----------------------------

make_shape_plot <- function(data, algo_name, machine_pair, pretty_name = algo_name) {
  
  algo_df <- data %>%
    filter(
      algorithm == algo_name,
      machine %in% machine_pair
    )
  
  if (algo_name == "quick" && "input_type" %in% names(algo_df)) {
    algo_df <- algo_df %>%
      filter(input_type == "random")
  }
  
  algo_df <- algo_df %>% arrange(n)
  
  if (nrow(algo_df) == 0) {
    stop(
      paste(
        "No data found for algorithm:", algo_name,
        "and machines:", paste(machine_pair, collapse = ", ")
      )
    )
  }
  
  curve_df <- algo_df %>%
    distinct(n) %>%
    arrange(n) %>%
    mutate(
      n_linear = n,
      n_log_n = n * log(n),
      n_sq = n^2,
      scaled_n = scale_curve(n_linear, algo_df$energy_j),
      scaled_nlogn = scale_curve(n_log_n, algo_df$energy_j),
      scaled_nsq = scale_curve(n_sq, algo_df$energy_j)
    )
  
  pair_label <- paste(machine_pair, collapse = " + ")
  
  ggplot(algo_df, aes(x = n, y = energy_j, shape = machine)) +
    geom_point(size = 2.2, alpha = 0.75) +
    
    geom_line(
      data = curve_df,
      aes(x = n, y = scaled_n, color = "O(n)"),
      linewidth = 0.9,
      inherit.aes = FALSE
    ) +
    geom_line(
      data = curve_df,
      aes(x = n, y = scaled_nlogn, color = "O(n log n)"),
      linewidth = 0.9,
      inherit.aes = FALSE
    ) +
    geom_line(
      data = curve_df,
      aes(x = n, y = scaled_nsq, color = "O(n²)"),
      linewidth = 0.9,
      inherit.aes = FALSE
    ) +
    
    scale_color_manual(
      values = c(
        "O(n)" = "blue",
        "O(n log n)" = "darkgreen",
        "O(n²)" = "red"
      )
    ) +
    
    labs(
      title = paste(pretty_name, ":", pair_label),
      x = "Input size (n)",
      y = "Energy (J)",
      shape = "Machine",
      color = "Reference curve"
    ) +
    
    theme_minimal(base_size = 12)
}

# -----------------------------
# 6. MACHINE PAIRS
# -----------------------------

pair_1 <- c("m1", "m3")
pair_2 <- c("m2", "m4")

# -----------------------------
# 7. GENERATE 8 PLOTS
# -----------------------------

bubble_plot_13   <- make_shape_plot(df, "bubble",   pair_1, "Bubble Sort")
bubble_plot_24   <- make_shape_plot(df, "bubble",   pair_2, "Bubble Sort")

merge_plot_13    <- make_shape_plot(df, "merge",    pair_1, "Merge Sort")
merge_plot_24    <- make_shape_plot(df, "merge",    pair_2, "Merge Sort")

quick_plot_13    <- make_shape_plot(df, "quick",    pair_1, "Quick Sort")
quick_plot_24    <- make_shape_plot(df, "quick",    pair_2, "Quick Sort")

counting_plot_13 <- make_shape_plot(df, "counting", pair_1, "Counting Sort")
counting_plot_24 <- make_shape_plot(df, "counting", pair_2, "Counting Sort")

# -----------------------------
# 8. PRINT PLOTS
# -----------------------------

bubble_plot_13
bubble_plot_24

merge_plot_13
merge_plot_24

quick_plot_13
quick_plot_24

counting_plot_13
counting_plot_24
