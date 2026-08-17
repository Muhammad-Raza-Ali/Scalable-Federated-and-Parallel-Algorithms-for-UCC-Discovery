#!/bin/bash

#SBATCH --job-name=enum-all
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=1
#SBATCH --mem=120G
#SBATCH --exclusive
#SBATCH --time=1-00:00:00
#SBATCH --output=/home/rali/enumhyp/logs/enum-all-%j.out
#SBATCH --error=/home/rali/enumhyp/logs/enum-all-%j.err

set -uo pipefail

source "$HOME/activate-enumhyp.sh"

EXECUTABLE="$HOME/enumhyp/build/bin/enumhyp"
DATA_DIR="$HOME/enumhyp/data"
RESULT_DIR="$HOME/enumhyp/result"
LOG_DIR="$HOME/enumhyp/logs"
STATS_DIR="$HOME/enumhyp/stats"

mkdir -p "$RESULT_DIR" "$LOG_DIR" "$STATS_DIR"

SUMMARY="$STATS_DIR/experiment_${SLURM_JOB_ID}.csv"

GRAPHS=(
    "abalone.graph"
    "amalgam1.graph"
    "call_a_bike.graph"
    "civil_service.graph"
    "echocardiogram.graph"
    "fd_reduced_15.graph"
    "fd_reduced_30.graph"
    "flight_1k.graph"
    "hepatitis.graph"
    "horse.graph"
    "ncvoter_allc.graph"
    "uniprot.graph"
)

echo "graph,status,runtime_seconds,runtime_ns,output_size_bytes" > "$SUMMARY"

echo "================================================="
echo "EnumHyp sequential benchmark"
echo "================================================="
echo "Job ID:          $SLURM_JOB_ID"
echo "Node:            $(hostname)"
echo "MPI ranks:       $SLURM_NTASKS"
echo "CPUs on node:    $(nproc)"
echo "Memory requested: 120 GB"
echo "Graphs:          ${#GRAPHS[@]}"
echo "================================================="

echo
echo "CPU information:"
lscpu | grep -E \
    'CPU\(s\)|Core\(s\) per socket|Socket\(s\)|Thread\(s\) per core|Model name'

echo
echo "Memory before experiments:"
free -h

echo

test -x "$EXECUTABLE" || {
    echo "ERROR: Executable not found: $EXECUTABLE"
    exit 1
}

for GRAPH_NAME in "${GRAPHS[@]}"; do

    GRAPH="$DATA_DIR/$GRAPH_NAME"
    BASE="${GRAPH_NAME%.graph}"
    OUTPUT="$RESULT_DIR/${BASE}_MPI.out"
    RUN_LOG="$LOG_DIR/${BASE}_${SLURM_JOB_ID}.log"

    echo
    echo "================================================="
    echo "Starting: $GRAPH_NAME"
    echo "Time:     $(date)"
    echo "Output:   $OUTPUT"
    echo "================================================="

    if [[ ! -f "$GRAPH" ]]; then
        echo "ERROR: Graph not found: $GRAPH"
        echo "$GRAPH_NAME,NOT_FOUND,0,0,0" >> "$SUMMARY"
        continue
    fi

    START_NS=$(date +%s%N)

    mpirun \
        -np "$SLURM_NTASKS" \
        "$EXECUTABLE" \
        enumerate \
        -I legacy \
        "$GRAPH" \
        -o "$OUTPUT" \
        > "$RUN_LOG" 2>&1

    EXIT_CODE=$?

    END_NS=$(date +%s%N)

    RUNTIME_NS=$((END_NS - START_NS))
    RUNTIME_SEC=$(awk \
        -v ns="$RUNTIME_NS" \
        'BEGIN {printf "%.6f", ns / 1000000000}')

    if [[ -f "$OUTPUT" ]]; then
        OUTPUT_SIZE=$(stat -c%s "$OUTPUT")
    else
        OUTPUT_SIZE=0
    fi

    if [[ $EXIT_CODE -eq 0 ]]; then
        STATUS="SUCCESS"
    else
        STATUS="FAILED"
    fi

    echo
    echo "Finished: $GRAPH_NAME"
    echo "Status:   $STATUS"
    echo "Runtime:  $RUNTIME_SEC seconds"
    echo "Output:   $OUTPUT_SIZE bytes"

    echo \
        "$GRAPH_NAME,$STATUS,$RUNTIME_SEC,$RUNTIME_NS,$OUTPUT_SIZE" \
        >> "$SUMMARY"

done

echo
echo "================================================="
echo "ALL DATASETS PROCESSED"
echo "================================================="
echo "Finished: $(date)"
echo
echo "Experiment summary:"
cat "$SUMMARY"

echo
echo "Final memory state:"
free -h

echo
echo "Results stored in:"
echo "$RESULT_DIR"

echo "Statistics stored in:"
echo "$SUMMARY"