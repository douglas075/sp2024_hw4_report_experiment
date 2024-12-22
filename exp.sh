#!/bin/bash

# Usage check
if [ "$#" -ne 4 ] || [ "$1" == "-h" ]; then
  echo "Usage: sh exp.sh <your hw4 exe path> <a> <r> <num_runs>"
  echo "  <your hw4 exe path>: Path to your hw4 executable."
  echo "  <a>: Base number of threads."
  echo "  <r>: Multiplier for threads."
  echo "  <num_runs>: Number of times to run each thread count."
  echo "The script generates a testcase if not present and runs the hw4 program with thread counts of a, ar, ar^2, and ar^3, <num_runs> times each, recording and averaging runtime metrics."
  exit 0
fi

HW4_PATH=$1
A=$2
R=$3
NUM_RUNS=$4

# Define size_of_matrix and num_of_matrix
SIZE_OF_MATRIX=1000
NUM_OF_MATRIX=10

# Debug statements to check the values
echo "Checking if testcase needs to be generated..."
echo "Expected SIZE_OF_MATRIX: $SIZE_OF_MATRIX"
echo "Expected NUM_OF_MATRIX: $NUM_OF_MATRIX"

# Check if "testcase" exists and is up-to-date
if [ ! -f "testcase" ] || [ "$(head -n 1 testcase)" != "$SIZE_OF_MATRIX" ] || [ "$(head -n 2 testcase | tail -n 1)" != "$NUM_OF_MATRIX" ]; then
  echo "generate a testcase of $NUM_OF_MATRIX ${SIZE_OF_MATRIX}*${SIZE_OF_MATRIX} matrix multiplication"
  echo "$SIZE_OF_MATRIX" > testcase
  echo "$NUM_OF_MATRIX" >> testcase
  if [ ! -f "gen" ]; then
    echo "gen file not found. Compiling gen.c..."
    gcc -o gen gen.c
  fi
  echo "Running ./gen $SIZE_OF_MATRIX $NUM_OF_MATRIX"
  ./gen $SIZE_OF_MATRIX $NUM_OF_MATRIX >> testcase
  echo "Testcase generation completed"
fi

# Variables for thread counts
AR1=$(echo "$A * $R" | bc)
AR2=$(echo "$A * $R^2" | bc)
AR3=$(echo "$A * $R^3" | bc)

THREAD_COUNTS=($A $AR1 $AR2 $AR3)

# File to store runtime records
RUNTIME_FILE="runtime_record"
echo "" > $RUNTIME_FILE # Clear the file

# Create temporary files to store run counts
for THREADS in "${THREAD_COUNTS[@]}"; do
  echo 0 > "run_count_$THREADS"
done

run_and_record() {
  THREADS=$1
  TMPFILE=$(mktemp)
  TIMEFILE=$(mktemp)
  echo "$THREADS" > $TMPFILE
  cat testcase >> $TMPFILE
  { /usr/bin/time -f "$THREADS threads real %e\n$THREADS threads user %U\n$THREADS threads sys %S" -o $TIMEFILE $HW4_PATH < $TMPFILE; } 2>&1 | grep -E "$THREADS threads (real|user|sys)" | flock $RUNTIME_FILE -c "cat >> $RUNTIME_FILE"
  cat $TIMEFILE | flock $RUNTIME_FILE -c "cat >> $RUNTIME_FILE"
  rm $TMPFILE
  rm $TIMEFILE

  # Update and print run count
  flock "run_count_$THREADS" -c "RUN_COUNT=\$(cat run_count_$THREADS); RUN_COUNT=\$((RUN_COUNT + 1)); echo \$RUN_COUNT > run_count_$THREADS; echo Finished \$RUN_COUNT-th time running of $THREADS threads"
}

# Run the program NUM_RUNS times for each thread count in parallel
for THREADS in "${THREAD_COUNTS[@]}"; do
  echo "Thread count: $THREADS" >> $RUNTIME_FILE
  echo -e "\e[33mRunning hw4 with $THREADS threads\e[0m"
  for i in $(seq 1 $NUM_RUNS); do
    run_and_record $THREADS &
  done
  wait
  echo "Completed $NUM_RUNS runs for $THREADS threads" >> $RUNTIME_FILE
  echo "" >> $RUNTIME_FILE
  echo "Completed $NUM_RUNS runs for $THREADS threads"
done

calculate_average() {
  local TYPE="$1"     # "real", "user", or "sys"
  local THREADS="$2"  # e.g. 1, 10, 100, 1000

  # Grab lines matching e.g. "1 threads real 0.12" and extract the 4th field
  local AVG=$(
    grep "^$THREADS threads $TYPE" "$RUNTIME_FILE" \
      | awk '{sum += $4; count++} END {if(count>0) printf "%.3f", sum / count; else print 0}'
  )

  echo "$AVG"
}

# Print average runtime for each thread count
DESCRIPTION="average runtime of $A, $AR1, $AR2, $AR3 threads:"
echo -e "\n\e[34m$DESCRIPTION\e[0m"
for THREADS in "${THREAD_COUNTS[@]}"; do
  echo -e "For \e[32m$THREADS\e[0m threads:"
  echo -e "  real: \e[33m$(calculate_average real $THREADS)\e[0m"
  echo -e "  usr:  \e[33m$(calculate_average user $THREADS)\e[0m"
  echo -e "  sys:  \e[33m$(calculate_average sys $THREADS)\e[0m"
done

# Clean up temporary run count files
for THREADS in "${THREAD_COUNTS[@]}"; do
  rm "run_count_$THREADS"
done