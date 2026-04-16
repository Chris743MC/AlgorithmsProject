import csv
import math
import random


def generate_values(size, pattern, min_value, max_value, seed):
    rng = random.Random(seed)

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
        if header:
            writer.writerow([header])
        for value in values:
            writer.writerow([value])


def generate_log_spaced_sizes(min_size, max_size, num_points):
    sizes = [
        int(round(min_size * (max_size / min_size) ** (i / (num_points - 1))))
        for i in range(num_points)
    ]

    # Remove accidental duplicates from rounding while preserving order
    unique_sizes = []
    seen = set()
    for size in sizes:
        if size not in seen:
            unique_sizes.append(size)
            seen.add(size)

    return unique_sizes


def main():
    patterns = ["random", "sorted", "reverse", "nearly_sorted"]

    min_size = 10_000
    max_size = 1_000_000
    num_points = 30

    min_val = 0
    max_val = 10_000
    seed = 42
    header = "value"

    sizes = generate_log_spaced_sizes(min_size, max_size, num_points)

    print("Generating CSV benchmark files...")
    print(f"Patterns: {patterns}")
    print(f"Sizes ({len(sizes)} points): {sizes}")
    print()

    for pattern in patterns:
        for size in sizes:
            filename = f"{pattern}_{size}.csv"
            values = generate_values(size, pattern, min_val, max_val, seed)
            write_csv(filename, values, header)
            print(f"Successfully created: {filename} (Size: {size})")


if __name__ == "__main__":
    main()
