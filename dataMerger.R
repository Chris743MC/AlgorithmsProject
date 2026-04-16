library(tidyverse)

setwd("C:/Users/graur/Documents/Coding/PracticalStats")

# Load each machine file and tag it
m1 <- read_csv("results_adam.csv") %>%
  mutate(machine = "m1")

m2 <- read_csv("results_vlad.csv") %>%
  mutate(machine = "m2")

m3 <- read_csv("results_christian.csv") %>%
  mutate(machine = "m3")

m4 <- read_csv("results_carl.csv") %>%
  mutate(machine = "m4")

# Combine all machines
df <- bind_rows(m1, m2, m3, m4)

# Clean + create variables
df <- df %>%
  mutate(
    algorithm = tolower(algorithm),
    wall_time_s = wall_time_ms / 1000,
    
    # Energy proxy (since power unknown)
    energy_j = wall_time_s,
    
    # Complexity variables
    n = input_size,
    n_log_n = n * log(n),
    n_sq = n^2
  )

# Extract case from filename (very useful later)
df <- df %>%
  mutate(
    case = case_when(
      str_detect(input_file, "random") ~ "random",
      str_detect(input_file, "sorted") ~ "sorted",
      str_detect(input_file, "reverse") ~ "reverse",
      TRUE ~ "other"
    )
  )

# Save clean dataset
write_csv(df, "prepared_results.csv")