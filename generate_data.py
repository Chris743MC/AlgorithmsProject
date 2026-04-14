import argparse
import csv
import random


def generate_values(size, pattern, min_value, max_value, seed):
    rng = random.Random(seed)

    # Each pattern creates a different kind of benchmark input distribution.
    if pattern == "random":
        return [rng.randint(min_value, max_value) for _ in range(size)]

    if pattern == "sorted":
        return list(range(min_value, min_value + size))

    if pattern == "reverse":
        return list(range(min_value + size - 1, min_value - 1, -1))

    if pattern == "nearly_sorted":
        values = list(range(min_value, min_value + size))
        swaps = max(1, size // 20)
        for _ in range(swaps):
            i = rng.randint(0, size - 1)
            j = rng.randint(0, size - 1)
            values[i], values[j] = values[j], values[i]
        return values

    raise ValueError(f"Unknown pattern: {pattern}")


def write_csv(path, values, header):
    with open(path, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        # A single-column header keeps the file simple for both readers.
        if header:
            writer.writerow([header])
        for value in values:
            writer.writerow([value])


def main():
    # Standardize patterns based on COMP20280 requirements
    patterns = ["random", "sorted", "reverse", "nearly_sorted"]
    
    # Standardize sizes based on n = [100, ..., 10000] requirement
    sizes = [100, 500, 1000, 2500, 5000, 7500, 10000]

    # Default settings for the benchmark data
    min_val = 0
    max_val = 10000
    seed = 42
    header = "value"

    for pattern in patterns:
        for size in sizes:
            # Generate a unique filename like 'random_5000.csv'
            filename = f"{pattern}_{size}.csv"
            
            # Generate the list of integers
            values = generate_values(size, pattern, min_val, max_val, seed)
            
            # Write to the specific CSV file
            write_csv(filename, values, header)
            
            print(f"Successfully created: {filename} (Size: {size})")

if __name__ == "__main__":
    main()


if __name__ == "__main__":
    main()
