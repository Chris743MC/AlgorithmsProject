# Project Background

This project includes:
- Java sorting benchmark (`sortingAlgorithms.java`)
- Python energy benchmark with CodeCarbon (`carbon.py`)
- CSV data generator (`generate_csv_data.py`)

## 1) Requirements

### Windows (PowerShell)
- Java JDK 8+ installed (`javac`, `java` available)
- Python 3.9+ installed

### Linux/macOS
- Java JDK 8+ installed
- Python 3.9+ installed

## 2) Install Python dependency

Windows:
```powershell
python -m pip install codecarbon
```

Linux/macOS:
```bash
python3 -m pip install codecarbon
```

## 3) Generate input CSV data

Generate a file with one integer column (header: `value`):

Windows:
```powershell
python generate_csv_data.py sample.csv 10000 --pattern random --min 0 --max 100000 --seed 42
```

Linux/macOS:
```bash
python3 generate_csv_data.py sample.csv 10000 --pattern random --min 0 --max 100000 --seed 42
```

Patterns:
- `random`
- `sorted`
- `reverse`
- `nearly_sorted`

## 4) Run Java sorting benchmark

Compile:

Windows:
```powershell
javac sortingAlgorithms.java
```

Linux/macOS:
```bash
javac sortingAlgorithms.java
```

Run in-memory benchmark (all algorithms):

```bash
java sortingAlgorithms memory 8000 3 8 10000
```

Arguments:
- `size`: array size
- `warmup`: warmup runs
- `measured`: measured runs
- `maxValue`: random values in `[0, maxValue]`

Run CSV benchmark for one algorithm:

```bash
java sortingAlgorithms csv sample.csv merge
```

Allowed algorithms:
- `bubble`
- `counting`
- `merge`
- `quick`

## 5) Run CodeCarbon energy benchmark (all algorithms)

`carbon.py` reads one CSV column and measures each sorting algorithm separately:
- bubble
- counting
- merge
- quick

Windows:
```powershell
python carbon.py sample.csv 0 30
```

Linux/macOS:
```bash
python3 carbon.py sample.csv 0 30
```

Arguments:
- `sample.csv`: input CSV path
- `0`: zero-based column index to read
- `30`: optional runs per algorithm (default: 30)

Output:
- Console summary with wall time, energy (kWh), emissions (kgCO2eq)
- `carbon_results.csv` with per-algorithm metrics

