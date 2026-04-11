import sys
import csv
from codecarbon import EmissionsTracker

def merge_sort_algorithm(arr):
    if len(arr) > 1:
        mid = len(arr) // 2
        L = arr[:mid]
        R = arr[mid:]

        merge_sort_algorithm(L)
        merge_sort_algorithm(R)

        i = j = k = 0

        # Merge the temp arrays back into arr
        while i < len(L) and j < len(R):
            if L[i] <= R[j]:
                arr[k] = L[i]
                i += 1
            else:
                arr[k] = R[j]
                j += 1
            k += 1

        # Checking if any element was left
        while i < len(L):
            arr[k] = L[i]
            i += 1
            k += 1

        while j < len(R):
            arr[k] = R[j]
            j += 1
            k += 1

def csv_to_arr(file_path, column_index):
    temp_list = []
    try:
        col_idx = int(column_index)
        with open(file_path, mode='r', encoding='utf-8') as f:
            reader = csv.reader(f)
            for row in reader:
                if col_idx < len(row):
                    try:
                        # Strip quotes and whitespace then convert to int
                        value = int(row[col_idx].replace('"', '').strip())
                        temp_list.append(value)
                    except ValueError:
                        continue # Skip headers or non-numeric rows
    except Exception as e:
        print(f"Error reading file: {e}")
    
    return temp_list

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python merge_sort.py <csv_file> <column_index>")
        sys.exit(1)

    file_arg = sys.argv[1]
    col_arg = sys.argv[2]

    # 1. Import array once
    original_arr = csv_to_arr(file_arg, col_arg)

    # Initialize CodeCarbon Tracker
    # 'measure_power_secs' sets how often it samples
    tracker = EmissionsTracker(project_name="merge_sort_benchmark", measure_power_secs=1)
    
    print("Starting energy tracking...")
    tracker.start()

    # 2. Loop 400 times to capture measurable energy usage
    for _ in range(400):
        # 3. Create a fresh copy for each sort
        arr_copy = list(original_arr)
        merge_sort_algorithm(arr_copy)

    emissions_data = tracker.stop()
    print(f"\nFinished! Energy consumed (kWh): {emissions_data}")
