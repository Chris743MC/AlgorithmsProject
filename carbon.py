import csv
import math
import sys
import time
from codecarbon import EmissionsTracker


def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]


def counting_sort(arr):
    if len(arr) <= 1:
        return

    min_val = min(arr)
    max_val = max(arr)
    offset = -min_val if min_val < 0 else 0
    count = [0] * (max_val + offset + 1)

    for value in arr:
        count[value + offset] += 1

    idx = 0
    for value, c in enumerate(count):
        actual = value - offset
        for _ in range(c):
            arr[idx] = actual
            idx += 1


def merge_sort(arr):
    if len(arr) > 1:
        mid = len(arr) // 2
        left = arr[:mid]
        right = arr[mid:]

        merge_sort(left)
        merge_sort(right)

        i = j = k = 0

        while i < len(left) and j < len(right):
            if left[i] <= right[j]:
                arr[k] = left[i]
                i += 1
            else:
                arr[k] = right[j]
                j += 1
            k += 1

        while i < len(left):
            arr[k] = left[i]
            i += 1
            k += 1

        while j < len(right):
            arr[k] = right[j]
            j += 1
            k += 1


def quick_sort(arr):
    def partition(low, high):
        pivot = arr[high]
        i = low - 1
        for j in range(low, high):
            if arr[j] <= pivot:
                i += 1
                arr[i], arr[j] = arr[j], arr[i]
        arr[i + 1], arr[high] = arr[high], arr[i + 1]
        return i + 1

    def quick_sort_impl(low, high):
        if low < high:
            pi = partition(low, high)
            quick_sort_impl(low, pi - 1)
            quick_sort_impl(pi + 1, high)

    quick_sort_impl(0, len(arr) - 1)


def csv_to_arr(file_path, column_index):
    values = []
    col_idx = int(column_index)

    with open(file_path, mode="r", encoding="utf-8") as f:
        # Read each row and keep only numeric values from the requested column.
        # This makes the script tolerant of headers and mixed CSV content.
        reader = csv.reader(f)
        for row in reader:
            if col_idx < len(row):
                try:
                    values.append(int(row[col_idx].replace('"', "").strip()))
                except ValueError:
                    # Ignore headers, blank cells, and any non-numeric rows.
                    continue

    return values


def run_energy_benchmark(name, sorter, base_arr, runs):
    # Track one algorithm separately so the energy and emissions numbers stay isolated.
    tracker = EmissionsTracker(
        project_name=f"{name}_benchmark",
        measure_power_secs=1,
        save_to_file=False,
        log_level="error",
    )

    start = time.perf_counter()
    tracker.start()

    # Reuse the same input data, but sort a fresh copy each time.
    # That keeps each run fair and prevents one sort from affecting the next.
    for _ in range(runs):
        arr_copy = list(base_arr)
        sorter(arr_copy)

    emissions_kg = tracker.stop()
    elapsed = time.perf_counter() - start

    # Some CodeCarbon versions expose energy data through final_emissions_data.
    # If it is missing, fall back to NaN so the CSV output still stays valid.
    energy_kwh = None
    if getattr(tracker, "final_emissions_data", None) is not None:
        energy_kwh = tracker.final_emissions_data.energy_consumed

    if energy_kwh is None:
        energy_kwh = math.nan

    if emissions_kg is None:
        emissions_kg = math.nan

    return {
        "algorithm": name,
        "runs": runs,
        "input_size": len(base_arr),
        "wall_time_s": elapsed,
        "energy_kwh": energy_kwh,
        "emissions_kg": emissions_kg,
    }


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python carbon.py <csv_file> <column_index> [runs]")
        sys.exit(1)

    file_arg = sys.argv[1]
    col_arg = sys.argv[2]
    runs = int(sys.argv[3]) if len(sys.argv) > 3 else 30

    original_arr = csv_to_arr(file_arg, col_arg)
    if not original_arr:
        print("No numeric data found in the requested CSV column.")
        sys.exit(1)

    # Measure each sorter separately so the energy numbers stay readable.
    algorithms = [
        ("bubble", bubble_sort),
        ("counting", counting_sort),
        ("merge", merge_sort),
        ("quick", quick_sort),
    ]

    print("Measuring energy usage per sorting algorithm...")
    print(f"Input size: {len(original_arr)} | Runs per algorithm: {runs}")
    print("---------------------------------------------------------")

    results = []
    for name, sorter in algorithms:
        # Run the same wrapper for each algorithm so the output format stays identical.
        result = run_energy_benchmark(name, sorter, original_arr, runs)
        results.append(result)
        print(
            f"{name:<10} time={result['wall_time_s']:.3f}s "
            f"energy={result['energy_kwh']:.8f} kWh "
            f"emissions={result['emissions_kg']:.8f} kgCO2eq"
        )

    output_file = "carbon_results.csv"
    with open(output_file, mode="w", newline="", encoding="utf-8") as f:
        # Write a machine-readable summary so benchmark runs can be compared later.
        writer = csv.writer(f)
        writer.writerow([
            "algorithm",
            "input_size",
            "runs",
            "wall_time_s",
            "energy_kwh",
            "emissions_kgco2eq",
        ])
        for row in results:
            writer.writerow([
                row["algorithm"],
                row["input_size"],
                row["runs"],
                f"{row['wall_time_s']:.6f}",
                f"{row['energy_kwh']:.12f}",
                f"{row['emissions_kg']:.12f}",
            ])

    print("---------------------------------------------------------")
    print(f"Saved detailed results to {output_file}")
