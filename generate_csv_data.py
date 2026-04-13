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
    parser = argparse.ArgumentParser(description="Generate integer CSV data for sorting benchmarks.")
    parser.add_argument("output", help="Output CSV filename")
    parser.add_argument("size", type=int, help="Number of values to generate")
    parser.add_argument(
        "--pattern",
        choices=["random", "sorted", "reverse", "nearly_sorted"],
        default="random",
        help="Distribution pattern for generated values",
    )
    parser.add_argument("--min", dest="min_value", type=int, default=0, help="Minimum value")
    parser.add_argument("--max", dest="max_value", type=int, default=100000, help="Maximum value")
    parser.add_argument("--seed", type=int, default=42, help="Random seed")
    parser.add_argument("--header", default="value", help="Optional CSV header for the column")

    args = parser.parse_args()

    if args.size <= 0:
        raise ValueError("size must be > 0")

    if args.max_value < args.min_value:
        raise ValueError("--max must be >= --min")

    values = generate_values(args.size, args.pattern, args.min_value, args.max_value, args.seed)
    write_csv(args.output, values, args.header)

    # Echo the exact settings back to the user so benchmark inputs are easy to reproduce.
    print(
        f"Generated {args.size} values in {args.output} "
        f"(pattern={args.pattern}, min={args.min_value}, max={args.max_value})"
    )


if __name__ == "__main__":
    main()
