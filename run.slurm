#!/bin/bash
#SBATCH --job-name=enumhyp-bike
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --output=/home/rali/enumhyp/logs/%x-%j.out
#SBATCH --error=/home/rali/enumhyp/logs/%x-%j.err

set -euo pipefail

source "$HOME/activate-enumhyp.sh"

EXECUTABLE="$HOME/enumhyp/build/bin/enumhyp"
GRAPH_FILE="$HOME/enumhyp/data/call_a_bike_diffsets.graph"
OUTPUT_FILE="$HOME/enumhyp/result/call_a_bike.out"

echo "Job ID:       $SLURM_JOB_ID"
echo "Node:         $(hostname)"
echo "MPI tasks:    $SLURM_NTASKS"
echo "Executable:   $EXECUTABLE"
echo "Input:        $GRAPH_FILE"
echo "Output:       $OUTPUT_FILE"
echo "Started:      $(date)"

test -x "$EXECUTABLE" || {
    echo "ERROR: executable not found: $EXECUTABLE" >&2
    exit 1
}

test -s "$GRAPH_FILE" || {
    echo "ERROR: graph file not found or empty: $GRAPH_FILE" >&2
    exit 1
}

mkdir -p "$(dirname "$OUTPUT_FILE")"
rm -f "$OUTPUT_FILE"

mpirun \
    "$EXECUTABLE" \
    enumerate \
    -I legacy \
    "$GRAPH_FILE" \
    -o "$OUTPUT_FILE"

echo "Exit status:  $?"
echo "Completed:    $(date)"

if [ -f "$OUTPUT_FILE" ]; then
    echo "Output created successfully:"
    ls -lh "$OUTPUT_FILE"
else
    echo "WARNING: output file was not created."
fi
