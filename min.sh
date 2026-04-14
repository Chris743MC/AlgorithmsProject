#!/usr/bin/env bash

# Define the exact patterns you used in your Python script
patterns=("random" "sorted" "reverse" "nearly_sorted")

# Delete old results so you start fresh
rm -f results.csv

for p in "${patterns[@]}"; do
    # Only pick files that start with the pattern (e.g., random_100.csv)
    for file in ${p}_*.csv; do
        if [ -f "$file" ]; then
            echo "Benchmarking project file: $file"

            # Run the algorithms
            java sortingAlgorithms csv "$file" merge
            java sortingAlgorithms csv "$file" quick
            java sortingAlgorithms csv "$file" counting

            # Determine line count to skip Bubble Sort on huge files
            lines=$(wc -l < "$file")
            if [ "$lines" -lt 5001 ]; then
                java sortingAlgorithms csv "$file" bubble
            fi
        fi
    done
done

echo "Benchmark Complete! Open results.csv to see your data."
