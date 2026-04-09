
import java.io.*;
import java.util.*;

public class sortingAlgorithms {

// B u b b l e S o r t ( A )
// f o r i = 0 t o A . l e n g t h − 1
// f o r j = 0 A . l e n g t h − 2 − i
// i f A[ j ] > A[ j + 1 ] t h e n
// swap ( A[ J ] , A[ J + 1 ] )

    public static void bubbleSort( int[] arr){
        
        for (int i = 0; i < arr.length; i++) {
            for (int j = 0; j < arr.length - i - 2; j++) {
                
                if (arr[j] > arr[j+1]) {
                    int temp = arr[j];
                    arr[j] = arr[j+1];
                    arr[j + 1] = temp;

                }
            }
        }
    }

//     C o u n t i n g S o r t ( A , B , k )
// / / l e t C [ 0 . . k ] b e a new a r r a y
// f o r i = 0 t o k
// C[ i ] = 0
// f o r j = 1 t o A . l e n g t h
// C[A[ j ] ] = C[A[ j ] ] + 1
// / ∗ C [ i ] now c o n t a i n s t h e number o f e l e m e n t s
// e q u a l t o i ∗ /
// f o r i = 1 t o k
// C[ i ] = C[ i ] + C[ i − 1 ]
// / ∗ C [ i ] now c o n t a i n s t h e number o f e l e m e n t s
// l e s s t h a n o r e q u a l t o i ∗ /
// f o r j = A . l e n g t h down t o 1
// B [C[A[ j ] ] ] = A[ j ]
// C[A[ j ] ] = C[A[ j ] ] − 1

    public static void countingSort(int[] arr) {
        if (arr == null || arr.length <= 1) return;

        // 1. Find the maximum element to determine the range
        int max = arr[0];
        for (int num : arr) {
            if (num > max) max = num;
        }

        // 2. Create and fill the count array
        int[] count = new int[max + 1];
        for (int num : arr) {
            count[num]++;
        }

        // 3. Modify count array to store cumulative sums (positions)
        for (int i = 1; i <= max; i++) {
            count[i] += count[i - 1];
        }

        // 4. Build the output array (iterate backwards for stability)
        int[] output = new int[arr.length];
        for (int i = arr.length - 1; i >= 0; i--) {
            output[count[arr[i]] - 1] = arr[i];
            count[arr[i]]--;
        }

        // 5. Copy sorted elements back to the original array
        System.arraycopy(output, 0, arr, 0, arr.length);
    }

    public static void mergeSort(int[] arr) {
        if (arr == null || arr.length <= 1) return;
        divide(arr, 0, arr.length - 1);
    }

    private static void divide(int[] arr, int left, int right) {
        if (left < right) {
            // Find the middle point
            int mid = left + (right - left) / 2;

            // Recursively sort first and second halves
            divide(arr, left, mid);
            divide(arr, mid + 1, right);

            // Merge the sorted halves
            merge(arr, left, mid, right);
        }
    }

    private static void merge(int[] arr, int left, int mid, int right) {
        // Sizes of two subarrays to be merged
        int n1 = mid - left + 1;
        int n2 = right - mid;

        // Create temporary arrays
        int[] L = new int[n1];
        int[] R = new int[n2];

        // Copy data to temp arrays
        System.arraycopy(arr, left, L, 0, n1);
        System.arraycopy(arr, mid + 1, R, 0, n2);

        // Merge the temp arrays back into arr[left..right]
        int i = 0, j = 0, k = left;
        while (i < n1 && j < n2) {
            if (L[i] <= R[j]) {
                arr[k++] = L[i++];
            } else {
                arr[k++] = R[j++];
            }
        }

        // Copy remaining elements of L[] if any
        while (i < n1) arr[k++] = L[i++];

        // Copy remaining elements of R[] if any
        while (j < n2) arr[k++] = R[j++];
    }

    public static void QuickSort(int[] arr) {
        if (arr == null || arr.length <= 1) return;
        quickSort(arr, 0, arr.length - 1);
    }

    private static void quickSort(int[] arr, int low, int high) {
        if (low < high) {
            // 1. Partition the array and get the pivot index
            int pi = partition(arr, low, high);

            // 2. Recursively sort elements before and after partition
            quickSort(arr, low, pi - 1);
            quickSort(arr, pi + 1, high);
        }
    }

    private static int partition(int[] arr, int low, int high) {
        // Use the last element as the pivot
        int pivot = arr[high];
        int i = (low - 1); // Index of smaller element

        for (int j = low; j < high; j++) {
            // If current element is smaller than or equal to pivot
            if (arr[j] <= pivot) {
                i++;
                // Swap arr[i] and arr[j]
                int temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
        }

        // Swap the pivot element with the element at i+1
        int temp = arr[i + 1];
        arr[i + 1] = arr[high];
        arr[high] = temp;

        return i + 1;
    }

    public static int[] csvToArray(String filename) throws Exception {
        List<Integer> list = new ArrayList<>();
        BufferedReader br = new BufferedReader(new FileReader(filename));
        String line;
        while ((line = br.readLine()) != null) {
            for (String val : line.split(",")) {
                val = val.trim();
                if (!val.isEmpty()) list.add(Integer.parseInt(val));
            }
        }
        br.close();
        return list.stream().mapToInt(Integer::intValue).toArray();
    }

    @FunctionalInterface
    private interface Sorter {
        void sort(int[] arr);
    }

    private static int[] buildBaseArray(int size, int maxValue, long seed) {
        Random random = new Random(seed);
        int[] base = new int[size];
        for (int i = 0; i < size; i++) {
            base[i] = random.nextInt(maxValue + 1);
        }
        return base;
    }

    private static long checksum(int[] arr) {
        long hash = 1469598103934665603L;
        for (int value : arr) {
            hash ^= value;
            hash *= 1099511628211L;
        }
        return hash;
    }

    private static void benchmark(String name, Sorter sorter, int[] base, int warmupRuns, int measuredRuns) {
        long guard = 0L;

        for (int i = 0; i < warmupRuns; i++) {
            int[] arr = base.clone();
            sorter.sort(arr);
            guard ^= checksum(arr);
        }

        long totalNanos = 0L;
        for (int i = 0; i < measuredRuns; i++) {
            int[] arr = base.clone();
            long start = System.nanoTime();
            sorter.sort(arr);
            long end = System.nanoTime();
            totalNanos += (end - start);
            guard ^= checksum(arr);
        }

        double avgMs = totalNanos / (double) measuredRuns / 1_000_000.0;
        System.out.printf("%-12s avg=%.3f ms checksum=%d%n", name, avgMs, guard);
    }

    private static void benchmarkDeepCopy(String name, Sorter sorter,
                                          int[] base, int repetitions,
                                          PrintWriter csvOut, String inputFile) {
        long startTime = System.currentTimeMillis();

        for (int i = 0; i < repetitions; i++) {
            int[] arrCopy = new int[base.length];
            System.arraycopy(base, 0, arrCopy, 0, base.length);
            sorter.sort(arrCopy);
        }

        long wallTime = System.currentTimeMillis() - startTime;

        System.out.printf("%-12s  reps=%-4d  input_size=%-8d  wall_time=%d ms%n",
                name, repetitions, base.length, wallTime);

        if (csvOut != null) {
            csvOut.printf("%s,%s,%d,%d,%d%n",
                    name, inputFile, base.length, repetitions, wallTime);
        }
    }

    private static int parseArg(String[] args, int index, int defaultValue) {
        if (args.length <= index) {
            return defaultValue;
        }

        try {
            return Integer.parseInt(args[index]);
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }

    public static void main(String[] args) throws Exception {
        String mode = (args.length > 0) ? args[0] : "memory";

        if (mode.equals("csv")) {
            if (args.length < 3) {
                System.out.println("Usage: java sortingAlgorithms csv <csvFile> <algorithm>");
                System.out.println("  algorithms: bubble | counting | merge | quick");
                return;
            }

            String inputFile = args[1];
            String algorithm = args[2].toLowerCase();
            int[] base = csvToArray(inputFile);
            int repetitions = algorithm.equals("bubble") ? 400 : 30;

            File f = new File("results.csv");
            boolean writeHeader = !f.exists() || f.length() == 0;
            PrintWriter csvOut = new PrintWriter(new FileWriter(f, true));
            if (writeHeader) {
                csvOut.println("algorithm,input_file,input_size,repetitions,wall_time_ms");
            }

            System.out.println("=== Deep Copy Benchmark (Paper Method) ===");
            System.out.printf("File: %s | Size: %d | Algorithm: %s | Reps: %d%n",
                    inputFile, base.length, algorithm, repetitions);
            System.out.println("------------------------------------------");

            Sorter sorter;
            switch (algorithm) {
                case "bubble":
                    sorter = sortingAlgorithms::bubbleSort;
                    break;
                case "counting":
                    sorter = sortingAlgorithms::countingSort;
                    break;
                case "merge":
                    sorter = sortingAlgorithms::mergeSort;
                    break;
                case "quick":
                    sorter = sortingAlgorithms::QuickSort;
                    break;
                default:
                    System.out.println("Unknown algorithm: " + algorithm);
                    csvOut.close();
                    return;
            }

            benchmarkDeepCopy(algorithm, sorter, base, repetitions, csvOut, inputFile);
            csvOut.close();
            return;
        }

        int size = parseArg(args, 1, 8000);
        int warmupRuns = parseArg(args, 2, 3);
        int measuredRuns = parseArg(args, 3, 8);
        int maxValue = parseArg(args, 4, 10000);

        if (size <= 0 || warmupRuns < 0 || measuredRuns <= 0 || maxValue < 0) {
            System.out.println("Usage: java sortingAlgorithms memory [size>0] [warmup>=0] [measured>0] [maxValue>=0]");
            return;
        }

        int[] base = buildBaseArray(size, maxValue, 42L);

        System.out.println("=== In-Memory Benchmark ===");
        System.out.printf("size=%d warmup=%d measured=%d maxValue=%d%n",
                size, warmupRuns, measuredRuns, maxValue);
        System.out.println("---------------------------");

        benchmark("BubbleSort", sortingAlgorithms::bubbleSort, base, warmupRuns, measuredRuns);
        benchmark("CountSort", sortingAlgorithms::countingSort, base, warmupRuns, measuredRuns);
        benchmark("MergeSort", sortingAlgorithms::mergeSort, base, warmupRuns, measuredRuns);
        benchmark("QuickSort", sortingAlgorithms::QuickSort, base, warmupRuns, measuredRuns);
    }
}
