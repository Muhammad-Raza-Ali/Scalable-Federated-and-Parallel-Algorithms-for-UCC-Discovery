#!/usr/bin/env bash
set -euo pipefail

ENUMHYP="$HOME/enumhyp/build/bin/enumhyp"
TABLES_DIR="$HOME/enumhyp/tables"
DATA_DIR="$HOME/enumhyp/data"



files=(
    "abalone.csv"
    "amalgam1.csv"
    "call_a_bike.csv"
    "civil_service.csv"
    "echocardiogram.csv"
    "fd_reduced_15.csv"
    "fd_reduced_30.csv"
    "flight_1k.csv"
    "hepatitis.csv"
    "horse.csv"
    "ncvoter_allc.csv"
    "uniprot.csv"
)

for file in "${files[@]}"; do
    input="$TABLES_DIR/$file"
    output="$DATA_DIR/${file%.csv}.graph"

    echo "Generating: $input -> $output"

    if [[ ! -f "$input" ]]; then
        echo "ERROR: Input file not found: $input" >&2
        exit 1
    fi

    "$ENUMHYP" generate "$input" -o "$output"
done

echo "All graph files generated successfully."