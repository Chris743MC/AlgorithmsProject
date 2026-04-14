### Quick Summary of the Workflow:
1. Need to install  the python env,
2. sudo apt install python3-pip,
3. pip install codecarbon,
4. sudo apt install linux-tools-common linux-tools-$(uname -r),
5. sudo apt update && sudo apt install python3-venv -y,
6. python3 -m venv venv,
7. source venv/bin/activate,
1.  **Python:** Run `python3 generate_data.py` to create the 28 test cases.
2.  **Java:** Run `javac sortingAlgorithms.java` to prepare the benchmarking engine.
3.  **Bash:** Run sudo chmod +x min.sh and `./min.sh` to execute the tests.
4.  **Excel:** Open the resulting `results.csv` to create the graphs for your **A1 Poster**.
