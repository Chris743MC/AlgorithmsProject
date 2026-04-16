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
    def median_of_three(low, high):
        mid = (low + high) // 2

        a = arr[low]
        b = arr[mid]
        c = arr[high]

        if a <= b <= c or c <= b <= a:
            return mid
        elif b <= a <= c or c <= a <= b:
            return low
        else:
            return high

    def partition(low, high):
        pivot_index = median_of_three(low, high)
        arr[pivot_index], arr[high] = arr[high], arr[pivot_index]

        pivot = arr[high]
        i = low - 1
        for j in range(low, high):
            if arr[j] <= pivot:
                i += 1
                arr[i], arr[j] = arr[j], arr[i]

        arr[i + 1], arr[high] = arr[high], arr[i + 1]
        return i + 1

    def quick_sort_impl(low, high):
        while low < high:
            pi = partition(low, high)

            # Recurse on smaller side first to reduce maximum recursion depth
            if pi - low < high - pi:
                quick_sort_impl(low, pi - 1)
                low = pi + 1
            else:
                quick_sort_impl(pi + 1, high)
                high = pi - 1

    quick_sort_impl(0, len(arr) - 1)


def csv_to_arr(file_path, column_index):
    values = []
    col_idx = int(column_index)

    with open(file_path, mode="r", encoding="utf-8") as f:
        reader = csv.reader(f)
        for row in reader:
            if col_idx < len(row):
                try:
                    values.append(int(row[col_idx].replace('"', "").strip()))
                except ValueError:
                    continue

    return values


def run_energy_benchmark(name, sorter, base_arr, runs):
    tracker = EmissionsTracker(
        project_name=f"{name}_benchmark",
        measure_power_secs=1,
        save_to_file=False,
        log_level="error",
    )

    start = time.perf_counter()
    tracker.start()

    for _ in range(runs):
        arr_copy = list(base_arr)
        sorter(arr_copy)

    emissions_kg = tracker.stop()
    elapsed = time.perf_counter() - start

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


def get_sorter(name):
    algorithms = {
        "bubble": bubble_sort,
        "counting": counting_sort,
        "merge": merge_sort,
        "quick": quick_sort,
    }
    return algorithms.get(name)


def append_result(output_file, input_file, result):
    write_header = False
    try:
        with open(output_file, "r", encoding="utf-8"):
            pass
    except FileNotFoundError:
        write_header = True

    with open(output_file, mode="a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        if write_header:
            writer.writerow(
                [
                    "input_file",
                    "algorithm",
                    "input_size",
                    "runs",
                    "wall_time_s",
                    "energy_kwh",
                    "emissions_kgco2eq",
                ]
            )

        writer.writerow(
            [
                input_file,
                result["algorithm"],
                result["input_size"],
                result["runs"],
                f"{result['wall_time_s']:.6f}",
                f"{result['energy_kwh']:.12f}",
                f"{result['emissions_kg']:.12f}",
            ]
        )


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python carbon.py <csv_file> <column_index> <algorithm> [runs]")
        sys.exit(1)

    file_arg = sys.argv[1]
    col_arg = sys.argv[2]
    algorithm_name = sys.argv[3].lower()
    runs = int(sys.argv[4]) if len(sys.argv) > 4 else 30

    sorter = get_sorter(algorithm_name)
    if sorter is None:
        print("Unknown algorithm. Use: bubble, counting, merge, quick")
        sys.exit(1)

    original_arr = csv_to_arr(file_arg, col_arg)
    if not original_arr:
        print("No numeric data found in the requested CSV column.")
        sys.exit(1)

    print(f"Measuring {algorithm_name} on {file_arg} ...")
    result = run_energy_benchmark(algorithm_name, sorter, original_arr, runs)

    print(
        f"{algorithm_name:<10} time={result['wall_time_s']:.3f}s "
        f"energy={result['energy_kwh']:.8f} kWh "
        f"emissions={result['emissions_kg']:.8f} kgCO2eq"
    )

    output_file = "combined_results.csv"
    append_result(output_file, file_arg, result)

    print(f"Saved result to {output_file}")
