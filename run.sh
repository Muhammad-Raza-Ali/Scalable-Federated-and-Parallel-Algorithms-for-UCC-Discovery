#!/bin/bash
#SBATCH --job-name=enum-bike
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --output=/home/rali/enumhyp/logs/enum-abalone-%j.out
#SBATCH --error=/home/rali/enumhyp/logs/enum-abalone-%j.err

set -euo pipefail

source "$HOME/activate-enumhyp.sh"

EXECUTABLE="$HOME/enumhyp/build/bin/enumhyp"
GRAPH="$HOME/enumhyp/data/abalone.graph"
OUTPUT="$HOME/enumhyp/result/abalone_MPI.out"

mkdir -p "$HOME/enumhyp/logs"
mkdir -p "$HOME/enumhyp/result"

echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "MPI processes: $SLURM_NTASKS"
echo "Executable: $EXECUTABLE"
echo "Input: $GRAPH"
echo "Output: $OUTPUT"

test -x "$EXECUTABLE" || {
    echo "Executable not found: $EXECUTABLE"
    exit 1
}

test -f "$GRAPH" || {
    echo "Graph not found: $GRAPH"
    exit 1
}

mpirun \
    -np "$SLURM_NTASKS" \
    "$EXECUTABLE" \
    enumerate \
    -I legacy \
    "$GRAPH" \
    -o "$OUTPUT"

echo "Execution completed."
ls -lh "$OUTPUT"
