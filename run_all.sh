#!/bin/bash

SIZES=(25000 50000 75000 100000 200000 300000 400000 500000)
LARGE_SIZES=(600000 700000 800000 900000 1000000)
QUICK_WORST_SIZES=(25000 50000 75000 100000 125000 150000 175000 200000)
RUNS=30
BUBBLE_RUNS=30

echo "Compiling..."
javac sortingAlgorithms.java
gcc -o rapl_measure rapl_measure.c
echo "Done compiling."
echo ""

# --- Bubble Sort---
echo "=== Bubble Sort ==="
for size in "${SIZES[@]}"; do
    echo "  Bubble Sort | sorted   | size=$size"
    sudo ./rapl_measure $BUBBLE_RUNS inputs/sorted_${size}.csv bubble

    echo "  Bubble Sort | reverse  | size=$size"
    sudo ./rapl_measure $BUBBLE_RUNS inputs/reverse_${size}.csv bubble

    for r in $(seq 1 10); do
        echo "  Bubble Sort | random_$r | size=$size"
        sudo ./rapl_measure 4 inputs/random_${size}_${r}.csv bubble
    done
done

# --- Merge Sort---
echo "=== Merge Sort ==="
ALL_MERGE=("${SIZES[@]}" "${LARGE_SIZES[@]}")
for size in "${ALL_MERGE[@]}"; do
    echo "  Merge Sort | alternating | size=$size"
    sudo ./rapl_measure $RUNS inputs/alternating_${size}.csv merge

    echo "  Merge Sort | sorted      | size=$size"
    sudo ./rapl_measure $RUNS inputs/sorted_${size}.csv merge

    for r in $(seq 1 10); do
        echo "  Merge Sort | random_$r   | size=$size"
        sudo ./rapl_measure 3 inputs/random_${size}_${r}.csv merge
    done
done

# --- Quick Sort ---
echo "=== Quick Sort ==="
for size in "${QUICK_WORST_SIZES[@]}"; do
    echo "  Quick Sort | reverse (worst) | size=$size"
    sudo ./rapl_measure $RUNS inputs/quick_worst_${size}.csv quick
done

ALL_QUICK=("${SIZES[@]}" "${LARGE_SIZES[@]}")
for size in "${ALL_QUICK[@]}"; do
    echo "  Quick Sort | evenly (best) | size=$size"
    sudo ./rapl_measure $RUNS inputs/evenly_${size}.csv quick

    for r in $(seq 1 10); do
        echo "  Quick Sort | random_$r    | size=$size"
        sudo ./rapl_measure 3 inputs/random_${size}_${r}.csv quick
    done
done

# --- Counting Sort ---
echo "=== Counting Sort ==="
ALL_COUNT=("${SIZES[@]}" "${LARGE_SIZES[@]}")
for size in "${ALL_COUNT[@]}"; do
    echo "  Counting Sort | worst (big k) | size=$size"
    sudo ./rapl_measure $RUNS inputs/counting_worst_${size}.csv counting

    echo "  Counting Sort | best (small k)| size=$size"
    sudo ./rapl_measure $RUNS inputs/counting_best_${size}.csv counting
done

echo ""
echo "=== All done. Results in results.csv ==="