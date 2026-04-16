#!/usr/bin/env bash

patterns=("random" "sorted" "reverse" "nearly_sorted")

OUTPUT="combined_results.csv"

touch "$OUTPUT"

already_done () {
    file=$1
    algo=$2

    # Check if this file+algorithm combo already exists in CSV
    grep -q "^$file,$algo," "$OUTPUT"
}

for p in "${patterns[@]}"; do
    bubble_count=0

    for file in $(ls ${p}_*.csv 2>/dev/null | sort -V); do
        if [ -f "$file" ]; then
            echo "Processing file: $file"

            # MERGE
            if ! already_done "$file" "merge"; then
                python carbon.py "$file" 0 merge 30
            else
                echo "Skipping merge (already done)"
            fi

            # QUICK
            if ! already_done "$file" "quick"; then
                python carbon.py "$file" 0 quick 30
            else
                echo "Skipping quick (already done)"
            fi

            # COUNTING
            if ! already_done "$file" "counting"; then
                python carbon.py "$file" 0 counting 30
            else
                echo "Skipping counting (already done)"
            fi

            # BUBBLE (only first 10 per pattern)
            if [ "$bubble_count" -lt 10 ]; then
                if ! already_done "$file" "bubble"; then
                    python carbon.py "$file" 0 bubble 5
                    bubble_count=$((bubble_count + 1))
                else
                    echo "Skipping bubble (already done)"
                    bubble_count=$((bubble_count + 1))
                fi
            fi
        fi
    done
done

echo "Resume benchmark complete!"